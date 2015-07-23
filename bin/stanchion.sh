#! /bin/sh

IP_ADDRESS=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)

# Ensure correct ownership and permissions on volumes
chown stanchion:riak /var/log/stanchion
chmod 755 /var/log/stanchion

# Open file descriptor limit
ulimit -n 4096

# Ensure the Erlang node name is set correctly
sed -i.bak "s/riak_host = 127.0.0.1/riak_host = ${IP_ADDRESS}/" /etc/stanchion/stanchion.conf
sed -i.bak "s/nodename = stanchion@127.0.0.1/nodename = stanchion@${IP_ADDRESS}/" /etc/stanchion/stanchion.conf

# Start Stanchion
if ! env | egrep -q "SEED_PORT_8080_TCP_ADDR"; then
  exec /sbin/setuser stanchion "$(ls -d /usr/lib/stanchion/erts*)/bin/run_erl" "/tmp/stanchion" \
     "/var/log/stanchion" "exec /usr/sbin/stanchion console"
fi
