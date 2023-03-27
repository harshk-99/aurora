## this program demonstrates that we are able to integrate 4 threads with the NetFPGA FIFO
## in this program, we shall be adding each 16-bit onto itself and storing back to memory location
## this opertation shall be performed by each of the 4 threads independently

## all the 4 threads shall keep reading from location 0x100 (i.e. Bit 9 [beginnning from zero])
## keep loading from location 100, and check if it's 3 or not
.thread0wait:
ld ra 256(zero)
## loading and comparing with 7 since 7 is the CPU State in our State Diagram
li sp 7
## if the current state is indeed 7 the continue with next instuction otherwise jump back to PC 0
blt ra sp .thread0wait
## load the readpointer from location 0x200, add offset (5) to make it point to real packet header
ld sp 512(zero)
## using apriori knowledge that packet length is stored at 3rd offset
ld ra 3(sp) 
## since we do not have a divider, we shall perform right shift arithmetic 
li gp 20
## subtract header length from the total packet length to get the payload length
sub ra ra gp
## right shift the payload length by 5=(3+2) 3 because our data path is 16 bits and data memory is 64 bits
## and 2 because we have 4 threads , gp is the number of location per thread, ra is payload length in bytes
srai gp ra 5
#load 1 in ra, 
li ra 1
#offset of 6 is present in our payload for the packet
li tp 6
#to check if thread has any locations to work on or not
.T0target:
blt gp ra .thread0over
add sp sp tp
#load the data from the location of 6+rdptr to ra
ld ra 0(sp)
#double ra and put it back
add ra ra ra
#store the doubled value back to the location
sd ra 0(sp)
#since thread 0 is done working at that location, tp which was at 6 will move to 10, hence adding 4 to it
addi sp sp 4
#storing 1 in ra as 1 location has been worked upon
li ra 1
#subtracting 1 from number of locations in the fifo
sub gp gp ra
#go back and double the data again till gp is equal to ra
j .T0target  
.thread0over:
#write 1 in sp, it's a signal that thread is done working on all of it's allocated locations to it
li sp 1
#process done
sw sp 1024(zero) .thread0wait


## keep loading from location 100, and check if it's 3 or not
.thread1wait:
ld s1 256(zero)
## loading and comparing with 7 since 7 is the CPU State in our State Diagram
li a0 7
## if the current state is indeed 7 the continue with next instuction otherwise jump back to PC 0
blt s1 a0 .thread1wait
## load the readpointer from location 0x200, add offset (5) to make it point to real packet header
ld a0 512(zero)
## using apriori knowledge that packet length is stored at 3rd offset
ld s1 3(a0) 
## since we do not have a divider, we shall perform right shift arithmetic 
li a1 20
## subtract header length from the total packet length to get the payload length
sub s1 s1 a1
## right shift the payload length by 5=(3+2) 3 because our data path is 16 bits and data memory is 64 bits
## and 2 because we have 4 threads , gp is the number of location per thread, ra is payload length in bytes
srai a1 s1 5
#load 1 in ra, 
li s1 1
#offset of 7 is present in our payload for the packet
li a2 7
#to check if thread has any locations to work on or not
.T1target:
blt a1 s1 .thread1over
add a0 a0 a2
#load the data from the location of 6+rdptr to ra
ld s1 0(a0)
#double ra and put it back
add s1 s1 s1
#store the doubled value back to the location
sd s1 0(a0)
#since thread 0 is done working at that location, tp which was at 6 will move to 10, hence adding 4 to it
addi a0 a0 4
#storing 1 in ra as 1 location has been worked upon
li s1 1
#subtracting 1 from number of locations in the fifo
sub a1 a1 s1
#go back and double the data again till gp is equal to ra
j .T1target  
.thread1over:
#write 1 in sp, it's a signal that thread is done working on all of it's allocated locations to it
li a0 1
#process done
sw a0 2048(zero) .thread1wait

## keep loading from location 100, and check if it's 3 or not
.thread2wait:
ld a7 256(zero)
## loading and comparing with 7 since 7 is the CPU State in our State Diagram
li s2 7
## if the current state is indeed 7 the continue with next instuction otherwise jump back to PC 0
blt a7 s2 .thread2wait
## load the readpointer from location 0x200, add offset (5) to make it point to real packet header
ld s2 512(zero)
## using apriori knowledge that packet length is stored at 3rd offset
ld a7 3(s2) 
## since we do not have a divider, we shall perform right shift arithmetic 
li s3 20
## subtract header length from the total packet length to get the payload length
sub a7 a7 s3
## right shift the payload length by 5=(3+2) 3 because our data path is 16 bits and data memory is 64 bits
## and 2 because we have 4 threads , gp is the number of location per thread, ra is payload length in bytes
srai s3 a7 5
#load 1 in ra, 
li a7 1
#offset of 8 is present in our payload for the packet
li s4 8
#to check if thread has any locations to work on or not
.T2target:
blt s3 a7 .thread2over
add s2 s2 s4
#load the data from the location of 6+rdptr to ra
ld a7 0(s2)
#double ra and put it back
add a7 a7 a7
#store the doubled value back to the location
sd a7 0(s2)
#since thread 0 is done working at that location, tp which was at 6 will move to 10, hence adding 4 to it
addi s2 s2 4
#storing 1 in ra as 1 location has been worked upon
li a7 1
#subtracting 1 from number of locations in the fifo
sub s3 s3 a7
#go back and double the data again till gp is equal to ra
j .T2target 
.thread2over:
#write 1 in sp, it's a signal that thread is done working on all of it's allocated locations to it
li s2 1
#process done
sw s2 4096(zero) .thread2wait

## keep loading from location 100, and check if it's 3 or not
.thread3wait:
ld s9 256(zero)
## loading and comparing with 7 since 7 is the CPU State in our State Diagram
li s10 7
## if the current state is indeed 7 the continue with next instuction otherwise jump back to PC 0
blt s9 s10 .thread3wait
## load the readpointer from location 0x200, add offset (5) to make it point to real packet header
ld s10 512(zero)
## using apriori knowledge that packet length is stored at 3rd offset
ld s9 3(s10) 
## since we do not have a divider, we shall perform right shift arithmetic 
li s11 20
## subtract header length from the total packet length to get the payload length
sub s9 s9 s11
## right shift the payload length by 5=(3+2) 3 because our data path is 16 bits and data memory is 64 bits
## and 2 because we have 4 threads , gp is the number of location per thread, ra is payload length in bytes
srai s11 s9 5
#load 1 in ra, 
li s9 1
#offset of 9 is present in our payload for the packet
li t3 9
#to check if thread has any locations to work on or not
.T3target:
blt s11 s9 .thread3over
add s10 s10 t3
#load the data from the location of 6+rdptr to ra
ld s9 0(s10)
#double ra and put it back
add s9 s9 s9
#store the doubled value back to the location
sd s9 0(s10)
#since thread 3 is done working at that location, tp which was at 9 will move to 13, hence adding 4 to it
addi s10 s10 4
#storing 1 in ra as 1 location has been worked upon
li s9 1
#subtracting 1 from number of locations in the fifo
sub s11 s11 s9
#go back and double the data again till gp is equal to ra
j .T3target  
.thread3over:
#write 1 in sp, it's a signal that thread is done working on all of it's allocated locations to it
li s10 1
#process done
sw s10 8192(zero) .thread3wait

