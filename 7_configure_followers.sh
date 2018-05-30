#!/bin/bash 
set -euo pipefail

. utils.sh

announce "Configuring followers."

set_namespace $CONJUR_NAMESPACE_NAME

master_pod_name=$(get_master_pod_name)

echo "Preparing follower seed files..."

mkdir -p tmp
$cli exec $master_pod_name evoke seed follower conjur-follower > ./tmp/follower-seed.tar

master_pod_ip=$($cli describe pod $master_pod_name | awk '/IP:/ { print $2 }')
pod_list=$($cli get pods -l role=follower --no-headers | awk '{ print $1 }')

for pod_name in $pod_list; do
  printf "Configuring follower %s...\n" $pod_name

  copy_file_to_container "./tmp/follower-seed.tar" "/tmp/follower-seed.tar" "$pod_name"

  $cli exec $pod_name evoke unpack seed /tmp/follower-seed.tar
  $cli exec $pod_name -- evoke configure follower
done

rm -rf tmp

echo "Followers configured."