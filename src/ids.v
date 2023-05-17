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

module ids 
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
   parameter PROC_DATA_WIDTH                 = 64;
   parameter PROC_REGFILE_LOG2_DEEP          = 5;                             
   parameter NUM_REGISTERS                   = 2**PROC_REGFILE_LOG2_DEEP;                                        
   parameter BMEM_LOG2_DEEP                  = 8;
   parameter INSTMEM_LOG2_DEEP               = 8;
   parameter SHAMT_WIDTH                     = 6;  // if PROC_DATA_WIDTH=64, this parameter shall be 6
   localparam BMEM_DATA_WIDTH                = CTRL_WIDTH+DATA_WIDTH; 
   localparam STATEMACHINE_STATUS_ADDR_BIT   = 8;
   localparam READPTR_ADDR_BIT               = 9;                                                             
   localparam CPU_JOB_STATUS_ADDR_BIT        = 10;                                                        
   localparam MATCHER_SIGNAL_ADDR_BIT        = 11;
   localparam NUM_SPECIAL_REG                = 4;                    
   parameter PROC_DATA_INTERFACE_HIGHBIT     = 63;
   parameter PROC_DATA_INTERFACE_LOWBIT      = PROC_DATA_INTERFACE_HIGHBIT - PROC_DATA_WIDTH + 1;
   parameter START                           = 2'b00;
   parameter PAYLOAD                         = 2'b01;
   parameter CPU_PROCESS                     = 2'b11;
   parameter READ_READY                      = 2'b10;
   // CHANGE_READER(1) + CHANGE_WRITER(1) + OUT_WR(1) + FSMGENWREN(1) + FTSFRDEN(1) + CURRENT_READER(2) + CURRENT_WRITER(2) + CORE0/CORE1_STATE(2*2) + CORE0/CORE1_PC(INSTMEM_LOG2_DEEP=2*8) + CORE0/CORE1_RDADDR(BMEM_LOG2_DEEP=2*8) + CORE0/CORE1_DOUT(CTRL_WIDTH+DATA_WIDTH=2*72) + CORE0/CORE1_WREN(2*1) + CORE0/CORE1_WRADDR(BMEM_LOG2_DEEP=2*8) + CORE0/CORE1_DIN(CTRL_WIDTH+DATA_WIDTH=2*72)
   parameter LOGTHIEF_DATA_WIDTH             = 192;   // 6 software registers 
   parameter LOGTHIEF_LOG2_DEEP              = 8;
   parameter THREAD0_STATE                   = 2'b00;
   parameter THREAD1_STATE                   = 2'b01;
   parameter THREAD2_STATE                   = 2'b10;
   parameter THREAD3_STATE                   = 2'b11;
   parameter CORE0                           = 2'b01;
   parameter CORE1                           = 2'b10;
   parameter CORE_COUNT                      = 2;
   localparam CORE0_THREAD0_START_ADDR       = 8'h0;
   localparam CORE0_THREAD1_START_ADDR       = 8'h12;
   localparam CORE0_THREAD2_START_ADDR       = 8'h19;
   localparam CORE0_THREAD3_START_ADDR       = 8'h20;
   localparam CORE1_THREAD0_START_ADDR       = 8'h0;
   localparam CORE1_THREAD1_START_ADDR       = 8'h12;
   localparam CORE1_THREAD2_START_ADDR       = 8'h19;
   localparam CORE1_THREAD3_START_ADDR       = 8'h20;

   //------------------------- Signals-------------------------------
   // fall through small fifo state machine interface 
   wire                          fsmgenerated_wr_en_w; 
   wire [DATA_WIDTH-1:0]         in_fifo_data_p;
   wire [DATA_WIDTH-1:0]         CORE0_in_fifo_data_p;
   wire [DATA_WIDTH-1:0]         CORE1_in_fifo_data_p;
   wire [CTRL_WIDTH-1:0]         in_fifo_ctrl_p;   // decide the movement of state machine
   wire [CTRL_WIDTH-1:0]         CORE0_in_fifo_ctrl_p;   // decide the movement of state machine
   wire [CTRL_WIDTH-1:0]         CORE1_in_fifo_ctrl_p;   // decide the movement of state machine
	
   wire                          ftsf_nearly_full;
   wire                          ftsf_empty_w;           // fall through small fifo - ftsf
   wire                          CORE0_ftsf_empty_w;     // fall through small fifo - ftsf
   wire                          CORE1_ftsf_empty_w;     // fall through small fifo - ftsf
   wire                          ftsf_rd_en_w;
   reg                           CORE0_ftsf_rd_en_w;
   reg                           CORE1_ftsf_rd_en_w;
   reg			         CORE0_in_fifo_wr_messenger_next;
   reg			         CORE1_in_fifo_wr_messenger_next;
   reg                           CORE0_cpu_active_next;
   reg                           CORE1_cpu_active_next;
   reg                           CORE0_cpu_active_r;
   reg                           CORE1_cpu_active_r;
   // software registers 
   wire [31:0]                   sw_readaddr_w;
   wire [31:0]                   sw_cmd_w;
   //wire [31:0]                   ids_cmd;
   // hardware registers
   reg [31:0]                    hw_data0;
   reg [31:0]                    hw_data1;
   reg [31:0]                    hw_data2;
   reg [31:0]                    hw_data3;
   reg [31:0]                    hw_data4;
   reg [31:0]                    hw_data5;
   reg [31:0]                    hw_data6;
   reg [31:0]                    hw_data7;
   reg [31:0]                    hw_data8;
   reg [31:0]                    hw_data9;
   reg [31:0]                    hw_data10;
   reg [31:0]                    hw_data11;

   // logic thief
   wire [LOGTHIEF_DATA_WIDTH-1:0]      CORE0_logicthief_dataout_w;
   wire [LOGTHIEF_DATA_WIDTH-1:0]      CORE1_logicthief_dataout_w;
   // internal state
   reg [1:0]                           CORE0_state, CORE0_state_next;
   reg [1:0]                           CORE1_state, CORE1_state_next;
   // block memory state machine interface
   // out_wr interface signals
   wire                                CORE0_out_wr_w, CORE1_out_wr_w;
   reg                                 CORE0_out_wr_r, CORE1_out_wr_r;
   //reg [CTRL_WIDTH+DATA_WIDTH-1:0]     din_bmem_r;
   reg [BMEM_LOG2_DEEP-1:0]            CORE0_bmemasfifo_readptr_r, CORE1_bmemasfifo_readptr_r;
   reg [BMEM_LOG2_DEEP-1:0]            CORE0_bmemasfifo_writeptr_r, CORE1_bmemasfifo_writeptr_r ;
   wire [BMEM_LOG2_DEEP-1:0]           CORE0_bmem_write_addr_w, CORE1_bmem_write_addr_w ;
   wire [BMEM_LOG2_DEEP-1:0]           CORE0_bmem_read_addr_w, CORE1_bmem_read_addr_w ;
   wire                                CORE0_bmem_wr_en_w, CORE1_bmem_wr_en_w ;
   wire [CTRL_WIDTH+DATA_WIDTH-1:0]    CORE0_bmem_dout_w, CORE1_bmem_dout_w ;
   wire [CTRL_WIDTH+DATA_WIDTH-1:0]    CORE0_bmem_din_w, CORE1_bmem_din_w ;
   // cpu interface wires and regs
   wire                                CORE0_mem_mem_write_en_w,CORE1_mem_mem_write_en_w ;
   // mem_alu_out_w only BMEM_LOG2_DEEP+NUM_SPECIAL_REG wide is used in ids.v as this signal is
   // used for read and write address, whereas in processor this signal MAY be
   // used for carrying alu results as well
   wire [BMEM_LOG2_DEEP+NUM_SPECIAL_REG-1:0]    CORE0_mem_alu_out_w, CORE1_mem_alu_out_w ;
   wire [PROC_DATA_WIDTH-1:0]                   CORE0_mem_r2_out_w, CORE1_mem_r2_out_w ;
   wire                                         CORE0_cpu_job_complete_w, CORE1_cpu_job_complete_w ;
   wire [INSTMEM_LOG2_DEEP-1:0]                 CORE0_mem_pc_carry_baggage_w, CORE1_mem_pc_carry_baggage_w ;
   wire [CTRL_WIDTH-1:0]                        augment_proc_writedata_w;
   wire [1:0]                                   CORE0_mem_thread_id_w, CORE1_mem_thread_id_w ;
   
   // core synchronization signals
   reg [CORE_COUNT-1:0]                         current_writer_r;     // one-hot encoded
   reg [CORE_COUNT-1:0]                         next_writer;         // one-hot encoded
   reg [CORE_COUNT-1:0]                         current_reader_r;     // one-hot encoded
   reg [CORE_COUNT-1:0]                         next_reader;         // one-hot encoded
   wire                                         change_writer_w;
   wire                                         change_reader_w;
   wire                                         bmem_CORE0_writing_w;
   reg                                          bmem_CORE0_writing_r;
   wire                                         bmem_CORE1_writing_w;
   reg                                          bmem_CORE1_writing_r;
   wire                                         bmem_CORE0_reading_w;
   reg                                          bmem_CORE0_reading_r;
   wire                                         bmem_CORE1_reading_w;
   reg                                          bmem_CORE1_reading_r;

   // accelerator signals
   wire                                CORE0_accept;
   wire                                CORE0_reset;
   wire                                CORE0_worm_match;
   wire 			                        CORE1_accept;
   wire                                CORE1_reset;
   wire 			                        CORE1_worm_match; 
   //------------------------- Modules-------------------------------


   fallthrough_small_fifo #(
      .WIDTH(CTRL_WIDTH+DATA_WIDTH),
      .MAX_DEPTH_BITS(2)
   ) input_fifo (
      .din           ({in_ctrl, in_data}),   // Data in
      //.wr_en         (in_wr & state_next != CPU_PROCESS & state_next!= READ_READY),                // Write enable
      .wr_en         (fsmgenerated_wr_en_w),                // Write enable
      .rd_en         (ftsf_rd_en_w),        // Read the next word 
      //.dout          ({in_fifo_ctrl, in_fifo_data}),
      .dout          ({in_fifo_ctrl_p, in_fifo_data_p}),
      .full          (),
      .nearly_full   (ftsf_nearly_full),
      .empty         (ftsf_empty_w),
      .reset         (reset),
      .clk           (clk)
   );

   worm_squasher ws0 (
      .clk_i            (clk),
      .rst_i            (CORE0_reset),
      .start_i          (CORE0_accept),
      .valid_i          (CORE0_in_fifo_wr_messenger_next),
      .data_i           ({CORE0_in_fifo_ctrl_p, CORE0_in_fifo_data_p}),
      
      .match_o          (CORE0_worm_match)
   );

   worm_squasher ws1 (
      .clk_i            (clk),
      .rst_i            (CORE1_reset),
      .start_i          (CORE1_accept),
      .valid_i          (CORE1_in_fifo_wr_messenger_next),
      .data_i           ({CORE1_in_fifo_ctrl_p, CORE1_in_fifo_data_p}),
      
      .match_o          (CORE1_worm_match)
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
      .MATCHER_SIGNAL_ADDR_BIT            (MATCHER_SIGNAL_ADDR_BIT),
      .SHAMT_WIDTH                        (SHAMT_WIDTH),
      .THREAD0_STATE                      (THREAD0_STATE),
      .THREAD1_STATE                      (THREAD1_STATE),
      .THREAD2_STATE                      (THREAD2_STATE),
      .THREAD3_STATE                      (THREAD3_STATE),
      .THREAD0_START_ADDR                 (CORE0_THREAD0_START_ADDR),
      .THREAD1_START_ADDR                 (CORE0_THREAD1_START_ADDR),
      .THREAD2_START_ADDR                 (CORE0_THREAD2_START_ADDR),
      .THREAD3_START_ADDR                 (CORE0_THREAD3_START_ADDR)
   ) sc0 (
      .reset                      (reset),
      .mem_mem_write_en_out       (CORE0_mem_mem_write_en_w),
      .mem_r2_out_out             (CORE0_mem_r2_out_w),
      .mem_alu_out_out            (CORE0_mem_alu_out_w),
      .bmem_dout_in               (CORE0_bmem_dout_w[PROC_DATA_INTERFACE_HIGHBIT:PROC_DATA_INTERFACE_LOWBIT]),
      .state_status_in            (CORE0_state),
      .bmemreadptr_in             (CORE0_bmemasfifo_readptr_r),
      .mem_pc_carry_baggage_w     (CORE0_mem_pc_carry_baggage_w),
      .mem_thread_id_w            (CORE0_mem_thread_id_w),
      .matcher_in                 (CORE0_worm_match),
      .clk                        (clk)
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
      .MATCHER_SIGNAL_ADDR_BIT            (MATCHER_SIGNAL_ADDR_BIT),
      .SHAMT_WIDTH                        (SHAMT_WIDTH),
      .THREAD0_STATE                      (THREAD0_STATE),
      .THREAD1_STATE                      (THREAD1_STATE),
      .THREAD2_STATE                      (THREAD2_STATE),
      .THREAD3_STATE                      (THREAD3_STATE),
      .THREAD0_START_ADDR                 (CORE1_THREAD0_START_ADDR),
      .THREAD1_START_ADDR                 (CORE1_THREAD1_START_ADDR),
      .THREAD2_START_ADDR                 (CORE1_THREAD2_START_ADDR),
      .THREAD3_START_ADDR                 (CORE1_THREAD3_START_ADDR)
   ) sc1 (
      .reset                      (reset),
      .mem_mem_write_en_out       (CORE1_mem_mem_write_en_w),
      .mem_r2_out_out             (CORE1_mem_r2_out_w),
      .mem_alu_out_out            (CORE1_mem_alu_out_w),
      .bmem_dout_in               (CORE1_bmem_dout_w[PROC_DATA_INTERFACE_HIGHBIT:PROC_DATA_INTERFACE_LOWBIT]),
      .state_status_in            (CORE1_state),
      .bmemreadptr_in             (CORE1_bmemasfifo_readptr_r),
      .mem_pc_carry_baggage_w     (CORE1_mem_pc_carry_baggage_w),
      .mem_thread_id_w            (CORE1_mem_thread_id_w),
      .matcher_in                 (CORE1_worm_match),
      .clk                        (clk)
   );

   generic_regs
   #( 
      .UDP_REG_SRC_WIDTH   (UDP_REG_SRC_WIDTH),
      .TAG                 (`IDS_BLOCK_ADDR),          // Tag -- eg. MODULE_TAG
      .REG_ADDR_WIDTH      (`IDS_REG_ADDR_WIDTH),     // Width of block addresses -- eg. MODULE_REG_ADDR_WIDTH
      .NUM_COUNTERS        (0),                 // Number of counters
      .NUM_SOFTWARE_REGS   (2),                 // Number of sw regs
      .NUM_HARDWARE_REGS   (12)                  // Number of hw regs
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
      .hardware_regs    ({hw_data11, hw_data10, hw_data9, hw_data8, hw_data7, hw_data6, hw_data5, hw_data4, hw_data3, hw_data2, hw_data1, hw_data0}),

      .clk              (clk),
      .reset            (reset)
    );

   logic_thief 
   #(.INSTMEM_LOG2_DEEP       (INSTMEM_LOG2_DEEP),
     .CTRL_WIDTH              (CTRL_WIDTH),
     .DATA_WIDTH              (DATA_WIDTH),
     .LOGTHIEF_DATA_WIDTH     (LOGTHIEF_DATA_WIDTH),
     .BMEM_LOG2_DEEP          (BMEM_LOG2_DEEP),
     .LOGTHIEF_LOG2_DEEP      (LOGTHIEF_LOG2_DEEP)
   ) lt0(
      .probe_CORE0_wrdata_i            (CORE0_bmem_din_w),
      .probe_CORE1_wrdata_i            (CORE1_bmem_din_w),
      .probe_CORE0_wraddr_i            (CORE0_bmem_write_addr_w), 
      .probe_CORE1_wraddr_i            (CORE1_bmem_write_addr_w), 
      .probe_CORE0_wea_i               (CORE0_bmem_wr_en_w),
      .probe_CORE1_wea_i               (CORE1_bmem_wr_en_w),
      .probe_CORE0_rdata_i             (CORE0_bmem_dout_w),
      .probe_CORE1_rdata_i             (CORE1_bmem_dout_w),
      .probe_CORE0_rdaddr_i            (CORE0_bmem_read_addr_w),
      .probe_CORE1_rdaddr_i            (CORE1_bmem_read_addr_w),
      .probe_CORE0_state_i             (CORE0_state),
      .probe_CORE1_state_i             (CORE1_state),
      .probe_CORE0_mem_pc_i            (CORE0_mem_pc_carry_baggage_w),
      .probe_CORE1_mem_pc_i            (CORE1_mem_pc_carry_baggage_w),
      .probe_CORE0_mem_thread_id_i     (CORE0_mem_thread_id_w),
      .probe_CORE1_mem_thread_id_i     (CORE1_mem_thread_id_w),
      //mem_thread_id_i  ({1'b0, matcher_match}),
      .probe_current_writer_i          (current_writer_r),
      .probe_change_writer_i           (change_writer_w),
      .probe_fsmgenwren_i              (fsmgenerated_wr_en_w),
      .probe_ftsfrden_i                (ftsf_rd_en_w),
      .probe_CORE0_ftsfrden_i          (CORE0_ftsf_rd_en_w),
      .probe_CORE1_ftsfrden_i          (CORE1_ftsf_rd_en_w),
      .probe_current_reader_i          (current_reader_r),
      .probe_change_reader_i           (change_reader_w),
      .probe_outwr_i                   (out_wr),
      .cmd_i            (sw_cmd_w),
      .addr_i           (sw_readaddr_w),
      // .mem_thread_id_i  (mem_thread_id_w),
      .CORE0_data_o           (CORE0_logicthief_dataout_w),
      .CORE1_data_o           (CORE1_logicthief_dataout_w),
      .clk_i            (clk)
   );

   data_memory
       XLXI_14 (
      .addra      (CORE0_bmem_write_addr_w),
      .addrb      (CORE0_bmem_read_addr_w),
      .clka       (clk),
      .clkb       (clk),
      //.dina       (din_bmem_r),
      //.dina       ({in_fifo_ctrl_p, in_fifo_data_p}),
      .dina       (CORE0_bmem_din_w),
      //.wea        (fifowrite_bmem_r),
      .wea        (CORE0_bmem_wr_en_w),
      //.doutb      (bmem_dout_w)
      .doutb      (CORE0_bmem_dout_w)
      );

   data_memory
       XLXI_15 (
      .addra      (CORE1_bmem_write_addr_w),
      .addrb      (CORE1_bmem_read_addr_w),
      .clka       (clk),
      .clkb       (clk),
      //.dina       (din_bmem_r),
      //.dina       ({in_fifo_ctrl_p, in_fifo_data_p}),
      .dina       (CORE1_bmem_din_w),
      //.wea        (fifowrite_bmem_r),
      .wea        (CORE1_bmem_wr_en_w),
      //.doutb      (bmem_dout_w)
      .doutb      (CORE1_bmem_dout_w)
      );
   //------------------------- Logic-------------------------------
   // accelerator signals
  assign CORE0_accept = (!CORE0_ftsf_empty_w && out_rdy);
  assign CORE0_reset = (reset || CORE0_state_next == READ_READY);
  assign CORE1_accept = (!CORE1_ftsf_empty_w && out_rdy);
  assign CORE1_reset = (reset || CORE1_state_next == READ_READY);

   // interface signals with upstream and downstream
   assign fsmgenerated_wr_en_w = in_wr && (bmem_CORE0_writing_w || bmem_CORE1_writing_w);
   //assign in_rdy     = !ftsf_nearly_full & (!(state_next == CPU_PROCESS | state_next == READ_READY));
   assign in_rdy     = !ftsf_nearly_full && (bmem_CORE0_writing_w || bmem_CORE1_writing_w);
   //assign out_wr_w   = out_rdy & (bmemasfifo_readptr_r != bmemasfifo_writeptr_r) & (state == READ_READY);
   assign CORE0_out_wr_w   = out_rdy & (CORE0_bmemasfifo_readptr_r != CORE0_bmemasfifo_writeptr_r) & (CORE0_state == READ_READY) & (current_reader_r==CORE0) ;
   assign CORE1_out_wr_w   = out_rdy & (CORE1_bmemasfifo_readptr_r != CORE1_bmemasfifo_writeptr_r) & (CORE1_state == READ_READY) & (current_reader_r==CORE1) ;
   //assign out_wr     = out_wr_r;
   assign out_wr     = CORE0_out_wr_r | CORE1_out_wr_r;
   assign CORE0_ftsf_empty_w = current_writer_r==CORE0 ? ftsf_empty_w : 1'b1;
   assign CORE1_ftsf_empty_w = current_writer_r==CORE1 ? ftsf_empty_w : 1'b1;
   assign CORE0_in_fifo_ctrl_p = current_writer_r==CORE0 ? in_fifo_ctrl_p : {CTRL_WIDTH{1'b0}};
   assign CORE1_in_fifo_ctrl_p = current_writer_r==CORE1 ? in_fifo_ctrl_p : {CTRL_WIDTH{1'b0}};
   assign CORE0_in_fifo_data_p = current_writer_r==CORE0 ? in_fifo_data_p : {DATA_WIDTH{1'b0}};
   assign CORE1_in_fifo_data_p = current_writer_r==CORE1 ? in_fifo_data_p : {DATA_WIDTH{1'b0}};
   assign ftsf_rd_en_w = current_writer_r==CORE0 ? CORE0_ftsf_rd_en_w : (current_writer_r==CORE1 ? CORE1_ftsf_rd_en_w: 1'b0);
   assign augment_proc_writedata_w  = {CTRL_WIDTH{1'b0}};

   // muxes for allowing network and CPU to use same datamem
   // NOTE: cpu_active_r goes LOW in the same clock cycle as state becomes
   // READ_READY, bmemasfifo_readptr_r is incremented only when out_wr_w is
   // HIGH
   // POTENTIAL PROBLEM: when CPU is writing to special register, should we
   // disable bmem_wr_en_w?
   assign CORE0_bmem_wr_en_w = CORE0_cpu_active_r == 1'b1 ? CORE0_mem_mem_write_en_w & ~CORE0_mem_alu_out_w[CPU_JOB_STATUS_ADDR_BIT] :  CORE0_in_fifo_wr_messenger_next;
   assign CORE1_bmem_wr_en_w = CORE1_cpu_active_r == 1'b1 ? CORE1_mem_mem_write_en_w & ~CORE1_mem_alu_out_w[CPU_JOB_STATUS_ADDR_BIT] :  CORE1_in_fifo_wr_messenger_next;
   assign CORE0_bmem_write_addr_w = CORE0_cpu_active_r == 1'b1 ? CORE0_mem_alu_out_w[BMEM_LOG2_DEEP-1:0] : CORE0_bmemasfifo_writeptr_r;
   assign CORE1_bmem_write_addr_w = CORE1_cpu_active_r == 1'b1 ? CORE1_mem_alu_out_w[BMEM_LOG2_DEEP-1:0] : CORE1_bmemasfifo_writeptr_r;
   assign CORE0_bmem_read_addr_w = CORE0_cpu_active_r == 1'b1 ? CORE0_mem_alu_out_w[BMEM_LOG2_DEEP-1:0] : CORE0_bmemasfifo_readptr_r;
   assign CORE1_bmem_read_addr_w = CORE1_cpu_active_r == 1'b1 ? CORE1_mem_alu_out_w[BMEM_LOG2_DEEP-1:0] : CORE1_bmemasfifo_readptr_r;
   assign CORE0_bmem_din_w = CORE0_cpu_active_r == 1'b1 ? ({augment_proc_writedata_w, CORE0_mem_r2_out_w}) : ({CORE0_in_fifo_ctrl_p, CORE0_in_fifo_data_p});
   assign CORE1_bmem_din_w = CORE1_cpu_active_r == 1'b1 ? ({augment_proc_writedata_w, CORE1_mem_r2_out_w}) : ({CORE1_in_fifo_ctrl_p, CORE1_in_fifo_data_p});
   // HACK 0: 
   //assign bmem_din_w = cpu_active_r == 1'b1 ? ({sync_data_r[CTRL_WIDTH+DATA_WIDTH-1:PROC_DATA_INTERFACE_HIGHBIT+1], mem_r2_out_w, sync_data_r[PROC_DATA_INTERFACE_LOWBIT-1:0]}) : ({in_fifo_ctrl_p, in_fifo_data_p});
   //assign {out_ctrl, out_data} = bmem_dout_w;
   assign {out_ctrl, out_data} = CORE1_out_wr_r==1'b1 ? CORE1_bmem_dout_w : CORE0_bmem_dout_w;
   assign CORE0_cpu_job_complete_w = CORE0_mem_mem_write_en_w & CORE0_mem_alu_out_w[CPU_JOB_STATUS_ADDR_BIT];
   assign CORE1_cpu_job_complete_w = CORE1_mem_mem_write_en_w & CORE1_mem_alu_out_w[CPU_JOB_STATUS_ADDR_BIT];

   // reading logicthief data to hardware registers
   always @(*) begin
      {hw_data5, hw_data4, hw_data3, hw_data2, hw_data1, hw_data0} = CORE0_logicthief_dataout_w;
      {hw_data11, hw_data10, hw_data9, hw_data8, hw_data7, hw_data6} = CORE1_logicthief_dataout_w;
   end
  
   // CORE0 state machine 
   always @(*) begin
      //state_next = state;
      CORE0_ftsf_rd_en_w = 0;
      CORE0_in_fifo_wr_messenger_next = 0;
      CORE0_cpu_active_next = CORE0_cpu_active_r;
      
      case(CORE0_state)
         START: begin
            if (!CORE0_ftsf_empty_w && out_rdy) begin
               CORE0_ftsf_rd_en_w = 1;
               if (CORE0_in_fifo_ctrl_p != 0) begin
                  CORE0_in_fifo_wr_messenger_next = 1;
                  CORE0_state_next = PAYLOAD;
               end else begin
                  CORE0_state_next = START;
               end
            end else begin
                  CORE0_state_next = START;
            end
         end   // end of START State
         PAYLOAD: begin
            if (!CORE0_ftsf_empty_w && out_rdy) begin
               CORE0_ftsf_rd_en_w = 1;
               CORE0_in_fifo_wr_messenger_next = 1;
               if (CORE0_in_fifo_ctrl_p != 0) begin
                  CORE0_state_next = CPU_PROCESS;
               end
               else begin
                  CORE0_state_next = PAYLOAD;
               end
            end else begin
               CORE0_state_next = PAYLOAD;
            end
         end   // end of PAYLOAD state
         CPU_PROCESS: begin
            CORE0_ftsf_rd_en_w = 0;
            CORE0_cpu_active_next = 1'b1;
            if (CORE0_cpu_job_complete_w) begin
               CORE0_cpu_active_next = 1'b0;
               CORE0_state_next = READ_READY;
            end else begin
               CORE0_state_next = CPU_PROCESS;
            end
         end   // end of CPU_PROCESS state
         READ_READY: begin
            if (CORE0_bmemasfifo_readptr_r == CORE0_bmemasfifo_writeptr_r) begin
               CORE0_state_next = START;
            end   
            else begin
               CORE0_state_next = READ_READY;
            end
         end
      endcase // case(state)
   end // always @ (*)

   // CORE1 state machine 
   always @(*) begin
      //state_next = state;
      CORE1_ftsf_rd_en_w = 0;
      CORE1_in_fifo_wr_messenger_next = 0;
      CORE1_cpu_active_next = CORE1_cpu_active_r;
      
      case(CORE1_state)
         START: begin
            if (!CORE1_ftsf_empty_w && out_rdy) begin
               CORE1_ftsf_rd_en_w = 1;
               if (CORE1_in_fifo_ctrl_p != 0) begin
                  CORE1_in_fifo_wr_messenger_next = 1;
                  CORE1_state_next = PAYLOAD;
               end else begin
                  CORE1_state_next = START;
               end
            end else begin
                  CORE1_state_next = START;
            end
         end   // end of START State
         PAYLOAD: begin
            if (!CORE1_ftsf_empty_w && out_rdy) begin
               CORE1_ftsf_rd_en_w = 1;
               CORE1_in_fifo_wr_messenger_next = 1;
               if (CORE1_in_fifo_ctrl_p != 0) begin
                  CORE1_state_next = CPU_PROCESS;
               end
               else begin
                  CORE1_state_next = PAYLOAD;
               end
            end else begin
               CORE1_state_next = PAYLOAD;
            end
         end   // end of PAYLOAD state
         CPU_PROCESS: begin
            CORE1_ftsf_rd_en_w = 0;
            CORE1_cpu_active_next = 1'b1;
            if (CORE1_cpu_job_complete_w) begin
               CORE1_cpu_active_next = 1'b0;
               CORE1_state_next = READ_READY;
            end else begin
               CORE1_state_next = CPU_PROCESS;
            end
         end   // end of CPU_PROCESS state
         READ_READY: begin
            if (CORE1_bmemasfifo_readptr_r == CORE1_bmemasfifo_writeptr_r) begin
               CORE1_state_next = START;
            end   
            else begin
               CORE1_state_next = READ_READY;
            end
         end
      endcase // case(state)
   end // always @ (*)
   
   always @(posedge clk) begin
      if(reset) begin
         //matches <= 0;
         CORE0_state                   <= START;
         CORE0_cpu_active_r            <= 1'b0;
         CORE1_state                   <= START;
         CORE1_cpu_active_r            <= 1'b0;
      end
      else begin
         CORE0_state                   <= CORE0_state_next;
         CORE0_cpu_active_r            <= CORE0_cpu_active_next;
         CORE1_state                   <= CORE1_state_next;
         CORE1_cpu_active_r            <= CORE1_cpu_active_next;
      end // else: !if(reset)
   end // always @ (posedge clk)   
   
   // BRAM READ WRITE FUNCTIONALITY INTEGRATION
   always @(posedge clk) begin
      if (reset) begin
          CORE0_bmemasfifo_writeptr_r     <= {BMEM_LOG2_DEEP{1'b0}};
          CORE0_bmemasfifo_readptr_r      <= {BMEM_LOG2_DEEP{1'b0}};
          CORE1_bmemasfifo_writeptr_r     <= {BMEM_LOG2_DEEP{1'b0}};
          CORE1_bmemasfifo_readptr_r      <= {BMEM_LOG2_DEEP{1'b0}};
          //out_wr_r                  <= 1'b0;
          CORE0_out_wr_r                  <= 1'b0;
          CORE1_out_wr_r                  <= 1'b0;
      end
      else begin
          if (CORE0_in_fifo_wr_messenger_next) begin
             CORE0_bmemasfifo_writeptr_r     <= CORE0_bmemasfifo_writeptr_r + 1;
          end
          if (CORE1_in_fifo_wr_messenger_next) begin
             CORE1_bmemasfifo_writeptr_r     <= CORE1_bmemasfifo_writeptr_r + 1;
          end
          //out_wr_r     <= out_wr_w;
          CORE0_out_wr_r                     <= CORE0_out_wr_w;
          CORE1_out_wr_r                     <= CORE1_out_wr_w;
         if (CORE0_out_wr_w) begin
            CORE0_bmemasfifo_readptr_r       <= CORE0_bmemasfifo_readptr_r + 1;
         end
         if (CORE1_out_wr_w) begin
            CORE1_bmemasfifo_readptr_r       <= CORE1_bmemasfifo_readptr_r + 1;
         end
      end
   end   // always block
   
   // CORE SELECTOR logic
   assign bmem_CORE0_writing_w = (current_writer_r == CORE0) && ((CORE0_state == START) || (CORE0_state == PAYLOAD));   
   assign bmem_CORE1_writing_w = (current_writer_r == CORE1) && ((CORE1_state == START) || (CORE1_state == PAYLOAD));   
   assign change_writer_w = ((current_writer_r==CORE0) && (bmem_CORE0_writing_w==1'b0) && (bmem_CORE0_writing_r==1'b1)) || ((current_writer_r==CORE1) && (bmem_CORE1_writing_w==1'b0) && (bmem_CORE1_writing_r==1'b1));
   assign bmem_CORE0_reading_w = (current_reader_r==CORE0) && (CORE0_state==READ_READY);
   assign bmem_CORE1_reading_w = (current_reader_r==CORE1) && (CORE1_state==READ_READY);
   assign change_reader_w = (current_reader_r==CORE0 && bmem_CORE0_reading_w==1'b0 && bmem_CORE0_reading_r==1'b1) || (current_reader_r==CORE1 && bmem_CORE1_reading_w==1'b0 && bmem_CORE1_reading_r==1'b1);
  
   // writer into changing logic
   always @(*) begin
      next_writer = current_writer_r;
      if (change_writer_w) begin
         if (current_writer_r == CORE0) begin
            next_writer = CORE1;
         end
         else if (current_writer_r == CORE1) begin
            next_writer = CORE0;
         end
      end // if change_writer_w is HIGH
      else begin
         // if current writer is CORE0, but CORE0 is not in START or PAYLOAD
         // state and CORE1 is in START state, then make the next writer as CORE1
         // and vice-versa
         if (current_writer_r==CORE0 && CORE0_state!=START && CORE0_state!=PAYLOAD && CORE1_state==START) begin
            next_writer = CORE1;
         end 
         else if (current_writer_r==CORE1 && CORE1_state!=START && CORE1_state!=PAYLOAD && CORE0_state==START) begin
            next_writer = CORE0;
         end 
      end // if change_writer_w is LOW, but active core is not in START or PAYLOAD state
   end

   // reading from changing logic
   always @(*) begin
      next_reader = current_reader_r;
      if (change_reader_w) begin
         if (current_reader_r == CORE0) begin
            next_reader = CORE1;
         end
         if (current_reader_r == CORE1) begin
            next_reader = CORE0;
         end
      end
      else begin
         // if current_reader_r is CORE0, but CORE0 is not in READ_READY state
         // and CORE1 is in the READ_READY state, then chnage current_reader_r
         // to CORE1 and vice-versa
         if (current_reader_r==CORE0 && CORE0_state!=READ_READY && CORE1_state==READ_READY) begin
            next_reader = CORE1;
         end
         else if (current_reader_r==CORE1 && CORE1_state!=READ_READY && CORE0_state==READ_READY) begin
            next_reader = CORE0;
         end
      end // if change_reader_w is LOW, but active core is not in READ_READY state
   end

   always @(posedge clk) begin
      if (reset)  begin
         current_writer_r           <= CORE0;
         current_reader_r           <= CORE0;
         bmem_CORE0_writing_r       <= 1'b0;        
         bmem_CORE1_writing_r       <= 1'b0;        
         bmem_CORE0_reading_r       <= 1'b0;        
         bmem_CORE1_reading_r       <= 1'b0;        
      end   // end of reset
      else begin
         current_writer_r           <= next_writer;
         current_reader_r           <= next_reader;
         bmem_CORE0_writing_r       <= bmem_CORE0_writing_w;        
         bmem_CORE1_writing_r       <= bmem_CORE1_writing_w;        
         bmem_CORE0_reading_r       <= bmem_CORE0_reading_w;        
         bmem_CORE1_reading_r       <= bmem_CORE1_reading_w;        
      end   // else - if NOT reset
   end   // end of clocked block

endmodule 
