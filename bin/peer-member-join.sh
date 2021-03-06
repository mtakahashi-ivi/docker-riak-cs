#! /bin/bash

set -e
# set -x

# Skip events we don't care about
if [ "${SERF_USER_EVENT}" != "riak-cs-admin-key" ] && [ "${SERF_USER_EVENT}" != "riak-cs-admin-secret" ]; then
  echo "Not a valid event for this node."
  exit 0
fi

# Catch admin credentials and populate them
while read LINE; do
  if [ "${SERF_USER_EVENT}" = "riak-cs-admin-key" ]; then
    sudo su -c "sed -i 's/admin-key/${LINE}/' /etc/riak-cs/riak-cs.conf" - root
  fi

  if [ "${SERF_USER_EVENT}" = "riak-cs-admin-secret" ]; then
    sudo su -c "sed -i 's/admin-secret/${LINE}/' /etc/riak-cs/riak-cs.conf" - root
  fi
done

# Disable anonymous user creation
sudo su -c "sed -i 's/anonymous_user_creation = on/anonymous_user_creation = off/' /etc/riak-cs/riak-cs.conf" - root
# Restart Riak CS for credentials to take effect
sudo sv restart riak-cs
