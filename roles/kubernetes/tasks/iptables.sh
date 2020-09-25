#!/bin/bash
### Скрипт конфигурации IPTables ###
# Очищаем предыдущие записи
iptables -F
# Установка политик по умолчанию
iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT DROP
# Разрешаем локальный интерфейс
iptables -A INPUT -i lo -j ACCEPT
# REL, ESTB allow
iptables -A INPUT -p tcp -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p udp -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p udp -m state --state RELATED,ESTABLISHED -j ACCEPT
# Разрешаем рабочие порты
# 22 порт для всех
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
# Ansible
iptables -A INPUT -p tcp -s 192.168.1.177 --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -s 192.168.1.177  -j ACCEPT
iptables -A OUTPUT -p tcp -d 192.168.1.177  -j ACCEPT

# Прокси
iptables -A OUTPUT -p tcp -d 192.168.1.179 --dport 3128 -j ACCEPT
# DNS у нас гугловые
iptables -A OUTPUT -d 8.8.8.8  -j ACCEPT

#сервера kuber
iptables -A INPUT -p tcp -s 192.168.1.170,192.168.1.171,192.168.1.172,192.168.1.173,192.168.1.174,192.168.1.175,192.168.1.5 -j ACCEPT
iptables -A OUTPUT -d 192.168.1.170,192.168.1.171,192.168.1.172,192.168.1.173,192.168.1.174,192.168.1.175,192.168.1.5  -j ACCEPT
# Просмотр
iptables -L --line-number
echo
service iptables save
echo
service iptables reload
echo "Done"

