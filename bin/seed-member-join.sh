#! /bin/bash

set -e
# set -x

# Skip events we don't care about
if [ "${SERF_EVENT}" != "member-join" ] && [ "${SERF_SELF_NAME}" = "riak-cs01" ]; then
  echo "Not a valid event for this node."
  exit 0
fi

# Have the admin credentials been created yet?
if egrep -q "admin-key" /etc/riak-cs/riak-cs.conf; then
  # Wait for the Riak CS HTTP interface to come up
  until curl -s "http://127.0.0.1:8080/riak-cs/ping" | egrep "OK" > /dev/null;
  do
    sleep 5
  done

  # Create admin credentials
  curl -v --retry 5 --retry-delay 5 -XPOST "http://127.0.0.1:8080/riak-cs/user" \
       -H "Content-Type: application/json" \
       --data '{"email":"admin@admin.com", "name":"admin"}' > /tmp/riak-cs-credentials

  RIAK_CS_ADMIN_KEY=$(egrep -o "\{.*\}" /tmp/riak-cs-credentials | python3 -mjson.tool | egrep "key_id" | cut -d'"' -f4)
  RIAK_CS_ADMIN_SECRET=$(egrep -o "\{.*\}" /tmp/riak-cs-credentials  | python3 -mjson.tool | egrep "key_secret" | cut -d'"' -f4)

  # Populate admin credentials locally
  sudo su -c "sed -i 's/admin-key/${RIAK_CS_ADMIN_KEY}/' /etc/riak-cs/riak-cs.conf" - root
  sudo su -c "sed -i 's/admin-secret/${RIAK_CS_ADMIN_SECRET}/' /etc/riak-cs/riak-cs.conf" - root
  sudo su -c "sed -i 's/anonymous_user_creation = on/anonymous_user_creation = off/' /etc/riak-cs/riak-cs.conf" - root
  sudo su -c "sed -i 's/admin-key/${RIAK_CS_ADMIN_KEY}/' /etc/stanchion/stanchion.conf" - root
  sudo su -c "sed -i 's/admin-secret/${RIAK_CS_ADMIN_SECRET}/' /etc/stanchion/stanchion.conf" - root

  # Restart Riak CS and Stanchion for credentials to take effect
  sudo sv restart riak-cs
  sudo sv restart stanchion

  rm /tmp/riak-cs-credentials
else
  RIAK_CS_ADMIN_KEY=$(egrep "admin\.key" /etc/riak-cs/riak-cs.conf | cut -d' ' -f3)
  RIAK_CS_ADMIN_SECRET=$(egrep "admin\.secret" /etc/riak-cs/riak-cs.conf | cut -d' ' -f3)
fi

# Broadcast admin credentials
serf event riak-cs-admin-key "${RIAK_CS_ADMIN_KEY}"
serf event riak-cs-admin-secret "${RIAK_CS_ADMIN_SECRET}"
