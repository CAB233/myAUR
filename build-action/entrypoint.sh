#!/bin/bash

pkgname=$1

useradd builder -m
echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chmod -R a+rw .

cat << EOM >> /etc/pacman.conf
[archlinuxcn]
Server = https://repo.archlinuxcn.org/x86_64
EOM

cat << EOM >> /etc/makepkg.conf
CFLAGS="-march=x86-64-v3 -mtune=native -O2 -pipe -fno-plt -fexceptions \
        -Wp,-D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security \
        -fstack-clash-protection -fcf-protection -mpclmul"
CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"
MAKEFLAGS="-j$(nproc)"
BUILDENV=(!distcc !color !ccache check !sign)
OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug !lto)
PACKAGER="yidaduizuoye <yidaduizuoye@outlook.com>"
COMPRESSZST=(zstd -z -c -q -T0 -18 -)
PKGEXT=".pkg.tar.zst"
EOM

pacman-key --init
pacman-key --lsign-key "farseerfc@archlinux.org"
pacman -Sy --noconfirm && pacman -S --noconfirm archlinuxcn-keyring
pacman -Syu --noconfirm archlinux-keyring
pacman -Syu --noconfirm yay
if [ ! -z "$INPUT_PREINSTALLPKGS" ]; then
    pacman -Syu --noconfirm "$INPUT_PREINSTALLPKGS"
fi

sudo --set-home -u builder yay -S --noconfirm --builddir=./ "$pkgname"
cd "./$pkgname" || exit 1
python3 ../build-action/encode_name.py
