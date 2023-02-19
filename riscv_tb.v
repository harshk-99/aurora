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
  $monitor("PC: 0x%0h\n reg2 = 0x%0d\n reg3 = 0x%0h\n reg4 = 0x%0h\n reg5 = 0x%0h\n", 
    uut.pc_current_r, 
    uut.rf0.reg_file[2],
    uut.rf0.reg_file[3],
    uut.rf0.reg_file[4],
    uut.rf0.reg_file[5]
  );
  rst = 1;
  #50;
  rst = 0;
  #1200;
  // $monitor("Took 62 clocks to complete. Execution time: 1.24us");
  $display("Contents of Register file:");
  for(i = 0; i <= 7; i++) begin
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
