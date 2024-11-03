#!/bin/ksh

###################Linux Control###################
Linux_Information() {
echo -e "
#####################################################################
Health Check Report (CPU,Process,Disk Usage, Memory)
#####################################################################
Hostname : `hostname`
Kernel Version : `uname -r`
Uptime : `uptime | sed 's/.*up \([^,]*\), .*/\1/'`
Last Reboot Time : `/usr/bin/who -b | awk '{print $3,$4}'`
Core Number : `cat /proc/cpuinfo |grep processor|wc -l|awk '{print $1}'`
IP : `cat /etc/hosts|egrep 'loghost|localhost'|awk '{print $1}'|grep -v ":"|grep -v 127.0.0.1`
Load Average : `uptime | awk -F'load average:' '{ print $2 }' |cut -d ',' -f 1,1|awk '{print $1}'`
CPU count: `lscpu | egrep 'Model name|Socket|Thread|NUMA|CPU\(s\)'`
#####################################################################
System Performance Report
"
}

Linux_CPU() {
echo -e "
#####################################################################
CPU USAGE
#####################################################################
"
printf "%-20s%-20s%-20s\n" "CPU ID" "IDLE" "TOTAL IDLE"
printf "%-20s%-20s%-20s\n" "------" "----" "---------"
for i in $(cat /proc/cpuinfo |grep processor|awk '{print $3}'|head -10)
do
CPUID=`echo CPU$i`
#CPU_IDLEX=`/usr/bin/mpstat -P ALL`
#CPU_IDLE=`echo $CPU_IDLEX| awk -v var=$i '{ if ($3 == var ) print $10 }'`
CPU_IDLE=`/usr/bin/mpstat -P ALL 1 1|grep Average|grep -v all|awk -v var=$i '{ if ($2 == var ) print $9}'`
#TOTAL_CPU=`sar -u 1 1|awk '{print $8}'|grep '[0-9][0-9]'`
TOTAL_CPU=`/usr/bin/top -b -d 1 -n1|grep Cpu|awk '{print $5}'|cut -d '%' -f 1,1`
printf "%-20s%-20s%-20s\n" "$CPUID" "$CPU_IDLE" "$TOTAL_CPU"
done
echo "
---------------------------------------------------------------------
Process CPU Usage Detail
---------------------------------------------------------------------
"
printf "%-20s %-20s %-20s %-20s\n" "PID" "USER" "%CPU" "COMMAND"
printf "%-20s %-20s %-20s %-20s\n" "---" "----" "----" "------------------"
/usr/bin/top b -n1 | head -17 |grep -v "PID"|tail -11|awk '{ printf "%-20s %-20s %-20s %-20s\n", $1, $2, $9, $12}'
}
Linux_Memory() {
echo -e "
#####################################################################
Memory USAGE
#####################################################################
"
TOTALMEM=`/usr/bin/free -m | head -2 | tail -1| awk '{print $2}'`
TOTALBC=`echo "scale=2;if($TOTALMEM<1024 && $TOTALMEM > 0) print 0;$TOTALMEM/1024"| bc -l`
USEDMEM=`/usr/bin/free -m | head -2 | tail -1| awk '{print $3}'`
USEDBC=`echo "scale=2;if($USEDMEM<1024 && $USEDMEM > 0) print 0;$USEDMEM/1024"|bc -l`
FREEMEM=`/usr/bin/free -m | head -2 | tail -1| awk '{print $4}'`
FREEBC=`echo "scale=2;if($FREEMEM<1024 && $FREEMEM > 0) print 0;$FREEMEM/1024"|bc -l`
TOTALSWAP=`/usr/bin/free -m | tail -1| awk '{print $2}'`
TOTALSBC=`echo "scale=2;if($TOTALSWAP<1024 && $TOTALSWAP > 0) print 0;$TOTALSWAP/1024"| bc -l`
USEDSWAP=`/usr/bin/free -m | tail -1| awk '{print $3}'`
USEDSBC=`echo "scale=2;if($USEDSWAP<1024 && $USEDSWAP > 0) print 0;$USEDSWAP/1024"|bc -l`
FREESWAP=`/usr/bin/free -m | tail -1| awk '{print $4}'`
FREESBC=`echo "scale=2;if($FREESWAP<1024 && $FREESWAP > 0) print 0;$FREESWAP/1024"|bc -l`
Cache=`/usr/bin/free -m | head -2 | tail -1| awk '{print $7}'`
Cached=`echo "scale=2;if($Cache<1024 && $Cache > 0) print 0;$Cache/1024"|bc -l`
Mem_res=`echo "$(($FREEMEM * 100 / $TOTALMEM ))"`
Swap_res=`echo "$(($FREESWAP * 100 / $TOTALSWAP ))"`
echo "
---------------------------------------------------------------------
Memory Detail
---------------------------------------------------------------------
"
printf "%-20s%-20s%-20s%-20s%-20s\n" "TOTAL MEMORY" "USED MEMORY" "FREE MEMORY" "FREE MEMORY(%)" "CACHE MEM"
printf "%-20s%-20s%-20s%-20s%-20s\n" "------------" "-----------" "-----------" "--------------" "---------"
printf "%-20s%-20s%-20s%-20s%-20s\n" " $TOTALMEM MB" " $USEDMEM MB" " $FREEMEM MB" " %$Mem_res" "$Cache MB"
echo "
---------------------------------------------------------------------
Swap Detail
---------------------------------------------------------------------
"
printf "%-20s%-20s%-20s%-20s\n" "TOTAL SWAP" "USED SWAP" "FREE SWAP" "FREE SWAP(%)"
printf "%-20s%-20s%-20s%-20s\n" "------------" "-----------" "-----------" "--------------"
printf "%-20s%-20s%-20s%-20s\n" " $TOTALSWAP MB" " $USEDSWAP MB" " $FREESWAP MB" " %$Swap_res"

echo "
---------------------------------------------------------------------
Process Memory Usage Detail
---------------------------------------------------------------------
"
printf "%-20s %-20s %-20s %-20s %-20s\n" "USER" "PID" "%MEM" "RSS" "COMMAND"
#ps aux | awk '{print $1, $2, $4, $6, $11}' | sort -k3rn | head -n 10|awk '{ printf "%-20s %-20s %-20s %-20s %-20s\n", $1, $2, $3, $4, $5}'
ps -eo user,pid,pmem,rss,comm| awk '{print $1, $2, $3, $4, $5}' | sort -k3rn | head -n 10|awk '{ printf "%-20s %-20s %-20s %-20s %-20s\n", $1, $2, $3, $4, $5}'
}
Linux_Disk() {
echo -e "
#####################################################################
Disk Performance
#####################################################################
"
/usr/bin/iostat -x 1 1
echo "If r_await w_await are more than 10ms then Disk Service Time is NOT OK and Check with Storage to investigate the issue"

}
###################################################

OS=`uname -s`

case "$OS" in
"Linux")
Linux_Information
Linux_CPU
Linux_Memory
Linux_Disk

esac

exit 0
