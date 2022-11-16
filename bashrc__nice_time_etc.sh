seconds_apart() {
    local before="$1" && shift
    local after="$1" && shift
    echo $(( $(date +%s -d "$after") - $(date +%s -d "$before") ))
}

# Scale memory numbers to TB/GB/MB/KB; $1 = bytes, $2 = places [1]
nice_byte_size() {
    local orig="$(from_stdin)"
    [[ -z "$orig" ]] && orig="$1" && shift
    local places="${1:-1}" && shift

    cleaned_orig="${orig//,/}"
    [[ -z "$cleaned_orig" ]] && return 1
    [[ ! $cleaned_orig =~ ^[[:digit:]]+$ ]] && echo "$orig" && return 0

    local nice="$cleaned_orig"
    if [[ $nice -ge $((1024*1024*1024*1024)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1024*1024*1024*1024)")\ TB
    elif [[ $nice -ge $((1024*1024*1024)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1024*1024*1024)")\ GB
    elif [[ $nice -ge $((1024*1024)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1024*1024)")\ MB
    elif [[ $nice -ge $((1024)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1024)")\ kb
    fi

    echo "$nice"
}

# Scale milliseconds to d/h/m/s; $1 = milliseconds, $2 = places [1]
nice_milliseconds() {
    local orig="$1"; shift
    local places="${1:-1}"; shift
    cleaned_orig="${orig//,/}"
    [[ -z "$cleaned_orig" ]] && return 1
    [[ ! $cleaned_orig =~ ^[[:digit:]]+$ ]] && echo "$orig" && return 0

    local nice=$cleaned_orig
    if [[ $nice -gt $((1000*60*60*24)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1000*60*60*24)")d
    elif [[ $nice -gt $((1000*60*60)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1000*60*60)")h
    elif [[ $nice -gt $((1000*60)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1000*60)")m
    elif [[ $nice -gt $((1000)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1000)")s
    fi

    echo "$nice"
}

# Insert commas into large numbers
commafy() {
    local orig="$1"; shift
    cleaned_orig="${orig//,/}"
    [[ -z "$cleaned_orig" ]] && return 1
    [[ ! $cleaned_orig =~ ^[[:digit:]]+.*$ ]] && eecho "$orig" && return 1

    local nice=$cleaned_orig
    for i in {1..10}; do
        [[ ! $nice =~ [[:digit:]]{4,} ]] && break
        nice=$(echo "$nice" | sed -E 's/([[:digit:]])([[:digit:]]{3})([^[:digit:]]|$)/\1,\2\3/g;')
    done

    echo "$nice"
}

# Usage: [ms places] [format]
datetime_plus_ms() {
  local places="${1:-3}" && shift
  local format="${1:-%D %T}" && shift
  local ms="$(perl - <<-'EOF'
    use Time::HiRes qw(time);
    my $t = time;
    printf "%06d\n", ($t - int($t)) * 1000000;
EOF
)00000"
  date +"$format.${ms:0:$places}"
}

