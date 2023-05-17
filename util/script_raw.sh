#!/bin/bash

c0file_name=c0testingreadfile.txt
c1file_name=c1testingreadfile.txt
sudo rm $c0file_name
sudo rm $c1file_name
sudo touch $c0file_name
sudo touch $c1file_name
sudo chmod 777 $c1file_name
sudo chmod 777 $c0file_name
#printf "%-7s\t%-5s\t%-2s\t%-6s\t%-6s\t%-8s\t%-8s\t%-4s\t%-6s\t%-6s\t%-8s\t%-8s\n" "counter""state""pc""rdaddr""rdatac""rdatah""rdatal""wren""wraddr""wdatac""wdatah""wdatal" >> $file_name
#printf "%3x\t%x\t%2x\t%2x\t%2x\t%8x\t%8x\t%x\t%2x\t%2x\t%8x\t%8x\n" "$i"  "$state_hex" "$pc_hex" "$rdaddr_hex" "$rddata_ctrl_hex" "$rddata_hi_hex" "$rddata_lo_hex" "$wr_en_extracted" "$wraddr_hex" "$wrdata_ctrl_hex" "$wrdata_hi_hex" "$wrdata_lo_hex">> $file_name
printf "counter\tword_5\tword_4\tword_3\tword_2\tword_1\tword_0\n">> $c0file_name
#printf "counter\toutwr\tchangereader\tcurrentreader\tc0ftsfrden\tftsfrden\tftsfwren\tchangewriter\tcurrentwriter\tthreadid\tstate\tpc\trdaddr\trdatac\trdatah\trdatal\twrten\twraddr\twdatac\twdatah\twdatal\n">> $c0file_name
#printf "counter\toutwr\tchangereader\tcurrentreader\tc1ftsfrden\tftsfrden\tftsfwren\tchangewriter\tcurrentwriter\tthreadid\tstate\tpc\trdaddr\trdatac\trdatah\trdatal\twrten\twraddr\twdatac\twdatah\twdatal\n">> $c1file_name
printf "counter\tword_11\tword_10\tword_9\tword_8\tword_7\tword_6\n">> $c1file_name
readaddr_pointer=0x2000300
address_0=0x2000308
address_1=0x200030c
address_2=0x2000310
address_3=0x2000314
address_4=0x2000318
address_5=0x200031c
address_6=0x2000320
address_7=0x2000324
address_8=0x2000328
address_9=0x200032c
address_10=0x2000330
address_11=0x2000334
constant=1
for i in {0..255}
do
    lineno=$((i+constant))
    #-----------------------------------------------
    # CORE0
    #-----------------------------------------------
    ./regwrite $readaddr_pointer $i 
    # Word 0
    temp_file_0=$(sudo mktemp)
    sudo chmod 777 $temp_file_0
    # read the lower address
    ./regread $address_0 >> $temp_file_0
    # store all the words in the line to an array called words
    linereaddata=$(head -$lineno $temp_file_0 | tail -1)
    #word_0=$(cat $temp_file_0 | cut -c32-39)
    word_0=$(echo $linereaddata | cut -c30-37)
    echo "word_0"
    echo $word_0
    uppercase_word_0=$(echo "$word_0" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_0" | bc)
    wrdata_lo_hex=$integer_value
    echo $wrdata_lo_hex
  
    # Word 1
    temp_file_1=$(sudo mktemp)
    sudo chmod 777 $temp_file_1
    # read the higher address
    ./regread $address_1 >> $temp_file_1
    linereaddata=$(head -$lineno $temp_file_1 | tail -1)
    #word_1=$(cat $temp_file_1 | cut -c32-39)
    word_1=$(echo $linereaddata | cut -c30-37)
    echo "word_1"
    echo $word_1
    uppercase_word_1=$(echo "$word_1" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_1" | bc)
    wrdata_hi_hex=$integer_value
    echo $wrdata_hi_hex

    # Word 2
    temp_file_2=$(sudo mktemp)
    sudo chmod 777 $temp_file_2
    ./regread $address_2 >> $temp_file_2
    linereaddata=$(head -$lineno $temp_file_2 | tail -1)
    #word_2=$(cat $temp_file_2 | cut -c32-39)
    word_2=$(echo $linereaddata | cut -c30-37)
    uppercase_word_2=$(echo "$word_2" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_2" | bc)
    #------ WR DATA CTRL extraction
    bitmask=$(((1<<8)-1))
    extracted_binary=$((integer_value & bitmask))
    wrdata_ctrl_hex=$extracted_binary
    echo "word_2"
    echo $word_2
    echo "wrdata_ctrl"
    echo $wrdata_ctrl_hex

    ##------ WR ADDR extraction
    shifted_amount=8
    shifted_value=$((integer_value >> shifted_amount))
    echo $shifted_value
    bitmask=$(((1<<8)-1))
    extracted_binary=$((shifted_value & bitmask))
    echo $extracted_binary
    wraddr_hex=$extracted_binary
    echo "wraddr"
    echo $wraddr_hex

    ##------ WR EN extraction
    wr_en_bit_index=16
    shifted_value_wren=$((integer_value >> wr_en_bit_index))
    wr_en_extracted=$((shifted_value_wren&1))
    echo "wr_en"
    echo $wr_en_extracted

    ##------ RD DATA LOWER 32 Bits extraction
    shifted_amount=17
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<15)-1)) 
    extracted_binary_lo=$((shifted_value & bitmask))
    
    # Word 3
    temp_file_3=$(sudo mktemp)
    sudo chmod 777 $temp_file_3
    ./regread $address_3 >> $temp_file_3
    linereaddata=$(head -$lineno $temp_file_3 | tail -1)
    #word_3=$(cat $temp_file_3 | cut -c32-39)
    word_3=$(echo $linereaddata | cut -c30-37)
    uppercase_word_3=$(echo "$word_3" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_3" | bc)
    bitmask=$(((1<<17)-1))
    extracted_binary_hi=$((integer_value & bitmask))
    shifted_binary_hi=$((extracted_binary_hi << 15))
    rddata_lo_binary=$((shifted_binary_hi | extracted_binary_lo))
    rddata_lo_hex=$rddata_lo_binary
    echo "word_3"
    echo $word_3
    echo "rddata_lo"
    echo $rddata_lo_hex

    ##------ RD DATA UPPER 32 Bits extraction
    shifted_amount=17
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<15)-1)) 
    extracted_binary_lo=$((shifted_value & bitmask))

    # Word 4
    temp_file_4=$(sudo mktemp)
    sudo chmod 777 $temp_file_4
    ./regread $address_4 >> $temp_file_4
    linereaddata=$(head -$lineno $temp_file_4 | tail -1)
    word_4=$(echo $linereaddata | cut -c30-37)
    #word_4=$(cat $temp_file_4 | cut -c32-39)
    # extract the lower 9 bits from word_4 shift them to the left by 9 bits and or with 23 bit LSBs 
    uppercase_word_4=$(echo "$word_4" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_4" | bc)
    bitmask=$(((1<< 17)-1))
    extracted_binary_hi=$((integer_value & bitmask))
    shifted_binary_hi=$((extracted_binary_hi << 15))
    rddata_hi_binary=$((shifted_binary_hi | extracted_binary_lo))
    rddata_hi_hex=$rddata_hi_binary
    echo "word_4"
    echo $word_4
    echo "rddata_hi"
    echo $rddata_hi_hex

    ##------ RD DATA CTRL 8 Bits extraction
    shifted_amount=17
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<8)-1)) 
    extracted_binary=$((shifted_value & bitmask))
    rddata_ctrl_hex=$extracted_binary
    echo "rddata_ctrl"
    echo $rddata_ctrl_hex
    
    ##------ RD ADDR 8 Bits extraction
    shifted_amount=25
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<7)-1)) 
    extracted_binary_lo=$((shifted_value & bitmask))

    # Word 5
    temp_file_5=$(sudo mktemp)
    sudo chmod 777 $temp_file_5
    ./regread $address_5 >> $temp_file_5
    linereaddata=$(head -$lineno $temp_file_5 | tail -1)
    #word_5=$(cat $temp_file_5 | cut -c32-39)
    word_5=$(echo $linereaddata | cut -c30-37)
    uppercase_word_5=$(echo "$word_5" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_5" | bc)
    extracted_binary_hi=$((integer_value & 1))
    shifted_binary_hi=$((extracted_binary_hi << 7))
    rdaddr_binary=$((shifted_binary_hi | extracted_binary_lo))
    rdaddr_hex=$rdaddr_binary
    echo "word_5"
    echo $word_5
    echo "rdaddr"
    echo $rdaddr_hex
    
    ##------ PC 8 Bits extraction
    shifted_amount=1
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<8)-1)) 
    pc_binary=$((shifted_value & bitmask))
    pc_hex=$pc_binary
    echo "pc"
    echo $pc_hex
    
    #------ state bits extraction
    shifted_amount=9
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<2)-1)) 
    state_binary=$((shifted_value & bitmask))
    state_hex=$state_binary
    echo $state_hex

    #------ thread id bits extraction
    shifted_amount=11
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<2)-1)) 
    tid_binary=$((shifted_value & bitmask))
    tid_hex=$tid_binary

    #------ current_writer extraction
    shifted_amount=13
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<2)-1)) 
    currwriter_binary=$((shifted_value & bitmask))
    currwriter_hex=$currwriter_binary

    #------ change_writer extraction
    shifted_amount=15
    shifted_value=$((integer_value >> shifted_amount))
    changewriter_binary=$((shifted_value&1))
    changewriter_hex=$changewriter_binary

    #------ fsm generated ftsf wren extraction
    shifted_amount=16
    shifted_value=$((integer_value >> shifted_amount))
    fsmgenftsfwren_binary=$((shifted_value&1))
    fsmgenftsfwren_hex=$fsmgenftsfwren_binary

    #------ ftsf read enable extraction
    shifted_amount=17
    shifted_value=$((integer_value >> shifted_amount))
    ftsfrden_binary=$((shifted_value&1))
    ftsfrden_hex=$ftsfrden_binary

    #------ CORE0 ftsf read enable extraction
    shifted_amount=18
    shifted_value=$((integer_value >> shifted_amount))
    coreftsfrden_binary=$((shifted_value&1))
    coreftsfrden_hex=$c0ftsfrden_binary

    #------ current reader extraction
    shifted_amount=19
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<2)-1)) 
    currreader_binary=$((shifted_value & bitmask))
    currreader_hex=$currreader_binary

    #------ change reader extraction
    shifted_amount=21
    shifted_value=$((integer_value >> shifted_amount))
    changereader_binary=$((shifted_value&1))
    changereader_hex=$changereader_binary

    #------ outwr extraction
    shifted_amount=22
    shifted_value=$((integer_value >> shifted_amount))
    outwr_binary=$((shifted_value&1))
    outwr_hex=$outwr_binary

    #-----------------------------------------------
    # CORE1
    #-----------------------------------------------
    # Word 6
    temp_file_6=$(sudo mktemp)
    sudo chmod 777 $temp_file_6
    # read the lower address
    ./regread $address_6 >> $temp_file_6
    # store all the words in the line to an array called words
    linereaddata=$(head -$lineno $temp_file_6 | tail -1)
    #word_6=$(cat $temp_file_6 | cut -c32-39)
    word_6=$(echo $linereaddata | cut -c30-37)
    uppercase_word_6=$(echo "$word_6" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_6" | bc)
    c1wrdata_lo_hex=$integer_value
  
    # Word 7
    temp_file_7=$(sudo mktemp)
    sudo chmod 777 $temp_file_7
    # read the higher address
    ./regread $address_7 >> $temp_file_7
    linereaddata=$(head -$lineno $temp_file_7 | tail -1)
    #word_7=$(cat $temp_file_7 | cut -c32-39)
    word_7=$(echo $linereaddata | cut -c30-37)
    uppercase_word_7=$(echo "$word_7" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_7" | bc)
    c1wrdata_hi_hex=$integer_value

    # Word 8
    temp_file_8=$(sudo mktemp)
    sudo chmod 777 $temp_file_8
    ./regread $address_8 >> $temp_file_8
    linereaddata=$(head -$lineno $temp_file_8 | tail -1)
    #word_8=$(cat $temp_file_8 | cut -c32-39)
    word_8=$(echo $linereaddata | cut -c30-37)
    uppercase_word_8=$(echo "$word_8" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_8" | bc)
    #------ WR DATA CTRL extraction
    bitmask=$(((1<<8)-1))
    extracted_binary=$((integer_value & bitmask))
    c1wrdata_ctrl_hex=$extracted_binary

    ##------ WR ADDR extraction
    shifted_amount=8
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<8)-1))
    extracted_binary=$((shifted_value & bitmask))
    c1wraddr_hex=$extracted_binary

    ##------ WR EN extraction
    wr_en_bit_index=16
    shifted_value_wren=$((integer_value >> wr_en_bit_index))
    c1wr_en_extracted=$((shifted_value_wren&1))

    ##------ RD DATA LOWER 32 Bits extraction
    shifted_amount=17
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<15)-1)) 
    extracted_binary_lo=$((shifted_value & bitmask))
    
    # Word 9
    temp_file_9=$(sudo mktemp)
    sudo chmod 777 $temp_file_9
    ./regread $address_9 >> $temp_file_9
    linereaddata=$(head -$lineno $temp_file_9 | tail -1)
    #word_9=$(cat $temp_file_9 | cut -c32-39)
    word_9=$(echo $linereaddata | cut -c30-37)
    uppercase_word_9=$(echo "$word_9" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_9" | bc)
    bitmask=$(((1<<17)-1))
    extracted_binary_hi=$((integer_value & bitmask))
    shifted_binary_hi=$((extracted_binary_hi << 15))
    rddata_lo_binary=$((shifted_binary_hi | extracted_binary_lo))
    c1rddata_lo_hex=$rddata_lo_binary

    ##------ RD DATA UPPER 32 Bits extraction
    shifted_amount=17
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<15)-1)) 
    extracted_binary_lo=$((shifted_value & bitmask))

    # Word 10
    temp_file_10=$(sudo mktemp)
    sudo chmod 777 $temp_file_10
    ./regread $address_10 >> $temp_file_10
    linereaddata=$(head -$lineno $temp_file_10 | tail -1)
    word_10=$(echo $linereaddata | cut -c30-37)
    #word_10=$(cat $temp_file_10 | cut -c30-37)
    # extract the lower 9 bits from word_10 shift them to the left by 9 bits and or with 23 bit LSBs 
    uppercase_word_10=$(echo "$word_10" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_10" | bc)
    bitmask=$(((1<< 17)-1))
    extracted_binary_hi=$((integer_value & bitmask))
    shifted_binary_hi=$((extracted_binary_hi << 15))
    rddata_hi_binary=$((shifted_binary_hi | extracted_binary_lo))
    c1rddata_hi_hex=$rddata_hi_binary

    ##------ RD DATA CTRL 8 Bits extraction
    shifted_amount=17
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<8)-1)) 
    extracted_binary=$((shifted_value & bitmask))
    c1rddata_ctrl_hex=$extracted_binary
    
    ##------ RD ADDR 8 Bits extraction
    shifted_amount=25
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<7)-1)) 
    extracted_binary_lo=$((shifted_value & bitmask))

    # Word 11
    temp_file_11=$(sudo mktemp)
    sudo chmod 777 $temp_file_11
    ./regread $address_11 >> $temp_file_11
    linereaddata=$(head -$lineno $temp_file_11 | tail -1)
    #word_11=$(cat $temp_file_11 | cut -c32-39)
    word_11=$(echo $linereaddata | cut -c30-37)
    uppercase_word_11=$(echo "$word_11" | tr '[:lower:]' '[:upper:]')
    integer_value=$(echo "ibase=16; $uppercase_word_11" | bc)
    extracted_binary_hi=$((integer_value & 1))
    shifted_binary_hi=$((extracted_binary_hi << 7))
    rdaddr_binary=$((shifted_binary_hi | extracted_binary_lo))
    c1rdaddr_hex=$rdaddr_binary
    
    ##------ PC 8 Bits extraction
    shifted_amount=1
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<8)-1)) 
    pc_binary=$((shifted_value & bitmask))
    c1pc_hex=$pc_binary
    
    #------ state bits extraction
    shifted_amount=9
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<2)-1)) 
    state_binary=$((shifted_value & bitmask))
    c1state_hex=$state_binary

    #------ thread id bits extraction
    shifted_amount=11
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<2)-1)) 
    tid_binary=$((shifted_value & bitmask))
    c1tid_hex=$tid_binary

    #------ current_writer extraction
    shifted_amount=13
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<2)-1)) 
    currwriter_binary=$((shifted_value & bitmask))
    c1currwriter_hex=$currwriter_binary

    #------ change_writer extraction
    shifted_amount=15
    shifted_value=$((integer_value >> shifted_amount))
    changewriter_binary=$((shifted_value&1))
    c1changewriter_hex=$changewriter_binary

    #------ fsm generated ftsf wren extraction
    shifted_amount=16
    shifted_value=$((integer_value >> shifted_amount))
    fsmgenftsfwren_binary=$((shifted_value&1))
    c1fsmgenftsfwren_hex=$fsmgenftsfwren_binary

    #------ ftsf read enable extraction
    shifted_amount=17
    shifted_value=$((integer_value >> shifted_amount))
    ftsfrden_binary=$((shifted_value&1))
    c1ftsfrden_hex=$ftsfrden_binary

    #------ CORE0 ftsf read enable extraction
    shifted_amount=18
    shifted_value=$((integer_value >> shifted_amount))
    c1coreftsfrden_binary=$((shifted_value&1))
    c1coreftsfrden_hex=$c1coreftsfrden_binary

    #------ current reader extraction
    shifted_amount=19
    shifted_value=$((integer_value >> shifted_amount))
    bitmask=$(((1<<2)-1)) 
    currreader_binary=$((shifted_value & bitmask))
    c1currreader_hex=$currreader_binary

    #------ change reader extraction
    shifted_amount=21
    shifted_value=$((integer_value >> shifted_amount))
    changereader_binary=$((shifted_value&1))
    c1changereader_hex=$changereader_binary

    #------ outwr extraction
    shifted_amount=22
    shifted_value=$((integer_value >> shifted_amount))
    outwr_binary=$((shifted_value&1))
    c1outwr_hex=$outwr_binary

    #printf "%3x\t%0x\t%0x\t%0x\t%0x\t%0x\t%0x\t%0x\t%0x\t%0x\t%0x\t%02x\t%02x\t%02x\t%08x\t%08x\t%0x\t%02x\t%02x\t%08x\t%08x\n" "$i" "$outwr_hex" "$changereader_hex" "$currreader_hex" "$coreftsfrden_hex" "$ftsfrden_hex" "$fsmgenftsfwren_hex" "$changewriter_hex" "$currwriter_hex" "$tid_hex"  "$state_hex" "$pc_hex" "$rdaddr_hex" "$rddata_ctrl_hex" "$rddata_hi_hex" "$rddata_lo_hex" "$wr_en_extracted" "$wraddr_hex" "$wrdata_ctrl_hex" "$wrdata_hi_hex" "$wrdata_lo_hex">> $c0file_name
    printf "%3x\t%08x\t%08x\t%08x\t%08x\t%08x\t%08x\n" "$i" "$word_5" "$word_4" "$word_3" "$word_2" "$word_1" "$word_0">> $c0file_name
    printf "%3x\t%08x\t%08x\t%08x\t%08x\t%08x\t%08x\n" "$i" "$word_11" "$word_10" "$word_9" "$word_8" "$word_7" "$word_6">> $c1file_name
    #printf "%3x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%02x\t%02x\t%02x\t%08x\t%08x\t%x\t%02x\t%02x\t%08x\t%08x\n" "$i" "$c1outwr_hex" "$c1changereader_hex" "$c1currreader_hex" "$c1coreftsfrden_hex" "$c1ftsfrden_hex" "$c1fsmgenftsfwren_hex" "$c1changewriter_hex" "$c1currwriter_hex" "$c1tid_hex"  "$c1state_hex" "$c1pc_hex" "$c1rdaddr_hex" "$c1rddata_ctrl_hex" "$c1rddata_hi_hex" "$c1rddata_lo_hex" "$c1wr_en_extracted" "$c1wraddr_hex" "$c1wrdata_ctrl_hex" "$c1wrdata_hi_hex" "$c1wrdata_lo_hex">> $c1file_name
   # #echo -e "$i \t $wraddr \t $wrdata_hi \t $word_0" >> $file_name
   # #sudo rm $temp_file_5
   # #sudo rm $temp_file_4
   # #sudo rm $temp_file_3
   # #sudo rm $temp_file_2
   # #sudo rm $temp_file_0
   # #sudo rm $temp_file_1
done 
sudo rm $temp_file_11
sudo rm $temp_file_10
sudo rm $temp_file_9
sudo rm $temp_file_8
sudo rm $temp_file_7
sudo rm $temp_file_6
sudo rm $temp_file_5
sudo rm $temp_file_4
sudo rm $temp_file_3
sudo rm $temp_file_2
sudo rm $temp_file_0
sudo rm $temp_file_1
