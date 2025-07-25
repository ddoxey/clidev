#!/bin/bash

# clear and print a page of newlines
function cls()
{
    clear
    for n in $(seq 1 $(tput lines)); do echo; done
}

# strip ANSI escape sequences
function strip_ansi() {
  sed -E $'s/\e\\[[0-9;]*[mK]//g'
}

# highlight lines on STDIN with the given regex
function highlight()
{
    if [[ $# -eq 0 ]]
    then
        cat
    else
        local pattern="$(sed -e 's|\([+/()|]\)|\\\1|g' <<< "$@")"
        local on='\\\\033[32m'
        local off='\\\\033[0m'
        sed -e "s|'|\\\'|g"                       \
            -e "s/\($pattern\)/${on}\1${off}/g"   \
            -e 's/"/\\"/g'                      | \
            xargs echo -e
    fi
}

# expand file paths to absolute paths
function abspath() {
    awk -F: -v OFS=: '{
        if ($1 ~ /^\//) {  # already an absolute path
            abs = $1
        } else {
            cmd = "realpath -q \"" $1 "\""
            ret = cmd | getline abs
            close(cmd)
            if (ret <= 0) abs = $1  # failed
        }

        $1 = abs  # overwrite
        print
    }'
}

# convert paths to relative
function relpath() {
    awk -F: -v OFS=: -v base="$PWD" ' {
        n = ""
        if (match($1, /^[0-9]+ /)) {
            n = substr(line, RSTART, RLENGTH)
            $1 = substr($1, RLENGTH + 1)
        }
        cmd = "realpath -q --relative-to=\"" base "\" \"" $1 "\" 2>/dev/null"
        ret = cmd | getline rel
        close(cmd)
        if (ret <= 0) rel = $1  # failed
        if (n) $1 = n " " rel
        else $1 = rel
        print
    }'
}

