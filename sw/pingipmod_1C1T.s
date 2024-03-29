## algo:
## check if its icmp packet by
## reading the 2nd offset from the readptr, 
## extracting the 8 bit LSB
## comparing the extracted value with 01 (ICMP)
## if it doesn't match then proceed to jobcomplete
## if it matches then fetch the 2nd word from here (64 bits) 
## and store the MSB 16 bits
## add 256 to this number and do not modify the remaining bits
## store back the number
## do this for all the packets with destination 02.03

## USAGE OF REGISTERS BY THREADS
# s0 - mask for 0xFFFF
# t1 - stores '1'
# sp - readpointer
# gp - decimal 515 is 0x0203 the 16-bit LSBs of Port 2 
# ra - generally stores the value loaded from memory
# s1 - stores duplicate destination ip address copy

li fp 0
li t1 1
li tp 2
li gp 515
.thread0_gobacktowait:
ld ra 256(zero)
li sp 3
addi zero zero 0
addi zero zero 0
addi zero zero 0
blt ra sp .thread0_gobacktowait
.ICMP_check:
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
# mask of 0x00000000000000FF is applied on the 3rd offset
andi ra ra 255  
addi zero zero 0
addi zero zero 0
addi zero zero 0
beq ra t1 .destip_check 
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
.destip_check:
## add 2 to current location to fetch lower 16 bits of destination ip address
addi sp sp 2
addi zero zero 0
addi zero zero 0
addi zero zero 0 
ld ra 0(sp)
addi zero zero 0
addi zero zero 0
addi zero zero 0
# store a copy in s1
add s1 ra zero
# shift the number to the right by 48 bits
srai ra ra 48
# prepare the mask of the value 65535
addi fp t1 0
addi zero zero 0
addi zero zero 0
addi zero zero 0
slli fp fp 16
addi zero zero 0
addi zero zero 0
addi zero zero 0
addi fp fp -1
# apply the mask to fetch the lower 16 bits only
addi zero zero 0
addi zero zero 0
addi zero zero 0
and ra ra fp 
addi zero zero 0
addi zero zero 0
addi zero zero 0
beq ra gp .destipmatch
addi zero zero 0
addi zero zero 0
addi zero zero 0
j .communicate_jobcomplete
.destipmatch:
## go back one position to change the checksum of IP, 
## we have AND the number fetched with the mask of 0x0000_FFFF_FFFF_FFFF
sub sp sp t1
addi zero zero 0
addi zero zero 0
addi zero zero 0
ld ra 0(sp)
addi zero zero 0
addi zero zero 0
addi zero zero 0
# prepare the mask of the value 0x0000_FFFF_FFFF_FFFF
addi fp t1 0
addi zero zero 0
addi zero zero 0
addi zero zero 0
slli fp fp 48
addi zero zero 0
addi zero zero 0
addi zero zero 0
addi fp fp -1
addi zero zero 0
addi zero zero 0
addi zero zero 0
and ra ra fp
addi zero zero 0
addi zero zero 0
addi zero zero 0
sw ra 0(sp)
add sp sp t1
# store t0 with 0x01_00_00_00_00_00_00_00, essentially we are storing 1 into 56th bit (beginning from 0th bit)
li t0 1024
addi zero zero 0
addi zero zero 0
addi zero zero 0 
slli t0 t0 46 
addi zero zero 0
addi zero zero 0
addi zero zero 0 
add s1 s1 t0
addi zero zero 0
addi zero zero 0
addi zero zero 0
sw s1 0(sp)
addi zero zero 0
addi zero zero 0
addi zero zero 0
j .communicate_jobcomplete