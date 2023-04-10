#!/bin/bash

file_name=testingreadfile.txt
sudo rm $file_name
sudo touch $file_name
sudo chmod 777 $file_name
printf "%-7s\t%-5s\t%-2s\t%-6s\t%-6s\t%-8s\t%-8s\t%-4s\t%-6s\t%-6s\t%-8s\t%-8s\n" "counter""state""pc""rdaddr""rdatac""rdatah""rdatal""wren""wraddr""wdatac""wdatah""wdatal" >> $file_name
#printf "%3x\t%x\t%2x\t%2x\t%2x\t%8x\t%8x\t%x\t%2x\t%2x\t%8x\t%8x\n" "$i"  "$state_hex" "$pc_hex" "$rdaddr_hex" "$rddata_ctrl_hex" "$rddata_hi_hex" "$rddata_lo_hex" "$wr_en_extracted" "$wraddr_hex" "$wrdata_ctrl_hex" "$wrdata_hi_hex" "$wrdata_lo_hex">> $file_name
printf "counter\tstate\tpc\trdaddr\trdatac\trdatah\t\trdatal\t\twren\twraddr\twdatac\twdatah\t\twdatal\n">> $file_name
#echo -e "Address \t Control_Word \t Hi_Data \t Low_Data \n" >> $file_name
readaddr_pointer=0x2000300
#address_lo=0x2000308
#address_hi=0x200030c
#address_cntr=0x2000310
address_0=0x2000308
address_1=0x200030c
address_2=0x2000310
address_3=0x2000314
address_4=0x2000318
address_5=0x200031c

for i in {0..255}
do
    ./regwrite $readaddr_pointer $i 
    # Word 0
    temp_file_0=$(sudo mktemp)
    sudo chmod 777 $temp_file_0
    # read the lower address
    ./regread $address_0 >> $temp_file_0
    # store all the words in the line to an array called words
    word_0=$(cat $temp_file_0 | cut -c32-39)
    uppercase_word_0=$(echo "$word_0" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_0" | bc)
    wrdata_lo_hex=$integer_value
  
    # Word 1
    temp_file_1=$(sudo mktemp)
    sudo chmod 777 $temp_file_1
    # read the higher address
    ./regread $address_1 > $temp_file_1
    word_1=$(cat $temp_file_1 | cut -c32-39)
    uppercase_word_1=$(echo "$word_1" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_1" | bc)
    wrdata_hi_hex=$integer_value

    # Word 2
    temp_file_2=$(sudo mktemp)
    sudo chmod 777 $temp_file_2
    ./regread $address_2 >> $temp_file_2
    word_2=$(cat $temp_file_2 | cut -c32-39)
    uppercase_word_2=$(echo "$word_2" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_2" | bc)
    #------ WR DATA CTRL extraction
    bitmask=$(((1<<8)-1))
    extracted_binary=$((integer_value & bitmask))
    wrdata_ctrl_hex=$extracted_binary

    ##------ WR ADDR extraction
    shifted_amount=8
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<8)-1))
    extracted_binary=$((shifted_value & bitmask))
    wraddr_hex=$extracted_binary

    ##------ WR EN extraction
    wr_en_bit_index=16
    shifted_value_wren=$((integer_value >> wr_en_bit_index))
    wr_en_extracted=$((shifted_value_wren&1))

    ##------ RD DATA LOWER 32 Bits extraction
    shifted_amount=17
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<15)-1)) 
    extracted_binary_lo=$((shifted_value & bitmask))
    
    # Word 3
    temp_file_3=$(sudo mktemp)
    sudo chmod 777 $temp_file_3
    ./regread $address_3 >> $temp_file_3
    word_3=$(cat $temp_file_3 | cut -c32-39)
    uppercase_word_3=$(echo "$word_3" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_3" | bc)
    bitmask=$(((1<<17)-1))
    extracted_binary_hi=$((integer_value & bitmask))
    shifted_binary_hi=$((extracted_binary_hi << 15))
    rddata_lo_binary=$((shifted_binary_hi | extracted_binary_lo))
    rddata_lo_hex=$rddata_lo_binary

    ##------ RD DATA UPPER 32 Bits extraction
    shifted_amount=17
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<15)-1)) 
    extracted_binary_lo=$((shifted_value & bitmask))

    # Word 4
    temp_file_4=$(sudo mktemp)
    sudo chmod 777 $temp_file_4
    ./regread $address_4 >> $temp_file_4
    word_4=$(cat $temp_file_4 | cut -c32-39)
    # extract the lower 9 bits from word_4 shift them to the left by 9 bits and or with 23 bit LSBs 
    uppercase_word_4=$(echo "$word_4" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_4" | bc)
    bitmask=$(((1<< 17)-1))
    extracted_binary_hi=$((integer_value & bitmask))
    shifted_binary_hi=$((extracted_binary_hi << 15))
    rddata_hi_binary=$((shifted_binary_hi | extracted_binary_lo))
    rddata_hi_hex=$rddata_hi_binary

    ##------ RD DATA CTRL 8 Bits extraction
    shifted_amount=17
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<8)-1)) 
    extracted_binary=$((shifted_value & bitmask))
    rddata_ctrl_hex=$extracted_binary
    
    ##------ RD ADDR 8 Bits extraction
    shifted_amount=25
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<7)-1)) 
    extracted_binary_lo=$((shifted_value & bitmask))

    # Word 5
    temp_file_5=$(sudo mktemp)
    sudo chmod 777 $temp_file_5
    ./regread $address_5 >> $temp_file_5
    word_5=$(cat $temp_file_5 | cut -c32-39)
    uppercase_word_5=$(echo "$word_5" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_5" | bc)
    extracted_binary_hi=$((integer_value & 1))
    shifted_binary_hi=$((extracted_binary_hi << 7))
    rdaddr_binary=$((shifted_binary_hi | extracted_binary_lo))
    rdaddr_hex=$rdaddr_binary
    
    ##------ PC 8 Bits extraction
    shifted_amount=1
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<8)-1)) 
    pc_binary=$((shifted_value & bitmask))
    pc_hex=$pc_binary
    
    #------ state bits extraction
    shifted_amount=9
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<2)-1)) 
    state_binary=$((shifted_value & bitmask))
    state_hex=$state_binary

    printf "%3x\t%x\t%02x\t%02x\t%02x\t%08x\t%08x\t%2x\t%02x\t%02x\t%08x\t%08x\n" "$i"  "$state_hex" "$pc_hex" "$rdaddr_hex" "$rddata_ctrl_hex" "$rddata_hi_hex" "$rddata_lo_hex" "$wr_en_extracted" "$wraddr_hex" "$wrdata_ctrl_hex" "$wrdata_hi_hex" "$wrdata_lo_hex">> $file_name
    #echo -e "$i \t $wraddr \t $wrdata_hi \t $word_0" >> $file_name
    sudo rm $temp_file_5
    sudo rm $temp_file_4
    sudo rm $temp_file_3
    sudo rm $temp_file_2
    sudo rm $temp_file_0
    sudo rm $temp_file_1
done 
