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

declare -A arch=(
	[arm32v7]='arm'
	[arm64v8]='aarch64'
	[amd64]='amd64'
)

latest="$(curl -fsSL 'https://www.phpmyadmin.net/home_page/version.json' | jq -r '.version')"
sha256="$(curl -fsSL "https://files.phpmyadmin.net/phpMyAdmin/$latest/phpMyAdmin-$latest-all-languages.tar.xz.sha256" | cut -f1 -d ' ' | tr -cd 'a-f0-9' | cut -c 1-64)"

for variant in apache fpm fpm-alpine; do
	cp config.inc.php "$variant/config.inc.php"
	cp hooks/build "$variant/hooks/build"
	cp hooks/push "$variant/hooks/push"
	cp hooks/pre_build "$variant/hooks/pre_build"
	cp hooks/post_push "$variant/hooks/post_push"
	cp multi-arch-manifest.yaml "$variant/multi-arch-manifest.yaml"
	sed -ri -e 's/%%VARIANT%%/'"$variant"'/;' "$variant/multi-arch-manifest.yaml"
	cp docker-entrypoint.sh "$variant/docker-entrypoint.sh"
	for arc in arm32v7 arm64v8 amd64; do
		template="Dockerfile-${base[$variant]}.template"
		cp $template "$variant/Dockerfile.$arc"
		sed -ri -e '
		s/%%VERSION%%/'"$latest"'/;
		s/%%SHA256%%/'"$sha256"'/;
		s/%%VARIANT%%/'"$variant"'/;
		s/%%CMD%%/'"${cmd[$variant]}"'/;
		s/%%ARCH%%/'"${arch[$arc]}"'/g;
		s/%%ARCHLONG%%/'"$arc"'/;
		' "$variant/Dockerfile.$arc"
		if [ $arc == amd64 ]; then
			sed -i '/COPY qemu-amd64-static \/usr\/bin/d' "$variant/Dockerfile.$arc"
			mv "$variant/Dockerfile.$arc" "$variant/Dockerfile"
		fi
	done
done
