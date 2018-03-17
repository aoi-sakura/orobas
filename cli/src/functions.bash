#
# configration variables ------------
#
#  1. image_conf の値がデフォルト
#  2. イメージファイル名からパースした値を image_conf に上書き
#  3. vm_conf に値が入っている場合、2. の上に上書き
#

#
# pseudo array function
#   - bash's Arrays is not posix, so checkbahism error
#     and cannot exporting outside, so unittest is not work.
#
# Usage:
#     getter:
#         $(ar "array nme" "array key")
#     setter:
#         ar "array nme" "array key" "value"
#
ar() {
    name=$1
    key=$2
    val=$3
    if [ -z "${val}" ]; then
        eval echo \"\$ar_${name}_${key}\"
    else
        eval ar_${name}_${key}="${val}"
    fi
}

# virtualmachine settings
#ar "vm" "arch" ""
#ar "vm" "machine" ""
#ar "vm" "cpu_type" ""
#ar "vm" "cpu" ""
#ar "vm" "memory" ""
#ar "vm" "network" ""
#ar "vm" "mac_addr" ""
#ar "vm" "cdrom" ""
#ar "vm" "display" ""

# image(os) side settings
ar "image" "format" "qcow2"
#ar "image" "path" ""
#ar "image" "title" ""
ar "image" "size" "10G"
ar "image" "arch" "x86_64"
ar "image" "machine" "q35"
ar "image" "cpu_type" "SandyBridge"
ar "image" "cpu" 2
ar "image" "memory" 1024
ar "image" "network" "bridge"
ar "image" "mac_addr" "52:34:00:22:34:56"
#ar "image" "cdrom" ""
ar "image" "display" "sdl"

# system wide settings
ar "system" "hypervisor" "kvm"
ar "system" "network_bridge" "br0"
ar "system" "server_url" "http://alice.aoisakura/vm/images/"
# 52:54: で始まるアドレスである暗黙のルール?
ar "system" "macaddr_prefix" "52:54:"
ar "system" "vm_store" "$HOME/.local/share/orobas"
ar "system" "config_path" "$HOME/.config/orobas.yml"
ar "system" "qemu_bridge_file" "/etc/qemu/bridge.conf"

# command arguments
ar "com" "com_prefix" "qemu-system-"
ar "com" "machine" "-machine"
ar "com" "cpu_type" "-cpu"
ar "com" "cpu" "-smp"
ar "com" "memory" "-m"
ar "com" "network" "-netdev"
ar "com" "network_device" "-device"
ar "com" "cdrom" "-cdrom"
ar "com" "display" "-display"
ar "com" "display_console" "-nographic"

#
# untouched variables ---------------
#
subcommand=""

#
# functions -------------------------
#
#
# libraries: 共通処理
#
# ":" なしで並んでいる MAC アドレス文字列を 2 文字ずつ ":" 区切りで出力
#   input: mac_str: MAC アドレス文字列
#          reverse: true なら ":" なし -> ":" あり
#                   false なら ":" あり -> ":" なし
convert_mac_address() {
    mac_str=$1
    reverse=$2

    mac=""
    if $reverse ; then
        mac=${mac_str:0:2}
        target_mac=${mac_str:2}
        for i in `echo $target_mac | fold -s2`; do mac=$mac:${i}; done
    else
        mac=`echo $mac_str | tr -d ':'`
    fi

    echo ${mac}
}

#
#
#

# get qemu bridge name from /etc file
get_network_bridge() {
    grep -v "#" $(ar "system" "qemu_bridge_file") | grep allow | cut -d' ' -f2
}

# build user or bridge network options
build_option_network() {
    mac_addr=$(ar "image" "mac_addr")
    if [ $(ar "image" "network") = "user" ]; then
        # TODO: 5555 -> random and displayed
        result="-netdev user,id=user.0,hostfwd=tcp::5555-:22 -device virtio-net-pci,netdev=user.0,mac=$mac_addr"
    else
        bridge_if=$(get_network_bridge)
        result="-netdev bridge,id=bridge.0,br=${bridge_if} -device virtio-net-pci,netdev=bridge.0,mac=$mac_addr"
    fi
    echo ${result}
}

