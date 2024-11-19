#!/bin/bash

# Define the paths for configuration files
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

# Step 1: Remove all firewall and IDS configurations from Host B
echo "Removing all firewall and IDS configurations from Host B..."
ssh root@host_b "systemctl stop nftables && systemctl disable nftables"
ssh root@host_b "systemctl stop snort && systemctl disable snort"
ssh root@host_b "rm -f /etc/nftables.conf /etc/snort/snort.yaml"
echo "Firewall and IDS configurations removed from Host B."

# Step 2: Configure nftables on Host A to block certain types of outgoing traffic
echo "Creating nftables configuration at $NFTABLES_CONF on Host A..."

cat <<EOF > $NFTABLES_CONF
# nftables configuration for blocking outgoing traffic

# Define the 'filter' table for handling traffic
table inet filter {
    # Create a chain for output traffic (leaving the host)
    chain output {
        type filter hook output priority 0; policy accept;

        # Protection Against SYN Flood
        ip protocol tcp tcp flags syn limit rate 1/second accept
        ip protocol tcp tcp flags syn drop

        # Protection Against Ping of Death (ICMP Echo Requests)
        ip protocol icmp icmp type echo-request limit rate 1/second accept
        ip protocol icmp icmp type echo-request drop
    }
}
EOF

# Apply the nftables configuration
echo "Applying the nftables rules on Host A..."
nft -f $NFTABLES_CONF

# Enable the nftables service to persist on boot
echo "Enabling nftables service to start on boot on Host A..."
systemctl enable nftables

# Start the nftables service if it's not already running
echo "Starting nftables service on Host A..."
systemctl start nftables

# Verify the rules are applied
echo "Current nftables rules on Host A:"
nft list ruleset

# Step 3: Configure Snort3 on Host A to detect attack signatures
echo "Creating Snort3 configuration at $SNORT_CONF on Host A..."

if [ ! -f "$SNORT_CONF" ]; then
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

# Add Snort rules to detect UDP Flood, Xmas Tree Scan, and Buffer Overflow
echo "Creating custom Snort3 rule file..."

cat <<EOF | tee $CUSTOM_RULES > /dev/null
# Custom Snort3 Rules for detecting attacks
alert udp any any -> any any (msg:"UDP Flood detected"; threshold:type both, track by_dst, count 50, seconds 1; sid:1000003;)
alert tcp any any -> any any (msg:"Xmas Tree Scan detected"; flags: FPU; sid:1000004;)
alert ip any any -> any any (msg:"Possible Buffer Overflow"; content:"AAAAAAAAAAAAAAAAAAAA"; sid:1000002;)
EOF

# Add custom rule file to snort.yaml
echo "Adding custom rule file to snort.yaml configuration..."
sed -i "/rule-path:/a \ \ - $CUSTOM_RULES" $SNORT_CONF

# Step 4: Enable Snort3 on Host A
echo "Enabling Snort3 service to start on boot on Host A..."
systemctl enable snort

# Start Snort3 service
echo "Starting Snort3 service on Host A..."
systemctl start snort

# Step 5: Rerun all attacks from Host A to Host B
echo "Rerunning attacks from Host A to Host B..."

# Step 6: Capture the traffic using Wireshark on Host A
echo "Starting Wireshark to capture traffic on Host A..."
wireshark &

# Step 7: Review nftables logs and Snort3 alerts on Host A
echo "Reviewing nftables logs..."
journalctl -u nftables

echo "Reviewing Snort3 alerts..."
tail -f /var/log/snort/alert

