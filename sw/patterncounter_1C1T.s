## definitions: word is 64 bits
## algo:
## for each packet, compare its protocol with TCP (0x06)
##                              3rd offset from readpointer, zero beginning 
## if it's not a match, proceed to jobcomplete
## if match, then check if the length is greater than 1000 (decimal) bytes
##                              3rd offset from readpointer, zero beginning, upper 16 bits of the word 
## if it's not a match, proceed to jobcomplete
## if match, then compare its destination ip address with 0203
##                              lower 16 bits of IP address stored at 16 MSBs, 
##                              5th offset from read pointer, zero beginning
## if it's not a match, proceed to jobcomplete
## if match, then match the occurance of the pattern for pre-defined number of times
## and store the counted value after pre-defined iterations to next address
## proceed to jobcomplete
##-------------------------------------------
## USAGE OF REGISTERS BY THREADS
## ra - use to load the data from the memory
## sp - readpointer
## gp - store the 3rd offset from beginning of new packet for temporary processing
## tp - 'sunshine' in decimal, the pattern to be compared
## t0 - TCP protocol value of 0x06
## t1 - mask of 65535 or 0xFFFF
## t2 - stores the target destination ip address of 0x0203, decimal 515
## s0 - temporary register - stores 1500 for comparing packet length
## s1 - stores the number of times comparison of pattern needs to be performed
## a0 - stores the match count
## a1 - stores numeral 1
##-------------------------------------------
li tp 8319677328588893797
li t0 6
li t2 515
li a1 1
.thread0_gobacktowait:
ld ra 256(zero)
li sp 3
addi zero zero 0
addi zero zero 0
addi zero zero 0
blt ra sp .thread0_gobacktowait
.protocol_check:
## load the readpointer from location 0x200
ld sp 512(zero)
addi zero zero 0
addi zero zero 0
addi zero zero 0
## using apriori knowledge that ethernet type field is at 3rd offset
addi sp sp 3
addi zero zero 0
addi zero zero 0
addi zero zero 0
ld ra 0(sp)
addi zero zero 0
addi zero zero 0
addi zero zero 0
# copy the contents to one more register
add gp ra zero
# mask of 0x00000000000000FF is applied on the 3rd offset
andi ra ra 255  
addi zero zero 0
addi zero zero 0
addi zero zero 0
beq ra t0 .lengthgt1000B_check 
.communicate_jobcomplete:
li sp 1
addi zero zero 0
addi zero zero 0
addi zero zero 0
## process done
sw sp 1024(zero)
addi zero zero 0
addi zero zero 0
addi zero zero 0 
j .thread0_gobacktowait
.lengthgt1000B_check:
add ra gp zero
# shift the number by 48 bits
addi zero zero 0
addi zero zero 0
addi zero zero 0
srai ra ra 48
# apply the mask to select the lower 16 bits of this shifted number
addi t1 zero 1
addi zero zero 0
addi zero zero 0
addi zero zero 0
slli t1 t1 16
addi zero zero 0
addi zero zero 0
addi zero zero 0
addi t1 t1 -1
addi zero zero 0
addi zero zero 0
addi zero zero 0
and ra ra t1
# compare if this number is greater than 1000 Bytes
li s0 1000
addi zero zero 0
addi zero zero 0
blt ra s0 .communicate_jobcomplete
.destip_compare:
## add 2 to current location to fetch lower 16 bits of destination ip address
addi sp sp 2
addi zero zero 0
addi zero zero 0
addi zero zero 0 
ld ra 0(sp)
addi zero zero 0
addi zero zero 0
addi zero zero 0
# shift the number to the right by 48 bits
srai ra ra 48
addi zero zero 0
addi zero zero 0
addi zero zero 0
and ra ra t1
addi zero zero 0
addi zero zero 0
addi zero zero 0 
beq ra t2 .pattern_match 
addi zero zero 0
addi zero zero 0
addi zero zero 0 
j .communicate_jobcomplete
.loop_inititialization:
## using apriori knowledge that packet length is stored at 5th offset
addi sp sp 5
li s1 4  
li a0 0
.patternmatch_loop:
addi zero zero 0
addi zero zero 0
addi zero zero 0
beq s1 zero .thread0_storeresult
#load the data from the location of 6+rdptr to ra
ld ra 0(sp)
# ra  = ra - tp
addi zero zero 0
addi zero zero 0
addi zero zero 0
beq ra tp .thread0_matchfound
addi zero zero 0
addi zero zero 0
addi zero zero 0
.thread0_loopcontinue:
# increment the address counter
addi sp sp 1
# decrement the lopp counter
sub s1 s1 a1
## check the while condition again
j .patternmatch_loop  
.thread0_matchfound:
addi a0 a0 1
j .thread0_loopcontinue
.thread0_storeresult:
sw a0 0(sp)
addi zero zero 0
addi zero zero 0
addi zero zero 0
j .communicate_jobcomplete