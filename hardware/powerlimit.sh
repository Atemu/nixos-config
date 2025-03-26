limit="${1:-}"

DEFAULT_LIMIT=80
UNLIMITED=100

case "$limit" in
    "" | "get")
        exec ectool fwchargelimit
        ;;
    "toggle")
        current="$(ectool fwchargelimit)"
        if [ "$current" = "$UNLIMITED" ]; then
            limit="$DEFAULT_LIMIT"
        else
            limit="$UNLIMITED"
        fi
        ;;
    "on")
        limit="$DEFAULT_LIMIT"
        ;;
    "off")
        limit="$UNLIMITED"
        ;;
esac

exec ectool fwchargelimit "$limit"
