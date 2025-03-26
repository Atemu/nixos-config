limit="${1:-}"

DEFAULT_LIMIT=80

case "$limit" in
    "" | "get")
        exec ectool fwchargelimit
        ;;
    "toggle")
        current="$(ectool fwchargelimit)"
        if [ "$current" = 100 ]; then
            limit="$DEFAULT_LIMIT"
        else
            limit=100
        fi
        ;;
    "on")
        limit="$DEFAULT_LIMIT"
        ;;
    "off")
        limit=100
        ;;
esac

exec ectool fwchargelimit "$limit"
