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
	[default]='8.2'
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

function create_variant() {
	local variant="$1"
	local version="$2"
	local sha256="$3"

	local branch="$(sed -ne 's/^\([0-9]*\.[0-9]*\)\..*$/\1/p' <<< "$version")"
	local url="$(download_url "$version")"
	local ascUrl="$(download_url "$version").asc"
	local phpVersion="${php_version[$version]-${php_version[default]}}"

	echo "updating $version [$branch] $variant"

	# Create the variant directory with a Dockerfile
	mkdir -p "$variant"

	local template="Dockerfile-${base[$variant]}.template"
	echo "# DO NOT EDIT: created by update.sh from $template" > "$variant/Dockerfile"
	cat "$template" >> "$variant/Dockerfile"

	# Replace Dockerfile variables
	sed -ri -e '
		s/%%VARIANT%%/'"$variant"'/;
		s/%%VERSION%%/'"$version"'/;
		s/%%SHA256%%/'"$sha256"'/;
		s/%%DOWNLOAD_URL%%/'"$(sed -e 's/[\/&]/\\&/g' <<< "$url")"'/;
		s/%%DOWNLOAD_URL_ASC%%/'"$(sed -e 's/[\/&]/\\&/g' <<< "$ascUrl")"'/;
		s/%%PHP_VERSION%%/'"$phpVersion"'/g;
		s/%%GPG_KEY%%/'"$gpg_key"'/g;
		s/%%CMD%%/'"${cmd[$variant]}"'/;
	' "$variant/Dockerfile"

	# Copy docker-entrypoint.sh
	cp docker-entrypoint.sh "$variant/docker-entrypoint.sh"
	if [ "$variant" != "apache" ]; then
		sed -i "/^# start: Apache specific settings$/,/^# end: Apache specific settings$/d" "$variant/docker-entrypoint.sh"
	fi

	# Copy config.inc.php
	cp config.inc.php "$variant/config.inc.php"

	# Add variant to versions.json
	versionVariantsJson="$(jq -e \
		--arg branch "$branch" --arg variant "$variant" --arg base "${base[$variant]}" --arg phpVersion "$phpVersion" \
		'.[$branch].variants[$variant] = {"variant": $variant, "base": $base, "phpVersion": $phpVersion}' versions.json)"
	versionJson="$(jq -e \
		--arg branch "$branch" --arg version "$version" --arg sha256 "$sha256" --arg url "$url" --arg ascUrl "$ascUrl" --argjson variants "$versionVariantsJson" \
		'.[$branch] = {"branch": $branch, "version": $version, "sha256": $sha256, "url": $url, "ascUrl": $ascUrl, "variants": $variants[$branch].variants}' versions.json)"
	printf '%s\n' "$versionJson" > versions.json
}

# Check script dependencies
command -v curl >/dev/null 2>&1 || { echo >&2 "'curl' is required but not found. Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "'jq' is required but not found. Aborting."; exit 1; }
[ -n "${BASH_VERSINFO}" ] && [ -n "${BASH_VERSINFO[0]}" ] && [ ${BASH_VERSINFO[0]} -ge 4 ] \
	|| { echo >&2 "Bash 4.0 or greater is required. Aborting."; exit 1; }

# Create variants
printf '%s\n' "{}" > versions.json

latest="$(curl -fsSL 'https://www.phpmyadmin.net/home_page/version.json' | jq -r '.version' | grep -E '^[0-9]{1,}.[0-9]{1,}.[0-9]{1,}$')"
sha256="$(curl -fsSL "$(download_url "$latest").sha256" | cut -f1 -d ' ' | tr -cd 'a-f0-9' | cut -c 1-64)"

for variant in "${variants[@]}"; do
	create_variant "$variant" "$latest" "$sha256"
done

# Cleanup the file as for now it's not wanted in the repository
rm versions.json
