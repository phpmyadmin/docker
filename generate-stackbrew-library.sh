#!/bin/bash
set -e

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Get the most recent commit which modified any of "$@".
fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}

# Get the most recent commit which modified "$1/Dockerfile" or any file that
# the Dockerfile copies into the rootfs (with COPY).
dockerfileCommit() {
	local dir="$1"; shift
	(
		cd "$dir";
		fileCommit Dockerfile \
			$(git show HEAD:./Dockerfile | awk '
				toupper($1) == "COPY" {
					for (i = 2; i < NF; i++)
							print $i;
				}
			')
	)
}

# depends on docker library
#getArches() {
#	local repo="$1"; shift
#	local officialImagesUrl='https://github.com/docker-library/official-images/raw/master/library/'
#
#	eval "declare -g -A parentRepoToArches=( $(
#		find -name 'Dockerfile' -exec awk '
#				toupper($1) == "FROM" && $2 !~ /^('"$repo"'|scratch|microsoft\/[^:]+)(:|$)/ {
#					print "'"$officialImagesUrl"'" $2
#				}
#			' '{}' + \
#			| sort -u \
#			| xargs bashbrew cat --format '[{{ .RepoName }}:{{ .TagName }}]="{{ join " " .TagEntry.Architectures }}"'
#	) )"
#}
#getArches 'phpmyadmin'

# Header.
cat <<-EOH
# This file is generated via https://github.com/phpmyadmin/docker/blob/$(fileCommit "$self")/$self
Maintainers: Isaac Bennetch <bennetch@gmail.com>
             Michal Čihař <michal@cihar.com>
GitRepo: https://github.com/phpmyadmin/docker.git
EOH

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

latest="$(
	git ls-remote --tags https://github.com/phpmyadmin/phpmyadmin.git \
		| cut -d/ -f3 \
		| grep -vE -- '-rc|-b' \
		| sort -V \
		| tail -1
)"

for variant in apache fpm fpm-alpine; do
	commit="$(dockerfileCommit "$variant")"
	fullversion="$(git show "$commit":"$variant/Dockerfile" | awk '$1 == "ENV" && $2 == "VERSION" { print $3; exit }')"

	versionAliases=( "$fullversion" "${fullversion%.*}" "${fullversion%.*.*}" )
	if [ "$fullversion" = "$latest" ]; then
		versionAliases+=( "latest" )
	fi

	variantAliases=( "${versionAliases[@]/%/-$variant}" )
	variantAliases=( "${variantAliases[@]//latest-}" )

	if [ "$variant" = "apache" ]; then
		variantAliases+=( "${versionAliases[@]}" )
	fi

	variantParent="$(awk 'toupper($1) == "FROM" { print $2 }' "$variant/Dockerfile")"

	# depends on docker library
	#variantArches="${parentRepoToArches[$variantParent]}"
	variantArches="amd64 arm32v7 arm64v8 i386 ppc64le"

	cat <<-EOE

		Tags: $(join ', ' "${variantAliases[@]}")
		Architectures: $(join ', ' $variantArches)
		GitCommit: $commit
		Directory: $variant
	EOE
done
