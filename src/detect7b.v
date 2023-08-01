////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2008 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 10.1
//  \   \         Application : sch2verilog
//  /   /         Filename : detect7b.vf
// /___/   /\     Timestamp : 01/25/2023 15:34:33
// \   \  /  \ 
//  \___\/\___\ 
//
//Command: C:\Xilinx\10.1\ISE\bin\nt\unwrapped\sch2verilog.exe -intstyle ise -family virtex2p -w "C:/Documents and Settings/jasneet/IDS/detect7b.sch" detect7b.vf
//Design Name: detect7b
//Device: virtex2p
//Purpose:
//    This verilog netlist is translated from an ECS schematic.It can be 
//    synthesized and simulated, but it should not be modified. 
//
`timescale 1ns / 1ps

module detect7b(ce, 
                clk, 
                hwregA, 
                match_en, 
                mrst, 
                pipe1, 
                match);

    input ce;
    input clk;
    input [63:0] hwregA;
    input match_en;
    input mrst;
    input [71:0] pipe1;
   output match;
   
   wire [71:0] pipe0;
   wire [111:0] XLXN_6;
   wire XLXN_12;
   wire XLXN_14;
   wire XLXN_20;
   wire match_DUMMY;
   
   assign match = match_DUMMY;
   reg9B XLXI_1 (.ce(ce), 
                 .clk(clk), 
                 .clr(XLXN_20), 
                 .d(pipe1[71:0]), 
                 .q(pipe0[71:0]));
   wordmatch XLXI_2 (.datacomp(hwregA[55:0]), 
                     .detain(XLXN_6[111:0]), 
                     .wildcard(hwregA[62:56]), 
                     .match(XLXN_12));
   busmerge XLXI_3 (.da(pipe0[47:0]), 
                    .db(pipe1[63:0]), 
                    .q(XLXN_6[111:0]));
   FD XLXI_4 (.C(clk), 
              .D(mrst), 
              .Q(XLXN_20));
   defparam XLXI_4.INIT = 1'b0;
   FDCE XLXI_5 (.C(clk), 
                .CE(XLXN_14), 
                .CLR(XLXN_20), 
                .D(XLXN_14), 
                .Q(match_DUMMY));
   defparam XLXI_5.INIT = 1'b0;
   AND3B1 XLXI_6 (.I0(match_DUMMY), 
                  .I1(match_en), 
                  .I2(XLXN_12), 
                  .O(XLXN_14));
endmodule
