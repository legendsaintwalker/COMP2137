#!/bin/bash

#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or use sudo."
    exit 1
fi

# Ignore TERM, HUP and INT signals
trap '' TERM HUP INT

VERBOSE=0
HOSTNAME=""
IPADDRESS=""
HOSTENTRY_NAME=""
HOSTENTRY_IP=""

SUBNET_MASK="24"
GATEWAY="192.168.16.2"

# DNS servers (optional, adjust if needed)
DNS1="8.8.8.8"
DNS2="8.8.4.4"

# Function to print verbose messages
function vprint() {
    if [ "$VERBOSE" -eq 1 ]; then
        echo "$1"
    fi
}

# Function to update the hostname
function update_hostname() {
    CURRENT_HOSTNAME=$(hostname)
    if [ "$CURRENT_HOSTNAME" != "$HOSTNAME" ]; then
        vprint "Changing hostname from $CURRENT_HOSTNAME to $HOSTNAME"
        echo "$HOSTNAME" > /etc/hostname
        sed -i "s/$CURRENT_HOSTNAME/$HOSTNAME/g" /etc/hosts
        hostnamectl set-hostname "$HOSTNAME"
        logger "Hostname changed from $CURRENT_HOSTNAME to $HOSTNAME"
    else
        vprint "Hostname is already set to $HOSTNAME"
    fi
}

# Function to update the IP address
function update_ipaddress() {
    CURRENT_IP=$(hostname -I | awk '{print $1}')
    NETPLAN_FILE="/etc/netplan/10-lxc.yaml"

    if [ "$CURRENT_IP" != "$IPADDRESS" ]; then
        vprint "Changing IP address from $CURRENT_IP to $IPADDRESS"
           cat <<EOL > $NETPLAN_FILE
network:
    version: 2
    ethernets:
        $INTERFACE:
            addresses: [$IPADDRESS/$SUBNET_MASK]
            routes:
              - to: default
                via: $GATEWAY
            nameservers:
                addresses: [192.168.16.2]
                search: [home.arpa, localdomain]
        eth1:
            addresses: [172.16.1.200/24]
EOL

    else
        vprint "IP address is already set to $IPADDRESS"
    fi
}

# Function to update /etc/hosts with host entry
function update_hostentry() {
    if grep -q "$HOSTENTRY_IP" /etc/hosts; then
        CURRENT_HOSTENTRY=$(grep "$HOSTENTRY_IP" /etc/hosts)
        if [ "$CURRENT_HOSTENTRY" != "$HOSTENTRY_IP $HOSTENTRY_NAME" ]; then
            vprint "Updating host entry to $HOSTENTRY_IP $HOSTENTRY_NAME"
            sed -i "s/.*$HOSTENTRY_IP.*/$HOSTENTRY_IP $HOSTENTRY_NAME/g" /etc/hosts
            logger "Host entry changed to $HOSTENTRY_IP $HOSTENTRY_NAME"
        else
            vprint "Host entry is already set to $HOSTENTRY_IP $HOSTENTRY_NAME"
        fi
    else
        vprint "Adding new host entry $HOSTENTRY_IP $HOSTENTRY_NAME"
        sudo echo "$HOSTENTRY_IP $HOSTENTRY_NAME" >> /etc/hosts
        logger "Host entry added: $HOSTENTRY_IP $HOSTENTRY_NAME"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -verbose)
            VERBOSE=1
            shift
            ;;
        -name)
            HOSTNAME="$2"
            shift 2
            ;;
        -ip)
            IPADDRESS="$2"
            shift 2
            ;;
        -hostentry)
            HOSTENTRY_NAME="$2"
            HOSTENTRY_IP="$3"
            shift 3
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done
 
# Apply the configurations
if [ -n "$HOSTNAME" ]; then
    update_hostname
fi

if [ -n "$IPADDRESS" ]; then
    update_ipaddress
fi

if [ -n "$HOSTENTRY_NAME" ] && [ -n "$HOSTENTRY_IP" ]; then
    update_hostentry
fi

# Exit script
exit 0

