#!/bin/bash

# clear and print a page of newlines
function cls()
{
    clear
    for n in $(seq 1 $(tput lines)); do echo; done
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
        sed -e "s|'|\\\'|g" -e "s/\($pattern\)/${on}\1${off}/g" | xargs echo -e
    fi
}

# number lines and add them to the ~/.num database
function num()
{
    if [[ $# -eq 0 ]]
    then
        awk '{printf("[%d] %s\n", NR, $0)}' | \
            tee "${HOME}/.num" | \
            sed -e "s|^[[]\([0-9]\+\)[]][ ]\($wd/\)\?|[\1] |"

    elif [[ $# -eq 2 ]] && [[ "$1" == "-n" ]] && [[ "$2" =~ ^[0-9]+$ ]]
    then
        awk -v N="$2" '{printf("[%d] %s\n", N, $0)}' | \
            tee -a "${HOME}/.num" | \
            sed -e "s|^[[]\([0-9]\+\)[]][ ]\($wd/\)\?|[\1] |"

    elif [[ "$1" = "-c" ]]
    then
        # clear the number db
        >"${HOME}/.num"

    elif [[ "$1" =~ ^[0-9]+$ ]]
    then
        local n="$1"
        local wd="$(pwd)"
        touch "${HOME}/.num"
        grep "^[[]${n}[]][ ]" "${HOME}/.num"       | \
            sed -e "s|^[[][0-9]\+[]][ ]\($wd/\)\?||" \
                -e 's/:\([0-9]\+\):.\+$/:\1/'
    fi
}

# find text files
function findf()
{
    local where ext
    if [[ $# -eq 2 ]]
    then
        where="$1"
        ext="$2"
    elif [[ $# -eq 0 ]]
    then
        where="."
    else
        where="."
        ext="$1"
    fi

    local ignore_re="(^Binary|[.]swp$|[.]pyc$)"

    if [[ -n $ext ]]
    then
        find "$where" -type f -name "*.${ext}" | egrep -v "$ignore_re"
    else
        find "$where" -type f | egrep -v "$ignore_re"
    fi
}

# wrapper for /usr/bin/vim opens numbered files
function vim()
{
    if [[ $# -eq 1 ]]
    then
        local filename="$1"
        if [[ "$filename" =~ ^[0-9]+$ ]]
        then
            local n
            filename="$(num $1)"
            if [[ "$filename" =~ [:] ]]
            then
                n="+$(awk -F: '{print $2}' <<< "$filename")"
                filename="$(awk -F: '{print $1}' <<< "$filename")"
            fi
        elif [[ ! "$filename" =~ [/] ]] && [[ ! -e "$filename" ]]
        then
            if [[ "$filename" =~ [.] ]]
            then
                local found="$(find . -type f -name "$filename" 2>/dev/null | head -n 1)"
                if [[ -n $found ]]
                then
                    filename="$(sed 's|^[.]/||' <<< "$found")"
                fi
            fi
        fi
        if [[ "${filename:0:1}" == "/" ]]
        then
            filename="$(sed "s|$(pwd)/||" <<< "$filename")"
        fi
        history -s vim $n "$filename"
        /usr/bin/vim $n "$filename"
    else
        /usr/bin/vim "$@"
    fi
}

# search for files containing the given pattern
function search()
{
    if [[ $# -lt 1 ]]
    then
        echo "search <regex> [<ext>]" >&2
        return 1
    fi
    local pattern="$1"
    local ext="$2"
    local wd="$(pwd)"
    num -c
    local n=0
    while IFS="\n" read -r filename
    do
        if [[ -f "$filename" ]]
        then
            while IFS="\n" read -r result
            do
                if [[ -n $result ]]
                then
                    let n=n+1
                    if [[ -t 1 ]]
                    then
                        echo "$result" | highlight "$pattern" | num -n $n
                    else
                        echo "$result" | num -n $n
                    fi
                fi
            done <<< "$(egrep -Hn "$pattern" "$filename")"
        fi
    done <<< "$(findf "$ext" | sed "s|^[.]/|$wd/|")"
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

    while IFS="\n" read -r permutation
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
