#!/bin/bash

sudo ssh -w 5:0 -o PermitLocalCommand=yes -o LocalCommand="ip link set dev tun5 up && ip address add 192.168.244.2/24 dev tun5 && ip route add 10.0.0.0/8 via 192.168.244.1 dev tun5 && echo 'routing configured'" root@127.0.0.1 -p2231 'echo "you might wanna configure the dns if you want to resolve domain names as well"; echo "started tunnel..."'
