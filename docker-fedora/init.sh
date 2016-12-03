#!/bin/sh

# set storage first
(
    . /etc/sysconfig/docker-storage-setup
    /usr/bin/docker-storage-setup
)

for i in /etc/sysconfig/{docker,docker-storage,docker-network}; do
    test -e $i && . $i
done

while read i; do
        echo EVAL $i
        test -e $i && source $i
done < <(sed -n -e "s/EnvironmentFile=-*// p" /etc/systemd/system/docker.service.d/*)

export GOTRACEBACK=crash

/usr/libexec/docker/docker-containerd-current \
    --listen unix:///run/containerd.sock      \
    --shim /usr/bin/shim.sh &

exec /usr/bin/dockerd-current \
     --add-runtime oci=/usr/libexec/docker/docker-runc-current \
     --default-runtime=oci \
     --containerd /run/containerd.sock \
     --exec-opt native.cgroupdriver=systemd \
     --userland-proxy-path=/usr/libexec/docker/docker-proxy-current \
     $OPTIONS \
     $DOCKER_STORAGE_OPTIONS \
     $DOCKER_NETWORK_OPTIONS \
     $ADD_REGISTRY \
     $BLOCK_REGISTRY \
     $INSECURE_REGISTRY