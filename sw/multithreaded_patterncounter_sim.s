## this program demonstrates that we are able to make SRAM dual-use for both recieicng and dispatching packets as well as Data memory
## in this program, we shall be adding each searching for 2-letter words strings "qi", "mu", "jo"
## q - 113
## i - 105
## m - 109
## u - 117
## j - 106
## o - 111
## a - 
## i - 105
## this operation shall be performed by each of the 4 threads independently
## LIMITATION: the payload length has to be equal to 6 Bytes + Multiple of 32 Bytes.. for instance, 38B, 70B, 102B 
## NOTE: here 38, 70, 102 are in decimal 
## LAST 4 locations shall be overwritten with the match count of 4 sequences

.thread0_gobacktowait:
## all the 4 threads shall keep reading from location 0x100 (i.e. Bit 9 [beginnning from zero])
ld ra 256(zero)
## loading and comparing with 7 since 7 is the CPU State in our State Diagram
li sp 7
## if the current state is indeed 7 the continue with next instuction otherwise gobacktowait
blt ra sp .thread0_gobacktowait
## USAGE OF REGISTERS BY THREADS
## 't2' - Match Counter
## 'ra' - data read from memory
## 'sp' - read address
## 'gp' - packet payload length dedicated for thread0/No. of times iteration has to be performed
## 'tp' - pattern to be matched with
## 't1' - stores numeral '1' for comparison
## 't0' - original location for readptr

## initialize the matchcounter
li t2 0
## load the readpointer from location 0x200
ld sp 512(zero)
## store the readpointer at t0 location
add t0 sp zero
## using apriori knowledge that packet length is stored at 3rd offset
ld ra 3(sp) 
## subtract header length from the total packet length to get the payload length
li gp 20
sub ra ra gp
## load 1 in ra 
li t1 1
## check if packet length is greater than 20B, if yes, then continue, else jump to .thread0_process_done
blt ra zero .thread0_process_done
## register "gp" is used by thread0 for terminating coundition akin to while(gp > 0)
## since we do not have a divider, we shall perform right shift arithmetic 
## right shift the payload length by 5=(3+2) 3 because our data path is 16 bits and data memory is 64 bits
## and 2 because we have 4 threads , gp is the number of location per thread, ra is payload length in bytes
srai gp ra 5
# 29033 in decimal is equivalent to 0x7169 and 0x71 is 'q' and 0x69 is 'i'
li tp 29033 
#offset of 6 is present in our payload, when the IP payload begins
addi sp sp 6
## to check if thread has any locations to work on or not
.thread0_main:
blt gp t1 .thread0_loopfinish
#load the data from the location of 6+rdptr to ra
ld ra 0(sp)
# ra  = ra - tp
sub ra ra tp
blt ra t1 .thread0_matchfound
.thread0_loopcontinue:
## increment sp by 4 to read next address location
addi sp sp 4
## decrement gp
sub gp gp t1
## check the while condition again
j .thread0_main  

.thread0_matchfound:
addi t2 t2 1
j .thread0_loopcontinue

.thread0_loopfinish:
## because of lack of registers, following lines recalculate the length and the offset and write the match count to the offset
## detailed calculation for next 3 steps is in the XLS titled 
## 'lab11_address_calculator_matchesprogram.xlsx' under 'util' dir
ld ra 3(t0) 
srai ra ra 3
sub ra ra t1
add t0 t0 ra
.thread0_process_done:
sw t2 0(t0) 
## write 1 in sp, it's a signal that thread is done working on all of it's allocated locations to it
li sp 1
## process done
sw sp 1024(zero) 
j .thread0_gobacktowait

