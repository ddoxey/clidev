#!/bin/bash


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


function vim()
{
    if [[ $# -eq 1 ]] && [[ "$1" =~ ^[0-9]+$ ]]
    then
        local n
        local filename="$(num $1)"
        if [[ "$filename" =~ [:] ]]
        then
            n="+$(awk -F: '{print $2}' <<< "$filename")"
            filename="$(awk -F: '{print $1}' <<< "$filename")"
        fi
        history -s vim $n "$filename"
        /usr/bin/vim $n "$filename"
    else
        /usr/bin/vim "$@"
    fi
}


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


function search()
{
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
                    echo "$result" | num -n $n
                fi
            done <<< "$(egrep -Hn "$pattern" "$filename")"
        fi
    done <<< "$(findf "$ext" | sed "s|^[.]/|$wd/|")"
}
