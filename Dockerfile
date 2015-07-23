# Riak CS
#
# VERSION       0.7.0

FROM phusion/baseimage:0.9.17
MAINTAINER Hector Castro hectcastro@gmail.com

# Environmental variables
ENV DEBIAN_FRONTEND noninteractive
ENV RIAK_VERSION 2.1.1-1
ENV RIAK_SHORT_VERSION 2.1.1
ENV RIAK_CS_VERSION 2.0.1-1
ENV RIAK_CS_SHORT_VERSION 2.0.1
ENV STANCHION_VERSION 2.0.0-1
ENV STANCHION_SHORT_VERSION 2.0.0
ENV SERF_VERSION 0.6.4

# Install dependencies
RUN apt-get update -qq && apt-get install unzip -y

# Install Riak
RUN (curl -s https://packagecloud.io/install/repositories/basho/riak/script.deb.sh | sudo bash)
RUN (apt-get install riak=${RIAK_VERSION})

# Setup the Riak service
RUN mkdir -p /etc/service/riak
ADD bin/riak.sh /etc/service/riak/run

# Install Riak CS
RUN (curl -s https://packagecloud.io/install/repositories/basho/riak-cs/script.deb.sh | sudo bash)
RUN (apt-get install riak-cs=${RIAK_CS_VERSION})

# Setup the Riak CS service
RUN mkdir -p /etc/service/riak-cs
ADD bin/riak-cs.sh /etc/service/riak-cs/run

# Install Stanchion
RUN (curl -s https://packagecloud.io/install/repositories/basho/stanchion/script.deb.sh | sudo bash)
RUN (apt-get install stanchion=${STANCHION_VERSION})

# Setup the Stanchion service
RUN mkdir -p /etc/service/stanchion
ADD bin/stanchion.sh /etc/service/stanchion/run

# Setup automatic clustering for Riak
ADD bin/automatic_clustering.sh /etc/my_init.d/99_automatic_clustering.sh

# Install Serf
ADD https://dl.bintray.com/mitchellh/serf/${SERF_VERSION}_linux_amd64.zip /
RUN (cd / && unzip ${SERF_VERSION}_linux_amd64.zip -d /usr/bin/)

# Setup the Serf service
RUN mkdir -p /etc/service/serf && \
    adduser --system --disabled-password --no-create-home \
            --quiet --force-badname --shell /bin/bash --group serf && \
    echo "serf ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99_serf && \
    chmod 0440 /etc/sudoers.d/99_serf
ADD bin/serf.sh /etc/service/serf/run
ADD bin/peer-member-join.sh /etc/service/serf/
ADD bin/seed-member-join.sh /etc/service/serf/

# Tune Riak and Riak CS configuration settings for the container
ADD etc/riak-advanced.config /etc/riak/advanced.config
RUN sed -i.bak 's/listener.http.internal = 127.0.0.1/listener.http.internal = 0.0.0.0/' /etc/riak/riak.conf && \
    sed -i.bak 's/listener.protobuf.internal = 127.0.0.1/listener.protobuf.internal = 0.0.0.0/' /etc/riak/riak.conf && \
    sed -i.bak 's/storage_backend = bitcask/## storage_backend = bitcask/' /etc/riak/riak.conf && \
	echo "buckets.default.allow_mult = true" >> /etc/riak/riak.conf && \
	echo "erlang.distribution_buffer_size = 96000" >> /etc/riak/riak.conf && \
    sed -i.bak "s/riak_cs-VERSION/riak_cs-${RIAK_CS_SHORT_VERSION}/" /etc/riak/advanced.config && \
    sed -i.bak "s/listener = 127.0.0.1/listener =  0.0.0.0/" /etc/riak-cs/riak-cs.conf && \
    sed -i.bak "s/anonymous_user_creation = off/anonymous_user_creation = on/" /etc/riak-cs/riak-cs.conf && \
    sed -i.bak "s/listener = 127.0.0.1/listener =  0.0.0.0/" /etc/stanchion/stanchion.conf

# Make the Riak, Riak CS, and Stanchion log directories into volumes
VOLUME /var/lib/riak
VOLUME /var/log/riak
VOLUME /var/log/riak-cs
VOLUME /var/log/stanchion

# Open the HTTP port for Riak and Riak CS (S3)
EXPOSE 8098 8080 22

# Enable sshd to get credentials
# See: https://github.com/phusion/baseimage-docker#enabling_ssh
RUN rm -f /etc/service/sshd/down

# Enable insecure SSH key
# See: https://github.com/phusion/baseimage-docker#using_the_insecure_key_for_one_container_only
RUN /usr/sbin/enable_insecure_key

# Cleanup
RUN rm "/${SERF_VERSION}_linux_amd64.zip"
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Leverage the baseimage-docker init system
CMD ["/sbin/my_init", "--quiet"]
