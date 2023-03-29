#!/bin/bash

file_name=testingreadfile.txt
sudo rm $file_name
sudo touch $file_name
sudo chmod 777 $file_name
echo -e "Address \t Control_Word \t Hi_Data \t Low_Data \n" >> $file_name
readaddr_pointer=0x2000304
address_lo=0x2000308
address_hi=0x200030c
address_cntr=0x2000310

for i in {0..255}
do
    ./regwrite $readaddr_pointer $i 
    # create a temporary file
    temp_file_lo=$(sudo mktemp)
    sudo chmod 777 $temp_file_lo
    # read the lower address
    ./regread $address_lo >> $temp_file_lo
    # store all the words in the line to an array called words
    word_lo=$(cat $temp_file_lo | cut -c30-39)
    # create a temporary file
    temp_file_hi=$(sudo mktemp)
    
    sudo chmod 777 $temp_file_hi
    # read the higher address
    ./regread $address_hi > $temp_file_hi
    word_hi=$(cat $temp_file_hi | cut -c30-39)
    temp_file_cntr=$(sudo mktemp)
    sudo chmod 777 $temp_file_cntr
    ./regread $address_cntr >> $temp_file_cntr

    word_cntr=$(cat $temp_file_cntr | cut -c30-39)
    # write these three words into the file 
    echo -e "$i \t $word_cntr \t $word_hi \t $word_lo" >> $file_name
    sudo rm $temp_file_cntr
    sudo rm $temp_file_lo
    sudo rm $temp_file_hi
done 
