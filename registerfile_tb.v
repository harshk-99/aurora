`timescale 1ns/1ns
`include "registerfile_xilinx.v"
//`include "registerfile_writeportonly.v"

module registerfile_tb;

reg clk;
reg write_en;
reg [4:0] write_addr;
reg [4:0] read_addr1;
reg [4:0] read_addr2;
reg  [63:0] write_data;
wire  [63:0] read_data1;
wire  [63:0] read_data2;

registerfile_xilinx uut (
  .clk_i        (clk),
  .write_en_i   (write_en),
  .write_addr_i (write_addr),
  .write_data_i (write_data),
  .read_addr1_i (read_addr1),
  .read_addr2_i (read_addr2),
  .read_data1_o (read_data1),
  .read_data2_o (read_data2)
);

initial begin
  $dumpfile("wave.vcd");
  $dumpvars(0, registerfile_tb);
  clk = 0;
  forever #5 clk = ~ clk;
end

initial begin
  write_en = 1'b0;
  write_addr = 5'h00;
  read_addr1 = 5'h00;
  read_addr2 = 5'h00;
  write_data = 64'd0;
  #10;
  write_data = 64'hBABEBEEFCAFEDEAD;
  #10;
  write_data = 64'hCAFEBABECAFEBABE;
  write_en = 1'b1;
  write_addr = 5'd20;
  #10;
  write_data = 64'hDECADEFACADECAFE;
  write_addr = 5'd5;
  #10;
  write_en = 1'b0;
  read_addr1 = 5'd20;
  read_addr2 = 5'd5;
  #10;
  write_en = 1'b0;
  read_addr1 = 5'd0;
  read_addr2 = 5'd0;
  #10;
  write_en = 1'b1;
  write_data = 64'hCAFEBABE12345678;
  write_addr = 5'd19;
  read_addr1 = 5'd19;
  read_addr2 = 5'd5;
  #10;
  write_en = 1'b1;
  write_data = 64'hDEADBEEFBEEFDEAD;
  write_addr = 5'd23;
  read_addr1 = 5'd23;
  read_addr2 = 5'd23;
  #10;
  write_en = 1'b1;
  write_data = 64'h1234567887654321;
  write_addr = 5'd0;
  read_addr1 = 5'd23;
  read_addr2 = 5'd23;
  #10;
  write_en = 1'b0;
  write_data = 64'h1234567887654321;
  write_addr = 5'd0;
  read_addr1 = 5'd0;
  read_addr2 = 5'd0;
  #10;
  write_en = 1'b1;
  write_data = 64'h1234567887654321;
  write_addr = 5'd0;
  read_addr1 = 5'd0;
  read_addr2 = 5'd0;
  #10;
  write_en = 1'b0;
  write_data = 64'hCAFEBABE12345678;
  write_addr = 5'd19;
  read_addr1 = 5'd19;
  read_addr2 = 5'd20;
  #30;
  $finish;
end


  
endmodule
