#!/bin/bash
set -eu -o pipefail

variants=(
	apache
	fpm
	fpm-alpine
)

declare -A base=(
	[apache]='debian'
	[fpm]='debian'
	[fpm-alpine]='alpine'
)

declare -A php_version=(
	[default]='8.3'
)

declare -A cmd=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
	[fpm-alpine]='php-fpm'
)

gpg_key='3D06A59ECE730EB71B511C17CE752F178259BD92'

function download_url() {
	echo "https://files.phpmyadmin.net/phpMyAdmin/$1/phpMyAdmin-$1-all-languages.tar.xz"
}

# Commit the signed release tag points at; the Dockerfiles build from it
# Release tags are RELEASE_<major>_<minor>_<patch>[_<revision>], the format the
# daily-composer script of phpmyadmin/scripts relies on to process releases
release_tag_re='RELEASE_[0-9]+_[0-9]+_[0-9]+(_[0-9]+)?'

# The version 5.2.3 is released as the tag RELEASE_5_2_3
function release_tag() {
	local version="$1"
	local tag="RELEASE_${version//./_}"

	if ! grep -qE "^${release_tag_re}$" <<< "$tag"; then
		echo >&2 "'$version' does not match the release tag format $release_tag_re. Aborting."
		exit 1
	fi

	echo "$tag"
}

function release_commit() {
	local tag="$1"
	local repo='https://github.com/phpmyadmin/phpmyadmin.git'
	local tags commit

	if ! grep -qE "refs/tags/${release_tag_re}$" <<< "refs/tags/${tag}"; then
		echo >&2 "'$tag' does not match the release tag format $release_tag_re. Aborting."
		exit 1
	fi

	# One request, so the known tags can be listed when this one is missing
	tags="$(git ls-remote --tags "$repo")" || exit 1

	if ! grep -qE "refs/tags/${tag}$" <<< "$tags"; then
		echo >&2 "Unable to find the tag $tag in $repo. The latest release tags are:" >&2
		grep -oE "refs/tags/${release_tag_re}$" <<< "$tags" \
			| sed -e 's@refs/tags/@@' \
			| sort -t_ -k2,2n -k3,3n -k4,4n -k5,5n \
			| tail -n 5 >&2
		exit 1
	fi

	# An annotated tag is listed twice, the tag object and its peeled commit
	commit="$(grep -E "refs/tags/${tag}\^\{\}$" <<< "$tags" | cut -f1)"
	if [ -z "$commit" ]; then
		commit="$(grep -E "refs/tags/${tag}$" <<< "$tags" | cut -f1)"
	fi
	if [ -z "$commit" ]; then
		echo >&2 "Unable to resolve the commit of $tag in $repo. Aborting."
		exit 1
	fi

	echo "$commit"
}

function create_variant() {
	local variant="$1"
	local version="$2"

	local branch
	branch="$(sed -ne 's/^\([0-9]*\.[0-9]*\)\..*$/\1/p' <<< "$version")"
	local phpVersion="${php_version[$version]-${php_version[default]}}"
	local tag
	local releaseBranch="QA_${branch//./_}"
	local commit
	tag="$(release_tag "$version")"
	commit="$(release_commit "$tag")"

	echo "updating $version [$branch] $variant (tag $tag, commit $commit)"

	# Create the variant directory with a Dockerfile
	mkdir -p "$variant"

	local template="Dockerfile-${base[$variant]}.template"
	echo "# DO NOT EDIT: created by update.sh from $template" > "$variant/Dockerfile"
	cat "$template" >> "$variant/Dockerfile"

	# Replace Dockerfile variables
	sed -ri -e '
		s/%%VARIANT%%/'"$variant"'/;
		s/%%VERSION%%/'"$version"'/;
		s/%%PHP_VERSION%%/'"$phpVersion"'/g;
		s/%%GPG_KEY%%/'"$gpg_key"'/g;
		s/%%RELEASE_BRANCH%%/'"$releaseBranch"'/g;
		s/%%TAG%%/'"$tag"'/g;
		s/%%PMA_COMMIT%%/'"$commit"'/g;
		s/%%CMD%%/'"${cmd[$variant]}"'/;
	' "$variant/Dockerfile"

	# Copy docker-entrypoint.sh
	cp docker-entrypoint.sh "$variant/docker-entrypoint.sh"
	if [ "$variant" != "apache" ]; then
		sed -i "/^# start: Apache specific settings$/,/^# end: Apache specific settings$/d" "$variant/docker-entrypoint.sh"
		sed -i "/^\s*# start: Apache specific build$/,/^\s*# end: Apache specific build$/d" "$variant/Dockerfile"
	fi

	# Copy config.inc.php and helpers.php
	cp config.inc.php "$variant/config.inc.php"
	cp helpers.php "$variant/helpers.php"
}

# Check script dependencies
command -v curl >/dev/null 2>&1 || { echo >&2 "'curl' is required but not found. Aborting."; exit 1; }
command -v git >/dev/null 2>&1 || { echo >&2 "'git' is required but not found. Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "'jq' is required but not found. Aborting."; exit 1; }
[ -n "${BASH_VERSINFO}" ] && [ -n "${BASH_VERSINFO[0]}" ] && [ ${BASH_VERSINFO[0]} -ge 4 ] \
	|| { echo >&2 "Bash 4.0 or greater is required. Aborting."; exit 1; }

# Create variants
latest="$(curl -fsSL 'https://www.phpmyadmin.net/home_page/version.json' | jq -r '.version' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$')"
for variant in "${variants[@]}"; do
	create_variant "$variant" "$latest"
done

