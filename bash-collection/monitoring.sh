#!/bin/bash

NUM_OF_CPU_CORES=12

apps1="nginx php5-fpm dovecot memcached SCREEN mono"
apps2="master clamd smtpd icinga2 "

#################################################################

distri=$( lsb_release -d | cut -d ":" -f 2 | xargs )
kernel=$( uname -r )
mytop=$( mytop -b --nocolor --resolve )
top=$( top -b -n 1 | head -n 5 )
topapps=$( top -b -n 1 | grep -A 18 "PID USER" )
uptime=$( uptime -p )
mem=$( free -m | grep "Mem:" | xargs )
swap=$( free -m | grep "Swap:" | xargs )
iotop=$( iotop -b -n 1 | grep "Actual DISK READ" | head -n 1 )
cpus=($( mpstat -P ALL 1 1 | awk '/Average:/ && $2 ~ /[0-9]/ {printf "%d\n",$3}' ))
net=$( tail -n 1 /tmp/netstat.log | xargs )
updates=$( cat /var/lib/update-notifier/updates-available | xargs | cut -d " " -f 1 )
if [[ "$updates" = "" ]]; then
	updates=0
fi
out=""

bold="\e[1m"
red="\e[31m"
bred="\e[41m"
byellow="\e[43m"
white="\e[97m"
green="\e[32m"
blue="\e[34m"
black="\e[30m"
blink="\e[5m"
co="\e[0m\e[1m"

attention="${co}${bold}${bred}${white}${blink}"
warn="${co}${bold}${byellow}${black}${blink}"
okay="\e[0m\e[1m"

################################################################

colorize() {
	local out=$1
	local max=$2
	local low=$( echo "scale=2; (${max}/100)*75" | bc )
	out=$( echo "${out}" | xargs )
	if (( $(bc <<< "$out > $max") )); then
		out="${attention}${out}${co}"
	elif (( $(bc <<< "$out > $low") )); then
		out="${warn}${out}${co}"
	else
		out="${co}${green}${out}${co}"
	fi
	echo -e "${out}"
}

status() {
        local out=$1
        local min=$2
        if (( $(bc <<< "$out < $min") )); then
                out="${attention}${out}${co}"
        else
                out="${co}${green}${out}${co}"
        fi
        echo -e "${out}"
}

num_sleeps=$( echo "$mytop" | grep Sleep | wc -l )
queries=$( echo "$mytop" | grep "Queries:" | xargs | cut -d " " -f 2 )
qps=$( echo "$mytop" | grep "Queries:" | xargs | cut -d " " -f 4 )
slowqueries=$( echo "$mytop" | grep "Queries:" | xargs | cut -d " " -f 6 )
lavg1=$( cat /proc/loadavg | xargs | cut -d " " -f 1 )
lavg5=$( cat /proc/loadavg | xargs | cut -d " " -f 2 )
lavg15=$( cat /proc/loadavg | xargs | cut -d " " -f 3 )
procs=$( echo "$top" | grep "Tasks:" | xargs | cut -d " " -f 2 )
procs_running=$( echo "$top" | head -n 5 | grep "Tasks:" | xargs | cut -d "," -f 2 | xargs | cut -d " " -f 1 )
procs_sleeping=$( echo "$top" | head -n 5 | grep "Tasks:" | xargs | cut -d "," -f 3 | xargs | cut -d " " -f 1 )
procs_zombi=$( echo "$top" | head -n 5 | grep "Tasks:" | xargs | cut -d "," -f 5 | xargs | cut -d " " -f 1 )
rx=$( echo "$net" | cut -d " " -f 1 )
tx=$( echo "$net" | cut -d " " -f 2 )
mem_total=$( echo "$mem" | cut -d " " -f 2 )
mem_used=$( echo "$mem" | cut -d " " -f 3 )
swap_total=$( echo "$swap" | cut -d " " -f 2 )
swap_used=$( echo "$swap" | cut -d " " -f 3 )

disk_read=$( echo "$iotop" | cut -d "|" -f 1 | xargs | cut -d ":" -f 2 | xargs )
disk_write=$( echo "$iotop" | cut -d "|" -f 2 | xargs | cut -d ":" -f 2 | xargs )

