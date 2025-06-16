#!/usr/bin/env bash
# shellcheck disable=SC2015

set -eu

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$(git rev-parse --show-toplevel)"
cd "$DIR"

function die() {
    echo -e "$@" >&2
    exit 1
}

function cleanup() {
    rm -rf "$OUT/server"
    rm -rf "$OUT/tree"
}

function store_branches() {
    cd "$OUT/server"

    f="$OUT/branches.md"
    branches=()
    readarray -t branches < <(git for-each-ref --format '%(refname)')

    echo "## Branches" >"$f"
    for b in "${branches[@]}"; do
        echo "Branch '$b'"
        merge_base=$(git merge-base refs/heads/main "$b")
        log=$(git log --oneline -1 --pretty=format:"%s" "$merge_base")
        {
            echo "- Branch \`$b\`"
            echo "  Merge-Base SHA: \`$merge_base\`"
            echo "  Commit Subject: \`$log\`"
        } >>"$f"
    done
}

cleanup

URL="${URL:-https://gitlab.com/data-custodian/dac-portal.git}"
BRANCH_FILES="main"

mkdir -p "$OUT" && cd "$OUT"
git clone --bare "$URL" server || die "clone server"
git -C "server" remote remove origin

git clone "$OUT/server" tree || die "clone tree"

echo "Store branches file."
store_branches

cd "$OUT/server"
script=$(
    cat <<EOF
import os
import subprocess

def store_file(file):
  fhash = subprocess.check_output(["git", "hash-object", "-w", file]).strip()
  return fhash

def file_mode(file):
  return b'100755' if os.access(file, os.X_OK) else b'100644'

if not commit.parents:
  print("ROOT commit: appending files")
EOF
)

delete_paths=()
readarray -t files < <(cd "$DIR/prepend" && find . -type f)
for f in "${files[@]}"; do
    path="$DIR/prepend/$f"
    echo "Store file '$f' from '$BRANCH_FILES' to prepend."

    mkdir -p "$(dirname "$path")"
    git_path="${f##./}"
    sha=$(git rev-parse "$BRANCH_FILES:$git_path") || die "no sha"
    echo "SHA: $sha"
    git cat-file -p "$sha" >"$path"

    delete_paths+=(--path "$git_path")

    s="
  print('----> Add file $git_path to commit.')
  commit.file_changes.append(
    FileChange(b'M', b'$git_path', store_file('$path'), file_mode('$path'))
  )"
    script="$script$s"

done

echo -e "Commit Callback Script ==== \n$script\n======"

echo -e "Delete all files which we want to prepend:\n" "${delete_paths[@]}" "---"
git filter-repo --force \
    "${delete_paths[@]}" \
    --invert-paths

echo "Add back files at first commit."
git filter-repo --force --commit-callback "$script"
