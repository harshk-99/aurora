module register_file (
  input          clk_i,
  input          write_en_i,
  input  [4:0]   write_addr_i,
  input  [63:0]  write_data_i,
  input  [4:0]   read_addr1_i,
  input  [4:0]   read_addr2_i,
  output [63:0]  read_data1_o,
  output [63:0]  read_data2_o
);

  reg [63:0] reg_file [31:0];

  always @(posedge clk_i) begin
    if (write_en_i == 1'b1 & write_addr_i != 1'b0)
      reg_file[write_addr_i] <= write_data_i;
  end

  assign read_data1_o = (read_addr1_i == 0) ? 64'd0 : (write_addr_i == read_addr1_i && write_en_i == 1'b1) ? write_data_i : reg_file[read_addr1_i];
  assign read_data2_o = (read_addr2_i == 0) ? 64'd0 : (write_addr_i == read_addr2_i && write_en_i == 1'b1) ? write_data_i : reg_file[read_addr2_i];
  
endmodule
