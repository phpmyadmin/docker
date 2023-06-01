#!/bin/bash
set -eu -o pipefail -x

# Check for dependencies
command -v curl >/dev/null 2>&1 || { echo >&2 "'curl' is required but not found. Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "'jq' is required but not found. Aborting."; exit 1; }
[ -n "${BASH_VERSINFO}" ] && [ -n "${BASH_VERSINFO[0]}" ] && [ ${BASH_VERSINFO[0]} -ge 4 ] \
	|| { echo >&2 "Bash 4.0 or greater is required. Aborting."; exit 1; }

declare -A cmd=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
	[fpm-alpine]='php-fpm'
)

declare -A base=(
	[apache]='debian'
	[fpm]='debian'
	[fpm-alpine]='alpine'
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

	echo "updating $version [$branch] $variant"

	local template="Dockerfile-${base[$variant]}.template"
	cp "$template" "$variant/Dockerfile"
	cp config.inc.php "$variant/config.inc.php"
	cp docker-entrypoint.sh "$variant/docker-entrypoint.sh"
	sed -ri -e '
		s/%%VERSION%%/'"$version"'/;
		s/%%SHA256%%/'"$sha256"'/;
		s/%%DOWNLOAD_URL%%/'"$(sed -e 's/[\/&]/\\&/g' <<< "$url")"'/;
		s/%%DOWNLOAD_URL_ASC%%/'"$(sed -e 's/[\/&]/\\&/g' <<< "$ascUrl")"'/;
		s/%%GPG_KEY%%/'"$gpg_key"'/g;
		s/%%VARIANT%%/'"$variant"'/;
		s/%%CMD%%/'"${cmd[$variant]}"'/;
	' "$variant/Dockerfile"
	if [ "$variant" != "apache" ]; then
		sed -i "/^# start: Apache specific settings$/,/^# end: Apache specific settings$/d" "$variant/docker-entrypoint.sh"
	fi
}

latest="$(curl -fsSL 'https://www.phpmyadmin.net/home_page/version.json' | jq -r '.version')"
sha256="$(curl -fsSL "$(download_url "$latest").sha256" | cut -f1 -d ' ' | tr -cd 'a-f0-9' | cut -c 1-64)"

for variant in apache fpm fpm-alpine; do
	create_variant "$variant" "$latest" "$sha256"
done
