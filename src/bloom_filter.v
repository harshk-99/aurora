module bloom_filter (
  input           rst_i,
  input [7:0]     hash0_i,
  input [7:0]     hash1_i,
  input [7:0]     hash2_i,
  input [7:0]     hash3_i,
  input [7:0]     hash4_i,
  input [7:0]     hash5_i,
  input [7:0]     hash6_i,
  input [7:0]     hash7_i,
  input [7:0]     hash8_i,
  input           clk_i,
  output          match_o
);

  reg bloom_mem [114:0];
  reg match_q;

  always @(posedge clk) begin
    if (rst_i == 1'b1) begin
      bloom_mem <= 115'hFFFFFFFF10FF10FF40FF0000;
    end
    else begin
      bloom_mem <= 115'hFFFFFFFF10FF10FF40FF0000;
    end
  end

  always @(*) begin
    match_q = bloom_mem[hash0_i] &
                bloom_mem[hash1_i] &
                bloom_mem[hash2_i] &
                bloom_mem[hash3_i] &
                bloom_mem[hash4_i] &
                bloom_mem[hash5_i] &
                bloom_mem[hash6_i] &
                bloom_mem[hash7_i] &
                bloom_mem[hash8_i];
  end

endmodule
