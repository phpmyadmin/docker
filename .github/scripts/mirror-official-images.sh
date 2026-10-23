#!/usr/bin/env bash
set -Eeuo pipefail

# Mirror tags of the official phpMyAdmin image into the legacy namespace.
# See https://github.com/phpmyadmin/docker/issues/363
#
# Usage:
#   mirror-official-images.sh plan [-j|--json] # show what would be synced
#   mirror-official-images.sh list-tags        # JSON array of the tags this repo publishes
#   mirror-official-images.sh login            # authenticate to the registry
#   mirror-official-images.sh mirror <tag>     # mirror one tag
#
# `plan` prints the actions and, in CI, writes the matrix of tags to sync to
# $GITHUB_OUTPUT. It needs the same tools as the workflow: bashbrew, git and
# curl (used by generate-stackbrew-library.sh), plus jq and skopeo.

SOURCE_REPO="${SOURCE_REPO:-docker.io/library/phpmyadmin}"
TARGET_REPO="${TARGET_REPO:-docker.io/phpmyadmin/phpmyadmin}"

error_log="$(mktemp)"
trap 'rm -f "${error_log}"' EXIT

# The tags this repository publishes, as a compact JSON array
generate_tags() {
	local tags
	# The explicit `|| return` matters: this function is called from an OR
	# list, where set -e is disabled, so a failing generator would otherwise
	# be ignored and a partial tag list used
	tags="$(
		cd "$(dirname "$(readlink -f "$0")")/../.."
		./generate-stackbrew-library.sh \
			| awk '/^Tags:/ { sub(/^Tags:[[:space:]]*/, ""); print }' \
			| tr ',' '\n' \
			| sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
			| sort -u \
			| jq -R -s -c 'split("\n") | map(select(length > 0))'
	)" || {
		echo 'Failed to generate the tag list from generate-stackbrew-library.sh' >&2
		return 1
	}

	if [ "${tags}" = '[]' ]; then
		echo 'No tags found in generate-stackbrew-library.sh output' >&2
		return 1
	fi

	printf '%s\n' "${tags}"
}

list_tags() {
	local tags
	tags="$(generate_tags)" || return

	printf '%s\n' "${tags}"

	if [ -n "${GITHUB_OUTPUT:-}" ]; then
		printf 'tags=%s\n' "${tags}" >>"${GITHUB_OUTPUT}"
	fi
}

login() {
	local registry="${TARGET_REPO%%/*}"
	: "${DOCKERHUB_USERNAME:?DOCKERHUB_USERNAME is not set}"
	: "${DOCKERHUB_TOKEN:?DOCKERHUB_TOKEN is not set}"

	printf '%s' "${DOCKERHUB_TOKEN}" \
		| skopeo login --username "${DOCKERHUB_USERNAME}" --password-stdin "${registry}"
}

# Only a missing tag is expected; an unknown repository ("name unknown") or a
# rejected credential has to fail the run
is_missing() {
	grep -qiE 'manifest unknown' "${error_log}"
}

# Digest, version and build date of the linux/amd64 image behind a tag,
# tab separated so that empty or blank values cannot shift the fields
inspect_meta() {
	skopeo inspect --no-tags --retry-times 3 \
		--override-os linux --override-arch amd64 "$1" 2>"${error_log}" \
		| jq -r 'def nz: if . == null or . == "" then "unknown" else tostring end;
			[(.Digest | nz), (.Labels["org.opencontainers.image.version"] | nz), (.Created | nz)]
			| @tsv' 2>>"${error_log}"
}

# Print a tag's "digest<TAB>version<TAB>created", failing on anything but a
# missing tag
tag_meta() {
	local rc=0 meta
	meta="$(inspect_meta "$1")" || rc=$?
	if [ "${rc}" -ne 0 ]; then
		if ! is_missing; then
			echo "Failed to inspect $1:" >&2
			cat "${error_log}" >&2
			return "${rc}"
		fi
		return 0
	fi
	printf '%s\n' "${meta}"
}

