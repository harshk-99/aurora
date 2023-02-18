module EXMEM (
  input              clk_i,
  input              rst_i,
  input              reg_write_en_i,
  input      [63:0]  mem_data_i,
  input      [4:0]   reg_write_data_i,

  output reg         reg_write_en_o,
  output reg [63:0]  mem_data_o,
  output reg [4:0]   reg_write_data_o
);

  always @(posedge clk_i) begin
    if (rst_i == 1'b1) begin
      reg_write_en_o    <= 1'b0; 
      mem_data_o        <= 64'd0;
      reg_write_data_o  <= 5'd0;
    end else begin
      reg_write_en_o    <= reg_write_en_i;
      mem_data_o        <= mem_data_i;
      reg_write_data_o  <= reg_write_data_i;
    end
  end
  
endmodule
