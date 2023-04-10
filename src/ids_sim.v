///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: module_template 2008-03-13 gac1 $
// Module: ids.v
// Project: NF2.1
// Description: Defines a simple ids module for the user data path.  The
// modules reads a 64-bit register that contains a pattern to match and
// counts how many packets match.  The register contents are 7 bytes of
// pattern and one byte of mask.  The mask bits are set to one for each
// byte of the pattern that should be included in the mask -- zero bits
// mean "don't care".
// This file has been modified and now mimics ids_sim file
// POTENTIAL PROBLEMS: 
// 1. WRPTR run-off: can be avoided by introduction of headptr
// 2. when we disable in_rdy, should we also disable fallthrough smallfifo wr_ptr incrementation?
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module ids_sim 
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter UDP_REG_SRC_WIDTH = 2
   )
   (
      input  [DATA_WIDTH-1:0]             in_data,
      input  [CTRL_WIDTH-1:0]             in_ctrl,
      input                               in_wr,
      output                              in_rdy,

      output [DATA_WIDTH-1:0]             out_data,
      output [CTRL_WIDTH-1:0]             out_ctrl,
      output                              out_wr,
      input                               out_rdy,
      
      // --- Register interface
      input                               reg_req_in,
      input                               reg_ack_in,
      input                               reg_rd_wr_L_in,
      input  [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr_in,
      input  [`CPCI_NF2_DATA_WIDTH-1:0]   reg_data_in,
      input  [UDP_REG_SRC_WIDTH-1:0]      reg_src_in,

      output                              reg_req_out,
      output                              reg_ack_out,
      output                              reg_rd_wr_L_out,
      output  [`UDP_REG_ADDR_WIDTH-1:0]   reg_addr_out,
      output  [`CPCI_NF2_DATA_WIDTH-1:0]  reg_data_out,
      output  [UDP_REG_SRC_WIDTH-1:0]     reg_src_out,

      // misc
      input                                reset,
      input                                clk
   );

   // Define the log2 function
   // `LOG2_FUNC

   //------------------------- Parameters-------------------------------
   parameter PROC_DATA_WIDTH              = 64;
   parameter PROC_REGFILE_LOG2_DEEP       = 5;                             
   parameter NUM_REGISTERS                = 2**PROC_REGFILE_LOG2_DEEP;                                                        
   parameter BMEM_LOG2_DEEP               = 8;
   parameter INSTMEM_LOG2_DEEP            = 8;
   parameter SHAMT_WIDTH                     = 6;     // if PROC_DATA_WIDTH=64, this parameter shall be 6
   localparam BMEM_DATA_WIDTH             = CTRL_WIDTH+DATA_WIDTH; 
   localparam STATEMACHINE_STATUS_ADDR_BIT = 8;
   localparam READPTR_ADDR_BIT            = 9;                                                             
   localparam CPU_JOB_STATUS_ADDR_BIT     = 10;                                                        
   localparam NUM_SPECIAL_REG             = 3;                    
   localparam THREAD0_START_ADDR          = 8'd0;                                                      
   localparam THREAD0_UPSTREAM_STATUS_BIT_POS             = 0; 
   //localparam COOLOFFCOUNT                = 1; // in simulation this value was found to be 2
   parameter PROC_DATA_INTERFACE_HIGHBIT  = 63;
   parameter PROC_DATA_INTERFACE_LOWBIT   = PROC_DATA_INTERFACE_HIGHBIT - PROC_DATA_WIDTH + 1;
   parameter START                        = 2'b00;
   parameter PAYLOAD                      = 2'b01;
   parameter CPU_PROCESS                  = 2'b11;
   parameter READ_READY                   = 2'b10;
   parameter LOGTHIEF_DATA_WIDTH          = 192;   // 2 (STATE ENCODING) + 1 (WEN)+ INSTMEM_LOG2_DEEP + 2*(BMEM_LOG2_DEEP) + 2*(CTRL_WIDTH + DATA_WIDTH)
   parameter LOGTHIEF_LOG2_DEEP           = 8;																																				

   //------------------------- Signals-------------------------------
   
   wire [DATA_WIDTH-1:0]         in_fifo_data_p;
   wire [CTRL_WIDTH-1:0]         in_fifo_ctrl_p;   // decide the movement of state machine
	
   //reg [DATA_WIDTH-1:0]         in_fifo_data;
   //reg [CTRL_WIDTH-1:0]         in_fifo_ctrl;

   wire                          ftsf_nearly_full;
   wire                          ftsf_empty_w;     // fall through small fifo - ftsf
   //reg [2:0]                     cooloff_counter_next_w;
   //reg [2:0]                     cooloff_counter_r;
   reg                           ftsf_rd_en_w;
   reg                           in_fifo_wr_messenger_r;
   reg			         in_fifo_wr_messenger_next;
   reg                           cpu_active_next;
   reg                           cpu_active_r;
   //reg [2:0]                     waitforcpujobcomplete_counter_r;
   //reg [2:0]                     waitforcpujobcomplete_counter_next;
   // software registers 
   wire [31:0]                   sw_readaddr_w;
   wire [31:0]                   sw_cmd_w;
   // hardware registers
   //reg [31:0]                    hw_data_ctrl;
   //reg [31:0]                    hw_data_high;
   //reg [31:0]                    hw_data_low;
   //reg [31:0]                    hw_readdata_ctrl;
   //reg [31:0]                    hw_readdata_high;
   //reg [31:0]                    hw_readdata_low;
   reg [31:0]                    hw_data0;
   reg [31:0]                    hw_data1;
   reg [31:0]                    hw_data2;
   reg [31:0]                    hw_data3;
   reg [31:0]                    hw_data4;
   reg [31:0]                    hw_data5;
   //wire [95:0]                   readdataout_96bit_w;

   // logic thief
   //wire [95:0]                   dataout_96bit_w;
   wire [LOGTHIEF_DATA_WIDTH-1:0]      logicthief_dataout_w;
   // internal state
   reg [1:0]                           state, state_next;

   // out_wr interface signals
   wire                                out_wr_w;
   reg                                 out_wr_r;
   //reg [CTRL_WIDTH+DATA_WIDTH-1:0]     din_bmem_r;
   reg [BMEM_LOG2_DEEP-1:0]            bmemasfifo_readptr_r;
   reg [BMEM_LOG2_DEEP-1:0]            bmemasfifo_writeptr_r;
   //reg                                 fifowrite_bmem_r;
   // sram endpoint signals
   wire [BMEM_LOG2_DEEP-1:0]           bmem_write_addr_w;
   wire [BMEM_LOG2_DEEP-1:0]           bmem_read_addr_w;
   wire                                bmem_wr_en_w;
   wire [CTRL_WIDTH+DATA_WIDTH-1:0]    bmem_dout_w;
   wire [CTRL_WIDTH+DATA_WIDTH-1:0]    bmem_din_w;
   // cpu interface wires and regs
   wire                                mem_mem_write_en_w;
   // mem_alu_out_w only BMEM_LOG2_DEEP is used in ids.v as this signal is
   // used for read and write address, whereas in processor this signal MAY be
   // used for carrying alu results as well
   wire [BMEM_LOG2_DEEP+NUM_SPECIAL_REG-1:0]           mem_alu_out_w;
   //reg [BMEM_LOG2_DEEP+NUM_SPECIAL_REG-1:0]            mem_alu_out_r;
   wire [PROC_DATA_WIDTH-1:0]          mem_r2_out_w;
   //wire [PROC_DATA_WIDTH-1:0]          wb_r2_out_w;
   //wire [PROC_DATA_WIDTH-1:0]          mem_read_data_wb_r2_out_w;
   wire                                cpu_job_complete_w;
   wire [INSTMEM_LOG2_DEEP-1:0]        mem_pc_carry_baggage_w;
   wire [CTRL_WIDTH-1:0]     			augment_proc_writedata_w;
   //reg [CTRL_WIDTH+DATA_WIDTH-1:0]     sync_data_r;
 
   //------------------------- Modules-------------------------------

   fallthrough_small_fifo #(
      .WIDTH(CTRL_WIDTH+DATA_WIDTH),
      .MAX_DEPTH_BITS(2)
   ) input_fifo (
      .din           ({in_ctrl, in_data}),   // Data in
      .wr_en         (in_wr & state_next != CPU_PROCESS & state_next!= READ_READY),                // Write enable
      .rd_en         (ftsf_rd_en_w),        // Read the next word 
      //.dout          ({in_fifo_ctrl, in_fifo_data}),
      .dout          ({in_fifo_ctrl_p, in_fifo_data_p}),
      .full          (),
      .nearly_full   (ftsf_nearly_full),
      .empty         (ftsf_empty_w),
      .reset         (reset),
      .clk           (clk)
   );

   SINGLECORE #(
      .DATA_WIDTH                         (DATA_WIDTH),
      .CTRL_WIDTH                         (CTRL_WIDTH),
      .PROC_DATA_WIDTH                    (PROC_DATA_WIDTH),
      .PROC_REGFILE_LOG2_DEEP             (PROC_REGFILE_LOG2_DEEP),
      .NUM_REGISTERS                      (NUM_REGISTERS),
      .BMEM_LOG2_DEEP                     (BMEM_LOG2_DEEP),
      .INSTMEM_LOG2_DEEP                  (INSTMEM_LOG2_DEEP),
      .BMEM_DATA_WIDTH                    (BMEM_DATA_WIDTH),
      .STATEMACHINE_STATUS_ADDR_BIT       (STATEMACHINE_STATUS_ADDR_BIT),
      .READPTR_ADDR_BIT                   (READPTR_ADDR_BIT),
      .CPU_JOB_STATUS_ADDR_BIT            (CPU_JOB_STATUS_ADDR_BIT),
      .THREAD0_START_ADDR                 (THREAD0_START_ADDR),
      .THREAD0_UPSTREAM_STATUS_BIT_POS    (THREAD0_UPSTREAM_STATUS_BIT_POS),
      .SHAMT_WIDTH                        (SHAMT_WIDTH)						   
   ) sc0 (
      .reset                      (reset),
      .mem_mem_write_en_out       (mem_mem_write_en_w),
      .mem_r2_out_out             (mem_r2_out_w),
      .mem_alu_out_out            (mem_alu_out_w),
      .bmem_dout_in               (bmem_dout_w[PROC_DATA_INTERFACE_HIGHBIT:PROC_DATA_INTERFACE_LOWBIT]),
      .state_status_in            (state),
      .bmemreadptr_in             (bmemasfifo_readptr_r),
	  .mem_pc_carry_baggage_w     (mem_pc_carry_baggage_w),
      .clk                        (clk)
   );

   generic_regs
   #( 
      .UDP_REG_SRC_WIDTH   (UDP_REG_SRC_WIDTH),
      .TAG                 (`IDS_BLOCK_ADDR),          // Tag -- eg. MODULE_TAG
      .REG_ADDR_WIDTH      (`IDS_REG_ADDR_WIDTH),     // Width of block addresses -- eg. MODULE_REG_ADDR_WIDTH
      .NUM_COUNTERS        (0),                 // Number of counters
      .NUM_SOFTWARE_REGS   (2),                 // Number of sw regs
      .NUM_HARDWARE_REGS   (6)                  // Number of hw regs
   ) module_regs (
      .reg_req_in       (reg_req_in),
      .reg_ack_in       (reg_ack_in),
      .reg_rd_wr_L_in   (reg_rd_wr_L_in),
      .reg_addr_in      (reg_addr_in),
      .reg_data_in      (reg_data_in),
      .reg_src_in       (reg_src_in),

      .reg_req_out      (reg_req_out),
      .reg_ack_out      (reg_ack_out),
      .reg_rd_wr_L_out  (reg_rd_wr_L_out),
      .reg_addr_out     (reg_addr_out),
      .reg_data_out     (reg_data_out),
      .reg_src_out      (reg_src_out),

      // --- counters interface
      .counter_updates  (),
      .counter_decrement(),

      // --- SW regs interface
      .software_regs    ({sw_cmd_w, sw_readaddr_w}),

      // --- HW regs interface
      .hardware_regs    ({hw_data5, hw_data4, hw_data3, hw_data2, hw_data1, hw_data0}),

      .clk              (clk),
      .reset            (reset)
    );

   //logic_thief lt0(
   //   .probe_data_i     (bmem_din_w),
   //   .state_i          (state),
   //   .probe_r_addr_i   (bmem_read_addr_w),
   //   .probe_w_addr_i   (bmem_write_addr_w),
   //   .probe_wea_i      (bmem_wr_en_w),
   //   .cmd_i            (sw_cmd_w),
   //   .addr_i           (sw_readaddr_w),
   //   .data_o           (dataout_96bit_w),
   //   .clk_i            (clk)
   //);

   dual_port_memory_9byte
       dm0 (
      .addra      (bmem_write_addr_w),
      .addrb      (bmem_read_addr_w),
      .clka       (clk),
      .clkb       (clk),
      .dina       (bmem_din_w),
      .wea        (bmem_wr_en_w),
      .doutb      (bmem_dout_w)
      );

   //------------------------- Logic-------------------------------
   // interface signals with upstream and downstream
   assign in_rdy     = !ftsf_nearly_full & (!(state_next == CPU_PROCESS | state_next == READ_READY));
   assign out_wr_w   = out_rdy & (bmemasfifo_readptr_r != bmemasfifo_writeptr_r) & (state == READ_READY);
   assign out_wr     = out_wr_r;
   assign augment_proc_writedata_w = {CTRL_WIDTH{1'b0}};
   // muxes for allowing network and CPU to use same datamem
   // NOTE: cpu_active_r goes LOW in the same clock cycle as state becomes
   // READ_READY, bmemasfifo_readptr_r is incremented only when out_wr_w is
   // HIGH
   // POTENTIAL PROBLEM: when CPU is writing to special register, should we
   // disable bmem_wr_en_w?
  
   // HACK 0: THIS HACK IS TO COMPENSATE FOR THE FACT THAT PROC_DATA_WIDTH = 16 bits
   // and BMEM_DATA_WIDTH = 72
   //assign bmem_wr_en_w = cpu_active_r == 1'b1 ? mem_mem_write_en_w :  in_fifo_wr_messenger_next;
   assign bmem_wr_en_w = cpu_active_r == 1'b1 ? mem_mem_write_en_w & ~mem_alu_out_w[CPU_JOB_STATUS_ADDR_BIT] :  in_fifo_wr_messenger_next;
   assign bmem_write_addr_w = cpu_active_r == 1'b1 ? mem_alu_out_w[BMEM_LOG2_DEEP-1:0] : bmemasfifo_writeptr_r;
   assign bmem_read_addr_w = cpu_active_r == 1'b1 ? mem_alu_out_w[BMEM_LOG2_DEEP-1:0] : bmemasfifo_readptr_r;
   assign bmem_din_w = cpu_active_r == 1'b1 ? ({augment_proc_writedata_w, mem_r2_out_w}) : ({in_fifo_ctrl_p, in_fifo_data_p});
   // HACK 0: 
   //assign bmem_din_w = cpu_active_r == 1'b1 ? ({sync_data_r[CTRL_WIDTH+DATA_WIDTH-1:PROC_DATA_INTERFACE_HIGHBIT+1], mem_r2_out_w, sync_data_r[PROC_DATA_INTERFACE_LOWBIT-1:0]}) : ({in_fifo_ctrl_p, in_fifo_data_p});
   assign {out_ctrl, out_data} = bmem_dout_w;
   assign cpu_job_complete_w = mem_mem_write_en_w & mem_alu_out_w[CPU_JOB_STATUS_ADDR_BIT];

   always @(*) begin
     // {hw_data_ctrl, hw_data_high, hw_data_low} = dataout_96bit_w;
      {hw_data5, hw_data4, hw_data3, hw_data2, hw_data1, hw_data0} = logicthief_dataout_w;
   end
  
   // state machine 
   always @(*) begin
      //state_next = state;
      ftsf_rd_en_w = 0;
      in_fifo_wr_messenger_next = 0;
      //cooloff_counter_next_w = cooloff_counter_r;
      //waitforcpujobcomplete_counter_next = waitforcpujobcomplete_counter_r;
      cpu_active_next = cpu_active_r;
      
      //if (!ftsf_empty_w && out_rdy) begin
         //in_fifo_wr_messenger_next = 1;
         //ftsf_rd_en_w = 1;
         
         case(state)
            START: begin
					if (!ftsf_empty_w && out_rdy) begin
						ftsf_rd_en_w = 1;
						if (in_fifo_ctrl_p != 0) begin
							in_fifo_wr_messenger_next = 1;
							state_next = PAYLOAD;
						end else begin
                  state_next = START;
						end
               end else begin
						state_next = START;
					end
				end
            PAYLOAD: begin
					if (!ftsf_empty_w && out_rdy) begin
						ftsf_rd_en_w = 1;
						in_fifo_wr_messenger_next = 1;
						if (in_fifo_ctrl_p != 0) begin
							state_next = CPU_PROCESS;
						end
						else begin
							state_next = PAYLOAD;
						end
					end
					else begin
						state_next = PAYLOAD;
					end
            end
            CPU_PROCESS: begin
               ftsf_rd_en_w = 0;
               cpu_active_next = 1;
               if (cpu_job_complete_w) begin
                  cpu_active_next = 0;
                  state_next = READ_READY;
               end else begin
                  state_next = CPU_PROCESS;
               end
            end
            READ_READY: begin
               if (bmemasfifo_readptr_r == bmemasfifo_writeptr_r) begin
                  state_next = START;
               end else begin
                  state_next = READ_READY;
               end
            end
         endcase // case(state)
      
   end
   
   always @(posedge clk) begin
      if(reset) begin
         //matches <= 0;
         state <= START;
	      //in_fifo_ctrl                     <= 0;
	      //in_fifo_data                     <= 0;
         cpu_active_r                     <= 0;
         // HACK 0: 
         // THESE LINE TO BE REMOVED WHEN WE DO MULTI-THREADED
         //sync_data_r                      <= 'b0;
         //mem_alu_out_r                    <= 'b0;
      end
      else begin
         state <= state_next;
	      //in_fifo_ctrl <= in_fifo_ctrl_p;
	      //in_fifo_data <= in_fifo_data_p;
	      //in_fifo_wr_messenger_r <= in_fifo_wr_messenger_next;
         cpu_active_r           <= cpu_active_next;
         // HACK 0: 
         // THESE LINE TO BE REMOVED WHEN WE DO MULTI-THREADED
         //mem_alu_out_r        <= mem_alu_out_w;
         //if (mem_alu_out_r == (bmemasfifo_readptr_r + 5)) begin
           // sync_data_r       <= bmem_dout_w;
         //end
      end // else: !if(reset)
   end // always @ (posedge clk)   
   
    

   // BRAM READ WRITE FUNCTIONALITY INTEGRATION
   
   always @(posedge clk) begin
       if (reset) begin
          //din_bmem_r          <= 'b0;
          //fifowrite_bmem_r    <= 'b0;
          bmemasfifo_writeptr_r     <= {BMEM_LOG2_DEEP{1'b0}};
          bmemasfifo_readptr_r      <= {BMEM_LOG2_DEEP{1'b0}};
          out_wr_r            <= 'b0;
       end
       else begin
          //din_bmem_r          <= {in_fifo_ctrl,in_fifo_data};
          //fifowrite_bmem_r    <= in_fifo_wr_messenger_r;
          if (in_fifo_wr_messenger_next) begin
          //if (fifowrite_bmem_r) begin
             bmemasfifo_writeptr_r     <= bmemasfifo_writeptr_r + 1;
          end
          out_wr_r     <= out_wr_w;
          if (out_wr_w)
             bmemasfifo_readptr_r      <= bmemasfifo_readptr_r + 1;
       end
    end   // always block

endmodule 
