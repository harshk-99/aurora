module EXMEM (
  input              clk_i,           
  input              rst_i,           
  input              reg_write_en_i,  
  input              mem_write_en_i,  
  input              mem_to_reg_i,  
  input      [15:0]  alu_i,             
  input      [15:0]  reg_data2_i,       
  input      [3:0]   reg_write_addr_i,    

  output reg         reg_write_en_o,    
  output reg         mem_write_en_o,      
  output reg         mem_to_reg_o,    
  output reg [15:0]  alu_o,           
  output reg [15:0]  reg_data2_o,       
  output reg [3:0]   reg_write_addr_o 
);

  always @(posedge clk_i) begin
    if (rst_i == 1'b1) begin
      reg_write_en_o    <= 1'b0; 
      mem_write_en_o    <= 1'b0;
      mem_to_reg_o      <= 1'b0;
      alu_o             <= 16'd0;
      reg_data2_o       <= 16'd0;
      reg_write_addr_o  <= 4'd0;
    end else begin
      reg_write_en_o    <= reg_write_en_i;
      mem_write_en_o    <= mem_write_en_i;
      mem_to_reg_o      <= mem_to_reg_i;
      alu_o             <= alu_i;
      reg_data2_o       <= reg_data2_i;
      reg_write_addr_o  <= reg_write_addr_i;
    end
  end
  
endmodule
