#!/bin/bash

# Define the path for the nftables configuration file
NFTABLES_CONF="/etc/nftables.conf"

# Define Snort3 configuration file
SNORT_CONF="/etc/snort/snort.yaml"
RULES_DIR="/etc/snort/rules"

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Re-running with sudo..."
  sudo "$0" "$@"
  exit
fi

# Create nftables.conf with SYN Flood and Ping of Death protection rules
echo "Creating nftables configuration at $NFTABLES_CONF..."

cat <<EOF > $NFTABLES_CONF
# nftables configuration for SYN Flood and Ping of Death protection

# Define the 'filter' table for handling traffic
table inet filter {
    # Create a chain for input traffic (coming to the host)
    chain input {
        type filter hook input priority 0; policy drop;

        # Accept established and related connections
        ct state established,related accept

        # Allow localhost traffic (loopback interface)
        iif lo accept

        # Protection Against SYN Flood
        ip protocol tcp tcp flags syn limit rate 1/second accept
        ip protocol tcp tcp flags syn drop

        # Protection Against Ping of Death (ICMP Echo Requests)
        ip protocol icmp icmp type echo-request limit rate 1/second accept
        ip protocol icmp icmp type echo-request drop

        # Drop packets from invalid IP ranges
        ip saddr { 10.0.0.0/8, 192.168.0.0/16, 169.254.0.0/16 } drop

        # Drop fragmented IP packets
        ip frag-off & 0x1fff != 0 drop
    }

    # Create a chain for forwarding traffic (if you have routing)
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
}
EOF

# Apply the nftables configuration
echo "Applying the nftables rules..."
nft -f $NFTABLES_CONF

# Enable the nftables service to persist on boot
echo "Enabling nftables service to start on boot..."
systemctl enable nftables

# Start the nftables service if it's not already running
echo "Starting nftables service..."
systemctl start nftables

# Verify the rules are applied
echo "Current nftables rules:"
nft list ruleset

echo "nftables configuration is set up and applied successfully!"


# Create Snort3 configuration if it does not exist
if [ ! -f "$SNORT_CONF" ]; then
  echo "Creating snort.yaml configuration file..."
  mkdir -p /etc/snort
  touch $SNORT_CONF
  cat <<EOF | tee $SNORT_CONF > /dev/null
# Snort3 Configuration File

source-ip: 0.0.0.0
output:
  - console: {}

# Snort3 rules configuration
rule-path: $RULES_DIR
EOF
fi

# Download and configure Snort rule sets if needed
echo "Downloading Snort3 community rules..."
mkdir -p $RULES_DIR
cd $RULES_DIR
wget https://www.snort.org/rules/snort3-community-rules.tar.gz

# Extract and configure rules
echo "Extracting Snort3 rules..."
tar -xvzf snort3-community-rules.tar.gz
rm snort3-community-rules.tar.gz

# Verify that rules are downloaded and extracted correctly
echo "Snort3 rules directory contains:"
ls $RULES_DIR

# Add Snort rule to detect SYN flood attacks and buffer overflows
echo "Creating custom Snort3 rule file..."

CUSTOM_RULES="/etc/snort/rules/custom.rules"
cat <<EOF | tee $CUSTOM_RULES > /dev/null
# Custom Snort3 Rules for detecting attacks
alert tcp any any -> any 80 (msg:"SYN Flood detected"; flags:S; threshold:type both, track by_dst, count 50, seconds 1; sid:1000001;)
alert ip any any -> any any (msg:"Possible Buffer Overflow"; content:"AAAAAAAAAAAAAAAAAAAA"; sid:1000002;)
EOF

# Add custom rule file to snort.yaml
echo "Adding custom rule file to snort.yaml configuration..."
sed -i "/rule-path:/a \ \ - $CUSTOM_RULES" $SNORT_CONF

