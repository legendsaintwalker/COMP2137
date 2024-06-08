echo "my hostname is: $HOSTNAME "


#This line of code get the operating system information.
myOS=$(sudo hostnamectl | grep Operating)

# The system uptime is checked and filtered to know how long the system have being up. 
 
myuptime=$(uptime -p)

#The cpu information is extracted and filtered based on model name and assigned to a variable name.
cpu_info=$(lscpu | grep "Model name" | awk -F: '{print $2}')

#this script generate the current speed of the cpu and assign it to a viariable.
cpu_speed=$(grep "MHz" /proc/cpuinfo) 

#the total and available ram on the system is generated and filtered and assign it to a variable.
ram_installed=$(free -h | grep "Mem" | awk -F: '{print $2}') 

#The code loop through each disk available on the system and exclude the loop drives and assign it to a variable
disk_make=$(for disk in $(lsblk -dno NAME | grep -v '^loop'); do echo -n "Disk: /dev/$disk, Model: "; udevadm info --query=all --name=/dev/$disk | grep ID_MODEL= | awk - F= '{print $2}'; echo -n ", Size: "; lsblk -dno SIZE /dev/$disk; done)

#This code check the make and model of the video card installed on the system and assign it to a variable.
video=$(lspci -nn | grep -i vga)
#####################################################
#This check the fully qalified domain name of the system and assign it to a variable.
fqdn=$(hostname -f)

#The ip address was generated and filtered to meet CIDR format.
ip_add=$(nmcli device show ens37 | grep IP4.ADDRESS)
# The IP default gateway was generated and assigned to a variable name.
gateway=$(nmcli device show | grep 'IP4.GATEWAY' | awk '{print $2}' )

#show the available dns servers.
dns_server=$(nmcli | grep servers)

#The network interface make and model is generated and assined to a variable
interface=$(sudo lshw -class network | grep -i "description:" -A 2)

#This show the main ip address on all interface and assigned to a variable.
network_addr=$(ip -o -4 addr show | awk '{print $4}' )

###########################################################

#This show the current user in the account.
users_logged=$(who | awk '{print $1}')

#This show the available disk space on the system.
avail_space=$(df -h | grep dev/sd)

#The number of process is counted and assigned to a variable.
process_no=$(ps -e | wc -l)

#The load time and averate time of the system is generated and assigned to a variable .
load_time=$(uptime | awk '{print $8, $9, $10}')

#This show the free memory available on the system and assign it to a variable.
memory_allocation=$(free -h)

#This shows all listening port on the system.
listening_port=$(ss -tuln | grep LISTEN | awk '{print $1, $3, $4, $5, $6}')

#This show all the listening port on the system.
ufw_status=$(sudo ufw status | awk '{print $2}')


#The cat command is used to start the report and print multiple lines of output.

cat << ENDOFMYINPUT
System Report generated by $HOSTNAME , $DATE

SYSTEM INFORMATION

hostname: $HOSTNAME
Operatiing ayatem: $myOS
Uptime: $myuptime

HARDWARE INFORMATION

cpu: $cpu_info
Speed: $cpu_speed
Ram: $ram_installed
Disk: $disk_make
video card: $video

NETWORK INFORMATION

FQDN: $fqdn
Host Address: $ip_add
Gateway IP: $gateway
DNS Server: $dns_server
InterfaceName: $interface
IP Address: $network_addr

SYSTEM STATUS

Users Logged In: $users_logged
Disk Space: $avail_space
Process Count: $process_no
Load Averages: $load_time
Memory Allocation: $memory_allocation
Listening Network Ports: $listening_port
UFW Rules: $ufw_status



ENDOFMYINPUT