# Fill the result_* variables describing what should happen to a tag.
# This is the single place where the sync rules live, shared by `plan`
# and `mirror` so that the two cannot disagree.
decide() {
	local tag="$1"
	local src_meta dst_meta

	result_src="${SOURCE_REPO}:${tag}"
	result_dst="${TARGET_REPO}:${tag}"
	result_action=""
	result_reason=""
	result_src_digest=""
	result_src_version="unknown"
	result_src_created="unknown"
	result_dst_digest=""
	result_dst_version=""
	result_dst_created=""

	src_meta="$(tag_meta "docker://${result_src}")" || return
	if [ -z "${src_meta}" ]; then
		result_action="skip"
		result_reason="not in the official image"
		return 0
	fi
	IFS=$'\t' read -r result_src_digest result_src_version result_src_created <<<"${src_meta}"
	if [ "${result_src_digest}" = "unknown" ]; then
		echo "Could not read the manifest digest of docker://${result_src}" >&2
		return 1
	fi

	dst_meta="$(tag_meta "docker://${result_dst}")" || return
	if [ -n "${dst_meta}" ]; then
		IFS=$'\t' read -r result_dst_digest result_dst_version result_dst_created <<<"${dst_meta}"
	fi

	if [ -z "${result_dst_digest}" ]; then
		result_action="copy"
		result_reason="missing from the target"
		return 0
	fi

	# A newer target must never be overwritten, so an unreadable source
	# version means we cannot tell: keep what is there
	if [ "${result_dst_version}" != "unknown" ] && [ "${result_src_version}" = "unknown" ]; then
		result_action="skip"
		result_reason="source version unreadable, keeping ${result_dst_version}"
		return 0
	fi

	if [ "${result_src_version}" != "unknown" ] && [ "${result_dst_version}" != "unknown" ] \
		&& [ "${result_src_version}" != "${result_dst_version}" ] \
		&& [ "$(printf '%s\n%s\n' "${result_src_version}" "${result_dst_version}" | sort -V | tail -n 1)" = "${result_dst_version}" ]; then
		result_action="skip"
		result_reason="target is newer (${result_dst_version} > ${result_src_version})"
		return 0
	fi

	if [ "${result_dst_digest}" = "${result_src_digest}" ]; then
		result_action="skip"
		result_reason="already up to date"
		return 0
	fi

	result_action="copy"
	result_reason="manifest differs"
	return 0
}

# "version built" of an image, or "absent" when the tag does not exist
describe_image() {
	local digest="$1" version="$2" created="$3"
	if [ -z "${digest}" ]; then
		printf 'absent'
		return
	fi
	if [ "${version}" = "unknown" ] && [ "${created}" = "unknown" ]; then
		printf 'version unknown'
		return
	fi
	printf '%s built %s' "${version}" "${created}"
}

# Print the plan and write the matrix of tags to sync to $GITHUB_OUTPUT
plan() {
	local json=0
	case "${1:-}" in
	'') ;;
	-j | --json) json=1 ;;
	*)
		echo "usage: $0 plan [-j|--json]" >&2
		return 1
		;;
	esac
	if [ "$#" -gt 1 ]; then
		echo "usage: $0 plan [-j|--json]" >&2
		return 1
	fi

	local tags tag entries=() to_copy=0 to_skip=0 matrix

	tags="$(generate_tags)" || return

	jq -e 'type == "array" and length > 0' >/dev/null <<<"${tags}" || {
		echo 'Malformed tag list from generate-stackbrew-library.sh' >&2
		return 1
	}

	if [ "${json}" -eq 0 ]; then
		printf '%-24s %-6s %-44s %-44s %s\n' 'TAG' 'ACTION' 'SOURCE' 'TARGET' 'REASON'
	fi

	# Not mapfile: it needs bash 4, and this script is meant to run locally
	# on whatever bash the user has
	while IFS= read -r tag; do
		[ -n "${tag}" ] || continue
		decide "${tag}" || return

		case "${result_action}" in
		copy) to_copy=$((to_copy + 1)) ;;
		*) to_skip=$((to_skip + 1)) ;;
		esac

		if [ "${json}" -eq 0 ]; then
			printf '%-24s %-6s %-44s %-44s %s\n' \
				"${tag}" "${result_action}" \
				"$(describe_image "${result_src_digest}" "${result_src_version}" "${result_src_created}")" \
				"$(describe_image "${result_dst_digest}" "${result_dst_version}" "${result_dst_created}")" \
				"${result_reason}"
		fi

		entries+=("$(jq -n -c \
			--arg tag "${tag}" \
			--arg action "${result_action}" \
			--arg reason "${result_reason}" \
			--arg src "${result_src}" \
			--arg srcDigest "${result_src_digest}" \
			--arg srcVersion "${result_src_version}" \
			--arg srcCreated "${result_src_created}" \
			--arg dst "${result_dst}" \
			--arg dstDigest "${result_dst_digest}" \
			--arg dstVersion "${result_dst_version}" \
			--arg dstCreated "${result_dst_created}" \
			'{tag: $tag, action: $action, reason: $reason,
			  source: {ref: $src, digest: $srcDigest, version: $srcVersion, created: $srcCreated},
			  target: {ref: $dst, digest: $dstDigest, version: $dstVersion, created: $dstCreated}}')")
	done < <(jq -r '.[]' <<<"${tags}")

	if [ "${to_copy}" -eq 0 ]; then
		matrix='{"include":[]}'
	else
		matrix="$(printf '%s\n' "${entries[@]}" \
			| jq -s -c '{include: [.[] | select(.action == "copy") | {tag}]}')"
	fi

	if [ "${json}" -eq 1 ]; then
		printf '%s\n' "${entries[@]}" | jq -s .
	else
		printf '\n%d to sync, %d skipped\n' "${to_copy}" "${to_skip}"
	fi

	if [ -n "${GITHUB_OUTPUT:-}" ]; then
		printf 'matrix=%s\n' "${matrix}" >>"${GITHUB_OUTPUT}"
		printf 'count=%d\n' "${to_copy}" >>"${GITHUB_OUTPUT}"
	fi
}

