#!/bin/bash
cat /etc/systemd/system/docker.service.d/http-proxy.conf| grep NO_PROXY | sed 's|\[||' | sed 's|\]||' > /root/docker-no-proxy.txt
cat /etc/systemd/system/docker.service.d/http-proxy.conf | grep -v 'NO_PROXY' > /root/docker-proxy.txt
cat /root/docker-proxy.txt /root/docker-no-proxy.txt > /etc/systemd/system/docker.service.d/http-proxy.conf
systemctl daemon-reload
systemctl restart docker