num_sleeps=$( colorize $num_sleeps 10 )
queries=$( colorize $queries 10 )
qps=$( colorize $qps 10 )
slowqueries=$( colorize $slowqueries 10 )
lavg1=$( colorize $lavg1 3.99 )
lavg5=$( colorize $lavg5 3.99 )

lavg15=$( colorize $lavg15 3.99 )
procs=$( colorize $procs 409 )
procs_running=$( colorize $procs_running 20 )
procs_sleeping=$( colorize $procs_sleeping 999999 )
procs_zombi=$( colorize $procs_zombi 0 )
updates=$( colorize $updates 0 )
rx=$( colorize $rx 1000 )
tx=$( colorize $tx 1000 )
mem_used=$( colorize $mem_used 47500 )
swap_used=$( colorize $swap_used 0 )

appsr1=""
for i in $apps1; do
	pids=$( pidof ${i} | wc -w )
	if [[ "${appsr1}" != "" ]]; then
		appsr1="${appsr1} "
	fi
	pids=$( status $pids 1 )
	appsr1="${appsr1}${i}:${pids}"
done
appsr2=""
for i in $apps2; do
        pids=$( pidof ${i} | wc -w )
        if [[ "${appsr2}" != "" ]]; then
                appsr2="${appsr2} "
        fi
        pids=$( status $pids 1 )
        appsr2="${appsr2}${i}:${pids}"
done
appsr="${appsr1}\n\t\t${appsr2}"

usage=""
c=0
while true; do
	if [[ ${c} -eq ${NUM_OF_CPU_CORES} ]]; then
		break;
	fi
	if [[ "${usage}" != "" ]]; then
                usage="${usage} "
        fi
	# echo ${cpus[$c]}
	cpus[${c}]=$( colorize ${cpus[$c]} 10 )
	# echo ${cpus[$c]}
	usage="${usage}${cpus[$c]}%"
	c=$(( $c + 1 ))
done

date=$( date +"%d.%m.%Y" )
time=$( date +"%H:%M:%S" )
out="${out}\n          ~ ~ ~ LiCo - The Linux Counter Project - Server Monitor ~ ~ ~\n\n"
out="${out}================================================================================\n"
out="${out} Today:\t\t${date}\t${time}\n"
out="${out}--------------------------------------------------------------------------------\n"
out="${out} Info:\t\t${distri}\t${kernel}\n"
out="${out} \t\t${uptime}\tApt Updates: ${updates}\n"
out="${out}--------------------------------------------------------------------------------\n"
out="${out} Perf.:\t\tLoad avg: $lavg1 $lavg5 $lavg15\tProcesses: ${procs} (${procs_running}/${procs_sleeping}/${procs_zombi})\n"
out="${out}--------------------------------------------------------------------------------\n"
out="${out} Mem:\t\tRam total: $mem_total MB\tRam used: $mem_used MB\n"
out="${out} \t\tSwap total: $swap_total MB\tSwap used:  $swap_used MB\n"
out="${out}--------------------------------------------------------------------------------\n"
out="${out} HDD:\t\tCurrent read: $disk_read\tCurrent write: $disk_write\n"
out="${out}--------------------------------------------------------------------------------\n"
out="${out} CPU:\t\t${usage}\n"
out="${out}--------------------------------------------------------------------------------\n"
out="${out} MySQL:\t\tSleeps: $num_sleeps\tQueries: $queries\tqps: $qps\tSlowQueries: $slowqueries\n"
out="${out}--------------------------------------------------------------------------------\n"
out="${out} Net:\t\tIncoming: ${rx} kbps\tOutgoing: ${tx} kbps\n"
out="${out}--------------------------------------------------------------------------------\n"
out="${out} Status:\t${appsr}\n"
out="${out}--------------------------------------------------------------------------------\n"
out="${out}${topapps}\n"
out="${out}================================================================================\n"
out="${out}                         (c) 2015 by Alexander Löhner, The Linux Counter Project"

clear
echo -e "\e[1m${out}\e[0m"
exit 0
