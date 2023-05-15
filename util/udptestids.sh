#!/bin/bash
# File name: udptestids.sh
# Date: 02/10/2023
# this file tests the effectiveness of IDS on UDP protocol 
# by making all the 4 nodes connnected to netFPGA router as server and then
# sends UDP traffic to all the nodes one by one
# Current limitation:
# this script assumes that file named message is available in the folder from where idsreg is run
# you have to copy this file named message to your home directory

if [ $# -eq 0 ]; then
  echo "udptestids: No pattern provided"
  echo "udptestids: usage: bash udptestids.sh <7-digit-pattern>"  
  exit 1
fi

# count number of times pattern was sent
counter=0

# set the pattern shared as an input
current_dir=$(pwd)
cd $HOME
echo "udptestids: setting the pattern to $1"
./idsreg pattern $1
# reset the matches
echo "udptestids: resetting matches"
./idsreg reset
echo "udptestids: new value of matches"
./idsreg matches
cd $current_dir
# making all the 4 nodes as servers
echo "udptestids: starting servers in all nodes"
#for i in 0 1 2 3
for i in {0..3}
do 
    ssh n$i.lab7.USCEE533.isi.deterlab.net "/usr/local/etc/emulab/emulab-iperf -s -u -p 3004" &
done 
sleep 2 
echo -e "\nudptestids: starting clients in all nodes"
#for i in 1
# sending udp traffic to all the nodes
for i in {0..3}
do 
  ssh n$i.lab7.USCEE533.isi.deterlab.net "/usr/local/etc/emulab/emulab-iperf -c n$(((i+1)%4)) -u -p 3004 -F message" &
sleep 2 
  let counter=counter+1
  echo -e "\nudptestids: sending the malicious code $1 cumulative no. of times $counter"
  ssh n$i.lab7.USCEE533.isi.deterlab.net  "/usr/local/etc/emulab/emulab-iperf -c n$(((i+2)%4)) -u -p 3004 -F $1" &
sleep 2 
  ssh n$i.lab7.USCEE533.isi.deterlab.net  "/usr/local/etc/emulab/emulab-iperf -c n$(((i+3)%4)) -u -p 3004 -F message" &
sleep 2 
done 
sleep 20 
for i in 0 1 2 3
do
    ssh n$i.lab7.USCEE533.isi.deterlab.net "sudo killall emulab-iperf"
done

current_dir=$(pwd)
cd $HOME
echo "udptestids: current value of matches"
./idsreg matches
cd $current_dir
echo "---------------------------------------------------------------"
echo "udptestids: pattern sent $counter times"
