#!/bin/bash

# Define paths for Snort3 and nftables configurations
NFTABLES_CONF="/etc/nftables.conf"
SNORT_CONF="/etc/snort/snort.yaml"
RULES_DIR="/etc/snort/rules"
CUSTOM_RULES="/etc/snort/rules/custom.rules"

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Re-running with sudo..."
  sudo "$0" "$@"
  exit
fi

# Flush and reset nftables configuration
echo "Resetting nftables configuration to default..."
nft flush ruleset

# Remove the custom nftables configuration file
if [ -f "$NFTABLES_CONF" ]; then
    echo "Removing custom nftables configuration file..."
    rm $NFTABLES_CONF
fi

# Reset nftables to its default settings
echo "Resetting nftables to default rules..."
nft -f /etc/nftables.conf

# Restart nftables service to apply default configuration
echo "Restarting nftables service..."
systemctl restart nftables

# Reset Snort3 configuration to default
echo "Resetting Snort3 configuration..."

# Remove custom Snort rules
if [ -f "$CUSTOM_RULES" ]; then
    echo "Removing custom Snort3 rules..."
    rm $CUSTOM_RULES
fi

# Restore default Snort3 rule configuration file
if [ -f "$SNORT_CONF" ]; then
    echo "Restoring default Snort3 configuration..."
    cp /etc/snort/snort.default.yaml $SNORT_CONF
fi

# Remove downloaded Snort3 rules
if [ -d "$RULES_DIR" ]; then
    echo "Removing custom Snort3 rule set..."
    rm -rf $RULES_DIR
fi

# Restart Snort3 service to apply default configuration
echo "Restarting Snort3 service..."
systemctl restart snort

# Check the status of nftables and Snort3
echo "Current nftables rules:"
nft list ruleset

echo "Snort3 status:"
systemctl status snort

echo "Snort3 and nftables configurations reset to default successfully!"

