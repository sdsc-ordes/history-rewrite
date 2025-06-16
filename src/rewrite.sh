#!/usr/bin/env bash
# shellcheck disable=SC2015

set -eu

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$(git rev-parse --show-toplevel)/.output"
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

    {
        echo "## Branches"
        echo ""
        echo "These are the branches and merge-base ref/commit before the rewrite."
    } >"$f"
    for b in "${branches[@]}"; do
        echo "Branch '$b'"
        merge_base=$(git merge-base refs/heads/main "$b")
        log=$(git log --oneline -1 --pretty=format:"%s" "$merge_base")
        {
            echo "- Branch \`$b\`"
            echo "  Merge-Base SHA: \`$merge_base\`"
            echo "  Merge-Base Subject: \`$log\`"
        } >>"$f"
    done
}

function add_prepend_paths() {
    local -n _delete_paths="$1"
    local -n _script="$2"
    local folder="$3"
    local branch="${4:-main}"

    readarray -t files < <(cd "$folder" && find . -type f)
    for f in "${files[@]}"; do
        path="$folder/$f"
        git_path="${f##./}"

        mkdir -p "$(dirname "$path")"
        if [ "$branch" != "" ]; then
            echo "Store file '$f' from '$branch' to prepend."

            sha=$(git rev-parse "$branch:$git_path") || die "no sha"
            echo "SHA: $sha"
            git cat-file -p "$sha" >"$path"
        else
            echo "Store file '$f' to prepend."
        fi

        _delete_paths+=(--path "$git_path")

        s="
  print('----> Add file $git_path to commit.')
  commit.file_changes.append(
      FileChange(b'M', b'$git_path', store_file('$path'), file_mode('$path'))
  )
"
        _script="$_script$s"

    done
}

cleanup

URL="${URL:-https://gitlab.com/data-custodian/dac-portal.git}"

mkdir -p "$OUT" && cd "$OUT"
git clone --bare --mirror "$URL" server || die "clone server"
cd server &&
    git lfs install --local &&
    git lfs fetch --all &&
    git lfs ls-files &&
    git remote remove origin

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
add_prepend_paths delete_paths script "$DIR/prepend"
add_prepend_paths delete_paths script "$DIR/prepend-fixed" ""

echo -e "Commit Callback Script ==== \n$script\n======"

echo -e "Delete all files which we want to prepend:\n" "${delete_paths[@]}" "---"
git filter-repo --force \
    "${delete_paths[@]}" \
    --invert-paths

echo "Add back files at first commit."
git filter-repo --force --commit-callback "$script"

echo "Rewrite whole history over git-lfs."
# --fixup uses .gitattributes file on a commit basis.
git lfs migrate import --everything --fixup
