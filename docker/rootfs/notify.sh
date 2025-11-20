#!/usr/bin/bash

if [[ $RESULT == "successful" ]]; then
    exit 0
fi

: "${SERVERCHAN_UID?}"
: "${SERVERCHAN_SENDKEY?}"
: "${PKGBASE?}"
: "${RESULT?}"
: "${VERSION?}"

title="lilac 构建通知"
desp="${PKGBASE}-${VERSION}：${RESULT}"

curl "https://${SERVERCHAN_UID}.push.ft07.com/send/${SERVERCHAN_SENDKEY}.send" \
    --data-urlencode "title=$title" \
    --data-urlencode "tags=$title" \
    --data-urlencode "desp=$desp"
