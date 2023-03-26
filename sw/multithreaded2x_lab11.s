## this program demonstrates that we are able to integrate 4 threads with the NetFPGA FIFO
## in this program, we shall be adding each 16-bit onto itself and storing back to memory location
## this opertation shall be performed by each of the 4 threads independently

## all the 4 threads shall keep reading from location 0x200 (i.e. Bit 9 [beginnning from zero])
## keep loading from location 200, and check if it's 3 or not
.wait:
ld ra 512(zero)
## loading and comparing with 7 since 7 is the CPU State in our State Diagram
li sp 7
## if the current state is indeed 7 the continue with next instuction otherwise jump back to PC 0
blt ra sp .wait
## load the readpointer from location 0x400, add offset (5) to make it point to real packet header
ld sp 1024(zero)
## using apriori knowledge that packet length is stored at 3rd offset
ld ra 3(sp) 
## since we do not have a divider, we shall perform right shift arithmetic 
li gp 20
## subtract header lenggth from the total packet length to get the pauload length
subi ra ra gp
## right shift the payload length by 5=(3+2) 3 because our data path is 16 bits and data memory is 64 bits
## and 2 because we have 4 threads
srai gp ra 5
blt gp  .wait
## check if after dividing by 4, the length is greater than 1

## using apriori knowledge that first byte shall begin from 6th offset from RA
li sp 7
ld ra 6(sp) 
add ra ra ra
sw ra 5(t2) 

## increment the ip target address by 1 
addi ra ra 1
## store it back to mem to the same location where destination IP address was stored 
## 2 nops added to avoid RAW hazard
addi zero zero 0 
addi zero zero 0 
## communicate to the state machine that CPU has finished its job
sw sp 256(zero) 
## jump to .wait state again 
j .wait


