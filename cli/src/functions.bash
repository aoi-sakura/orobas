#
# configration variables ------------
#
#  1. image_conf の値がデフォルト
#  2. イメージファイル名からパースした値を image_conf に上書き
#  3. vm_conf に値が入っている場合、2. の上に上書き
#

# virtualmachine settings
declare -A vm_conf
vm_conf["arch"]=
vm_conf["machine"]=
vm_conf["cpu_type"]=
vm_conf["cpu"]=
vm_conf["memory"]=
vm_conf["network"]=
vm_conf["mac_addr"]=
vm_conf["cdrom"]=
vm_conf["display"]=

# image(os) side settings
declare -A image_conf
image_conf["format"]="qcow2"
image_conf["path"]=""
image_conf["title"]=""
image_conf["size"]="10G"
image_conf["arch"]="x86_64"
image_conf["machine"]="q35"
image_conf["cpu_type"]="SandyBridge"
image_conf["cpu"]=2
image_conf["memory"]=1024
image_conf["network"]="bridge"
image_conf["mac_addr"]="52:34:00:22:34:56"
image_conf["cdrom"]=
image_conf["display"]="sdl"

# system wide settings
declare -A system_conf
system_conf["hypervisor"]="kvm"
system_conf["network_bridge"]="br0"
system_conf["server_url"]="http://alice.aoisakura/vm/images/"
# 52:54: で始まるアドレスである暗黙のルール?
system_conf["macaddr_prefix"]="52:54:"
system_conf["vm_store"]="$HOME/.local/share/orobas"
system_conf["config_path"]="$HOME/.config/orobas.yml"
system_conf["qemu_bridge_file"]="/etc/qemu/bridge.conf"

# command arguments
declare -A com_conf
com_conf["com_prefix"]="qemu-system-"
com_conf["machine"]="-machine"
com_conf["cpu_type"]="-cpu"
com_conf["cpu"]="-smp"
com_conf["memory"]="-m"
com_conf["network"]="-netdev"
com_conf["network_device"]="-device"
com_conf["cdrom"]="-cdrom"
com_conf["display"]="-display"
com_conf["display_console"]="-nographic"

#
# untouched variables ---------------
#
declare subcommand

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
function convert_mac_address() {
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
function get_network_bridge() {
    grep -v "#" ${system_conf["qemu_bridge_file"]} | grep allow | cut -d' ' -f2
}

# build user or bridge network options
function get_network_option() {
    mac_addr=${image_conf["mac_addr"]}
    if [ ${image_conf["network"]} = "user" ]; then
        result="-netdev user,id=user.0 -device virtio-net-pci,netdev=user.0,mac=$mac_addr"
    else
        bridge_if=$(get_network_bridge)
        result="-netdev bridge,id=bridge.0,br=${bridge_if} -device virtio-net-pci,netdev=bridge.0,mac=$mac_addr"
    fi
    echo ${result}
}

function get_display_option() {
    if [ ${image_conf["display"]} = "console" ]; then
        result=${com_conf["display_console"]}
    else
        display_option=${image_conf["display"]}
        result="-display $display_option"
    fi
    echo ${result}
}

# image の title から mac addr に使える文字列を生成
function generate_mac_addr_from_title() {
    crc_result=$(echo ${image_conf["title"]} | cksum | cut -d' ' -f1)
    mac_addr_str=$(echo ${system_conf["macaddr_prefix"]} | tr -d ':')$(printf '%x' $crc_result)

    echo $(convert_mac_address ${mac_addr_str:0:12} true)
}

# generate filename from image_conf settings
function generate_filename_from_conf() {
    echo ${image_conf["title"]}__c${image_conf["cpu"]}_m${image_conf["memory"]}_M$(convert_mac_address ${image_conf["mac_addr"]} false).${image_conf["format"]}
}

function get_hypervisor_option() {
    result=""
    case ${system_conf["hypervisor"]} in
        "kvm")
            result="-enable-kvm"
        ;;
    esac
    echo ${result}
}

function __do_list() {
    for i in `find ${system_conf["vm_store"]} -type f`;
    do
        basename $i
    done
}

# display available VM image filenames
function do_list() {
    __do_list
}

function do_download() {
    echo "do download"
}

function __do_create_image() {
    # generate image file
    qemu-img create -f ${image_conf["format"]} \
             ${image_conf["path"]} ${image_conf["size"]}
}

