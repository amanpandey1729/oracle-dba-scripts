#!/bin/bash
#
white="\033[1;23m"
cyan="\033[1;36m"
reset="\033[0m"
echo " "
echo -e "${white}------------------------------------------------------------------System Information--------------------------------------------------------------${reset}"
echo -e "${cyan}Hostname:${reset}\t\t"`hostname -f`
echo -e "${cyan}IP Address:${reset}\t\t"`hostname -I`
echo -e "${cyan}Uptime:${reset}\t\t"`uptime | awk '{print $3,$4}' | sed 's/,//'`
echo -e "${cyan}Machine Type:${reset}\t\t"`vserver=$(lscpu | grep Hypervisor | wc -l); if [ $vserver -gt 0 ]; then echo "VM"; else echo "Physical"; fi`
echo -e "${cyan}Product Name:${reset}\t\t"`cat /sys/class/dmi/id/product_name`
echo -e "${cyan}Operating System:${reset}\t\t"`cat /etc/redhat-release`
echo -e "${cyan}Kernel:${reset}\t\t"`uname -r`
echo -e "${cyan}Architecture:${reset}\t\t"`arch`
echo -e "${cyan}Processor Name:${reset}\t\t"`awk -F':' '/^model name/ {print $2}' /proc/cpuinfo | uniq | sed -e 's/^[ \t]*//'`
echo -e "${cyan}CPU Cores:${reset}\t\t"`grep -c ^processor /proc/cpuinfo`
echo -e "${cyan}Total RAM:${reset}\t\t"`free -h | awk '/^Mem:/{print $2}'`
echo -e "${cyan}Disk Usage:${reset}\t\t"
df -h | grep '^/dev/'
echo -e "${cyan}Load Average:${reset}\t\t"`uptime | awk -F'load average:' '{ print $2 }'`
echo " "
echo -e "${white}------------------------------------------------------------------Resource Usage--------------------------------------------------------------${reset}"
echo -e "${cyan}CPU Usage:${reset}\t\t"`awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1) "%";}' <(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat)`
echo -e "${cyan}Memory Usage:${reset}\t\t"`free | awk '/Mem/{printf("%.2f%"), $3/$2*100}'`
echo -e "${cyan}Swap Usage:${reset}\t\t"`free | awk '/Swap/{printf("%.2f%"), $3/$2*100}'`
echo -e "${cyan}Top 5 Processes by CPU Usage:${reset}"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -6
echo -e "${cyan}Top 5 Processes by Memory Usage:${reset}"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -6
echo -e "${cyan}Disk I/O:${reset}\t\t"
iostat -x | head -10
echo -e "${cyan}Network Usage:${reset}\t\t"
netstat -i | grep -vE '^Kernel|Iface|lo'
echo -e "${cyan}Active Network Connections:${reset}"
netstat -ant | grep 'ESTABLISHED'
echo -e "${cyan}Swap Activity:${reset}"
vmstat 1 5
echo -e "${cyan}Zombie Processes:${reset}\t\t"
ps aux | awk '{ if ($8 == "Z") print $0; }'
echo " "
