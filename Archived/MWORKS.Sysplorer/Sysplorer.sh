#!/bin/bash

export LD_LIBRARY_PATH=/opt/MWORKS/Sysplorer/bin64
export QT_QWS_FONTDIR=/usr/share/fonts
export QT_QPA_PLATFORM_PLUGIN_PATH=/usr/lib/qt

exec /opt/MWORKS/Sysplorer/bin64/mworks "$@"