function __do_create_install() {
    qemu-system-${image_conf["arch"]} \
                -machine ${image_conf["machine"]} \
                -cpu ${image_conf["cpu_type"]} $(get_hypervisor_option) \
                -smp ${image_conf["cpu"]} -m ${image_conf["memory"]} \
                $(get_network_option) \
                -drive file=${image_conf["path"]},if=virtio,format=qcow2,cache=none,aio=threads \
                -cdrom ${image_conf["cdrom"]} \
                $(get_display_option)
}

# create VM image file.
# start qemu with installer
function do_create() {
    echo "create image & start installer"

    image_conf["mac_addr"]=$(generate_mac_addr_from_title)
    image_conf["path"]=${system_conf["vm_store"]}/$(generate_filename_from_conf)

    __do_create_image

    # build command
    __do_create_install
}

function __do_start() {
    qemu-system-${image_conf["arch"]} \
                -machine ${image_conf["machine"]} \
                -cpu ${image_conf["cpu_type"]} $(get_hypervisor_option) \
                -smp ${image_conf["cpu"]} -m ${image_conf["memory"]} \
                $(get_network_option) \
                -drive file=${image_conf["path"]},if=virtio,format=qcow2,cache=none,aio=threads \
                $(get_display_option)
}

# start qemu
function do_start() {
    echo "VM start"
    __do_start
}

# create setting files on pre stage.
function env_init() {
    mkdir -p ${system_conf["vm_store"]}
    if [ ! -e ${system_conf["config_path"]} ]; then
        # ToDo: 実装途中、誰も使っていないファイル
        cat <<-EOT > ${system_conf["config_path"]}
		system:
		    hypervisor: kvm
		    vm_store: ${system_conf["vm_store"]}
		EOT
    fi
}

function parse_subcommand() {
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
            if [ -e ${system_conf["vm_store"]}/$__subcommand ]; then
                image_conf["path"]=$__subcommand
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

function parse_option() {
    # parse options and image path
    unset GETOPT_COMPATIBLE

    # MEMO: GNU getopt
    OPT=`getopt -o c:m:n:d:i:s:lh -l cpu:,mem:,net:,display:,install:,size:,legacy,help -- "$@"`

    eval set -- "$OPT"
    while [ $# -gt 0 ]; do
        case $1 in
            --)
                if [ $subcommand = "start" -a x${image_conf["path"]} = 'x' -a x$2 != 'x' -a -e ${system_conf["vm_store"]}/$2 ]; then
                    image_conf["path"]=${system_conf["vm_store"]}/$2
                    shift
                elif [ $subcommand = "create" ]; then
                    image_conf["title"]=$2
                    shift
                fi
                ;;
            -c | --cpu)
                vm_conf["cpu"]=$2
                shift
                ;;
            -m | --mem)
                vm_conf["memory"]=$2
                shift
                ;;
            -n | --net)
                vm_conf["network"]=$2
                shift
                ;;
            -d | --display)
                vm_conf["display"]=$2
                shift
                ;;
            -i | --install)
                vm_conf["cdrom"]=$2
                shift
                ;;
            -s | --size)
                image_conf["size"]=$2
                shift
                ;;
            -l | --legacy)
                vm_conf["machine"]="pc"
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
function merge_conf_filename_to_image() {
    filename=$1
    configs=`echo ${filename%.*} | awk -F'__' '{print $2}' | tr '_' ' '`
    for conf in $configs;
    do
        key=${conf:0:1}
        val=${conf:1}
        case "$key" in
            'c')
                image_conf["cpu"]=$val
                ;;
            'm')
                image_conf["memory"]=$val
                ;;
            'n')
                image_conf["network"]=$val
                ;;
            'M')
                mac=$(convert_mac_address $val true)
                image_conf["mac_addr"]=$mac
                ;;
        esac
    done
}

# overwrite settings vm_conf -> image_conf
function merge_conf_vm_to_image() {
    for key in "${!vm_conf[@]}";
    do
        if [ -n "${vm_conf[${key}]}" ]; then
            image_conf[${key}]="${vm_conf[${key}]}"
        fi
    done
}

# parse subcommand or image path
function parse_args() {
    __subcommand=$1
    shift
    options=$@

    parse_subcommand $__subcommand
    parse_option $options

    # merge settings
    if [ $subcommand = "start" ]; then
        merge_conf_filename_to_image ${image_conf["path"]}
    fi
    merge_conf_vm_to_image
}

function validate_option() {
    # ToDo: validation
    if [ $subcommand = "start" -a x${image_conf["path"]} = 'x' ]; then
        echo "path is not set."  1>&2
        exit 1
    elif [ $subcommand = "create" ]; then
        if [ x${image_conf["title"]} = 'x' ]; then
            echo "title is not set."  1>&2
            exit 1
        fi
        if [ x${image_conf["cdrom"]} = 'x' ]; then
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
