#!/bin/bash
set -e

pacman-key --init
pacman-key --recv-key 62FFE3FEF4158CF1 --keyserver keys.openpgp.org
pacman-key --lsign-key 62FFE3FEF4158CF1
pacman-key --populate

# pacman -Syu --noconfirm
