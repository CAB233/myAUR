#!/bin/bash

if [ -d ~/.config/QQ/versions ]; then
    find ~/.config/QQ/versions -name sharp-lib -type d -exec rm -r {} \; 2>/dev/null
    find ~/.config/QQ/versions -name libssh2.so.1 -type f -exec rm {} \; 2>/dev/null
fi

rm -rf ~/.config/QQ/crash_files/*

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-~/.config}

if [[ -f "${XDG_CONFIG_HOME}/qq-flags.conf" ]]; then
    mapfile -t QQ_USER_FLAGS <<<"$(grep -v '^#' "${XDG_CONFIG_HOME}/qq-flags.conf")"
    echo "User flags:" ${QQ_USER_FLAGS[@]}
fi

# 适配 LiteLoaderQQNT
export LITELOADERQQNT_PROFILE
if [ -n "${LITELOADERQQNT_PROFILE}" ]; then
    mkdir -p "${LITELOADERQQNT_PROFILE}/plugins"
else
    export LITELOADERQQNT_PROFILE=${XDG_CONFIG_HOME}/QQ/LiteLoaderQQNT
    mkdir -p "${LITELOADERQQNT_PROFILE}/plugins"
fi

cp -r /opt/LiteLoaderQQNT/plugins/* "${LITELOADERQQNT_PROFILE}/plugins/"

exec /opt/QQ/qq ${QQ_USER_FLAGS[@]} "$@"
