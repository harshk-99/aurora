module MEMWB (
  input              clk_i,                     
  input              rst_i,                   
  input              reg_write_en_i,          
  input              mem_to_reg_i,          
  input      [4:0]   reg_write_addr_i,        
  input      [63:0]  alu_i,                     
  output reg         reg_write_en_o,              
  output reg         mem_to_reg_o,              
  output reg [4:0]   reg_write_addr_o,            
  output reg [63:0]  alu_o                        
);

  always @(posedge clk_i) begin
    if (rst_i == 1'b1) begin
      reg_write_en_o    <= 1'b0; 
      mem_to_reg_o      <= 1'b0; 
      reg_write_addr_o  <= 5'd0;
      alu_o             <= 64'd0;
    end else begin
      reg_write_en_o    <= reg_write_en_i;
      mem_to_reg_o      <= mem_to_reg_i;
      reg_write_addr_o  <= reg_write_addr_i;
      alu_o             <= alu_i;
    end
  end
  
endmodule
