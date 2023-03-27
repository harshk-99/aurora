module register_file
   # (parameter PROC_DATA_WIDTH=16, PROC_REGFILE_LOG2_DEEP=5)
   (
      input          clk_i,
      input          write_en_i,
      input [PROC_REGFILE_LOG2_DEEP-1:0]         write_addr_i,
      input [PROC_DATA_WIDTH-1:0]                 write_data_i,
      input [PROC_REGFILE_LOG2_DEEP-1:0]         read_addr1_i,
      input [PROC_REGFILE_LOG2_DEEP-1:0]         read_addr2_i,
      output [PROC_DATA_WIDTH-1:0]                read_data1_o,
      output [PROC_DATA_WIDTH-1:0]                read_data2_o
   );

   localparam NUM_REGISTERS = 32;

   reg [PROC_DATA_WIDTH-1:0] reg_file [NUM_REGISTERS-1:0];

   always @(negedge clk_i) begin
      if (write_en_i == 1'b1 & write_addr_i != 1'b0)
         reg_file[write_addr_i] <= write_data_i;
   end

   assign read_data1_o = (read_addr1_i == 0) ? {PROC_DATA_WIDTH{1'b0}} : (write_addr_i == read_addr1_i && write_en_i == 1'b1) ? write_data_i : reg_file[read_addr1_i];
   assign read_data2_o = (read_addr2_i == 0) ? {PROC_DATA_WIDTH{1'b0}} : (write_addr_i == read_addr2_i && write_en_i == 1'b1) ? write_data_i : reg_file[read_addr2_i];
  
endmodule
