#!/bin/bash

# Set variables based on your student number
STUDENT_NUMBER="1"  # Ganti dengan nomor absen Anda
CLIENT_IP="192.168.$STUDENT_NUMBER.0/24"
SERVER_IP="203.101.$STUDENT_NUMBER.0/29"
GATEWAY_IP="192.168.$STUDENT_NUMBER.1"
DHCP_START="192.168.$STUDENT_NUMBER.51"
DHCP_END="192.168.$STUDENT_NUMBER.100"
DNS_IP="203.101.0.2"
DOMAIN_NAME="smkn22.id"
ROOT_PASSWORD="SMKN22"

# Update and install required packages
apt-get update
apt-get install -y isc-dhcp-server iptables-persistent

# 1. Basic Configuration
echo "Configuring network interfaces..."

# Configure VM Gateway
cat <<EOL > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces (5).
source /etc/network/interfaces.d/*
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto enp0s3
iface enp0s3 inet static
address $GATEWAY_IP
netmask 255.255.255.0
network 192.168.$STUDENT_NUMBER.0

auto enp0s8
iface enp0s8 inet static
address $SERVER_IP
netmask 255.255.255.248
network 203.101.$STUDENT_NUMBER.0
EOL

# Restart networking
systemctl restart networking

# Set hostname
hostnamectl set-hostname "gateway-hostname"

# Set root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Configure DHCP Server
echo "Configuring DHCP Server..."
cat <<EOL >> /etc/dhcp/dhcpd.conf
subnet 192.168.$STUDENT_NUMBER.0 netmask 255.255.255.0 {
    range $DHCP_START $DHCP_END;  # DHCP option range
    option routers $GATEWAY_IP;   # DHCP option router
    option domain-name-servers $DNS_IP;  # DHCP option DNS
    option domain-name "$DOMAIN_NAME";  # DHCP option domain name
}
EOL

# Restart DHCP server
systemctl restart isc-dhcp-server

# Enable IP forwarding
echo "Enabling IP forwarding..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

# Configure NAT
iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE

# Install iptables-persistent to save iptables rules
netfilter-persistent save

# Finish
echo "Configuration completed successfully."
echo "Please reboot your system."