build_option_display() {
    if [ $(ar "image" "display") = "console" ]; then
        result=$(ar "com" "display_console")
    else
        display_option=$(ar "image" "display")
        result="-display $display_option"
    fi
    echo ${result}
}

# image の title から mac addr に使える文字列を生成
generate_mac_addr_from_title() {
    crc_result=$(echo $(ar "image" "title") | cksum | cut -d' ' -f1)
    mac_addr_str=$(echo $(ar "system" "macaddr_prefix") | tr -d ':')$(printf '%x' $crc_result)

    echo $(convert_mac_address ${mac_addr_str:0:12} true)
}

# generate filename from image_conf settings
generate_filename_from_conf() {
    echo $(ar "image" "title")__c$(ar "image" "cpu")_m$(ar "image" "memory")_M$(convert_mac_address $(ar "image" "mac_addr") false).$(ar "image" "format")
}

get_hypervisor_option() {
    result=""
    case $(ar "system" "hypervisor") in
        "kvm")
            result="-enable-kvm"
            ;;
    esac
    echo ${result}
}

__do_list() {
    for i in `find $(ar "system" "vm_store") -type f`;
    do
        basename $i
    done
}

# display available VM image filenames
do_list() {
    __do_list
}

do_download() {
    echo "do download"
}

__do_create_image() {
    # generate image file
    qemu-img create -f $(ar "image" "format") \
             $(ar "image" "path") $(ar "image" "size")
}

__do_create_install() {
    qemu-system-$(ar "image" "arch") \
                -machine $(ar "image" "machine") \
                -cpu $(ar "image" "cpu_type") $(get_hypervisor_option) \
                -smp $(ar "image" "cpu") -m $(ar "image" "memory") \
                $(build_option_network) \
                -drive file=$(ar "image" "path"),if=virtio,format=qcow2,cache=none,aio=threads \
                -cdrom $(ar "image" "cdrom") \
                $(build_option_display)
}

__compress_image() {
    echo "compress image ..."
    # compress
    qemu-img convert -c -f $(ar "image" "format") -O $(ar "image" "format") $(ar "image" "path"){,_compress}
    mv $(ar "image" "path"){_compress,}

    echo "compress done!"
}

# create VM image file.
# start qemu with installer
do_create() {
    echo "create image & start installer"

    ar "image" "mac_addr" $(generate_mac_addr_from_title)
    ar "image" "path" $(ar "system" "vm_store")/$(generate_filename_from_conf)

    __do_create_image

    # build command
    __do_create_install

    __compress_image
}

__do_start() {
    qemu-system-$(ar "image" "arch") \
                -machine $(ar "image" "machine") \
                -cpu $(ar "image" "cpu_type") $(get_hypervisor_option) \
                -smp $(ar "image" "cpu") -m $(ar "image" "memory") \
                $(build_option_network) \
                -drive file=$(ar "image" "path"),if=virtio,format=qcow2,cache=none,aio=threads \
                $(build_option_display)
}

# start qemu
do_start() {
    echo "VM start"
    __do_start
}

# create setting files on pre stage.
env_init() {
    mkdir -p $(ar "system" "vm_store")
    if [ ! -e $(ar "system" "config_path") ]; then
        # ToDo: 実装途中、誰も使っていないファイル
        cat <<-EOT > $(ar "system" "config_path")
		system:
		    hypervisor: kvm
		    vm_store: $(ar "system" "vm_store")
		EOT
    fi
}

