#!/bin/bash
set -e

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

for variant in apache fpm fpm-alpine; do
	template="Dockerfile-${base[$variant]}.template"
	cp $template "$variant/Dockerfile"
	cp config.inc.php "$variant/config.inc.php"
	cp docker-entrypoint.sh "$variant/docker-entrypoint.sh"
	cp php.ini "$variant/php.ini"
	sed -ri -e '
		s/%%VARIANT%%/'"$variant"'/;
		s/%%CMD%%/'"${cmd[$variant]}"'/;
	' "$variant/Dockerfile"
done
