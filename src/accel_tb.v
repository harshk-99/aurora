`include "worm_squasher.v"

module accel_tb;

reg clk;
reg rst;

reg req0;
reg req1;

reg [55:0] payload0;
reg [55:0] payload1;
reg [55:0] payload2;
reg [55:0] payload3;
reg [55:0] payload4;
reg [55:0] payload5;
reg [55:0] payload6;
reg [55:0] payload7;
reg [55:0] payload8;
reg [55:0] payload9;

reg [31:0] in_ip;
reg [31:0] out_ip;
reg [7:0]  proto;
reg [15:0] in_port;
reg [15:0] out_port;

wire [1:0] core_id;
wire       busy;
wire       valid;
wire       match;

worm_squasher uut (
  .clk_i(clk),
  .rst_i(rst),
  .cpureq0_i(req0),
  .cpureq1_i(req1),

  .payload0_i(payload0),
  .payload1_i(payload1),
  .payload2_i(payload2),
  .payload3_i(payload3),
  .payload4_i(payload4),
  .payload5_i(payload5),
  .payload6_i(payload6),
  .payload7_i(payload7),
  .payload8_i(payload8),
  .payload9_i(payload9),

  .in_ip_i(in_ip),
  .out_ip_i(out_ip),
  .proto_i(proto),
  .in_port_i(in_port),
  .out_port_i(out_port),

  .clientid_o(core_id),
  .busy_o(busy),
  .valid_o(valid),
  .match_o(match)
  );

initial begin
  $dumpfile("accel_tb.vcd");
  $dumpvars(0, accel_tb);
  clk = 0;
  forever #5 clk = ~clk;
end

// * External nodes:
// * n0: 10.1.0.3
// * n1: 10.1.1.3

// * Home nodes:
// * n2: 10.1.2.3
// * n3: 10.1.3.3

initial begin
  rst = 1;
  #50;
  rst = 0;
  #100;
  req0      = 1;
  req1      = 0;

  payload0  = 56'h792dfcaec45c24;
  payload1  = 56'hcc4d21c5a2256d;
  payload2  = 56'hcde06fbbbb49d9;
  payload3  = 56'h30534366b92ef2;
  payload4  = 56'hf30aeefec2cb07;
  payload5  = 56'hd6b43271811184;
  payload6  = 56'h0c4afa8a917566;
  payload7  = 56'h31509a23c1de7d;
  payload8  = 56'h3f50023b36ec21;
  payload9  = 56'hf6fccb8c0f31dd;

  in_ip     = 32'h0a010203;
  out_ip    = 32'h0a010003;
  proto     = 8'h11;
  in_port   = 16'd3000;
  out_port  = 16'd8080;
  #50;
  req0      = 0;
  #120;
  req1      = 1;

  payload0  = 56'h792dfcaec45c24;
  payload1  = 56'hcc4d21c5a2256d;
  payload2  = 56'hcde06fbbbb49d9;
  payload3  = 56'h30534366b92ef2;
  payload4  = 56'hf30aeefec2cb07;
  payload5  = 56'hd6b43271811184;
  payload6  = 56'h0c4afa8a917566;
  payload7  = 56'h31509a23c1de7d;
  payload8  = 56'h3f50023b36ec21;
  payload9  = 56'hf6fccb8c0f31dd;

  in_ip     = 32'h0a010003;
  out_ip    = 32'h0a010303;
  proto     = 8'h11;
  in_port   = 16'd0015;
  out_port  = 16'd8080;

  #50;
  req1      = 0;
  #120;
  req0      = 1;

  payload0  = 56'h792dfcaec45c24;
  payload1  = 56'hcc4d21c5a2256d;
  payload2  = 56'hcde06fbbbb49d9;
  payload3  = 56'h30534366b92ef2;
  payload4  = 56'h7C38397C484446;
  payload5  = 56'hd6b43271811184;
  payload6  = 56'h0c4afa8a917566;
  payload7  = 56'h31509a23c1de7d;
  payload8  = 56'h3f50023b36ec21;
  payload9  = 56'hf6fccb8c0f31dd;

  in_ip     = 32'h0a010203;
  out_ip    = 32'h0a010003;
  proto     = 8'h11;
  in_port   = 16'd3000;
  out_port  = 16'd8080;

  #50;
  req0      = 0;
  #120;
  req1      = 1;

  payload0  = 56'h792dfcaec45c24;
  payload1  = 56'hcc4d21c5a2256d;
  payload2  = 56'hcde06fbbbb49d9;
  payload3  = 56'h30534366b92ef2;
  payload4  = 56'h7C38397C484446;
  payload5  = 56'hd6b43271811184;
  payload6  = 56'h0c4afa8a917566;
  payload7  = 56'h31509a23c1de7d;
  payload8  = 56'h3f50023b36ec21;
  payload9  = 56'hf6fccb8c0f31dd;

  in_ip     = 32'h0a010003;
  out_ip    = 32'h0a010303;
  proto     = 8'h11;
  in_port   = 16'd0015;
  out_port  = 16'd8080;

  #50;
  req1      = 0;
  #120;
  req0      = 0;
  $finish;
end

endmodule