#######################################################
## thread 1
#######################################################
.thread1_gobacktowait:
ld s1 256(zero)
li a0 7
blt s1 a0 .thread1_gobacktowait
## register usage
## 's0' - Match Counter
## 's1' - stores numeral '1' for comparison
## 'a0' - read address
## 'a1' - packet payload length dedicated for thread1
## 'a2' - pattern to be matched with
## 'a3' - data read from memory
## 'a4' - original readptr
## 'a5' - original length
li s0 0
ld a0 512(zero)
ld s1 3(a0) 
addi a5 s1 0
li a1 20
sub s1 s1 a1
blt s1 zero .thread1_process_done
srai a1 s1 5
li s1 1
addi a4 a0 0
#offset of 7 from readptr is present in our payload for thread1
addi a0 a0 7
# 28021 in decimal is equivalent to 0x6D75 and 0x6D is 'm' and 0x71 is 'u'
li a2 28021 
.thread1_main:
blt a1 s1 .thread1_loopfinish
ld a3 0(a0)
sub a3 a3 a2
blt a3 s1 .thread1_matchfound
.thread1_loopcontinue:
addi a0 a0 4
sub a1 a1 s1
j .thread1_main  
.thread1_matchfound:
addi s0 s0 1
j .thread1_loopcontinue
## detailed calculation for next 3 steps is in the XLS titled 
## 'lab11_address_calculator_matchesprogram.xlsx' under 'util' dir
.thread1_loopfinish:
srai a5 a5 3
add a4 a4 a5
.thread1_process_done:
sw s0 0(a4) 
li a0 1
sw a0 1024(zero) 
j .thread1_gobacktowait

#######################################################
## thread 2
#######################################################
.thread2_gobacktowait:
ld a7 256(zero)
li s2 7
blt a7 s2 .thread2_gobacktowait
## register usage
## 'a6' - Match Counter
## 'a7' - stores numeral '1' for comparison
## 's2' - read address
## 's3' - packet payload length dedicated for thread2
## 's4' - pattern to be matched with
## 's5' - data read from memory
## 's6' - original readptr
## 's7' - original length
li a6 0
ld s2 512(zero)
add s6 s2 zero
ld a7 3(s2) 
add s7 a7 zero
li s3 20
sub a7 a7 s3
blt a7 zero .thread2_process_done
srai s3 a7 5
li a7 1
#offset of 8 is present in our payload for the packet
addi s2 s2 8
# 27247 in decimal is equivalent to 0x6A6F and 0x6A is 'j' and 0x6F is 'o'
li s4 27247
.thread2_main:
blt s3 a7 .thread2_loopfinish
ld s5 0(s2)
sub s5 s5 s4
blt s5 a7 .thread2_matchfound
.thread2_loopcontinue:
addi s2 s2 4
sub s3 s3 a7
j .thread2_main 
.thread2_matchfound:
addi a6 a6 1
j .thread2_loopcontinue
.thread2_loopfinish:
## detailed calculation for next 3 steps is in the XLS titled 
## 'lab11_address_calculator_matchesprogram.xlsx' under 'util' dir
srai s7 s7 3
addi s7 s7 1
add s6 s6 s7
.thread2_process_done:
sw a6 0(s6) 
li s2 1
sw s2 1024(zero) 
j .thread2_gobacktowait

#######################################################
## thread 3
#######################################################
.thread3_gobacktowait:
ld s9 256(zero)
li s10 7
blt s9 s10 .thread3_gobacktowait
## register usage
## 's8' - Match Counter
## 's9' - stores numeral '1' for comparison
## 's10' - read address
## 's11' - packet payload length dedicated for thread2
## 't3' - pattern to be matched with
## 't4' - data read from memory
## 't5' - original readptr
## 't6' - original length
li s8 0
ld s10 512(zero)
add t5 s10 zero
ld s9 3(s10) 
add t6 s9 zero
li s11 20
sub s9 s9 s11
blt s9 zero .thread3_process_done
srai s11 s9 5
li s9 1
#offset of 9 is present in our payload for the packet
addi s10 s10 9
# 24937 in decimal is equivalent to 0x6169 and 0x61 is 'a' and 0x6F is 'i'
li t3 24937
.thread3_main:
blt s11 s9 .thread3_loopfinish
ld t4 0(s10)
sub t4 t4 t3
blt t4 s9 .thread3_matchfound
.thread3_loopcontinue:
addi s10 s10 4
sub s11 s11 s9
j .thread3_main  
.thread3_matchfound:
addi s8 s8 1
j .thread3_loopcontinue
.thread3_loopfinish:
## detailed calculation for next 3 steps is in the XLS titled 
## 'lab11_address_calculator_matchesprogram.xlsx' under 'util' dir
srai t6 t6 3
addi t6 t6 2
add t5 t5 t6
.thread3_process_done:
sw s8 0(t5) 
li s10 1
sw s10 1024(zero) 
j .thread3_gobacktowait