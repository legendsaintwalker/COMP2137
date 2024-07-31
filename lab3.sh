#!/bin/bash

# This script runs the configure-host.sh script from the current directory to modify 2 servers and update the local /etc/hosts file

VERBOSE=0
VERBOSE_OPTION=""

# Function to print verbose messages
function vprint() {
    if [ "$VERBOSE" -eq 1 ]; then
        echo "$1"
    fi
}

# Check if -verbose option is provided
for arg in "$@"; do
    if [ "$arg" == "-verbose" ]; then
        VERBOSE=1
        VERBOSE_OPTION="-verbose"
        break
    fi
done

# Function to transfer and execute the script on a remote server
function execute_remote_script() {
    local SERVER=$1
    local COMMAND=$2

    vprint "Transferring configure-host.sh to $SERVER"
    scp configure-host.sh remoteadmin@$SERVER:/root
    if [ $? -ne 0 ]; then
        echo "Error: Failed to transfer configure-host.sh to $SERVER"
        exit 1
    fi

    vprint "Executing configure-host.sh on $SERVER"
    ssh remoteadmin@$SERVER -- "/root/configure-host.sh $VERBOSE_OPTION $COMMAND"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to execute configure-host.sh on $SERVER"
        exit 1
    fi
}

# Execute the script on server1
execute_remote_script "server1-mgmt" "-name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4"

# Execute the script on server2
execute_remote_script "server2-mgmt" "-name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3"

# Execute the script on the local machine
vprint "Updating local /etc/hosts file"
./configure-host.sh $VERBOSE_OPTION -hostentry loghost 192.168.16.3
if [ $? -ne 0 ]; then
    echo "Error: Failed to update local /etc/hosts file for loghost"
    exit 1
fi

./configure-host.sh $VERBOSE_OPTION -hostentry webhost 192.168.16.4
if [ $? -ne 0 ]; then
    echo "Error: Failed to update local /etc/hosts file for webhost"
    exit 1
fi

vprint "Script execution completed successfully"
