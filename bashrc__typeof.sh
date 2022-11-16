# If $1 is defined, echo "alias", "keyword", "function", "builtin" or "file".
# If not defined, echo "" and return error status.
typeof_command() {
    type -t "$1"
    return  # type -t fails silently if not defined
}

alias_defined() { [[ "$(typeof_command "$1")" = "alias" ]]; }
function_defined() { [[ "$(typeof_command "$1")" = "function" ]]; }
executable_exists() { [[ "$(typeof_command "$1")" = "file" ]]; }

# Bash 4+ only. Returns 1 of: undefined, null, scalar, array, hash, unknown
typeof() {
    local var="$1"
    [[ -z "$var" ]] && eecho "usage: typeof var" && return 1

    read -r opt expr <<< "$(declare -p "$var" 2> /dev/null | cut -d' ' -f 2-3)"
    #decho "var=$var, opt=$opt, expr=$expr"
    [[ -z "$opt$expr" ]] && echo "undefined" && return 0
    [[ "$opt" = "-A" ]] && echo "hash" && return 0
    [[ "$opt" = "-a" ]] && echo "array" && return 0
    [[ "$expr" =~ .+=.+ ]] && echo "scalar" && return 0
    [[ "$expr" =~ .+ ]] && echo "null" && return 0
    echo "unknown"
}


