#!/bin/bash

# Define paths for Snort3 and nftables configurations
NFTABLES_CONF="/etc/nftables.conf"
SNORT_CONF="/etc/snort/snort.yaml"
RULES_DIR="/etc/snort/rules"
CUSTOM_RULES="/etc/snort/rules/custom.rules"

# Flush and reset nftables configuration
echo "Resetting nftables configuration to default..."
sudo nft flush ruleset

# Remove the custom nftables configuration file
if [ -f "$NFTABLES_CONF" ]; then
    echo "Removing custom nftables configuration file..."
    sudo rm $NFTABLES_CONF
fi

# Reset nftables to its default settings
echo "Resetting nftables to default rules..."
sudo nft -f /etc/nftables.conf

# Restart nftables service to apply default configuration
echo "Restarting nftables service..."
sudo systemctl restart nftables

# Reset Snort3 configuration to default
echo "Resetting Snort3 configuration..."

# Remove custom Snort rules
if [ -f "$CUSTOM_RULES" ]; then
    echo "Removing custom Snort3 rules..."
    sudo rm $CUSTOM_RULES
fi

# Restore default Snort3 rule configuration file
if [ -f "$SNORT_CONF" ]; then
    echo "Restoring default Snort3 configuration..."
    sudo cp /etc/snort/snort.default.yaml $SNORT_CONF
fi

# Remove downloaded Snort3 rules
if [ -d "$RULES_DIR" ]; then
    echo "Removing custom Snort3 rule set..."
    sudo rm -rf $RULES_DIR
fi

# Restart Snort3 service to apply default configuration
echo "Restarting Snort3 service..."
sudo systemctl restart snort3

# Check the status of nftables and Snort3
echo "Current nftables rules:"
sudo nft list ruleset

echo "Snort3 status:"
sudo systemctl status snort3

echo "Snort3 and nftables configurations reset to default successfully!"

