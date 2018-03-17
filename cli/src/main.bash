#
# procedure -------------------------
#
parse_args $@

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
