#! /usr/bin/env bash
set -e -u

declare -r SCRIPT_PATH=$(readlink -f $0)
declare -r SCRIPT_NAME=$(basename $0)
declare -r SCRIPT_DIR=$(cd $(dirname $SCRIPT_PATH) && pwd)

declare -r SQUID_DATA_CONTAINER=data_squid
declare -r SQUID_DATA_IMG=squidinacan_data
declare -r SQUID_CONTAINER=squid_proxy
declare -r SQUID_IMG=squidinacan_squid


usage() {
    # exit with one if no exit value is provided
    print_usage
    exit ${1:-1}
}

print_usage() {
    local sub_cmds=($(declare -F -p | cut -f3 -d ' ' |
        grep '^squid\.' | cut -f2- -d'.' ))

    read -r -d '' help <<-EOF_HELP || true
Usage:
    $SCRIPT_NAME
    $SCRIPT_NAME  -h|--help
    $SCRIPT_NAME  <${sub_cmds[@]}> [--dry-run]

Options:
    -h|--help   show this help

Commands:
    start
    stop
    restart
    status
    logs

EOF_HELP

    echo -e "$help"
    return 0

}

parse_args() {
    ### while there are args parse them
    while [[ -n "${1+xxx}" ]]; do
        case $1 in
        -h|--help)      SHOW_USAGE=true; break ;; # exit the loop
        --dry-run)      DRY_RUN=true; shift ;;
        *)              shift ;; # show usage on everything else
        esac
    done
    return 0
}

execute() {
    echo "Running: $@"
    ${DRY_RUN:-false} || "$@"
}


ensure_data_container_exists() {
    local data_container=$(docker ps -qa -f name=$SQUID_DATA_CONTAINER | wc -l)
    ### no data container create one
    [[ $data_container -ne 0 ]] && return 0

    echo "INFO: data container missing; creating one ..."
    execute docker run --name $SQUID_DATA_CONTAINER $SQUID_DATA_IMG ||  {
        echo "Did you 'fig build' first?"
        return 1
    }
    return 0
}


rm_squid() {
    local squid_container=$(docker ps -qa -f name=$SQUID_CONTAINER |  wc -l)
    ### no data container create one
    [[ $squid_container -ne 0 ]] && {
        execute docker rm -f $SQUID_CONTAINER
    }
    return 0
}

is_squid_running() {
    netstat -ntl | grep -q 3129
    return $?
}

run_squid() {
    execute docker  run -d \
        --net host --name $SQUID_CONTAINER \
        --volumes-from $SQUID_DATA_CONTAINER \
        $SQUID_IMG
    until is_squid_running; do
        sleep 0.5s
    done
    echo "Squid running on port 3129"
}

route_packages() {
    execute sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to 3129
}

unroute_packages() {
    execute sudo iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to 3129
}


squid.logs() {
    execute docker exec -t $SQUID_CONTAINER \
        bash -c 'tail -f /var/log/squid3/access.log | ccze -A'
}


squid.start() {
    ensure_data_container_exists
    is_squid_running && {
        echo "Squid is already running; use '$SCRIPT_NAME restart' to restart squid"
        return 0
    }
    rm_squid
    run_squid
    route_packages
    return 0
}

squid.restart() {
    is_squid_running && rm_squid
    squid.start
}

squid.status() {
    if is_squid_running; then
        echo "Squid: running"
    else
        echo "Squid: isn't running"
    fi
}


squid.stop() {
    is_squid_running || return 0
    echo "Going to stop and remove squid"
    rm_squid
    unroute_packages
    return 0
}

validate_method() {
    local fn=$1; shift
    [[ $(type -t $fn) == "function" ]]
    return $?
}

main() {
    local SHOW_USAGE=false
    local DRY_RUN=false

    ### validate and exit early
    parse_args "$@"|| usage 1
    $SHOW_USAGE && usage

    local fn="squid.${1:-''}"
    validate_method "$fn" || {
        echo "Error $fn doesn't exist"
        usage 1
    }
    shift  #

    $fn $@
    return $?
}

main "$@"
