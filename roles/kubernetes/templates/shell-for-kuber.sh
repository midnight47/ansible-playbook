#!/bin/bash
cat /root/token.txt | grep -Ei 'kubeadm join|--token|--discovery|--control-plane' | grep '^-' | sed 's|^-||g' | tr -d "'" | head -3 |tr -d '\' | tr -s '\r\n' ' ''' > /root/token-master.txt
cat /root/token.txt | grep -Ei 'kubeadm join|--token|--discovery|--control-plane' | grep '^-' | sed 's|^-||g' | tr -d "'" | tail -2 |tr -d '\' | tr -s '\r\n' ' ''' > /root/token-worker.txt
