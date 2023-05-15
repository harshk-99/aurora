#!/bin/bash
# File name: udptest.sh
# Date: 02/10/2023
# this file tests the effectiveness of IDS on generic UDP  protocol
# by making all the 4 nodes connnected to netFPGA router as server and then
# sends UDP traffic to all the nodes one by one
# Current limitation:
# this script assumes that file named message is available in the folder from 
# where idsreg is run you have to copy this file named message to your home directory

# if [ $# -lt 0 ]; then
#   echo "udptest.sh: No pattern provided"
#   echo "udptest.sh: usage: bash udptest.sh <7-digit-pattern>"
#   exit 1
# fi

# count number of times pattern was sent
#counter=0

# # set the pattern shared as an input
# current_dir=$(pwd)
# cd $HOME
# echo -e "udptest: setting the pattern to $1"
# ./idsreg pattern $1
# # reset the matches
# echo -e "udptest: resetting matches"
# ./idsreg reset
# echo -e "udptest: new value of matches"
# ./idsreg matches
# cd $current_dir


echo -e "udptest.sh: starting servers in all nodes"
for i in {0..3}
do
    echo -e "udptest: starting n$i"
    ssh n$i.lab7.USCEE533.isi.deterlab.net "/usr/local/etc/emulab/emulab-iperf -s -u -p 3000" &
    sleep 2
done 

echo -e "udptest.sh: starting clients in all nodes"
for i in {0..3}
do 
    ssh n$i.lab7.USCEE533.isi.deterlab.net "/usr/local/etc/emulab/emulab-iperf -c n$(((i+1)%4)) -u -p 3000 -b 1000M -l 512 -i 5 -t 30" &
done 
sleep 50

for i in {0..3}
do
    ssh n$i.lab7.USCEE533.isi.deterlab.net "sudo killall emulab-iperf"
done


# current_dir=$(pwd)
# cd $HOME
# echo "udptest: current value of matches"
# ./idsreg matches
# cd $current_dir
# echo "---------------------------------------------------------------"
#echo "udptest: pattern sent $counter times"

