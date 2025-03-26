limit="${1:-}"

DEFAULT_LIMIT=80

if [ -z "$limit" ]; then
    current="$(ectool fwchargelimit)"
    if [ "$current" = 100 ]; then
        limit="$DEFAULT_LIMIT"
    else
        limit=100
    fi
elif [ "$limit" = "on" ]; then
    limit="$DEFAULT_LIMIT"
elif [ "$limit" = "off" ]; then
    limit=100
elif [ "$limit" = "get" ]; then
    exec ectool fwchargelimit
fi

exec ectool fwchargelimit "$limit"
