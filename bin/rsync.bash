#!/bin/bash

homeport module <<-usage
    usage: homeport rsync
usage

homeport_emit_evaluated "$@" && exit
homeport_labels $1 && shift

dir=$(mktemp -d -t homeport_rsync.XXXXXXX)

function cleanup() {
    local pids=$(jobs -pr)
    [ -n "$pids" ] && kill $pids
    [ ! -z "$dir" ] && rm -rf "$dir"
}

trap cleanup EXIT SIGTERM SIGINT

if [[ "$dir" ==  *' '* ]]; then
    abend "Cannot use a temp directory that contains spaces. TMPDIR=$TMPDIR"
fi

docker cp "$homeport_container_name":/etc/ssh/ssh_host_rsa_key.pub "$dir/ssh_host_rsa_key.pub"

if [ -z "$DOCKER_HOST" ]; then
    ssh_host=$(docker inspect --format '{{ .NetworkSettings.Gateway }}' "$homeport_container_name")
else
    ssh_host=$(echo "$DOCKER_HOST" | sed 's/^tcp:\/\/\(.*\):.*$/\1/')
fi
ssh_port=$(docker port $homeport_container_name 22 | cut -d: -f2)

echo "[$ssh_host]:$ssh_port $(cut -d' ' -f1,2 < $dir/ssh_host_rsa_key.pub)" > "$dir/known_hosts"

arguments=("-e" "ssh -p $ssh_port -o UserKnownHostsFile=$dir/known_hosts")
while [ $# -ne 0 ]; do
    case "$1" in
        homeport:*)
            value=${1#homeport:}
            value=homeport@${ssh_host}:${value}
            arguments+=("$value")
            shift
            ;;
        *)
            arguments+=("$1")
            shift
            ;;
    esac
done

rsync "${arguments[@]}"