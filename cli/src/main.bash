#
# procedure -------------------------
#
parse_args $@

# dump
#echo ${vm_conf[@]}
#echo ${image_conf[@]}
#echo ${system_conf[@]}
#echo ${com_conf[@]}

validate_option
env_init

case "$subcommand" in
    'create')
        do_create
        ;;
    'start')
        do_start
        ;;
    'list')
        do_list
        ;;
    'download')
        do_download
        ;;
esac
