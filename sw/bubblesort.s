ld zero 0(zero)
ld ra   1(zero)
ld sp   2(zero)
ld gp   3(zero)
ld tp   4(zero)

#init arr[] to memory

# li  s0 0
# li	a5 3
# sw	a5 0(s0)
# li	a5 5
# sw	a5 1(s0)
# li	a5 1
# sw	a5 2(s0)
# li	a5 2
# sw	a5 3(s0)
# li	a5 4
# sw	a5 4(s0)

# ra (t0) is i
# sp (t1) is j
# gp (t2) is 4
# tp (t3) is 4 - i

li  ra 0
li  sp 0
li  gp 4

addi zero zero 0
addi zero zero 0
addi zero zero 0
addi zero zero 0
addi zero zero 0

.L1:
	# i < 4
	blt ra gp .L2
	j .L7

.L2:
	# 4 - i
	sub tp gp ra
	# j < 4 - i
	add zero zero zero
	addi zero zero 0
	addi zero zero 0
	addi zero zero 0
	addi zero zero 0
	addi zero zero 0
	blt sp tp .L3
	j .L6

# t0 (s2)
# t1 (s3)
# t2 (s4)

.L3:
	# load at loc j
	ld t0 0(sp)
	# load at loc j + 1
	ld t1 1(sp)
	addi zero zero 0
	addi zero zero 0
	addi zero zero 0
	addi zero zero 0
	addi zero zero 0
	# [j + 1] < [j]
	blt t1 t0 .L4
	j .L5

.L4:
	mv t2 t0
	mv t0 t1
	addi zero zero 0
	addi zero zero 0
	addi zero zero 0
	addi zero zero 0
	addi zero zero 0
	mv t1 t2
	addi zero zero 0
	addi zero zero 0
	addi zero zero 0
	addi zero zero 0
	addi zero zero 0
	sd t0 0(sp)
	sd t1 1(sp)
	j .L5

# inc j
.L5:
	addi sp sp 1
	j .L2

# inc i
.L6:
	addi ra ra 1
	li  sp 0

	j .L1
	
	
.L7:
	addi zero zero 0
	ld t0   0(zero)
	ld t1   1(zero)
	ld t2   2(zero)
	ld s0   3(zero)
	ld s1   4(zero)

.L8:
	addi zero zero 0
	j .L8
