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

getArches() {
	local repo="$1"; shift
	local officialImagesUrl='https://github.com/docker-library/official-images/raw/master/library/'

	eval "declare -g -A parentRepoToArches=( $(
		find -name 'Dockerfile' -exec awk '
				toupper($1) == "FROM" && $2 !~ /^('"$repo"'|scratch|microsoft\/[^:]+)(:|$)/ {
					print "'"$officialImagesUrl"'" $2
				}
			' '{}' + \
			| sort -u \
			| xargs bashbrew cat --format '[{{ .RepoName }}:{{ .TagName }}]="{{ join " " .TagEntry.Architectures }}"'
	) )"
}

if ! command -v bashbrew --version &> /dev/null
then
    echo "bashbrew could not be found"
	echo "You can download it from Jenkins at https://github.com/docker-library/bashbrew#installing"
    exit 1
fi

getArches 'phpmyadmin'

# Header.
cat <<-EOH
# This file is generated via https://github.com/phpmyadmin/docker/blob/$(fileCommit "$self")/$self
Maintainers: Isaac Bennetch <bennetch@gmail.com> (@ibennetch),
             William Desportes <williamdes@wdes.fr> (@williamdes)
GitRepo: https://github.com/phpmyadmin/docker.git
EOH

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

latest="$(curl -fsSL 'https://www.phpmyadmin.net/home_page/version.json' | jq -r '.version')"

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

	variantArches="${parentRepoToArches[$variantParent]}"

	cat <<-EOE

		Tags: $(join ', ' "${variantAliases[@]}")
		Architectures: $(join ', ' $variantArches)
		GitCommit: $commit
		Directory: $variant
	EOE
done
