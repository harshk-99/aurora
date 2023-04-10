## definitions: word is 64 bits
## algo:
## for each packet, compare its protocol with TCP (0x06)
##                              3rd offset from readpointer, zero beginning 
## if it's not a match, proceed to jobcomplete
## if match, then check if the length is greater than 1500 bytes
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
## tp - 'sunshine' in decimal, the pattern to be compared
## sp - readpointer
## ra - use to load the data from the memory
## gp - store the 3rd offset from beginning of new packet for temporary processing
## t0 - TCP protocol value of 0x06
## t1 - multiple purposes
##              - mask of 65535
##              - stores 1500 for comparing packet length
## t2 -  stores the target destination ip address of 0x0203, decimal 515
##-------------------------------------------
li tp 8319677328588893797
li t0 6
li t2 515
.thread0_gobacktowait:
ld ra 256(zero)
li sp 3
addi zero zero 0
addi zero zero 0
addi zero zero 0
blt ra sp .thread0_gobacktowait
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
sub ra ra t0
addi zero zero 0
addi zero zero 0
addi zero zero 0
blt ra zero .communicate_jobcomplete
addi zero zero 0
addi zero zero 0
addi zero zero 0
blt zero ra .communicate_jobcomplete
.TCP_found:
add ra gp zero
# shift the number by 48 bits
addi zero zero 0
addi zero zero 0
addi zero zero 0
srai ra ra 48
# apply the mask to select the lower 16 bits of this shifted number
addi zero zero 0
addi zero zero 0
addi zero zero 0
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
# compare if this number is greater than 1500 Bytes
li t1 1500
addi zero zero 0
addi zero zero 0
blt ra t1 .communicate_jobcomplete
.lengthgreaterthan1500B:
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
# apply the mask to select the lower 16 bits of this shifted number
addi zero zero 0
addi zero zero 0
addi zero zero 0
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
addi zero zero 0
addi zero zero 0
addi zero zero 0 
sub ra ra t2
addi zero zero 0
addi zero zero 0
addi zero zero 0
blt ra zero .communicate_jobcomplete
addi zero zero 0
addi zero zero 0
addi zero zero 0
blt zero ra .communicate_jobcomplete


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























# increment the packet traverser counter
addi s0 s0 1
addi zero zero 0
addi zero zero 0
addi zero zero 0
# check if the packet traverser count is < 4, if yes then communicate the job complete sttaus and go back to wait state
blt s0 a0 .thread0_skippacket

# since we dont have beq, so after 4th packet arrives, we load t0 with very high number like 255
li a0 255 

## load the readpointer from location 0x200
ld sp 512(zero)
addi zero zero 0
addi zero zero 0
addi zero zero 0
## using apriori knowledge that packet length is stored at 10th offset
addi sp sp 10 
.thread0_main:
addi zero zero 0
addi zero zero 0
addi zero zero 0
blt gp t1 .thread0_innerloopfinish
#load the data from the location of 6+rdptr to ra
ld ra 0(sp)
# ra  = ra - tp
addi zero zero 0
addi zero zero 0
addi zero zero 0
sub ra ra tp
addi zero zero 0
addi zero zero 0
addi zero zero 0
blt ra t1 .thread0_matchfound
.thread0_loopcontinue:
addi zero zero 0
## increment sp by 1 to read next address location
addi sp sp 1
## decrement gp
sub gp gp t1
## check the while condition again
j .thread0_main  

.thread0_matchfound:
addi t2 t2 1
j .thread0_loopcontinue

.thread0_innerloopfinish:
sw t2 0(sp) 
addi zero zero 0
addi zero zero 0
addi zero zero 0
## write 1 in sp, it's a signal that thread is done working on all of it's allocated locations to it
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


.thread0_skippacket:
li sp 1
addi zero zero 0
addi zero zero 0
addi zero zero 0
sw sp 1024(zero)
addi zero zero 0
addi zero zero 0
addi zero zero 0 
j .thread0_gobacktowait