#!/bin/bash

echo "

This script will change the IP address of your system to 192.168.16.21.
This script will check if apache2 and squid are installed and will install them if not installed.
The script will ensure the firewall rule is configured.
This script will create user accounts and set up ssh for user accounts.
"

echo " The process is updating and will keep you notified of every step. "

# Ensure script is run with superuser privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or use sudo."
    exit 1
fi

echo " Configuring the new IP address and setting up the interface."

# Network interface name for the 192.168.16 network
INTERFACE="eth0"

# New IP address, subnet mask, and gateway
NEW_IP="192.168.16.21"
SUBNET_MASK="24"
GATEWAY="192.168.16.2"

# DNS servers (optional, adjust if needed)
DNS1="8.8.8.8"
DNS2="8.8.4.4"

# Hostname to be set
HOSTNAME="server1"

# Netplan configuration file path
NETPLAN_CONFIG="/etc/netplan/10-lxc.yaml"

echo "Backing up the original netplan configuration file..."
cp $NETPLAN_CONFIG $NETPLAN_CONFIG.bak

# Function to add new network configuration to netplan
add_netplan_config() {
    echo "Adding new network configuration to netplan..."
    cat <<EOL > $NETPLAN_CONFIG
network:
    version: 2
    ethernets:
        $INTERFACE:
            addresses: [$NEW_IP/$SUBNET_MASK]
            routes:
              - to: default
                via: $GATEWAY
            nameservers:
                addresses: [192.168.16.2]
                search: [home.arpa, localdomain]
        eth1:
            addresses: [172.16.1.200/24]
EOL
}




# Apply new netplan configuration
add_netplan_config
echo "Applying the new netplan configuration..."
netplan apply

echo "Updating /etc/hosts file with the new IP address..."
# Update /etc/hosts file with the new IP address
if grep -q "$HOSTNAME" /etc/hosts; then
    # If hostname already exists, update its IP address
    sudo sed -i "s/.*$HOSTNAME/$NEW_IP $HOSTNAME/" /etc/hosts
else
    # Otherwise, add new hostname and IP address
    echo "$NEW_IP $HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
fi

echo "IP address of $INTERFACE changed to $NEW_IP"
echo "/etc/hosts file updated with $NEW_IP for $HOSTNAME"

# Function to check if a package is installed, and install it if not
check_and_install() {
    local package=$1
    if dpkg -l | grep -q "^ii  $package "; then
        echo "$package is already installed."
    else
        echo "$package is not installed. Installing $package..."
        sudo apt update
        sudo apt install -y $package
        echo "$package installation completed."
    fi
}
echo " Ip address has being successfully configured"


echo "Checking and installing Apache..."
# Check and install Apache
check_and_install apache2

echo "Checking and installing Squid..."
# Check and install Squid
check_and_install squid

echo "Apache and Squid have been checked and installed."

# Define management network and ports for UFW rules
MGMT_NETWORK="192.168.16.2/24"  # Change this to your management network subnet
HTTP_PORT=80
PROXY_PORT=3128  # Change this if your proxy uses a different port

# Function to check if a package is installed
is_installed() {
  dpkg -l | grep -q "$1"
}

# Check if UFW is installed
if ! is_installed "ufw"; then
  echo "UFW is not installed. Installing UFW."
  sudo apt install ufw -y
else
  echo "UFW is already installed."
fi

# Function to set up UFW (Uncomplicated Firewall) rules

    echo "Setting up UFW rules..."
    # Reset UFW to default settings
    sudo ufw reset -y

    # Set default policies to deny incoming connections and allow outgoing
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    # Allow SSH access only from the management network
    sudo ufw allow from 172.16.1.2 to any port 22

    # Allow HTTP traffic on all interfaces
    sudo ufw allow $HTTP_PORT/tcp

    # Allow web proxy traffic on all interfaces
    sudo ufw allow $PROXY_PORT/tcp

    # Enable UFW
    sudo ufw enable

    # Show UFW status and rules
    sudo ufw status verbose


# Execute the function to set up UFW rules


# Define the list of users
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

# Define additional SSH key for 'dennis'
DENNIS_ADDITIONAL_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

# Function to generate SSH keys for a user
generate_ssh_keys() {
    local user=$1
    # Generate RSA key
    sudo -u "$user" ssh-keygen -t rsa -b 4096 -f "/home/$user/.ssh/id_rsa" -N "" -q
    # Generate ED25519 key
    sudo -u "$user" ssh-keygen -t ed25519 -f "/home/$user/.ssh/id_ed25519" -N "" -q
}

# Loop through each user and create/setup as needed
for user in "${users[@]}"; do
    if id "$user" &>/dev/null; then
        echo "User $user already exists."
    else
        echo "Creating user $user..."
        sudo useradd -m -s /bin/bash "$user"
    fi
    
    if [ "$user" == "dennis" ]; then
        echo "Setting up SSH for $user..."
        sudo mkdir -p /home/"$user"/.ssh
        sudo chmod 700 /home/"$user"/.ssh
        generate_ssh_keys "$user"

        sudo touch /home/"$user"/.ssh/authorized_keys
        sudo chmod 600 /home/"$user"/.ssh/authorized_keys

        cat /home/"$user"/.ssh/id_rsa.pub | sudo tee -a /home/"$user"/.ssh/authorized_keys > /dev/null
        cat /home/"$user"/.ssh/id_ed25519.pub | sudo tee -a /home/"$user"/.ssh/authorized_keys > /dev/null

        echo "$DENNIS_ADDITIONAL_KEY" | sudo tee -a /home/"$user"/.ssh/authorized_keys > /dev/null
        echo "Adding 'dennis' to the sudo group..."
        sudo usermod -aG sudo dennis

        sudo chown -R "$user":"$user" /home/"$user"/.ssh
    fi
done

echo "All users have been set up and configured successfully."

