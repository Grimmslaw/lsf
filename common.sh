#!/bin/bash

nolog=0
s_nolog="NONE"
error=1
s_error="ERROR"
warn=2
s_warn="WARN"
info=3
s_info="INFO"
trace=4
s_trace="TRACE"

logstr_from_num () {
    case "$1" in
        "$error")
            echo "$s_error"
            ;;
        "$warn" )
            echo "$s_warn"
            ;;
        "$info" )
            echo "$s_info"
            ;;
        "$trace")
            echo "$s_trace"
            ;;
        "$nolog")
            echo "$s_nolog"
            ;;
        *       )
            echo "No loglevel named ""$1""."
            return 1
            ;;
    esac
}

lognum_from_str () {
    val="$(echo "$1" | awk '{print toupper($0)}')"
    case "$val" in
        "$s_error"  )
            echo "$error"
            ;;
        "$s_warn"   )
            echo "$warn"
            ;;
        "$s_info"   )
            echo "$info"
            ;;
        "$s_trace"  )
            echo "$trace"
            ;;
        "$s_nolog"  )
            echo "$nolog"
            ;;
        *           )
            echo "No loglevel with numeric value of ""$1"""
            return 1
            ;;
    esac
}

log () {
    level="$1"
    logfrom="$2"
    logmsg="$3"
    minlevel="$4"
    if [[ -z "$minlevel" ]]; then
        minlevel="$error"
    fi

    if [[ "$level" -ne 0 ]] && [[ "$level" -le "$minlevel" ]]; then
        logstr="$(logstr_from_num "$level")"
        echo "[$logstr] ($logfrom)    $logmsg" 1>&2
    fi
}

