#!/usr/bin/env bash
# shellcheck disable=SC2015

set -eu

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

function die() {
	echo -e "$@" >&2
	exit 1
}

# Extract merge bases.

function cleanup() {
	rm -rf "$DIR/base"
	rm -rf "$DIR/tree"
}

cleanup

url="https://gitlab.com/data-custodian/dac-portal.git"
git clone --bare --single-branch main "$url" server || die "clone server"
git clone --bare "$url" server-all || die "clone server"
git clone "$DIR/server" tree || die "clone"

echo "Store branches file."
cd server-all
f="branches.md"
branches=()
readarray -t branches <(git for-each-ref --format '%(refname)' refs/heads)
echo "## Branches" >$f
for b in "${branches[@]}"; do
	merge_base=$(git merge-base refs/heads/main "$b")
	log=$(git log --oneline -1 "$merge_base")
	{
		echo "- Branch '$b'"
		echo "  Merge-Base SHA: $merge_base"
		echo "  Commit Subject: $log"
	} >>$f
done

echo "Make start commit."
cd tree
git checkout --orphan start &&
	git checkout main -- LICENSE.md &&
	git add LICENSE.md &&
	git commit -a -m "feat: initial license" &&
	new_start=$(git rev-parse HEAD) || die "add license"

echo "Clean License."
cd server
git filter-repo --force \
	--path-regex ".*LICENSE" \
	--path-regex ".*/CLAC|CLAI.*" \
	--all

echo "Git replace."
old_start=$(git rev-list --max-parents=0 main)
echo "$old_start $new_start" >info/grafts

git filter-repo --force
