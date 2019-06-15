#!/bin/sh

set -x

if [ -e /etc/ssh-back/ssh ]; then
	mkdir -p /etc/ssh
	cp -rf /etc/ssh-back/ssh{ssh_host_rsa_key,ssh_host_rsa_key.pub,sshd_config} /etc/ssh
	cp -r /etc/ssh-back/shadow /etc/shadow
fi

if [ "$AUTH" == "empty" ]; then
    echo 'root:' | chpasswd
    sed -i 's/^.*PermitRootLogin.*$/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/^.*PermitEmptyPasswords.*$/PermitEmptyPasswords yes/' /etc/ssh/sshd_config
elif [ "$AUTH" == "key" ]; then
    if [ -n "${KEY}" ]; then
        if ! grep "${KEY}" /root/.ssh/authorized_keys; then
            echo "${KEY}" >> /root/.ssh/authorized_keys
        fi
    fi
    sed -i 's/^.*PermitRootLogin.*$/PermitRootLogin without-password/' /etc/ssh/sshd_config
    sed -i 's/^.*PermitEmptyPasswords.*$/PermitEmptyPasswords no/' /etc/ssh/sshd_config
else
    if [ -z "${PASSWORD}" ]; then
        if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
            PASSWORD=$(strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 30 | tr -d '\n')
            echo "using root password: ${PASSWORD}"
            echo "root:${PASSWORD}" | chpasswd
        fi
    else
        echo "root:${PASSWORD}" | chpasswd
    fi
    sed -i 's/^.*PermitRootLogin.*$/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/^.*PermitEmptyPasswords.*$/PermitEmptyPasswords no/' /etc/ssh/sshd_config
fi

if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
fi

if [ -e /etc/ssh-back ]; then
	mkdir -p /etc/ssh-back/ssh
	cp -rf /etc/ssh/ssh{ssh_host_rsa_key,ssh_host_rsa_key.pub,sshd_config} /etc/ssh-back/ssh
	cp -r /etc/shadow /etc/ssh-back/shadow
fi

mkdir -p /dev/net

mknod /dev/net/tun c 10 200
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -A FORWARD -i tun0 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

set +x

echo '
while sleep 0.1; do
    if ip link | grep tun0 >/dev/null && ! ip address | grep 192.168.244.1 >/dev/null; then
        echo "setting 192.168.244.1/24 on tun0"
	ip link set dev tun0 up
	ip address add 192.168.244.1/24 dev tun0
    fi
done
' | sh &

/usr/sbin/sshd -D
