////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2008 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 10.1
//  \   \         Application : sch2verilog
//  /   /         Filename : register_file.vf
// /___/   /\     Timestamp : 03/01/2023 16:24:57
// \   \  /  \ 
//  \___\/\___\ 
//
//Command: C:\Xilinx\10.1\ISE\bin\nt\unwrapped\sch2verilog.exe -intstyle ise -family virtex2p -w "C:/Documents and Settings/tj/RISC-V/register_file/register_file.sch" register_file.vf
//Design Name: register_file
//Device: virtex2p
//Purpose:
//    This verilog netlist is translated from an ECS schematic.It can be 
//    synthesized and simulated, but it should not be modified. 
//
`timescale 1ns / 1ps

module registerfile_writeportonly(clk, 
                     waddr, 
                     wdata, 
                     wena, 
                     x0data, 
                     x1data, 
                     x2data, 
                     x3data, 
                     x4data, 
                     x5data, 
                     x6data, 
                     x7data, 
                     x8data, 
                     x9data, 
                     x10data, 
                     x11data, 
                     x12data, 
                     x13data, 
                     x14data, 
                     x15data, 
                     x16data, 
                     x17data, 
                     x18data, 
                     x19data, 
                     x20data, 
                     x21data, 
                     x22data, 
                     x23data, 
                     x24data, 
                     x25data, 
                     x26data, 
                     x27data, 
                     x28data, 
                     x29data, 
                     x30data, 
                     x31data);

    input clk;
    input [4:0] waddr;
    input [63:0] wdata;
    input wena;
   output [63:0] x0data;
   output [63:0] x1data;
   output [63:0] x2data;
   output [63:0] x3data;
   output [63:0] x4data;
   output [63:0] x5data;
   output [63:0] x6data;
   output [63:0] x7data;
   output [63:0] x8data;
   output [63:0] x9data;
   output [63:0] x10data;
   output [63:0] x11data;
   output [63:0] x12data;
   output [63:0] x13data;
   output [63:0] x14data;
   output [63:0] x15data;
   output [63:0] x16data;
   output [63:0] x17data;
   output [63:0] x18data;
   output [63:0] x19data;
   output [63:0] x20data;
   output [63:0] x21data;
   output [63:0] x22data;
   output [63:0] x23data;
   output [63:0] x24data;
   output [63:0] x25data;
   output [63:0] x26data;
   output [63:0] x27data;
   output [63:0] x28data;
   output [63:0] x29data;
   output [63:0] x30data;
   output [63:0] x31data;
   
   wire XLXN_2;
   wire XLXN_4;
   wire XLXN_5;
   wire XLXN_6;
   wire XLXN_7;
   wire XLXN_8;
   wire XLXN_9;
   wire XLXN_10;
   wire XLXN_14;
   wire XLXN_15;
   wire XLXN_16;
   wire XLXN_17;
   wire XLXN_18;
   wire XLXN_19;
   wire XLXN_20;
   wire XLXN_21;
   wire XLXN_22;
   wire XLXN_23;
   wire XLXN_24;
   wire XLXN_26;
   wire XLXN_27;
   wire XLXN_28;
   wire XLXN_29;
   wire XLXN_30;
   wire XLXN_31;
   wire XLXN_32;
   wire XLXN_33;
   wire XLXN_34;
   wire XLXN_35;
   wire XLXN_37;
   wire XLXN_40;
   wire XLXN_41;
   wire XLXN_44;
   wire XLXN_45;
   wire XLXN_46;
   wire XLXN_47;
   wire XLXN_48;
   wire XLXN_49;
   wire XLXN_57;
   wire XLXN_58;
   wire XLXN_59;
   wire XLXN_60;
   wire XLXN_61;
   wire XLXN_62;
   wire XLXN_63;
   wire XLXN_64;
   wire XLXN_65;
   wire XLXN_66;
   wire XLXN_67;
   wire XLXN_68;
   wire XLXN_69;
   wire XLXN_70;
   wire XLXN_71;
   wire XLXN_72;
   wire XLXN_73;
   wire XLXN_74;
   wire XLXN_75;
   wire XLXN_76;
   wire XLXN_77;
   wire XLXN_78;
   wire XLXN_79;
   wire XLXN_80;
   wire XLXN_116;
   wire XLXN_117;
   
   decoder_32bit XLXI_8 (.wr_addr(waddr[4:0]), 
                         .x0(XLXN_40), 
                         .x1(XLXN_41), 
                         .x2(XLXN_44), 
                         .x3(XLXN_45), 
                         .x4(XLXN_46), 
                         .x5(XLXN_47), 
                         .x6(XLXN_48), 
                         .x7(XLXN_49), 
                         .x8(XLXN_57), 
                         .x9(XLXN_58), 
                         .x10(XLXN_59), 
                         .x11(XLXN_60), 
                         .x12(XLXN_61), 
                         .x13(XLXN_62), 
                         .x14(XLXN_63), 
                         .x15(XLXN_64), 
                         .x16(XLXN_65), 
                         .x17(XLXN_66), 
                         .x18(XLXN_67), 
                         .x19(XLXN_68), 
                         .x20(XLXN_69), 
                         .x21(XLXN_80), 
                         .x22(XLXN_79), 
                         .x23(XLXN_78), 
                         .x24(XLXN_77), 
                         .x25(XLXN_76), 
                         .x26(XLXN_75), 
                         .x27(XLXN_74), 
                         .x28(XLXN_73), 
                         .x29(XLXN_72), 
                         .x30(XLXN_71), 
                         .x31(XLXN_70));
   registers_32s XLXI_40 (.cex0(XLXN_2), 
                          .cex1(XLXN_4), 
                          .cex2(XLXN_5), 
                          .cex3(XLXN_6), 
                          .cex4(XLXN_7), 
                          .cex5(XLXN_8), 
                          .cex6(XLXN_9), 
                          .cex7(XLXN_10), 
                          .cex8(XLXN_14), 
                          .cex9(XLXN_15), 
                          .cex10(XLXN_16), 
                          .cex11(XLXN_17), 
                          .cex12(XLXN_18), 
                          .cex13(XLXN_19), 
                          .cex14(XLXN_20), 
                          .cex15(XLXN_21), 
                          .cex16(XLXN_22), 
                          .cex17(XLXN_23), 
                          .cex18(XLXN_24), 
                          .cex19(XLXN_117), 
                          .cex20(XLXN_26), 
                          .cex21(XLXN_27), 
                          .cex22(XLXN_28), 
                          .cex23(XLXN_29), 
                          .cex24(XLXN_30), 
                          .cex25(XLXN_31), 
                          .cex26(XLXN_32), 
                          .cex27(XLXN_33), 
                          .cex28(XLXN_34), 
                          .cex29(XLXN_35), 
                          .cex30(XLXN_116), 
                          .cex31(XLXN_37), 
                          .clk(clk), 
                          .wdata(wdata[63:0]), 
                          .x0data(x0data[63:0]), 
                          .x1data(x1data[63:0]), 
                          .x2data(x2data[63:0]), 
                          .x3data(x3data[63:0]), 
                          .x4data(x4data[63:0]), 
                          .x5data(x5data[63:0]), 
                          .x6data(x6data[63:0]), 
                          .x7data(x7data[63:0]), 
                          .x8data(x8data[63:0]), 
                          .x9data(x9data[63:0]), 
                          .x10data(x10data[63:0]), 
                          .x11data(x11data[63:0]), 
                          .x12data(x12data[63:0]), 
                          .x13data(x13data[63:0]), 
                          .x14data(x14data[63:0]), 
                          .x15data(x15data[63:0]), 
                          .x16data(x16data[63:0]), 
                          .x17data(x17data[63:0]), 
                          .x18data(x18data[63:0]), 
                          .x19data(x19data[63:0]), 
                          .x20data(x20data[63:0]), 
                          .x21data(x21data[63:0]), 
                          .x22data(x22data[63:0]), 
                          .x23data(x23data[63:0]), 
                          .x24data(x24data[63:0]), 
                          .x25data(x25data[63:0]), 
                          .x26data(x26data[63:0]), 
                          .x27data(x27data[63:0]), 
                          .x28data(x28data[63:0]), 
                          .x29data(x29data[63:0]), 
                          .x30data(x30data[63:0]), 
                          .x31data(x31data[63:0]));
   AND2 XLXI_42 (.I0(XLXN_40), 
                 .I1(wena), 
                 .O(XLXN_2));
   AND2 XLXI_43 (.I0(XLXN_41), 
                 .I1(wena), 
                 .O(XLXN_4));
   AND2 XLXI_44 (.I0(XLXN_44), 
                 .I1(wena), 
                 .O(XLXN_5));
   AND2 XLXI_45 (.I0(XLXN_45), 
                 .I1(wena), 
                 .O(XLXN_6));
   AND2 XLXI_46 (.I0(XLXN_46), 
                 .I1(wena), 
                 .O(XLXN_7));
   AND2 XLXI_47 (.I0(XLXN_47), 
                 .I1(wena), 
                 .O(XLXN_8));
   AND2 XLXI_48 (.I0(XLXN_48), 
                 .I1(wena), 
                 .O(XLXN_9));
   AND2 XLXI_49 (.I0(XLXN_49), 
                 .I1(wena), 
                 .O(XLXN_10));
   AND2 XLXI_50 (.I0(XLXN_57), 
                 .I1(wena), 
                 .O(XLXN_14));
   AND2 XLXI_51 (.I0(XLXN_58), 
                 .I1(wena), 
                 .O(XLXN_15));
   AND2 XLXI_52 (.I0(XLXN_59), 
                 .I1(wena), 
                 .O(XLXN_16));
   AND2 XLXI_53 (.I0(XLXN_60), 
                 .I1(wena), 
                 .O(XLXN_17));
   AND2 XLXI_54 (.I0(XLXN_61), 
                 .I1(wena), 
                 .O(XLXN_18));
   AND2 XLXI_55 (.I0(XLXN_62), 
                 .I1(wena), 
                 .O(XLXN_19));
   AND2 XLXI_56 (.I0(XLXN_63), 
                 .I1(wena), 
                 .O(XLXN_20));
   AND2 XLXI_57 (.I0(XLXN_64), 
                 .I1(wena), 
                 .O(XLXN_21));
   AND2 XLXI_58 (.I0(XLXN_65), 
                 .I1(wena), 
                 .O(XLXN_22));
   AND2 XLXI_59 (.I0(XLXN_66), 
                 .I1(wena), 
                 .O(XLXN_23));
   AND2 XLXI_60 (.I0(XLXN_67), 
                 .I1(wena), 
                 .O(XLXN_24));
   AND2 XLXI_61 (.I0(XLXN_68), 
                 .I1(wena), 
                 .O(XLXN_117));
   AND2 XLXI_62 (.I0(XLXN_69), 
                 .I1(wena), 
                 .O(XLXN_26));
   AND2 XLXI_63 (.I0(XLXN_80), 
                 .I1(wena), 
                 .O(XLXN_27));
   AND2 XLXI_64 (.I0(XLXN_79), 
                 .I1(wena), 
                 .O(XLXN_28));
   AND2 XLXI_65 (.I0(XLXN_78), 
                 .I1(wena), 
                 .O(XLXN_29));
   AND2 XLXI_66 (.I0(XLXN_77), 
                 .I1(wena), 
                 .O(XLXN_30));
   AND2 XLXI_67 (.I0(XLXN_76), 
                 .I1(wena), 
                 .O(XLXN_31));
   AND2 XLXI_68 (.I0(XLXN_75), 
                 .I1(wena), 
                 .O(XLXN_32));
   AND2 XLXI_69 (.I0(XLXN_74), 
                 .I1(wena), 
                 .O(XLXN_33));
   AND2 XLXI_70 (.I0(XLXN_73), 
                 .I1(wena), 
                 .O(XLXN_34));
   AND2 XLXI_71 (.I0(XLXN_72), 
                 .I1(wena), 
                 .O(XLXN_35));
   AND2 XLXI_72 (.I0(XLXN_71), 
                 .I1(wena), 
                 .O(XLXN_116));
   AND2 XLXI_73 (.I0(XLXN_70), 
                 .I1(wena), 
                 .O(XLXN_37));
endmodule