parse_subcommand() {
    __subcommand=$1
    case "$__subcommand" in
        'create')
            subcommand="create"
            ;;
        'start')
            subcommand="start"
            ;;
        'list')
            subcommand="list"
            ;;
        'download')
            subcommand="download"
            ;;
        *.*)
            # argument image path directly
            subcommand="start"
            if [ -e $(ar "system" "vm_store")/$__subcommand ]; then
                ar "image" "path" $__subcommand
            fi
            ;;
        -*)
            subcommand="start"
            ;;
        *)
            subcommand="help"
            ;;
    esac
}

parse_option() {
    # parse options and image path
    unset GETOPT_COMPATIBLE

    # MEMO: GNU getopt
    OPT=`getopt -o c:m:n:d:i:s:lh -l cpu:,mem:,net:,display:,install:,size:,legacy,help -- "$@"`

    eval set -- "$OPT"
    while [ $# -gt 0 ]; do
        case $1 in
            --)
                if [ $subcommand = "start" -a x$(ar "image" "path") = 'x' -a x$2 != 'x' -a -e $(ar "system" "vm_store")/$2 ]; then
                    ar "image" "path" $(ar "system" "vm_store")/$2
                    shift
                elif [ $subcommand = "create" ]; then
                    ar "image" "title" $2
                    shift
                fi
                ;;
            -c | --cpu)
                ar "vm" "cpu" $2
                shift
                ;;
            -m | --mem)
                ar "vm" "memory" $2
                shift
                ;;
            -n | --net)
                ar "vm" "network" $2
                shift
                ;;
            -d | --display)
                ar "vm" "display" $2
                shift
                ;;
            -i | --install)
                ar "vm" "cdrom" $2
                shift
                ;;
            -s | --size)
                ar "image" "size" $2
                shift
                ;;
            -l | --legacy)
                ar "vm" "machine" "pc"
                ;;
            -h | --help)
                subcommand="help"
                ;;
            *)
                subcommand="error"
                ;;
        esac
        shift
    done
}

# overwrite settings filename -> image_conf
merge_conf_filename_to_image() {
    filename=$1
    configs=`echo ${filename%.*} | awk -F'__' '{print $2}' | tr '_' ' '`
    for conf in $configs;
    do
        key=${conf:0:1}
        val=${conf:1}
        case "$key" in
            'c')
                ar "image" "cpu" $val
                ;;
            'm')
                ar "image" "memory" $val
                ;;
            'n')
                ar "image" "network" $val
                ;;
            'M')
                mac=$(convert_mac_address $val true)
                ar "image" "mac_addr" $mac
                ;;
        esac
    done
}

# overwrite settings vm_conf -> image_conf
merge_conf_vm_to_image() {
    # TODO: get keys from "vm" arrays. exporting ar_vm_XXX's XXX list.
    for key in "arch" "machine" "cpu_type" "cpu" "memory" "network" "mac_addr" "cdrom" "display";
    do
        if [ -n "$(ar "vm" ${key})" ]; then
            ar "image" ${key} "$(ar "vm" ${key})"
        fi
    done
}

# parse subcommand or image path
parse_args() {
    __subcommand=$1
    shift
    options=$@

    parse_subcommand $__subcommand
    parse_option $options

    # merge settings
    if [ $subcommand = "start" ]; then
        merge_conf_filename_to_image $(ar "image" "path")
    fi
    merge_conf_vm_to_image
}

validate_option() {
    # ToDo: validation
    if [ $subcommand = "start" -a x$(ar "image" "path") = 'x' ]; then
        echo "path is not set."  1>&2
        exit 1
    elif [ $subcommand = "create" ]; then
        if [ x$(ar "image" "title") = 'x' ]; then
            echo "title is not set."  1>&2
            exit 1
        fi
        if [ x$(ar "image" "cdrom") = 'x' ]; then
            echo "install media is not set."  1>&2
            exit 1
        fi
    elif [ $subcommand = "error" ]; then
        echo "Internal error!" 1>&2
        exit 1
    elif [ $subcommand = "help" ]; then
        usage
        exit 1
    fi
}
