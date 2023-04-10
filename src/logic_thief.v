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
     input [CTRL_WIDTH+DATA_WIDTH-1:0]    probe_wdata_i,
     input [INSTMEM_LOG2_DEEP-1:0]        probe_w_addr_i,
     input                                probe_wea_i,
     input [CTRL_WIDTH+DATA_WIDTH-1:0]    probe_rdata_i,
     input [INSTMEM_LOG2_DEEP-1:0]        probe_r_addr_i,
     input [1:0]                          state_i,
     input [INSTMEM_LOG2_DEEP-1:0]        probe_mem_pc_i,
     // software and hardware registers
     input [31:0]                         addr_i,
     input                                clk_i,
     input [31:0]                         cmd_i,
     output reg [LOGTHIEF_DATA_WIDTH-1:0] data_o
   );

  // wire [23:0]  ltworking;
  // 3 - STATE (2 bits) + write enable
  // 3 + 8 + 16 + 2*72 = 171
  localparam REAL_LOGTHIEF_DATA_WIDTH = 3 + INSTMEM_LOG2_DEEP + 2*(BMEM_LOG2_DEEP) + 2*(CTRL_WIDTH + DATA_WIDTH);
  localparam STATUS_BITS = LOGTHIEF_DATA_WIDTH - REAL_LOGTHIEF_DATA_WIDTH;
  wire [REAL_LOGTHIEF_DATA_WIDTH-1:0]  dout_w;
  reg  [LOGTHIEF_LOG2_DEEP-1:0]        count_r;
  reg  [7:0]                           beginrecording;
  reg private_wen;
  

  //! Synchronous reset

  //always @(posedge clk_i) begin
  //  if (cmd_i == 32'hDEADDEAD) begin
  //    count_r <= 0;
  //    wr_en_r <= 1'b0;
  //      	data_o[95:72] <= 24'hFACADE;
  //  end
  //  else
  //    if (cmd_i == 32'hDEADCAFE && count_r != 255) begin
  //      wr_en_r <= 1'b1;
  //      count_r <= count_r + 1;
  //    end
  //  if (count_r == 255) begin
  //    wr_en_r <= 1'b0;
  //    data_o[95:72] <= 24'hDECADE;
  //  end
  //end

  //assign wr_ptr_w = count_r;
  //assign wr_en_w = wr_en_r;

  always @(posedge clk_i) begin
      if (cmd_i == 32'hDEADDEAD) begin
         count_r <= 0;
         data_o[LOGTHIEF_DATA_WIDTH-1:REAL_LOGTHIEF_DATA_WIDTH] <= ({STATUS_BITS{1'b0}});
         beginrecording <= 8'h00;
	 private_wen <= 1'b0;
      end
      else if (cmd_i == 32'hDEADCAFE && count_r != 255) begin
	 private_wen <= 1'b1;
         if ((probe_wdata_i[71:64] == 8'hff) || (beginrecording == 8'hff)) begin
	    //private_wen <= 1'b1;
            beginrecording <= 8'hff;
            count_r <= count_r + 1;
         end
      end
      if (count_r == 255) begin
         data_o[LOGTHIEF_DATA_WIDTH-1:REAL_LOGTHIEF_DATA_WIDTH] <= ({STATUS_BITS{1'b1}});
         private_wen <= 1'b0;
      end
  end
      
  always @(*) begin
    data_o[REAL_LOGTHIEF_DATA_WIDTH-1:0] = dout_w;
  end
   // Dual-port memory such that port a is write only and thus connected
   // to fifo input
   // port b is read only and thus connected to hardware registers 

  dual_port_memory_logicthief bram (
      .dina({state_i,probe_mem_pc_i,probe_r_addr_i,probe_rdata_i, probe_wea_i,probe_w_addr_i,probe_wdata_i}),
      .addra(count_r),
      .wea(private_wen),
      .addrb(addr_i),
      .clka(clk_i),
      .clkb(clk_i),
      .doutb(dout_w)
  );

endmodule