# number lines and add them to the ~/.num database
function num()
{
    local num_db="${HOME}/.num"

    if [[ $# -eq 0 ]]
    then
        abspath                               | \
            awk '{printf("%d|%s\n", NR, $0)}' | \
            tee >( strip_ansi > "${num_db}" ) | \
            sed -e 's/[|]/ /'                   \
                -e "s|$(pwd)/||"

    elif [[ $# -eq 2 ]]
    then
        if [[ "$1" == "-a" ]]
        then
            # add an entry with the provided index
            abspath                                        | \
                awk -v N="$2" '{printf("%d|%s\n", N, $0)}' | \
                tee >( strip_ansi > "${num_db}" )          | \
                sed -e 's/[|]/ /'                            \
                    -e "s|$(pwd)/||"
        fi
    elif [[ "$1" = "-c" ]]
    then
        # clear the number db
        >"${num_db}"

    elif [[ "$1" =~ ^[0-9]+$ ]]
    then
        local n="$1"
        local wd="$(pwd)"
        touch "${num_db}"
        grep "^${n}[|]" "${num_db}"          | \
            sed -e 's/^[0-9]\+[|]//'           \
                -e 's/:\([0-9]\+\):.\+$/:\1/'  \
                -e "s|$wd/||"
    fi
}

# find text files
function findf()
{
    local where="."

    if [[ $# -gt 1 ]] && [[ -d "$1" ]]
    then
        where="$1"
        shift
    fi

    unset names
    if [[ $# -gt 0 ]]
    then
        names="$(printf " \x2Do \x2Dname '*.%s'" "$@" | sed 's/-o //')"
        names="-a \\( $names \\)"
    fi

    eval "find $where -type f $names"
}

# find index of substring in string
function string_first_of()
{
    local str="$1"
    local sub="$2"
    local aft=${str#*$sub}
    local pos=$(( ${#str} - ${#aft} - ${#sub} ))
    echo $pos
    if [[ $pos -lt 0 ]]; then return 1; fi
    return 0
}

# find last index of substring in string
function string_last_of()
{
    local str="$1"
    local sub="$2"
    local rts="$(rev <<< "$str")"
    local sop=$(string_first_of "$rts" "$sub")
    if [[ $sop -lt 0 ]]; then echo "$sop"; return 1; fi
    echo $(( ${#str} - $sop - 1 ))
    return 0
}

# true if string starts with substring
function string_starts_with()
{
    local str="$1"
    local sub="$2"
    local pos=$(string_first_of "$str" "$sub")
    if [[ $pos -eq 0 ]]; then return 0; fi
    return 1
}

# true if string ends with substring
function string_ends_with()
{
    local str="$1"
    local sub="$2"
    local pos=$(string_first_of "$str" "$sub")
    if [[ $(( ${#str} - $pos )) -eq ${#sub} ]]; then return 0; fi
    return 1
}

# wrapper for /usr/bin/vim opens numbered files
function vim()
{
    if [[ $# -gt 1 ]]
    then
        /usr/bin/vim "$@"
    else
        local n
        local filename="$1"

        if [[ "$filename" =~ ^[0-9]+$ ]]
        then
            filename="$(num $filename)"
        fi
        if [[ "$filename" =~ [:][0-9]+$ ]]
        then
            n="+$(awk -F: '{print $NF}' <<< "$filename")"
            filename="$(sed 's|:[0-9]\+$||' <<< "$filename")"
        fi
        history -s vim $n "$filename"
        /usr/bin/vim $n "$filename"
    fi
}

# search for files containing the given pattern
function search()
{
    if [[ $# -lt 1 ]]
    then
        echo "search <regex> [<ext> ...]" >&2
        return 1
    fi
    local pattern="$1"
    shift

    if [[ $# -eq 0 ]]
    then
        set -- "cpp" "hpp" "c" "h" "py"
    fi
    local names="$(printf " \x2Do \x2Dname '*.%s'" "$@" | sed 's/-o //')"

    set -- "./.git" "./build"
    local prunes="$(printf " \x2Do \x2Dpath '%s'" "$@" | sed 's/-o //')"

    local cmd
    cmd="${cmd}find . \( $prunes \) -prune "
    cmd="${cmd}-o -type f \\( $names \\) "
    cmd="${cmd}-exec grep -Hn --color=always \"${pattern}\" {} \; "
    cmd="${cmd}| sed 's|[.]/||' "

    eval "$cmd" | num
}

# enumerate all permutations of the given tokens
function permute()
{
    if [[ $# -eq 0 ]]
    then
        echo "permute <token 1> <token 2> [... <token 8>]" >&2
        return 1
    elif [[ $# -eq 1 ]]
    then
        echo "$1"
        return
    elif [[ $# -gt 8 ]]
    then
        echo "$(basename "$0"): No more than 8 tokens" >&2
        return 1
    fi

    local token="$1"
    shift
    local p_len=$#

    while IFS=$'\n' read -r permutation
    do
        local ptokens=($permutation)
        local k=0

        for i in $(seq 0 $p_len)
        do
            for j in $(seq 0 $p_len)
            do
                if [[ $j -eq $k ]]
                then
                    echo -n " $token";
                fi
                if [[ -n ${ptokens[$j]} ]]
                then
                    echo -n " ${ptokens[$j]}"
                fi
            done
            echo
            let k=k+1
        done
    done <<< "$(permute "$@")" | sed 's/ //'
}

# list matching files with a recursive search
function list()
{
    if [[ $# -eq 0 ]]
    then
        echo "list <token> [<token> ...]" >&2
        return 1
    fi

    permute "$@" | \
        awk -v q="'" '{
            gsub(/ /, "*", $0)
            find = "find . -type f -iname " q "*" $0 "*" q " 2>/dev/null"
            find | getline filename
            close(find)
            if (filename) {
                gsub(/^[.][/]/, "", filename)
                if (++count[filename] == 1) print filename
            }
        }' | \
        num
}
