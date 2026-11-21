#!/usr/bin/env bash
set -Eeuo pipefail

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

# get the most recent commit which modified any of "$@"
fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}

# get the most recent commit which modified "$1/Dockerfile" or any file COPY'd from "$1/Dockerfile"
dirCommit() {
	local dir="$1"; shift
	(
		cd "$dir"
		fileCommit \
			Dockerfile \
			$(git show HEAD:./Dockerfile | awk '
				toupper($1) == "COPY" {
					# a file taken from another build stage is not in the repository
					from = 0
					for (i = 2; i <= NF; i++) {
						if ($i ~ /^--from=/) {
							from = 1
						}
					}
					if (from) {
						next
					}
					# the last argument is the destination, the options are not paths
					for (i = 2; i < NF; i++) {
						if ($i !~ /^-/) {
							print $i
						}
					}
				}
			')
	)
}

# the image of the final FROM instruction, without its options
finalFrom() {
	awk '
		toupper($1) == "FROM" {
			image = ""
			for (i = 2; i <= NF; i++) {
				if ($i !~ /^-/ && toupper($i) != "AS") {
					image = $i
					break
				}
			}
		}
		END {
			if (image != "") {
				print image
			}
		}
	' "$1"
}

getArches() {
	local repo="$1"; shift
	local officialImagesUrl='https://github.com/docker-library/official-images/raw/master/library/'

	eval "declare -A -g parentRepoToArches=( $(
		find -name 'Dockerfile' -exec awk '
				toupper($1) == "FROM" {
					image = ""
					for (i = 2; i <= NF; i++) {
						if ($i !~ /^-/ && toupper($i) != "AS") {
							image = $i
							break
						}
					}
				}
				END {
					if (image != "" && image !~ /^('"$repo"'|scratch|.*\/.*)(:|$)/) {
						print "'"$officialImagesUrl"'" image
					}
				}
			' '{}' \; \
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

latest="$(curl -fsSL 'https://www.phpmyadmin.net/home_page/version.json' | jq -r '.version' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$')"

for variant in apache fpm fpm-alpine; do
	commit="$(dirCommit "$variant")"
	fullversion="$(git show "$commit":"$variant/Dockerfile" | awk -F" |=" '$1 == "ENV" && $2 == "VERSION" { print $3; exit }')"

	versionAliases=( "$fullversion" "${fullversion%.*}" "${fullversion%.*.*}" )
	if [ "$fullversion" = "$latest" ]; then
		versionAliases+=( "latest" )
	fi

	variantAliases=( "${versionAliases[@]/%/-$variant}" )
	variantAliases=( "${variantAliases[@]//latest-}" )

	if [ "$variant" = "apache" ]; then
		variantAliases+=( "${versionAliases[@]}" )
	fi

	variantParent="$(finalFrom "$variant/Dockerfile")"

	variantArches="${parentRepoToArches[$variantParent]}"

	cat <<-EOE

		Tags: $(join ', ' "${variantAliases[@]}")
		Architectures: $(join ', ' $variantArches)
		GitCommit: $commit
		Directory: $variant
	EOE
done
