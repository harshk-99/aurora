 /////////////////////////////////////////////////
// worm_squasher is main accelerator module 
/////////////////////////////////////////////////
module worm_squasher (
  // infrastructure
  input         clk_i,
  input         rst_i,
  // handshake inputs
  input         cpureq0_i,
  input         cpureq1_i,
  // data-related inputs
  input [55:0]  payload0_i,
  input [55:0]  payload1_i,
  input [55:0]  payload2_i,
  input [55:0]  payload3_i,
  input [55:0]  payload4_i,
  input [55:0]  payload5_i,
  input [55:0]  payload6_i,
  input [55:0]  payload7_i,
  input [55:0]  payload8_i,
  input [55:0]  payload9_i,

  input [31:0]  in_ip_i,
  input [31:0]  out_ip_i,
  input [7:0]   proto_i,
  input [15:0]  in_port_i,
  input [15:0]  out_port_i,

  output [1:0]    clientid_o,
  output          busy_o,
  output          valid_o,
  output          match_o,
);

  // internal wires
  // header_police wires and reg
  wire            match_w;    
  wire [2:0]      strip_index_w;

  // bloom_set wires and reg
  wire [9:0]      fmatch_w;

  // state machine wires and reg
  reg             busy_r, bust_next;
  reg [1:0]       clientid_r, clientid_next;
  reg             valid_r, valid_next;
  reg             match_r;           
  reg [1:0]       thrdcnt_r, thrdcnt_next;

  // assignments
  assign clientid_o     = clientid_r;
  assign busy_o         = busy_r;
  assign valid_o        = valid_r;
  assign match_o        = match_r;

  header_police hp0 (
    // inputs
    .in_ip_i(in_ip_i),
    .out_ip_i(out_ip_i),
    .proto_i(proto_i),
    .in_port_i(in_port_i),
    .out_port_i(out_port_i),
    // outputs
    .match_o(match_w),
    .index_o(strip_index_w)
  );

  bloom_set bs0 (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .data_i     ({strip_index_w,payload0_i}),
    .match_o    (fmatch_w[0])
  );
  bloom_set bs1 (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .data_i     ({strip_index_w,payload0_i}),
    .match_o    (fmatch_w[1])
  );
  bloom_set bs2 (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .data_i     ({strip_index_w,payload0_i}),
    .match_o    (fmatch_w[2])
  );
  bloom_set bs3 (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .data_i     ({strip_index_w,payload0_i}),
    .match_o    (fmatch_w[3])
  );
  bloom_set bs4 (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .data_i     ({strip_index_w,payload0_i}),
    .match_o    (fmatch_w[4])
  );
  bloom_set bs5 (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .data_i     ({strip_index_w,payload0_i}),
    .match_o    (fmatch_w[5])
  );
  bloom_set bs6 (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .data_i     ({strip_index_w,payload0_i}),
    .match_o    (fmatch_w[6])
  );
  bloom_set bs7 (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .data_i     ({strip_index_w,payload0_i}),
    .match_o    (fmatch_w[7])
  );
  bloom_set bs8 (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .data_i     ({strip_index_w,payload0_i}),
    .match_o    (fmatch_w[8])
  );
  bloom_set bs9 (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .data_i     ({strip_index_w,payload0_i}),
    .match_o    (fmatch_w[9])
  );

  always @(*) begin
    busy_next         = busy_r;
    clientid_next     = clientid_r;
    valid_next        = valid_r;
    thrdcnt_next      = thrdcnt_r;
    case (busy_r)
      1'b0: begin   // not busy i.e. idle
        busy_next       = 1'b1;
        valid_next      = 1'b1;
        if (cpureq0_i) begin
          clientid_next   = 2'b01;
        end
        if (cpureq1_i) begin
          clientid_next   = 2'b10;
        end
      end   // end of 1'b0
      1'b1: begin
        thrdcnt_next      = thrdcnt_r + 1;
        if (thrdcnt_r == 2'b11) begin
          thrdcnt_next    =  2'b00;
          busy_next       = 1'b0;
          valid_next      = 1'b0;
          clientid_next   = 2'b00;
        end
      end
  end

  always @(posedge clk_i) begin
    if (rst_i) begin 
      busy_r          <=    1'b0;
      clientid_r      <=    2'b00;
      match_r         <=    1'b0;
      valid_r         <=    1'b0;
      thrdcnt_r        <=    2'b0;
    end
    else begin
      busy_r          <=    bust_next;
      clientid_r      <=    clientid_next;
      valid_r         <=    valid_next;
      thrdcnt_r       <=    thrdcnt_next;
      match_r         <=    fmatch_w[0] | 
                            fmatch_w[1] |
                            fmatch_w[2] |
                            fmatch_w[3] |
                            fmatch_w[4] |
                            fmatch_w[5] |
                            fmatch_w[6] |
                            fmatch_w[7] |
                            fmatch_w[8] |
                            fmatch_w[9]; 
                            
    end
  end

endmodule