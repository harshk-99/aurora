#!/bin/bash
# File name: tcptestids.sh
# Date: 02/10/2023
# this file tests the effectiveness of IDS on TCP protocol
# by making all the 4 nodes connnected to netFPGA router as server and then
# sends TCP traffic to all the nodes one by one
# Current limitation:
# this script assumes that file named message is available in the folder from where idsreg is run
# you have to copy this file named message to your home directory

# reset the matches register
#/users/usc533af/idsreg reset

if [ $# -eq 0 ]; then
echo "tcptestids: No pattern provided"
echo "tcptestids: usage: bash tcptestids.sh <7-digit-pattern>"
exit 1
fi

# count number of times pattern was sent
counter=0

# set the pattern shared as an input
current_dir=$(pwd)
cd $HOME
echo "tcptestids: setting the pattern to $1"
./idsreg pattern $1
# reset the matches
echo "tcptestids: resetting matches"
./idsreg reset
echo "tcptestids: new value of matches"
./idsreg matches
cd $current_dir

echo "tcptestids: starting servers in all nodes"
for i in {0..3}
do 
    echo "tcptestids: starting n$i"
    ssh n$i.lab7.USCEE533.isi.deterlab.net "/usr/local/etc/emulab/emulab-iperf -s -p 3004" &
    sleep 2
done 
#sleep 2 

echo "tcptestids: starting clients in all nodes"
for i in {0..3}
do 
    echo -e "\n\ntcptestids: iperf from n$i\n"
    ssh n$i.lab7.USCEE533.isi.deterlab.net "/usr/local/etc/emulab/emulab-iperf -c n$(((i+1)%4)) -p 3004 -F message" &
    sleep 2
    let counter=counter+1
    echo -e "\ntcptestids: sending pattern to n$(((i+2)%4)) cum. no. of times = $counter\n"
    ssh n$i.lab7.USCEE533.isi.deterlab.net "/usr/local/etc/emulab/emulab-iperf -c n$(((i+2)%4)) -p 3004 -F $1" &
    sleep 2
    ssh n$i.lab7.USCEE533.isi.deterlab.net "/usr/local/etc/emulab/emulab-iperf -c n$(((i+3)%4)) -p 3004 -F message" &
    sleep 2
done 
#sleep 2 

sleep 25
for i in 0 1 2 3
do
    ssh n$i.lab7.USCEE533.isi.deterlab.net "sudo killall emulab-iperf"
done

current_dir=$(pwd)
cd $HOME
echo "tcptestids: current value of matches"
./idsreg matches
cd $current_dir
echo "---------------------------------------------------------------"
echo "tcptestids: pattern sent $counter times"
