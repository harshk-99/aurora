///////////////////////////
// this module takes the various fields (rawdata) of header as an input (SrcIP, DstIP, Protocol (IP Layer), SrcPort, DstPort)
// matches against the configured set of rules
// encodes  and passes on
///////////////////////////
module header_police (
  input         rst_i,

  input  [31:0] in_ip_i,
  input  [31:0] out_ip_i,
  input  [7:0]  proto_i,
  input  [15:0] in_port_i,
  input  [15:0] out_port_i,

  output        match_o,
  output [2:0]  index_o
);

  wire [63:0] ip_chunk_w;
  wire [31:0] port_chunk_w;


  reg ip_match_q;
  reg [1:0]  proto_match_q;
  reg [2:0]  port_match_q;

  assign ip_chunk_w   = {in_ip_i, out_ip_i};
  assign port_chunk_w = {in_port_i, out_port_i};

  // dst and src ip matching
  always @(*) begin
    case (ip_chunk_w)
      64'h0a0100030a010203, 64'h0a0100030a010303, 64'h0a0101030a010203, 64'h0a0101030a010303: // EXTERNAL -> HOME
        ip_match_q = 1'b1;
      default: 
        ip_match_q = 1'b0;
    endcase
  end

  // protocol matching
  always @(*) begin
    case (proto_i)
      8'h06:                                                                                  // TCP
        proto_match_q = 2'b10;
      8'h11:                                                                                  // UDP
        proto_match_q = 2'b11;
      default:
        proto_match_q = 2'b0x;
    endcase
  end

  // ports matching
  always @(*) begin
    casex (port_chunk_w)
      32'h0015_xxxx:                                                                          // 21 -> any
        port_match_q = 3'b100;
      32'b0000_000x_xxx0_x0xx_xxxx_xxxx_xxxx_xxxx:                                           // 80,443 -> any
        port_match_q = 3'b101;
      32'hxxxx_007b:                                                                         // any -> 123
        port_match_q = 3'b110;
      32'bxxxx_xxxx_xxxx_xxxx_0000_000x_xxx0_x0xx:                                          // any -> 80, 443
        port_match_q = 3'b111;
      default:
        port_match_q = 3'b0xx;                                                            
    endcase
  end

  assign match_o = ip_match_q & proto_match_q[1] & port_match_q[2];
  assign index_o = {proto_match_q[0], port_match_q[1:0]};
  
endmodule