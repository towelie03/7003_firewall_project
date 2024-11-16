#!/bin/bash

victim_ip="192.168.50.98"

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Re-running with sudo..."
  sudo "$0" "$@"
  exit
fi

# Disable Snort3
echo "Stopping Snort3 service..."
if systemctl is-active --quiet snort3; then
  sudo systemctl stop snort3
  echo "Snort3 service stopped."
else
  echo "Snort3 service is not running."
fi

# List all nftables rules
echo "Listing all nftables rules:"
nft list ruleset

# Clear all current nftables rules
echo "Flushing all nftables rules:"
nft flush ruleset

