module logic_thief 
   # (parameter INSTMEM_LOG2_DEEP      = 8,
      parameter CTRL_WIDTH             =8,
      parameter DATA_WIDTH             =64,
      parameter LOGTHIEF_DATA_WIDTH    =192,
      parameter LOGTHIEF_LOG2_DEEP     =8,
      parameter BMEM_LOG2_DEEP         =8
   )
   (
     // inputs
     input [CTRL_WIDTH+DATA_WIDTH-1:0]    probe_CORE0_wrdata_i,
     input [CTRL_WIDTH+DATA_WIDTH-1:0]    probe_CORE1_wrdata_i,
     input [INSTMEM_LOG2_DEEP-1:0]        probe_CORE0_wraddr_i,
     input [INSTMEM_LOG2_DEEP-1:0]        probe_CORE1_wraddr_i,
     input                                probe_CORE0_wea_i,
     input                                probe_CORE1_wea_i,
     input [CTRL_WIDTH+DATA_WIDTH-1:0]    probe_CORE0_rdata_i,
     input [CTRL_WIDTH+DATA_WIDTH-1:0]    probe_CORE1_rdata_i,
     input [INSTMEM_LOG2_DEEP-1:0]        probe_CORE0_rdaddr_i,
     input [INSTMEM_LOG2_DEEP-1:0]        probe_CORE1_rdaddr_i,
     input [1:0]                          probe_CORE0_state_i,
     input [1:0]                          probe_CORE1_state_i,
     input [INSTMEM_LOG2_DEEP-1:0]        probe_CORE0_mem_pc_i,
     input [INSTMEM_LOG2_DEEP-1:0]        probe_CORE1_mem_pc_i,
     input [1:0]                          probe_CORE0_mem_thread_id_i,
     input [1:0]                          probe_CORE1_mem_thread_id_i,
     input [1:0]                          probe_current_writer_i,   
     input                                probe_change_writer_i, 
     input                                probe_fsmgenwren_i,
     input                                probe_ftsfrden_i,
     input                                probe_CORE0_ftsfrden_i,
     input                                probe_CORE1_ftsfrden_i,
     input [1:0]                          probe_current_reader_i,   
     input                                probe_change_reader_i,   
     input                                probe_outwr_i,
     // software and hardware registers
     input [31:0]                         addr_i,
     input                                clk_i,
     input [31:0]                         cmd_i,
     output reg [LOGTHIEF_DATA_WIDTH-1:0] CORE0_data_o,
     output reg [LOGTHIEF_DATA_WIDTH-1:0] CORE1_data_o
   );

  localparam REAL_LOGTHIEF_DATA_WIDTH = 183;
  localparam STATUS_BITS = LOGTHIEF_DATA_WIDTH - REAL_LOGTHIEF_DATA_WIDTH;
  wire [REAL_LOGTHIEF_DATA_WIDTH-1:0]  CORE0_dout_w;
  wire [REAL_LOGTHIEF_DATA_WIDTH-1:0]  CORE1_dout_w;
  reg  [LOGTHIEF_LOG2_DEEP-1:0]        CORE0_count_r;
  reg  [LOGTHIEF_LOG2_DEEP-1:0]        CORE1_count_r;
  reg  [7:0]                           CORE0_beginrecording;
  reg  [7:0]                           CORE1_beginrecording;
  reg CORE0_private_wen;
  reg CORE1_private_wen;
  
  always @(posedge clk_i) begin
      if (cmd_i == 32'hDEADDEAD) begin
         CORE0_count_r <= 0;
         CORE1_count_r <= 0;
         CORE0_data_o[LOGTHIEF_DATA_WIDTH-1:REAL_LOGTHIEF_DATA_WIDTH] <= ({STATUS_BITS{1'b0}});
         CORE1_data_o[LOGTHIEF_DATA_WIDTH-1:REAL_LOGTHIEF_DATA_WIDTH] <= ({STATUS_BITS{1'b0}});
         CORE0_beginrecording <= 8'h00;
         CORE1_beginrecording <= 8'h00;
	 CORE0_private_wen <= 1'b0;
	 CORE1_private_wen <= 1'b0;
      end
      else begin 
         if (cmd_i == 32'hDEADCAFE && CORE0_count_r != 255) begin
            CORE0_private_wen <= 1'b1;
            if ((probe_CORE0_wrdata_i[71:64] == 8'hff) || (CORE0_beginrecording == 8'hff)) begin
               //private_wen <= 1'b1;
               CORE0_beginrecording <= 8'hff;
               CORE0_count_r <= CORE0_count_r + 1;
            end
         end
         if (cmd_i == 32'hDEADCAFE && CORE1_count_r != 255) begin
            CORE1_private_wen <= 1'b1;
            if ((probe_CORE1_wrdata_i[71:64] == 8'hff) || (CORE1_beginrecording == 8'hff)) begin
               //private_wen <= 1'b1;
               CORE1_beginrecording <= 8'hff;
               CORE1_count_r <= CORE1_count_r + 1;
            end
         end
      end
      if (CORE0_count_r==255) begin
         CORE0_private_wen <= 1'b0;
         CORE0_data_o[LOGTHIEF_DATA_WIDTH-1:REAL_LOGTHIEF_DATA_WIDTH] <= ({STATUS_BITS{1'b1}});
      end 
      if (CORE1_count_r==255) begin
         CORE1_private_wen <= 1'b0;
         CORE1_data_o[LOGTHIEF_DATA_WIDTH-1:REAL_LOGTHIEF_DATA_WIDTH] <= ({STATUS_BITS{1'b1}});
      end 
  end
      
  always @(*) begin
    CORE0_data_o[REAL_LOGTHIEF_DATA_WIDTH-1:0] = CORE0_dout_w;
    CORE1_data_o[REAL_LOGTHIEF_DATA_WIDTH-1:0] = CORE1_dout_w;
  end
   // Dual-port memory such that port a is write only and thus connected
   // to fifo input
   // port b is read only and thus connected to hardware registers 

  dual_port_memory_logicthief bram0 (
      //.dina({probe_outwr_i,probe_change_reader_i,probe_current_reader_i,probe_CORE1_ftsfrden_i,probe_CORE0_ftsfrden_i,probe_ftsfrden_i,probe_fsmgenwren_i,probe_change_writer_i,probe_current_writer_i,probe_CORE1_mem_thread_id_i,CORE1_state_i,probe_CORE1_mem_pc_i,probe_CORE1_rdaddr_i,probe_CORE1_rdata_i, probe_CORE1_wea_i,probe_CORE1_wraddr_i,probe_CORE1_wrdata_i,probe_CORE0_mem_thread_id_i,CORE0_state_i,probe_CORE0_mem_pc_i,probe_CORE0_rdaddr_i,probe_CORE0_rdata_i, probe_CORE0_wea_i,probe_CORE0_wraddr_i,probe_CORE0_wrdata_i}),
      .dina({probe_outwr_i,probe_change_reader_i,probe_current_reader_i,probe_CORE0_ftsfrden_i,probe_ftsfrden_i,probe_fsmgenwren_i,probe_change_writer_i,probe_current_writer_i,probe_CORE0_mem_thread_id_i,probe_CORE0_state_i,probe_CORE0_mem_pc_i,probe_CORE0_rdaddr_i,probe_CORE0_rdata_i, probe_CORE0_wea_i,probe_CORE0_wraddr_i,probe_CORE0_wrdata_i}),
      .addra(CORE0_count_r),
      .wea(CORE0_private_wen),
      .addrb(addr_i),
      .clka(clk_i),
      .clkb(clk_i),
      .doutb(CORE0_dout_w)
  );

  dual_port_memory_logicthief bram1 (
      //.dina({probe_outwr_i,probe_change_reader_i,probe_current_reader_i,probe_CORE1_ftsfrden_i,probe_CORE0_ftsfrden_i,probe_ftsfrden_i,probe_fsmgenwren_i,probe_change_writer_i,probe_current_writer_i,probe_CORE1_mem_thread_id_i,CORE1_state_i,probe_CORE1_mem_pc_i,probe_CORE1_rdaddr_i,probe_CORE1_rdata_i, probe_CORE1_wea_i,probe_CORE1_wraddr_i,probe_CORE1_wrdata_i,probe_CORE0_mem_thread_id_i,CORE0_state_i,probe_CORE0_mem_pc_i,probe_CORE0_rdaddr_i,probe_CORE0_rdata_i, probe_CORE0_wea_i,probe_CORE0_wraddr_i,probe_CORE0_wrdata_i}),
      .dina({probe_outwr_i,probe_change_reader_i,probe_current_reader_i,probe_CORE1_ftsfrden_i,probe_ftsfrden_i,probe_fsmgenwren_i,probe_change_writer_i,probe_current_writer_i,probe_CORE1_mem_thread_id_i,probe_CORE1_state_i,probe_CORE1_mem_pc_i,probe_CORE1_rdaddr_i,probe_CORE1_rdata_i, probe_CORE1_wea_i,probe_CORE1_wraddr_i,probe_CORE1_wrdata_i}),
      .addra(CORE1_count_r),
      .wea(CORE1_private_wen),
      .addrb(addr_i),
      .clka(clk_i),
      .clkb(clk_i),
      .doutb(CORE1_dout_w)
  );

endmodule
