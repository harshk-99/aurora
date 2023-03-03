`timescale 1ns/1ps
`include "data_path.v"

module riscv_tb;

reg clk;
reg rst;

integer i;

data_path uut (clk, rst);

initial begin
  $dumpfile("riscv_tb.vcd");
  $dumpvars(0, riscv_tb);
  clk = 0;
  forever #5 clk = ~clk;
end

initial begin
  $monitor("PC: 0x%0h\n ram0 = 0x%0h\n ram1 = 0x%0h\n ram2 = 0x%0h\n ram3 = 0x%0h\n ram4 = 0x%0h\n s2 = 0x%0h\n s3 = 0x%0h\n t0 = 0x%0h\n t1 = 0x%0h\n", 
    uut.pc_current_r, 
    uut.dm0.ram[0],
    uut.dm0.ram[1],
    uut.dm0.ram[2],
    uut.dm0.ram[3],
    uut.dm0.ram[4],
    uut.rf0.reg_file[18],
    uut.rf0.reg_file[19],
    uut.rf0.reg_file[5],
    uut.rf0.reg_file[6]
  );
  rst = 1;
  #50;
  rst = 0;
  #3700;
  // $monitor("Took 62 clocks to complete. Execution time: 1.24us");
  $display("Contents of Register file:");
  for(i = 0; i <= 7; i=i+1) begin
    $write("reg%0d = 0x%0h\t", i, uut.rf0.reg_file[i]);
    $write("reg%0d = 0x%0h\t", i+8, uut.rf0.reg_file[i+8]);
    $write("reg%0d = 0x%0h\t", i+16, uut.rf0.reg_file[i+16]);
    $write("reg%0d = 0x%0h\n", i+24, uut.rf0.reg_file[i+24]);
  end

  $display("Content of data memory location 12:");
  $write("ram[12] = 0x%0h\t", uut.dm0.ram[12]);
  $finish;
end

endmodule
