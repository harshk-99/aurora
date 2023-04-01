## keep loading from location 200, and check if it's 3 or not
.wait:
ld t0 256(zero)
addi zero zero 0
## loading and comparing with 7 since 7 is the CPU State in our State Diagram
li t1 3
addi zero zero 0
addi zero zero 0
addi zero zero 0
## if the current state is indeed 7 the continue with next instuction otherwise jump back to PC 0
blt t0 t1 .wait
## 2 nops added to avoid RAW hazard
addi zero zero 0
addi zero zero 0
addi zero zero 0
## load the readpointer from location 0x400, add offset (5) to make it point to real packet header
ld t2 512(zero)
addi zero zero 0
addi zero zero 0
addi zero zero 0
#load the dest addr
ld ra 5(t2) 
addi zero zero 0
addi zero zero 0
addi zero zero 0
## increment the ip target address by 1 
addi ra ra 256
addi zero zero 0
addi zero zero 0
addi zero zero 0
## store it back to mem to the same location where destination IP address was stored 
#sw ra 5(t2) 
## 2 nops added to avoid RAW hazard
addi zero zero 0 
addi zero zero 0 
addi zero zero 0 
## communicate to the state machine that CPU has finished its job
sw sp 1024(zero) 
addi zero zero 0 
addi zero zero 0 
## jump to .wait state again 
j .wait


