# all registers are using ld64 ABI name convention
# exposing the random/non-sorted data to be written to the data memory
# exposed to be cpatrued by logic_thief for the purpose of demonstration in DETER Lab  
ld zero, 0(zero)		#load the data_memory[0] to zero/x0 
ld ra,   1(zero)		#load the data_memory[1] to ra/x1 
ld sp,   2(zero)		#load the data_memory[2] to sp/x2 	
ld gp,   3(zero)		#load the data_memory[3] to gp/x3 	
ld tp,  4(zero)		#load the data_memory[4] to tp/x4 	

#init arr[] to memory
# writing the nnon-sorted data into the data memory form locatiojns 0 to 4
li  s0, 0
li	a5, 3
sw	a5, 0(s0)
li	a5, 5
sw	a5, 1(s0)
li	a5, 1
sw	a5, 2(s0)
li	a5, 2
sw	a5, 3(s0)
li	a5, 4
sw	a5, 4(s0)

# t0 is i
# t1 is j
# t2 is 4
# t3 is 4 - i

li  t0 0
li  t1 0
li  t2 4

.L1:
	# i < 4
	blt t0 t2 .L2
	# i > 4, go the end
	j .L7

.L2:
	# 4 - i
	sub t3 t2 t0
	# j < 4 - i
	blt t1 t3 .L3
	j .L6

.L3:
	# load at loc j
	ld s2 0(t1)
	# load at loc j + 1
	ld s3 1(t1)
	# [j + 1] < [j]
	blt s3 s2 .L4
	j .L5

.L4:
	mv s4 s2
	mv s2 s3
	mv s3 s4
	sd s2 0(t1)
	sd s3 1(t1)
	j .L5

# inc j
.L5:
	addi t1 t1 1
	j .L2

# inc i
.L6:
	addi t0 t0 1
	li  t1 0

	j .L1
	
	
.L7:
	# logic for exposing the data written to come on the bus so that logic thief
	# can capture the data
	addi zero zero 0					
	ld t0   0(zero)		#load the data_memory[0] to t0
	ld t1   1(zero)     #load the data_memory[1] to t1 
	ld t2   2(zero)     #load the data_memory[2] to t2 	
	ld s0   3(zero)     #load the data_memory[3] to t3 	
	ld s1   4(zero)     #load the data_memory[4] to t4 	

.L8:
	addi zero zero 0
	j .L8
