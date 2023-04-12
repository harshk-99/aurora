# * Thread 0: Parent thread to manage the rest of the threads
# * Thread 1: Child thread to make IP datagram checksum 0
# * Thread 2: Child thread to make UDP checksum 0
# * Thread 3: Child thread to maniplulate payload

# * Memory location 256: State variable of the state machine
# * Memory location 512: Read pointer of BMem
# * Memory location 1024: Job status flag

# * Thread-Regiser mapping:
# * Thread0: ra -> t2
# * Thread1: s0 -> a5
# * Thread2: a6 -> s7
# * Thread3: s8 -> t6

# ! Register usage (DON'T CHANGE)
# ! tp: Signal to start other threads (1,2,3)  
# ! a5: Signify thread 1 completion
# ! s7: Signify thread 2 completion
# ! t6: Signify thread 3 completion  

li tp 0
li a5 0
li s7 0
li t6 0

li t1 489
li t2 161

.thread0_gobacktowait:
  ld ra 256(zero)
  li sp 3
  blt ra sp .thread0_gobacktowait
.thread0_check_protocol_udp:
  ld ra 512(zero)
  addi ra ra 3
  ld sp 0(ra)
  andi sp sp 255
  li gp 17
  beq sp gp .thread0_update_status_for_other_threads
  j .thread0_gobacktowait
.thread0_update_status_for_other_threads:
  li tp 161
  addi zero zero 0
  li tp 0
.thread0_listen_for_child_completion:
  add t0 zero a5
  add t0 t0 s7
  add t0 t0 t6
  beq t0 t1 .thread0_job_complete
  j .thread0_listen_for_child_completion

.thread0_job_complete:
  li a5 0
  li s7 0
  li t6 0
  li ra 1
  sd ra 1024(zero)
  j .thread0_gobacktowait

.thread1_check_for_parent_signal:
  beq tp t2 .thread1_make_IP_checksum_0
  j .thread1_check_for_parent_signal
.thread1_make_IP_checksum_0:
  ld s0 512(zero)
  addi s0 s0 4
  ld s1 0(s0)
  li a0 1024
  slli a0 a0 38
  addi a0 a0 -1
  and s1 s1 a0
  sd s1 0(s0)
  li a5 162
  j .thread1_check_for_parent_signal


.thread2_check_for_parent_signal:
  beq tp t2 .thread2_make_UDP_checksum_0
  j .thread2_check_for_parent_signal
.thread2_make_UDP_checksum_0:
  ld a6 512(zero)
  addi a6 a6 6
  ld a7 0(a6)
  li s2 1024
  slli s2 s2 38
  addi s2 s2 -1
  and a7 a7 s2
  sd a7 0(a6)
  li s7 163
  j .thread2_check_for_parent_signal

.thread3_check_for_parent_signal:
  beq tp t2 .thread3_manipulate_payload
  j .thread3_check_for_parent_signal
.thread3_manipulate_payload:
  ld s8 512(zero)
  addi s8 s8 6
  li s9 1158
  slli s9 s9 12
  ori s9 s9 1388
  slli s9 s9 12
  ori s9 s9 1734
  slli s9 s9 8
  ori s9 s9 242
  slli s9 s9 4
  sd s9 0(s8)

  addi s8 s8 1
  li s9 1046
  slli s9 s9 12
  ori s9 s9 1893
  slli s9 s9 12
  ori s9 s9 1830
  slli s9 s9 12
  ori s9 s9 1891
  slli s9 s9 12
  ori s9 s9 1554
  slli s9 s9 4
  ori s9 s9 1
  sd s9 0(s8)

  li t6 164
  j .thread3_check_for_parent_signal
