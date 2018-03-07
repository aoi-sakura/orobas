#!/bin/bash
set -e
#
# Orobos: qemu 管理 script
#
#
# Specification:
#    - image filename format:
#        - filename への VM 設定については、create する時に設定を保持しておき、それが付加される
#
# ToDo:
#    - NIC は一つ、が前提なので、複数 NIC に対応できるようにする
#        - 想定するケースは bridge に 1 つ、VM 同士の通信用でもう 1 つ
#
#
readonly USAGE=$(cat <<EOF
Usage: $(basename "$0") [subcommand] [-c|--cpu <cpu count>] [-m|--mem <memory size>] [-n|--net "user" or "bridge"] [-d|--display "sdl", "gtk" or "console"] [-i|--install <install media path>] [-s|--size <disk image size(G)>] <image file path|title>
     subcommand: VM operations: "create", "start", "list", "download", "help"

     -l, --legacy: legacy machine feature or latest (default: latest)
     -c, --cpu: cpu count number
     -m, --mem: memory size
     -n, --net: network type "user" or "bridge", default is "bridge"
     -d, --display: display mode "sdl", "gtk" or "console", default is "sdl"
     -i, --install: install media image path
     -s, --size: disk image size by "G"B, create subcommand only

     <image file path|title>: boot image file path. If subcommand is "create": image file title
     - image filename format:
        - <image title>__c<cpu>_m<memory>_n<network type>_M<mac address(without ":")>.<image format>
            - <cpu>: cpu count number
            - <memory>: memory size
            - <network type>: network type "user" or "bridge"
            - <mac>: mac address without ":"
EOF
)

usage() {
    echo "$USAGE" >&2
}
