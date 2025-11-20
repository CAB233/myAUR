#!/usr/bin/bash

if [[ $RESULT != "successful" ]] && [[ -n "$SERVERCHAN_UID" ]] && [[ -n "$SERVERCHAN_SENDKEY" ]]; then
    readonly title="lilac 构建通知"
    readonly desp="${PKGBASE}-${VERSION}：${RESULT}"

    curl "https://${SERVERCHAN_UID}.push.ft07.com/send/${SERVERCHAN_SENDKEY}.send" \
        --data-urlencode "title=$title" \
        --data-urlencode "tags=$title" \
        --data-urlencode "desp=$desp"
fi
