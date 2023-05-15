////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2008 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 10.1
//  \   \         Application : sch2verilog
//  /   /         Filename : reg9B.vf
// /___/   /\     Timestamp : 01/25/2023 15:02:09
// \   \  /  \ 
//  \___\/\___\ 
//
//Command: C:\Xilinx\10.1\ISE\bin\nt\unwrapped\sch2verilog.exe -intstyle ise -family virtex2p -w "C:/Documents and Settings/jasneet/IDS/reg9B.sch" reg9B.vf
//Design Name: reg9B
//Device: virtex2p
//Purpose:
//    This verilog netlist is translated from an ECS schematic.It can be 
//    synthesized and simulated, but it should not be modified. 
//
`timescale 1ns / 1ps

module FD16CE_MXILINX_reg9B(C, 
                            CE, 
                            CLR, 
                            D, 
                            Q);

    input C;
    input CE;
    input CLR;
    input [15:0] D;
   output [15:0] Q;
   
   
   FDCE I_Q0 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[0]), 
              .Q(Q[0]));
   defparam I_Q0.INIT = 1'b0;
   FDCE I_Q1 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[1]), 
              .Q(Q[1]));
   defparam I_Q1.INIT = 1'b0;
   FDCE I_Q2 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[2]), 
              .Q(Q[2]));
   defparam I_Q2.INIT = 1'b0;
   FDCE I_Q3 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[3]), 
              .Q(Q[3]));
   defparam I_Q3.INIT = 1'b0;
   FDCE I_Q4 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[4]), 
              .Q(Q[4]));
   defparam I_Q4.INIT = 1'b0;
   FDCE I_Q5 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[5]), 
              .Q(Q[5]));
   defparam I_Q5.INIT = 1'b0;
   FDCE I_Q6 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[6]), 
              .Q(Q[6]));
   defparam I_Q6.INIT = 1'b0;
   FDCE I_Q7 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[7]), 
              .Q(Q[7]));
   defparam I_Q7.INIT = 1'b0;
   FDCE I_Q8 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[8]), 
              .Q(Q[8]));
   defparam I_Q8.INIT = 1'b0;
   FDCE I_Q9 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[9]), 
              .Q(Q[9]));
   defparam I_Q9.INIT = 1'b0;
   FDCE I_Q10 (.C(C), 
               .CE(CE), 
               .CLR(CLR), 
               .D(D[10]), 
               .Q(Q[10]));
   defparam I_Q10.INIT = 1'b0;
   FDCE I_Q11 (.C(C), 
               .CE(CE), 
               .CLR(CLR), 
               .D(D[11]), 
               .Q(Q[11]));
   defparam I_Q11.INIT = 1'b0;
   FDCE I_Q12 (.C(C), 
               .CE(CE), 
               .CLR(CLR), 
               .D(D[12]), 
               .Q(Q[12]));
   defparam I_Q12.INIT = 1'b0;
   FDCE I_Q13 (.C(C), 
               .CE(CE), 
               .CLR(CLR), 
               .D(D[13]), 
               .Q(Q[13]));
   defparam I_Q13.INIT = 1'b0;
   FDCE I_Q14 (.C(C), 
               .CE(CE), 
               .CLR(CLR), 
               .D(D[14]), 
               .Q(Q[14]));
   defparam I_Q14.INIT = 1'b0;
   FDCE I_Q15 (.C(C), 
               .CE(CE), 
               .CLR(CLR), 
               .D(D[15]), 
               .Q(Q[15]));
   defparam I_Q15.INIT = 1'b0;
endmodule
`timescale 1ns / 1ps

module FD8CE_MXILINX_reg9B(C, 
                           CE, 
                           CLR, 
                           D, 
                           Q);

    input C;
    input CE;
    input CLR;
    input [7:0] D;
   output [7:0] Q;
   
   
   FDCE I_Q0 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[0]), 
              .Q(Q[0]));
   defparam I_Q0.INIT = 1'b0;
   FDCE I_Q1 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[1]), 
              .Q(Q[1]));
   defparam I_Q1.INIT = 1'b0;
   FDCE I_Q2 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[2]), 
              .Q(Q[2]));
   defparam I_Q2.INIT = 1'b0;
   FDCE I_Q3 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[3]), 
              .Q(Q[3]));
   defparam I_Q3.INIT = 1'b0;
   FDCE I_Q4 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[4]), 
              .Q(Q[4]));
   defparam I_Q4.INIT = 1'b0;
   FDCE I_Q5 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[5]), 
              .Q(Q[5]));
   defparam I_Q5.INIT = 1'b0;
   FDCE I_Q6 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[6]), 
              .Q(Q[6]));
   defparam I_Q6.INIT = 1'b0;
   FDCE I_Q7 (.C(C), 
              .CE(CE), 
              .CLR(CLR), 
              .D(D[7]), 
              .Q(Q[7]));
   defparam I_Q7.INIT = 1'b0;
endmodule
`timescale 1ns / 1ps

module reg9B(ce, 
             clk, 
             clr, 
             d, 
             q);

    input ce;
    input clk;
    input clr;
    input [71:0] d;
   output [71:0] q;
   
   
   FD8CE_MXILINX_reg9B XLXI_1 (.C(clk), 
                               .CE(ce), 
                               .CLR(clr), 
                               .D(d[71:64]), 
                               .Q(q[71:64]));
   // synthesis attribute HU_SET of XLXI_1 is "XLXI_1_0"
   FD16CE_MXILINX_reg9B XLXI_6 (.C(clk), 
                                .CE(ce), 
                                .CLR(clr), 
                                .D(d[63:48]), 
                                .Q(q[63:48]));
   // synthesis attribute HU_SET of XLXI_6 is "XLXI_6_1"
   FD16CE_MXILINX_reg9B XLXI_7 (.C(clk), 
                                .CE(ce), 
                                .CLR(clr), 
                                .D(d[47:32]), 
                                .Q(q[47:32]));
   // synthesis attribute HU_SET of XLXI_7 is "XLXI_7_2"
   FD16CE_MXILINX_reg9B XLXI_8 (.C(clk), 
                                .CE(ce), 
                                .CLR(clr), 
                                .D(d[31:16]), 
                                .Q(q[31:16]));
   // synthesis attribute HU_SET of XLXI_8 is "XLXI_8_3"
   FD16CE_MXILINX_reg9B XLXI_9 (.C(clk), 
                                .CE(ce), 
                                .CLR(clr), 
                                .D(d[15:0]), 
                                .Q(q[15:0]));
   // synthesis attribute HU_SET of XLXI_9 is "XLXI_9_4"
endmodule
