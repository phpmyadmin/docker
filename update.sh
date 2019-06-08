#!/bin/bash
set -e

# Check for dependencies
command -v curl >/dev/null 2>&1 || { echo >&2 "'curl' is required but not found. Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "'jq' is required but not found. Aborting."; exit 1; }
if [ -z "${BASH_VERSINFO}" ] || [ -z "${BASH_VERSINFO[0]}" ] || [ ${BASH_VERSINFO[0]} -lt 4 ]; then
  echo "BASH version 4.0 or greater is required. Aborting."
  exit 1
fi

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

latest="$(curl -fsSL 'https://www.phpmyadmin.net/home_page/version.json' | jq -r '.version')"

for variant in apache fpm fpm-alpine; do
	template="Dockerfile-${base[$variant]}.template"
	cp $template "$variant/Dockerfile"
	cp config.inc.php "$variant/config.inc.php"
	cp docker-entrypoint.sh "$variant/docker-entrypoint.sh"
	cp php.ini "$variant/php.ini"
	sed -ri -e '
		s/%%VERSION%%/'"$latest"'/;
		s/%%VARIANT%%/'"$variant"'/;
		s/%%CMD%%/'"${cmd[$variant]}"'/;
	' "$variant/Dockerfile"
done
