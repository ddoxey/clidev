#!/usr/bin/env bash
##
# Optional installer program will copy the clidev.bash file
# to the user's home directory and it will append commands
# to source it in the user's bashrc.
##

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DEV="$SRC_DIR/clidev.bash"


function find_bashrc()
{
    for rc in "$HOME/.bashrc" "$HOME/.bash_profile"
    do
        if [[ -e "$rc" ]]; then echo "$rc"; break; fi
    done
}


function install()
{
    local bashrc="$1"
    if [[ -z $bashrc ]]; then bashrc="$(find_bashrc)"; fi
    if [[ -z $bashrc ]]
    then
        echo "Unable to locate .bashrc in $HOME"          >&2
        echo "USAGE: $(basename "$0") [<path-to-bashrc>]" >&2
        return 1
    fi

    if [[ ! -e "${HOME}/.clidev.bash" ]]
    then
        cp "$CLI_DEV" "${HOME}/.clidev.bash"
        echo "Copied clidev.bash to $HOME"
    fi

    if ! grep -q '[.]clidev[.]bash' "$bashrc"
    then
        echo                                >> "$bashrc"
        echo 'if [ -f .clidev.bash ]; then' >> "$bashrc"
        echo '    . .clidev.bash'           >> "$bashrc"
        echo 'fi'                           >> "$bashrc"
        echo "Updated: $bashrc"
    fi

    if [[ -e "$HOME/.clidev.bash" ]]
    then
        echo "Complete!"
    else
        echo "Failed."
        return 1
    fi

    return 0
}


if [[ $(caller | awk '{print $1}') -eq 0 ]]; then install "$@"; fi
