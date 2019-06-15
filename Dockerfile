FROM alpine

RUN apk add --no-cache openssh iptables && \
	sed -i 's/^.*AllowTcpForwarding.*$/AllowTcpForwarding yes/' /etc/ssh/sshd_config && \
	sed -i 's/^.*TCPKeepAlive.*$/TCPKeepAlive yes/' /etc/ssh/sshd_config && \
	sed -i 's/^.*PermitTunnel.*$/PermitTunnel yes/' /etc/ssh/sshd_config

ADD entrypoint.sh .

CMD ["./entrypoint.sh"]
