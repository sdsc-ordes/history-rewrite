set positional-arguments
set shell := ["bash", "-cue"]
root_dir := `git rev-parse --show-toplevel`
flake_dir := root_dir / "tools/nix"
output_dir := root_dir / ".output"
build_dir := output_dir / "build"

# Default target if you do not specify a target.
default:
    just --list --unsorted

# Enter the default Nix development shell and execute the command `"$@`.
develop *args:
    just nix-develop "default" "$@"

# Format the project.
format *args:
    "{{root_dir}}/tools/scripts/setup-config-files.sh"
    nix run --accept-flake-config {{flake_dir}}#treefmt -- "$@"

# Setup the project.
setup *args:
    cd "{{root_dir}}" && ./tools/scripts/setup.sh

# Run commands over the ci development shell.
ci *args:
    just nix-develop "ci" "$@"

## Nix Stuff ==================================================================
# Show all packages configured in the Nix `flake.nix`.
nix-list *args:
    cd tools/nix && nix flake --no-pure-eval show

# Enter the Nix `devShell` with name `$1` and execute the command `${@:2}` (default command is '$SHELL')
[private]
nix-develop *args:
    #!/usr/bin/env bash
    set -eu
    cd "{{root_dir}}"
    shell="$1"; shift 1;
    args=("$@") && [ "${#args[@]}" != 0 ] || args="$SHELL"
    nix develop --no-pure-eval --accept-flake-config \
        "{{flake_dir}}#$shell" --command "${args[@]}"
## ============================================================================

# Run the rewrite.
run:
    ./src/rewrite.sh

# Inspect the rewrite.
inspect:
    cd ./.output/server && gitk --all &
