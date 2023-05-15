module EXMEM 
   #(parameter PROC_DATA_WIDTH=64, 
     parameter PROC_REGFILE_LOG2_DEEP=5,
     parameter INSTMEM_LOG2_DEEP=8
   )
   (
  input                                clk_i,           
  input                                rst_i,           
  input                                reg_write_en_i,  
  input                                mem_write_en_i,  
  input                                mem_read_en_i, 
  input                                mem_to_reg_i,  
  input [PROC_DATA_WIDTH-1:0]          alu_i,             
  input [PROC_DATA_WIDTH-1:0]          reg_data2_i,       
  input [PROC_REGFILE_LOG2_DEEP-1:0]   reg_write_addr_i,   
  input [1:0]                          thread_id_i,
  input [INSTMEM_LOG2_DEEP-1:0]        pc_carry_baggage_i,
  output reg                           reg_write_en_o,    
  output reg                           mem_write_en_o,    
  output reg                           mem_read_en_o,     
  output reg                           mem_to_reg_o,    
  output reg [PROC_DATA_WIDTH-1:0]     alu_o,           
  output reg [PROC_DATA_WIDTH-1:0]     reg_data2_o,       
  output reg [PROC_REGFILE_LOG2_DEEP-1:0]   reg_write_addr_o, 
  output reg [1:0]                     thread_id_o,
  output reg [INSTMEM_LOG2_DEEP-1:0]   pc_carry_baggage_o
);

  always @(posedge clk_i) begin
    if (rst_i == 1'b1) begin
      reg_write_en_o    <= 1'b0; 
      mem_write_en_o    <= 1'b0;
      mem_read_en_o     <= 1'b0;
      mem_to_reg_o      <= 1'b0;
      alu_o             <= {PROC_DATA_WIDTH{1'b0}};
      reg_data2_o       <= {PROC_DATA_WIDTH{1'b0}};
      reg_write_addr_o  <= {PROC_REGFILE_LOG2_DEEP{1'b0}};
      thread_id_o       <= 2'b00;
      pc_carry_baggage_o   <= 8'd0;
    end else begin
      reg_write_en_o    <= reg_write_en_i;
      mem_write_en_o    <= mem_write_en_i;
      mem_read_en_o     <= mem_read_en_i;
      mem_to_reg_o      <= mem_to_reg_i;
      alu_o             <= alu_i;
      reg_data2_o       <= reg_data2_i;
      reg_write_addr_o  <= reg_write_addr_i;
      thread_id_o       <= thread_id_i;
      pc_carry_baggage_o   <= pc_carry_baggage_i;
    end
  end
  
endmodule
