#!/usr/bin/env bash
##
# Optional installer program will copy the clidev.bash file
# to the user's home directory and it will append commands
# to source it in the user's bashrc.
##

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -A cli_file=(
    [bash]="$SRC_DIR/clidev.bash"
    [vim]="$SRC_DIR/clidev.vim"
)

function find_rc()
{
    local type="$1"
    for rc in "$HOME/.${type}rc" "$HOME/.${type}_profile"
    do
        if [[ -e "$rc" ]]; then echo "$rc"; return 0; fi
    done
    touch "$HOME/.${type}rc"
    echo "$HOME/.${type}rc"
}


function install()
{
    for type in "${!cli_file[@]}" 
    do
        local cli_rc_src="${cli_file[$type]}"
        local cli_fn="$(basename "$cli_rc_src")"
        local rc="$(find_rc $type)"
        local rc_dir="$(dirname "$rc")"
        local cli_rc="${rc_dir}/.${cli_fn}"

        if ! cp -i "$cli_rc_src" "${cli_rc}"
        then
            echo "$(basename "$0") failed to write $cli_rc -- aborted" >&2
            return 1
        fi
        if ! grep -q "$cli_rc" "$rc"
        then
            echo "source $cli_rc" >> "$rc" 
        fi
    done

    return 0
}


if [[ $(caller | awk '{print $1}') -eq 0 ]]; then install "$@"; fi
