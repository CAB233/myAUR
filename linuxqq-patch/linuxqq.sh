#!/bin/bash

if [ -d ~/.config/QQ/versions ]; then
	find ~/.config/QQ/versions -name sharp-lib -type d -exec rm -r {} \; 2>/dev/null
fi

rm -rf ~/.config/QQ/crash_files/*

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-~/.config}

if [[ -f "${XDG_CONFIG_HOME}/qq-flags.conf" ]]; then
	mapfile -t QQ_USER_FLAGS <<<"$(grep -v '^#' "${XDG_CONFIG_HOME}/qq-flags.conf")"
	echo "User flags:" ${QQ_USER_FLAGS[@]}
fi

# 适配 LiteLoaderQQNT
LITELOADERQQNT_PROFILE_DIR=${LITELOADERQQNT_PROFILE_DIR:-~/.config/QQ/LiteLoaderQQNT}

export LITELOADERQQNT_PROFILE
if [ -n "${LITELOADERQQNT_PROFILE}" ]; then
    mkdir -p "${LITELOADERQQNT_PROFILE}/plugins"
else
    export LITELOADERQQNT_PROFILE=${LITELOADERQQNT_PROFILE_DIR}
    mkdir -p "${LITELOADERQQNT_PROFILE}/plugins"
fi

cp -r /opt/LiteLoaderQQNT/plugins/* "${LITELOADERQQNT_PROFILE}/plugins/"

# 固定 MAC
# https://alampy.com/2024/05/15/fix-mac-for-linux-qq/
if [ -z "$(which slirp4netns)" ]; then
    echo "Please install slirp4netns"
    exit 1
fi

if [ -z "$(which socat)" ]; then
    echo "Please install socat"
    exit 1
fi

if [ -z "$(which nsenter)" ]; then
    echo "nsenter not found"
    exit 1
fi

if [ -z "$(which unshare)" ]; then
    echo "unshare not found"
    exit 1
fi

if [ -z "$(which linuxqq)" ]; then
    echo "Please install linuxqq"
    exit 1
fi

if [ $(basename "$0") = "xdg-open" ]; then
    echo "$1" | socat - UNIX-CONNECT:$XDG_OPEN_SOCKET
    exit
fi

# Make sure sub-processes are killed when the script exits
trap 'kill $(jobs -p) 2>/dev/null' EXIT
# Get the real path of the script
SCRIPT=$(realpath -s "$0")
if [ "$1" = "inside" ]; then
    echo $$ >"$2"
    # wait for the file to be deleted
    while [ -f "$2" ]; do
        sleep 0.01
    done
    # clear proxy settings
    unset http_proxy
    unset https_proxy
    unset ftp_proxy
    unset all_proxy
    socat tcp-listen:94301,reuseaddr,fork tcp:127.0.0.1:4301 &
    socat tcp-listen:94310,reuseaddr,fork tcp:127.0.0.1:4310 &
    exec /opt/QQ/qq ${QQ_USER_FLAGS[@]} "$@" --no-proxy-server
    exit $?
elif [ "$1" = "mount" ]; then
    ETC_OVERLAY=$(mktemp -d)
    ETC_UPPER=$ETC_OVERLAY/upper
    ETC_LOWER=$ETC_OVERLAY/lower
    mkdir -p $ETC_UPPER $ETC_LOWER
    echo "nameserver 10.0.2.3" >$ETC_UPPER/resolv.conf
    mount --rbind /etc $ETC_LOWER
    mount -t overlay overlay -o lowerdir=$ETC_UPPER:$ETC_LOWER /etc
    mount --bind $SCRIPT /usr/bin/xdg-open
else
    # read the mac address from ~/.config/QQ/.qq_mac, if not exist, generate a random one
    if [ -f ~/.config/QQ/.qq_mac ]; then
        qq_mac=$(cat ~/.config/QQ/.qq_mac)
    else
        qq_mac=00\:$(hexdump -n5 -e '/1 ":%02X"' /dev/random | sed s/^://g)
        echo $qq_mac >~/.config/QQ/.qq_mac
    fi

    INFO_DIR=$(mktemp -d)
    INFO_FILE=$INFO_DIR/info
    export XDG_OPEN_SOCKET=$INFO_DIR/xdg-open.sock
    unshare --user --map-user=$(id -u) --map-group=$(id -g) --map-users=auto --map-groups=auto --keep-caps --setgroups allow --net --mount bash "$SCRIPT" inside $INFO_FILE &
    if [ $? -ne 0 ]; then
        rm -rf "${INFO_DIR:?}"
        echo "unshare failed"
        exit 1
    fi
    while [ ! -s $INFO_FILE ]; do
        sleep 0.01
    done
    PID=$(cat $INFO_FILE)
    echo "SubProcess PID: $PID"
    SLIRP_API_SOCKET=$INFO_DIR/slirp.sock
    slirp4netns --configure --mtu=65520 --disable-host-loopback --enable-ipv6 $PID eth0 --macaddress $qq_mac --api-socket $SLIRP_API_SOCKET &
    SLIRP_PID=$!
    # wait for the socket to be created, thanks for the fix from [Kirikaze Chiyuki](https://chyk.ink/)
    while [ ! -S "$SLIRP_API_SOCKET" ]; do
        sleep 0.01
    done
    if [ $? -ne 0 ]; then
        echo "slirp4netns failed"
        kill $PID
        rm -rf "${INFO_DIR:?}"
        exit 1
    fi
    nsenter -U -m --target $PID bash "$SCRIPT" mount
    add_hostfwd() {
        local proto=$1
        local guest_port=$2
        shift 2
        local ports=("$@")
        for port in "${ports[@]}"; do
            result=$(echo -n "{\"execute\": \"add_hostfwd\", \"arguments\": {\"proto\": \"$proto\", \"host_addr\": \"127.0.0.1\", \"host_port\": $port, \"guest_port\": $guest_port}}" | socat UNIX-CONNECT:$SLIRP_API_SOCKET -)
            if [[ $result != *"error"* ]]; then
                echo "$proto forwarding setup on port $port"
                return 0
            fi
        done
        echo "Failed to setup $proto forwarding."
        return 1
    }
    https_ports=(4301 4303 4305 4307 4309)
    http_ports=(4310 4308 4306 4304 4302)
    add_hostfwd "tcp" 94301 "${https_ports[@]}"
    add_hostfwd "tcp" 94310 "${http_ports[@]}"
    socat UNIX-LISTEN:$XDG_OPEN_SOCKET,fork EXEC:"xargs -d '\n' -n 1 xdg-open",pty,stderr &
    XDG_OPEN_SOCKET_PID=$!
    rm "$INFO_FILE"
    tail --pid=$PID -f /dev/null
    kill -TERM $SLIRP_PID
    wait $SLIRP_PID
    kill -TERM $XDG_OPEN_SOCKET_PID
    wait $XDG_OPEN_SOCKET_PID
    rm -rf "${INFO_DIR:?}"
    exit 0
fi
