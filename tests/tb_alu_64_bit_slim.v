`timescale 1ns/1ps

module tb_alu_64_bit_slim;

reg clk_tb;
reg [63:0]       a_tb;
reg [63:0]       b_tb;
reg [3:0]       opr_tb;
wire [63:0]      out_tb;
wire            slt_tb;
wire            sltu_tb;
wire            grt_tb;
wire            grtu_tb;

alu_64_bit_slim uut (
    .in_rs1          (a_tb),
    .in_rs2          (b_tb),
    .in_funct3        (opr_tb[2:0]),
    .in_funct7        (opr_tb[3]),
    .out_rd        (out_tb)
    //.slt        (slt_tb), 
    //.sltu       (sltu_tb), 
    //.grt        (grt_tb), 
    //.grtu       (grtu_tb)
);

initial begin
  clk_tb = 0;
  forever #5 clk_tb = ~clk_tb;
end

initial begin
  //$monitor("a: 0x%0h\n b = 0x%0h\n opr = 0x%0h\n a_signed = 0x%0h\n b_signed = 0x%0h\n a_unsigned = 0x%0h\n b_unsigned = 0x%0h\n out = 0x%0h\n soverflow = 0x%0h\n slt = 0x%0h\n sltu = 0x%0h\n grt = 0x%0h\n grtu = 0x%0h\n", 
  $monitor("in_rs1: 0x%0h\n in_rs2 = 0x%0h\n opr = 0x%0h\n a_signed = 0x%0h\n out = 0x%0h\n", 
    uut.in_rs1, 
    uut.in_rs2,
    uut.funct7_and_3,
    uut.rs1_signed,
    //uut.b_signed,
    //uut.soverflow,
    uut.out_rd
    //uut.slt,
    //uut.sltu,
    //uut.grt,
    //uut.grtu
  );
  #10;
  // Addition
  a_tb = 64'd1; b_tb = 64'd2; opr_tb = 4'h0;
  #10;
  // Subtraction - Signed - Both Positive - a < b
  a_tb = 64'd1; b_tb = 64'd2; opr_tb = 4'h8;
  #10;
  // Subtraction - Signed - Both positive - a > b
  a_tb = 64'd6; b_tb = 64'd2; opr_tb = 4'h8;
  #10;
  // Subtraction - Signed - a negative, b positive - a < b
  a_tb = 64'd10; b_tb = 64'd64; opr_tb = 4'h8;
  #10;
  // Subtraction - Signed - b negative, a positive - a > b
  a_tb = 64'd6; b_tb = 64'd13; opr_tb = 4'h8;
  #10;
  // SRL
  a_tb = 64'd6; b_tb = 64'd2; opr_tb = 4'h5;
  #10;
  // SRA a +ve
  a_tb = 64'd6; b_tb = 64'd2; opr_tb = 4'hd;
  #10;
  // SRA a -ve
  a_tb = 64'hFFFF_FFFF_FFFF_FFF0; b_tb = 64'd2; opr_tb = 4'hd;
  #10;
  // SLT a +ve > b +ve, expected 1'b0
  a_tb = 64'h0000_0000_0000_0003; b_tb = 64'h0000_0000_0000_0002; opr_tb = 4'h2;
  #10;
  // SLT a +ve < b +ve, expected 1'b1
  a_tb = 64'h0000_0000_0000_0003; b_tb = 64'h0000_0000_0000_0004; opr_tb = 4'h2;
  #10;
  // SLT a -ve > b +ve, expected 1'b1
  a_tb = 64'hFFFF_FFFF_FFFF_FFF3; b_tb = 64'h0000_0000_0000_0002; opr_tb = 4'h2;
  #10;
  // SLT a +ve < b -ve, expected 1'b0
  a_tb = 64'h0000_0000_0000_0002; b_tb = 64'hFFFF_FFFF_FFFF_FFF3; opr_tb = 4'h2;
  #10;
  // SLT a -ve (-1) > b -ve (-2), expected 1'b0
  a_tb = 64'hFFFF_FFFF_FFFF_FFFF; b_tb = 64'hFFFF_FFFF_FFFF_FFFE; opr_tb = 4'h2;
  #10;
  // SLT a -ve (-2) < b -ve (-1), expected 1'b1
  a_tb = 64'hFFFF_FFFF_FFFF_FFFE; b_tb = 64'hFFFF_FFFF_FFFF_FFFE; opr_tb = 4'h2;
  #10;
  // SLTU a +ve > b +ve, expected 1'b0
  a_tb = 64'h0000_0000_0000_0003; b_tb = 64'h0000_0000_0000_0002; opr_tb = 4'h3;
  #10;
  // SLTU a +ve < b +ve, expected 1'b1
  a_tb = 64'h0000_0000_0000_0003; b_tb = 64'h0000_0000_0000_0004; opr_tb = 4'h3;
  #10;
  // SLTU a +ve > b +ve, expected 1'b1
  a_tb = 64'hFFFF_FFFF_FFFF_FFF3; b_tb = 64'h0000_0000_0000_0002; opr_tb = 4'h3;
  #10;
  // SLTU a +ve < b +ve, expected 1'b0
  a_tb = 64'h0000_0000_0000_0002; b_tb = 64'hFFFF_FFFF_FFFF_FFF3; opr_tb = 4'h3;
  #10;
end
endmodule