mirror() {
	local tag="$1"
	local after_digest="" after_version="unknown" after_created="unknown"
	local after attempt rc current_src delay

	decide "${tag}" || return

	printf 'Before: %s version=%s built=%s digest=%s\n' \
		"${result_src}" "${result_src_version}" "${result_src_created}" "${result_src_digest:-none}"
	printf 'Before: %s version=%s built=%s digest=%s\n' \
		"${result_dst}" "${result_dst_version:-none}" "${result_dst_created:-none}" "${result_dst_digest:-none}"

	if [ "${result_action}" != "copy" ]; then
		echo "Tag '${tag}': ${result_reason}; nothing to do"
		return 0
	fi

	echo "Copying '${tag}' (${result_reason}) from ${SOURCE_REPO} to ${TARGET_REPO}"
	skopeo copy --all --preserve-digests --retry-times 3 \
		"docker://${result_src}" "docker://${result_dst}"

	# Give the registry time to serve the new manifest before reporting
	for attempt in 1 2 3 4; do
		rc=0
		after="$(tag_meta "docker://${result_dst}")" || rc=$?
		if [ "${rc}" -ne 0 ]; then
			echo "Copy reported success but the destination cannot be read" >&2
			return "${rc}"
		fi
		IFS=$'\t' read -r after_digest after_version after_created <<<"${after}"

		if [ "${after_digest}" = "${result_src_digest}" ]; then
			break
		fi

		# The upstream tag can move between our inspect and the copy
		rc=0
		current_src="$(tag_meta "docker://${result_src}")" || rc=$?
		if [ "${rc}" -eq 0 ] && [ -n "${current_src}" ] \
			&& [ "${after_digest}" != "unknown" ] \
			&& [ "${current_src%%$'\t'*}" != "unknown" ] \
			&& [ "${after_digest}" = "${current_src%%$'\t'*}" ]; then
			break
		fi

		if [ "${attempt}" -eq 4 ]; then
			if [ -z "${after_digest}" ]; then
				echo "Destination ${result_dst} still does not exist; expected ${result_src_digest}" >&2
			else
				echo "Destination digest ${after_digest} does not match source ${result_src_digest}" >&2
			fi
			return 1
		fi

		case "${attempt}" in
		1) delay=5 ;;
		2) delay=15 ;;
		*) delay=30 ;;
		esac
		echo "Waiting ${delay}s for the registry to publish the new manifest"
		sleep "${delay}"
	done

	printf 'After: %s version=%s built=%s digest=%s\n' \
		"${result_dst}" "${after_version}" "${after_created}" "${after_digest}"
}

case "${1:-}" in
list-tags)
	list_tags
	;;
plan)
	shift
	plan "$@"
	;;
login)
	login
	;;
mirror)
	if [ -z "${2:-}" ] || [ "$#" -gt 2 ]; then
		echo "usage: $0 mirror <tag>" >&2
		exit 1
	fi
	mirror "$2"
	;;
*)
	echo "usage: $0 {plan [-j|--json]|list-tags|login|mirror <tag>}" >&2
	exit 1
	;;
esac
