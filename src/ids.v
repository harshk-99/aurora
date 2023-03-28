`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// EARLY-BRANCH DESIGN 
// PARAMETERIZED
//////////////////////////////////////////////////////////////////////////////////

//`define UDP_REG_ADDR_WIDTH 16
//`define CPCI_NF2_DATA_WIDTH 16
//`define IDS_BLOCK_TAG 1
//`define IDS_REG_ADDR_WIDTH 16

module ids
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter UDP_REG_SRC_WIDTH = 2
    )
    (
      input [DATA_WIDTH-1:0]	in_data,
      input [CTRL_WIDTH-1:0]	in_ctrl,
      input                     in_wr,
      output	                in_rdy,

      output [DATA_WIDTH-1:0]	out_data,
      output [CTRL_WIDTH-1:0]	out_ctrl,
      output	                out_wr,
      input	                out_rdy,

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

   //wire rst_i;
   //wire clk_i;
   //
   //assign rst_i = reset;
   //assign clk_i = clk;

   //---------------------------------
   //wire rst;
   //assign rst =reset;
   // software registers
   wire [31:0]    sw_readaddr_w;
   wire [31:0]    sw_cmd;
   wire [31:0]    ids_cmd;
   
   // hardware registers
   reg   [31:0]      hw_data_ctrl;
   reg   [31:0]      hw_data_high;
   reg   [31:0]      hw_data_low;   


   //assign reg_req_out = reg_req_in; 
   //assign reg_ack_out = reg_ack_in; 
   //assign reg_rd_wr_L_out = reg_rd_wr_L_in;
   //assign reg_addr_out = reg_addr_in;
   //assign reg_data_out = reg_data_in; 
   //assign reg_src_out = reg_src_in;
   // local parameters
   parameter PROC_DATA_WIDTH              = 16;
   parameter PROC_REGFILE_LOG2_DEEP       = 5;
   parameter NUM_REGISTERS                = 32;
   parameter SRAM_LOG2_DEEP               = 8;
   parameter INSTMEM_LOG2_DEEP            = 8;
   localparam SRAM_DATA_WIDTH             = CTRL_WIDTH+DATA_WIDTH;
   parameter START                        = 3'b000;
   parameter HEADER                       = 3'b001; 
   parameter PAYLOAD                      = 3'b010;
   parameter READ_READY                   = 3'b011;
   parameter CPU_PROCESS                  = 3'b111;
   localparam STATEMACHINE_STATE_ADDR_BIT = 8;
   localparam READPTR_ADDR_BIT            = 9;
   localparam CPU_JOB_STATUS_ADDR_BIT     = 10; 
   localparam NUM_SPECIAL_REG             = 3;
   // THREADx_DONE means that state machine would check this specific address
   // bit to see if the specific bit has completed its opeartion
   // when all these bits are set to 1, then all threads have finished their
   // respective operation
   localparam THREAD0_BIT_POS          = 0;
   localparam THREAD1_BIT_POS          = 1;
   localparam THREAD2_BIT_POS          = 2;
   localparam THREAD3_BIT_POS          = 3;
   localparam THREAD0_STATE            = 2'b00;
   localparam THREAD1_STATE            = 2'b01;
   localparam THREAD2_STATE            = 2'b10;
   localparam THREAD3_STATE            = 2'b11;
   localparam THREAD0_START_ADDR       = 8'd0;
   localparam THREAD1_START_ADDR       = 8'd30;
   localparam THREAD2_START_ADDR       = 8'd59;
   localparam THREAD3_START_ADDR       = 8'd89;
    
   
   // latch 1 cycle to meet FSM next state logic
   // Do we need to further latch the input, even before generating pocket tSM next state? reg in_wr_reg;
   reg in_wr_reg;
   reg [CTRL_WIDTH-1:0] in_ctrl_reg;
   reg [DATA_WIDTH-1:0] in_data_reg;

   //FSM reg
   reg [2:0] state, state_next;
   reg end_of_pkt, end_of_pkt_next; 
   reg begin_pkt, begin_pkt_next;
   
   //Switching Registers 
   // Why do we need cpu_mode_r, since cpu_mode_next itself is a register
   reg cpu_mode_r, cpu_mode_next_r, stop_in_rdy; 
   wire                    process_done; 
   reg [3:0]               handshake_thread_status_r;
   
   reg [SRAM_LOG2_DEEP-1:0] headptr, readptr, writeptr_r;
   reg [SRAM_LOG2_DEEP:0] depth; 
   // fiforead goes high as soon as state changes to READ_READY, this allows read_ptr to be deposited with new value
   // Since cpu_mode_next_r goes LOW at the posedge clk when process_complete is written into
   // making cpu_mode LOW in the next clock
   // cpu_mode_r LOW means out_wr is asserted HIGH immmediately
   // headptr, writeptr_r, readptr, depth can be incremented
   // fifo_sram_waddr, fifo_sram_raddr, din_fifo_sram, fifo_sram_wen_w start listening to fifo operations
   reg out_wr_next_r;   // there is one clock delay between when the fiforead is asserted HIGH and when data appears on the Bus, out_wr_next_r helps make out_wr high when valid data appears on the bus

   ////////////////////////////////////////////////
   // FIFO SRAM OPERATIONS
   ////////////////////////////////////////////////
   wire full            = (depth == 9'h100);  //size 
   wire empty           = (depth == 9'h0);
   //wire fiforead  = (state == READ_READY) & out_rdy & (headptr != readptr) & (writeptr_r != readptr) & ~empty; 
   wire fiforead        = (state == READ_READY) & out_rdy & (headptr != readptr) & ~empty; 
   wire fifowrite_w     = in_wr_reg & ~full & ~process_done; 
   // This is to ensure that downstream doesn't reads till the time CPU is processing
   assign out_wr        = ~cpu_mode_r & out_wr_next_r; //add this 
   always @(posedge clk) begin 
      if (reset) begin
         headptr           <= 8'b0; 
         readptr           <= 8'b0; 
         writeptr_r        <= 8'b0; 
         out_wr_next_r     <= 1'b0; 
         depth             <= 9'b0;
      end
      else if (~cpu_mode_r) begin
         out_wr_next_r     <= fiforead;
         if (begin_pkt | end_of_pkt)   
            headptr        <= writeptr_r; 
         if (fifowrite_w)
            writeptr_r     <= writeptr_r + 1;
         if (fiforead)
            readptr        <= readptr + 1;
         if (fifowrite_w & ~fiforead)
            depth          <= depth + 1;
         if (~fifowrite_w & fiforead)
            depth          <= depth - 1;
      end
   end
 

   //////////////////////////////////////
   //mux to control the mode 
   //////////////////////////////////////
   reg [PROC_DATA_WIDTH-1:0]           cpu_din; //cpu data in
   reg                                 cpu_wen; //cpu write enable 
   // 10:0 = 11 bits is SUM of SRAM_LOG2_DEEP + 3 Special Registers
   // cpu_dadder[8]                           read state machine's 'state' variable
   // cpu_dadder[READPTR_ADDR_BIT]            read 'readptr'
   // cpu_dadder[CPU_JOB_STATUS_ADDR_BIT]     write the thread status to 'process_done' register
   reg [SRAM_LOG2_DEEP + NUM_SPECIAL_REG-1:0]       cpu_daddr; 
   wire [SRAM_LOG2_DEEP-1:0]           fifo_sram_write_addr;
   wire [SRAM_LOG2_DEEP-1:0]           fifo_sram_read_addr;
   wire [SRAM_DATA_WIDTH-1:0]          din_fifo_sram;
   wire [SRAM_DATA_WIDTH-1:0]          dout_fifo_sram;  //output from fifo_sram
   wire                                fifo_sram_wen_w; 

   assign fifo_sram_write_addr      = cpu_mode_r ? cpu_daddr[SRAM_LOG2_DEEP-1:0] : writeptr_r;
   assign fifo_sram_read_addr       = cpu_mode_r ? cpu_daddr[SRAM_LOG2_DEEP-1:0] : readptr;
   // our CPU data path is connected to bits 63:48 of SRAM
   //wire [SRAM_DATA_WIDTH-1:0]          din_fifo_sram = cpu_mode_r ? {temp_data_oneclkdel[71:64],cpu_din,temp_data_oneclkdel[47:0]} : {in_ctrl_reg, in_data_reg};
   assign din_fifo_sram             = cpu_mode_r ? {{8{1'b0}},cpu_din, {48{1'b0}}} : {in_ctrl_reg, in_data_reg};
   
   // inside CPU mode as well, WEN should be asserted only if we are NOT
   // writing to special registers
   assign fifo_sram_wen_w           = cpu_mode_r ? (cpu_wen & ~cpu_daddr[CPU_JOB_STATUS_ADDR_BIT]) : fifowrite_w; 
   assign {out_ctrl, out_data}      = dout_fifo_sram;
   
   //output to cpu  written on the bottom
   //if 
   //else 
   //    dout_fifo_sram[some 16 bits]

   //cpu to process complete 
   //[8] make process complete to 1 
   //assign process_done = cpu_wen & cpu_daddr[8];

   //////////////////////////////////////
   // DATA PATH
   //////////////////////////////////////

   // local variables
   // IF stage wires and regs
   //wire [INSTMEM_LOG2_DEEP-1:0]          hz_pc_w;
   //wire                                  wb_ff_w;
   //reg                                   thread0_wb_ff_r;
   //reg                                   thread1_wb_ff_r;
   //reg                                   thread2_wb_ff_r;
   //reg                                   thread3_wb_ff_r;
   wire [31:0]                           instr_w;
   wire [1:0]                            if_thread_id_w;
   reg [1:0]                             thread_state_r;
   wire [INSTMEM_LOG2_DEEP-1:0]          pc_current_w;
   reg  [INSTMEM_LOG2_DEEP-1:0]          thread0_pc_current_r;
   reg  [INSTMEM_LOG2_DEEP-1:0]          thread1_pc_current_r;
   reg  [INSTMEM_LOG2_DEEP-1:0]          thread2_pc_current_r;
   reg  [INSTMEM_LOG2_DEEP-1:0]          thread3_pc_current_r;
   //wire [PROC_DATA_WIDTH-1:0]            pc_next_address_w;
   reg [INSTMEM_LOG2_DEEP-1:0]            thread0_pc_next_address_r;
   reg [INSTMEM_LOG2_DEEP-1:0]            thread1_pc_next_address_r;
   reg [INSTMEM_LOG2_DEEP-1:0]            thread2_pc_next_address_r;
   reg [INSTMEM_LOG2_DEEP-1:0]            thread3_pc_next_address_r;
   //wire [INSTMEM_LOG2_DEEP-1:0]          pc_plus_one_w;
   reg [INSTMEM_LOG2_DEEP-1:0]            thread0_pc_plus_one_r;
   reg [INSTMEM_LOG2_DEEP-1:0]            thread1_pc_plus_one_r;
   reg [INSTMEM_LOG2_DEEP-1:0]            thread2_pc_plus_one_r;
   reg [INSTMEM_LOG2_DEEP-1:0]            thread3_pc_plus_one_r;

   // ID stage wires and regs
    //wire                mem_read_w;
   wire [1:0]                            id_thread_id_w;
   wire                                  mem_to_reg_w;
   wire                                  mem_write_w;
   wire                                  reg_write_w;
   wire                                  immd_w;
   wire                                  load_w;
   wire                                  store_w;
   wire                                  jal_w;
   //wire                jalr_w;
   wire                                  cu_branch_out_w;
   wire [PROC_REGFILE_LOG2_DEEP-1:0]     reg_read_addr1_w;
   wire [PROC_REGFILE_LOG2_DEEP-1:0]     reg_read_addr2_w;
   wire [PROC_REGFILE_LOG2_DEEP-1:0]     reg_write_addr_w;
   wire [PROC_DATA_WIDTH-1:0]            reg_write_data_w;
   wire [PROC_DATA_WIDTH-1:0]            reg_read_data1_w;
   wire [PROC_DATA_WIDTH-1:0]            reg_read_data2_w;
   wire [PROC_DATA_WIDTH-1:0]            sign_ext_w;
   wire [PROC_DATA_WIDTH-1:0]            branch_sign_ext_w;
   wire [PROC_DATA_WIDTH-1:0]            sign_ext_jal_w;
   wire [PROC_DATA_WIDTH-1:0]            sign_ext_j_b_w;
   wire [PROC_DATA_WIDTH-1:0]            control_inst_target_address_w;
   // wire [INSTMEM_LOG2_DEEP-1:0]          id_pc1_w;
   wire                                  rs2_swch_w;
   wire                                  ex_rs2_swch_w;
   wire [PROC_DATA_WIDTH-1:0]            data2_w;
   wire [2:0]                            func3_intm_w;
   wire 				 func7_intm_w;
   wire [PROC_DATA_WIDTH-1:0]            alu_out_w;
   reg [PROC_DATA_WIDTH-1:0]             mem_read_data_r;
   //wire                                  hazard_w;
   wire [INSTMEM_LOG2_DEEP-1:0]          id_pc_carry_baggage_w;
   //wire                                  id_wb_ff_w;
   wire                                  true_branch_w;
   wire                                  branch_alu_w;
   //reg  [INSTMEM_LOG2_DEEP-1:0]          pc_prev_r;
   //wire                                  hz_reg_write_w;
   //wire                                  hz_mem_write_w;
   //wire                                  hz_mem_read_w;
   //wire                                  hz_mem_to_reg_w;
   //wire                                  hz_load_w;
   //wire                                  hz_store_w;
   //wire                                  hz_jalr_w;
   //wire                                  hz_branch_w;
   //wire [PROC_DATA_WIDTH-1:0]            adder1_w;
   wire [PROC_DATA_WIDTH-1:0]            sign_extender_selecter_w;

   // EX stage wires and regs
   wire [1:0]                            ex_thread_id_w;
   wire                                  ex_reg_write_w;
   wire                                  ex_mem_write_w;
   //wire                                  ex_mem_read_w;
   wire                                  ex_mem_to_reg_w;
   wire                                  ex_immd_w;
   wire                                  ex_load_w;
   wire                                  ex_store_w;
   wire [PROC_DATA_WIDTH-1:0]            ex_r1_out_w;
   wire [PROC_DATA_WIDTH-1:0]            ex_r2_out_w;
   wire [PROC_DATA_WIDTH-1:0]            ex_sign_ext_w;
   wire [PROC_REGFILE_LOG2_DEEP-1:0]     ex_reg_write_addr_w;
   wire [2:0]                            ex_func3_w;
   wire 				 ex_func7_w;
   //wire [PROC_DATA_WIDTH-1:0]            ex_data2_j;
   //wire                                  ex_jal_w;
   //wire                ex_hz_jalr_w;
   
   // MEM stage wires and regs
   wire [1:0]                            mem_thread_id_w;
   wire                                  mem_reg_write_w;
   wire                                  mem_mem_write_w;
   //wire                mem_mem_read_w;
   wire                                  mem_mem_to_reg_w;
   wire [PROC_DATA_WIDTH-1:0]            mem_alu_out_w;
   wire [PROC_DATA_WIDTH-1:0]            mem_r2_out_w;
   wire [PROC_REGFILE_LOG2_DEEP-1:0]     mem_reg_write_addr_w;

   // WB Stage wires and regs
   wire                                  wb_reg_write_w;
   wire                                  wb_mem_to_reg_w;
   wire [PROC_REGFILE_LOG2_DEEP-1:0]     wb_reg_write_addr_w;
   wire [PROC_DATA_WIDTH-1:0]            wb_alu_out_w;

   //----------------------------------------------------------------
   // IF Stage
   //----------------------------------------------------------------
   always @(posedge clk) begin
       if (reset == 1'b1) begin
           thread_state_r              <= THREAD0_STATE;
           thread0_pc_current_r        <= THREAD0_START_ADDR;
           thread1_pc_current_r        <= THREAD1_START_ADDR;
           thread2_pc_current_r        <= THREAD2_START_ADDR;
           thread3_pc_current_r        <= THREAD3_START_ADDR;
           thread0_pc_plus_one_r       <= THREAD0_START_ADDR;
           thread1_pc_plus_one_r       <= THREAD1_START_ADDR;
           thread2_pc_plus_one_r       <= THREAD2_START_ADDR;
           thread3_pc_plus_one_r       <= THREAD3_START_ADDR;
           thread0_pc_next_address_r   <= THREAD0_START_ADDR;
           thread1_pc_next_address_r   <= THREAD1_START_ADDR;
           thread2_pc_next_address_r   <= THREAD2_START_ADDR;
           thread3_pc_next_address_r   <= THREAD3_START_ADDR;
           //thread0_wb_ff_r             <= 1'b0;
           //thread1_wb_ff_r             <= 1'b0;
           //thread2_wb_ff_r             <= 1'b0;
           //thread3_wb_ff_r             <= 1'b0;
       end
       else begin
          case(thread_state_r)
               THREAD0_STATE: begin
                  thread_state_r             <= THREAD1_STATE;
                  thread0_pc_current_r       <= thread0_pc_current_r;
                  thread0_pc_plus_one_r      <= thread0_pc_current_r + 8'd1;
                  thread0_pc_next_address_r  <= thread0_pc_next_address_r;
                  thread1_pc_current_r       <= thread1_pc_next_address_r;
                  thread1_pc_plus_one_r      <= thread1_pc_plus_one_r;
                  thread1_pc_next_address_r  <= thread1_pc_next_address_r;
                  thread2_pc_current_r       <= thread2_pc_current_r;
                  thread2_pc_plus_one_r      <= thread2_pc_plus_one_r;
                  thread2_pc_next_address_r  <= thread2_pc_next_address_r;
                  thread3_pc_current_r       <= thread3_pc_current_r;
                  thread3_pc_plus_one_r      <= thread3_pc_plus_one_r;
                  thread3_pc_next_address_r  <= (true_branch_w || jal_w) ? control_inst_target_address_w: thread3_pc_plus_one_r;
                  //thread0_wb_ff_r            <= thread0_wb_ff_r;
                  //thread1_wb_ff_r            <= thread1_wb_ff_r;
                  //thread2_wb_ff_r            <= thread2_wb_ff_r;
                  //thread3_wb_ff_r            <= (jal_w || true_branch_w);
               end
               THREAD1_STATE: begin
                  thread_state_r             <= THREAD2_STATE;
                  thread0_pc_current_r       <= thread0_pc_current_r;
                  thread0_pc_plus_one_r      <= thread0_pc_plus_one_r;
                  thread0_pc_next_address_r  <= (true_branch_w || jal_w) ? control_inst_target_address_w: thread0_pc_plus_one_r;
                  thread1_pc_current_r       <= thread1_pc_current_r;
                  thread1_pc_plus_one_r      <= thread1_pc_current_r + 8'd1;
                  thread1_pc_next_address_r  <= thread1_pc_next_address_r;
                  thread2_pc_current_r       <= thread2_pc_next_address_r;
                  thread2_pc_plus_one_r      <= thread2_pc_plus_one_r;
                  thread2_pc_next_address_r  <= thread2_pc_next_address_r;
                  thread3_pc_current_r       <= thread3_pc_current_r;
                  thread3_pc_plus_one_r      <= thread3_pc_plus_one_r;
                  thread3_pc_next_address_r  <= thread3_pc_next_address_r;
                  //thread0_wb_ff_r            <= (jal_w || true_branch_w);
                  //thread1_wb_ff_r            <= thread1_wb_ff_r;
                  //thread2_wb_ff_r            <= thread2_wb_ff_r;
                  //thread3_wb_ff_r            <= thread3_wb_ff_r;
               end
               THREAD2_STATE: begin
                  thread_state_r             <= THREAD3_STATE;
                  thread0_pc_current_r       <= thread0_pc_current_r;
                  thread0_pc_plus_one_r      <= thread0_pc_plus_one_r;
                  thread0_pc_next_address_r  <= thread0_pc_next_address_r;
                  thread1_pc_current_r       <= thread1_pc_current_r;
                  thread1_pc_plus_one_r      <= thread1_pc_plus_one_r;
                  thread1_pc_next_address_r  <= (true_branch_w || jal_w) ? control_inst_target_address_w: thread1_pc_plus_one_r;
                  thread2_pc_current_r       <= thread2_pc_current_r;
                  thread2_pc_plus_one_r      <= thread2_pc_current_r + 8'd1;
                  thread2_pc_next_address_r  <= thread2_pc_next_address_r;
                  thread3_pc_current_r       <= thread3_pc_next_address_r;
                  thread3_pc_plus_one_r      <= thread3_pc_plus_one_r;
                  thread3_pc_next_address_r  <= thread3_pc_next_address_r;
                  //thread0_wb_ff_r            <= thread0_wb_ff_r;
                  //thread1_wb_ff_r            <= (jal_w || true_branch_w);
                  //thread2_wb_ff_r            <= thread2_wb_ff_r;
                  //thread3_wb_ff_r            <= thread3_wb_ff_r;
               end
               THREAD3_STATE: begin
                  thread_state_r             <= THREAD0_STATE;
                  thread0_pc_current_r       <= thread0_pc_next_address_r;
                  thread0_pc_plus_one_r      <= thread0_pc_plus_one_r;
                  thread0_pc_next_address_r  <= thread0_pc_next_address_r;
                  thread1_pc_current_r       <= thread1_pc_current_r;
                  thread1_pc_plus_one_r      <= thread1_pc_plus_one_r;
                  thread1_pc_next_address_r  <= thread1_pc_next_address_r;
                  thread2_pc_current_r       <= thread2_pc_current_r;
                  thread2_pc_plus_one_r      <= thread2_pc_plus_one_r;
                  thread2_pc_next_address_r  <= (true_branch_w || jal_w) ? control_inst_target_address_w: thread2_pc_plus_one_r;
                  thread3_pc_current_r       <= thread3_pc_current_r;
                  thread3_pc_plus_one_r      <= thread3_pc_current_r + 8'd1;
                  thread3_pc_next_address_r  <= thread3_pc_next_address_r;
                  //thread0_wb_ff_r            <= thread0_wb_ff_r;
                  //thread1_wb_ff_r            <= thread1_wb_ff_r;
                  //thread2_wb_ff_r            <= (jal_w || true_branch_w);
                  //thread3_wb_ff_r            <= thread3_wb_ff_r;
               end
          endcase
       end
   end
   assign pc_current_w     = thread_state_r==THREAD3_STATE ? thread3_pc_current_r : (thread_state_r==THREAD2_STATE ? thread2_pc_current_r : (thread_state_r==THREAD1_STATE ? thread1_pc_current_r : thread0_pc_current_r)) ;
   assign if_thread_id_w   = thread_state_r;

   //assign pc_plus_one_w = pc_current_r + 8'd1;
   //assign pc_next_address_w= ( true_branch_w || hz_jalr_w || jal_w) ? control_inst_target_address_w: pc_plus_one_w;
   
   //wristband flipflop logic
   //assign wb_ff_w= (jal_w || true_branch_w);
   //assign wb_ff_w     = thread_state_r==THREAD3_STATE ? thread3_wb_ff_r : (thread_state_r==THREAD2_STATE ? thread2_wb_ff_r : (thread_state_r==THREAD1_STATE ? thread1_wb_ff_r : thread0_wb_ff_r)) ;

   inst_memory im0 (.clk(clk), .addr(pc_current_w), .dout(instr_w));

   IFID #(.INSTMEM_LOG2_DEEP(INSTMEM_LOG2_DEEP))
     ifid0 (
       .CLK                (clk),           
       .RST                (reset),
       .PC_in              (pc_current_w),
       .PC_out             (id_pc_carry_baggage_w),
       //.hazard             (hazard_w),
       .thread_id_in       (if_thread_id_w),
       .hazard             (1'b0),
       .wb_ff_in           (1'b0),
       .wb_ff_out          (),
       .thread_id_out      (id_thread_id_w)
       //.incre_pc_in        (pc_plus_one_w),
       //.incre_pc_out       (id_pc1_w)
   );
   
   //----------------------------------------------------------------
   // ID Stage
   //----------------------------------------------------------------
   assign branch_sign_ext_w= {{5{instr_w[31]}},instr_w[7],instr_w[30:25], instr_w[11:8]};
   assign sign_ext_jal_w= {instr_w[14:12], instr_w[20], instr_w[30:21]};
   assign sign_ext_j_b_w= true_branch_w ? branch_sign_ext_w: sign_ext_w;   // this is a dead code
   //assign adder1_w= jalr_w ? reg_read_data1_w : id_pc_carry_baggage_w;
   assign sign_extender_selecter_w= jal_w ? sign_ext_jal_w: sign_ext_j_b_w;
   //assign control_inst_target_address_w= adder1_w + sign_extender_selecter_w;
   assign control_inst_target_address_w = id_pc_carry_baggage_w + sign_extender_selecter_w;
 
   br_alu #(.PROC_DATA_WIDTH(PROC_DATA_WIDTH)) 
     bru0 (
       .in_rs1             (reg_read_data1_w),
       .in_rs2             (reg_read_data2_w),
       //.in_funct3          (func3_intm_w),
       .out_branch         (branch_alu_w)
     );
   assign true_branch_w= branch_alu_w & cu_branch_out_w;

   //assign hz_pc_w = (hazard_w) ? pc_prev_r : pc_current_r;
   //assign hz_pc_w = pc_current_r;
   
   control_unit cu0 (
       .opcode_i       (instr_w[6:0]),
       .reset_i        (reset),
       .wb_ff_i        (1'b0),
       //.mem_read_i     (mem_read_w),
       .mem_to_reg_o   (mem_to_reg_w),
       .mem_write_o    (mem_write_w),
       .reg_write_o    (reg_write_w),
       .immd_o         (immd_w),
       .load_o         (load_w),
       .store_o        (store_w),
       .jal_o          (jal_w),
       //.jalr_i         (jalr_w),
       .branch_o       (cu_branch_out_w)  
   );

   assign reg_read_addr1_w = instr_w[18:15];
   assign reg_read_addr2_w = instr_w[23:20];       // ! Source register
   assign reg_write_addr_w = instr_w[10:7];
   //bubble injection logic into EX stage
   //assign {hz_reg_write_w, hz_mem_write_w, hz_branch_w} = (hazard_w == 1'b1) ? 3'b0 : {reg_write_w, mem_write_w, cu_branch_out_w};
	
    register_file #(.PROC_DATA_WIDTH(PROC_DATA_WIDTH),.PROC_REGFILE_LOG2_DEEP(PROC_REGFILE_LOG2_DEEP), .NUM_REGISTERS(NUM_REGISTERS))
      rf0(
            .clk_i          (clk),
            //.rst_i          (reset),
            .write_en_i     (wb_reg_write_w),
            .write_addr_i   (wb_reg_write_addr_w),
            .write_data_i   (reg_write_data_w),
            .read_addr1_i   (reg_read_addr1_w),
            .read_addr2_i   (reg_read_addr2_w),
            .read_data1_o   (reg_read_data1_w),
            .read_data2_o   (reg_read_data2_w)
         );

    //assign sign_ext_w = (load_w == 1'b1 || immd_w == 1'b1) ? {{52{instr_w[31]}}, instr_w[31:20]} : {{52{instr_w[31]}}, instr_w[31:25], instr_w[11:7]};
    // sign_ext_w selects between I-type instruction or S-type instruction
    assign sign_ext_w = (immd_w == 1'b1) ? {{4{instr_w[31]}}, instr_w[31:20]} : {{4{instr_w[31]}}, instr_w[31:25], instr_w[11:7]};
    assign func3_intm_w = (load_w == 1'b0 && store_w == 1'b0) ? instr_w[14:12] : 3'b000;
    assign func7_intm_w = (load_w == 1'b0 && store_w == 1'b0) ? instr_w[30] : 1'b0		;
    // control instructions mux logic for ID stage
	
    assign rs2_swch_w = ~(load_w | store_w | immd_w);

    IDEX #(.PROC_DATA_WIDTH(PROC_DATA_WIDTH), .PROC_REGFILE_LOG2_DEEP(PROC_REGFILE_LOG2_DEEP))
      idex0 (
        .WRegEn_in          (reg_write_w), 
        .WMemEn_in          (mem_write_w), 
        //.RMemEn_in          (hz_mem_read_w), 
	.rs2_swch_in        (rs2_swch_w), 
	.mem_to_reg_in      (	mem_to_reg_w),
        //.imm_in             (immd_w),
        //.load_in            (hz_load_w),
        //.store_in           (hz_store_w), 
        .R1out_in           (reg_read_data1_w), 
        .R2out_in           (reg_read_data2_w), 
        .WReg1_in           (reg_write_addr_w),
        .sign_ext_in        (sign_ext_w),
        .func3_in           (func3_intm_w), 
        .func7_in           (func7_intm_w), 
        .CLK                (clk),           
        .RST                (reset),
        .thread_id_in       (id_thread_id_w),
        //.jal_in             (jal_w),
        //.hz_jalr_in         (hz_jalr_w),
        .WRegEn_out         (ex_reg_write_w), 
        .WMemEn_out         (ex_mem_write_w), 
        //.RMemEn_out         (ex_mem_read_w), 
        .rs2_swch_out       (ex_rs2_swch_w),
        .mem_to_reg_out     (ex_mem_to_reg_w), 
        //.imm_out            (ex_immd_w),
        //.load_out           (ex_load_w),
        //.store_out          (ex_store_w), 
        .R1out_out          (ex_r1_out_w), 
        .R2out_out          (ex_r2_out_w),
        .sign_ext_out       (ex_sign_ext_w),
        .WReg1_out          (ex_reg_write_addr_w),
        .func3_out          (ex_func3_w),
        .func7_out          (ex_func7_w),
        .thread_id_out       (ex_thread_id_w)
        //.jal_out            (ex_jal_w),
        //.hz_jalr_out        (ex_hz_jalr_w)
    );

    assign data2_w = (ex_rs2_swch_w) ? ex_r2_out_w : ex_sign_ext_w;
    //assign data2_w = (ex_load_w == 1'b0 && ex_store_w == 1'b0 && ex_immd_w == 1'b0) ? ex_r2_out_w : ex_sign_ext_w;
    //assign ex_data2_j= (ex_jal_w || ex_hz_jalr_w) ? 64'h0000000000000000 : data2_w;

    alu_16_bit #(.PROC_DATA_WIDTH(PROC_DATA_WIDTH)) 
      alu0 
         (
         .in_rs1     (ex_r1_out_w),
         .in_rs2     (data2_w), 
         .in_funct3  (ex_func3_w),
         .in_funct7  (ex_func7_w),
         .out_rd     (alu_out_w)
         );

    EXMEM #(.PROC_DATA_WIDTH(PROC_DATA_WIDTH), .PROC_REGFILE_LOG2_DEEP(PROC_REGFILE_LOG2_DEEP))
      exmem0 (
        .clk_i              (clk),           
        .rst_i              (reset),           
        .reg_write_en_i     (ex_reg_write_w),  
        .mem_write_en_i     (ex_mem_write_w),          
        //.mem_read_en_i      (ex_mem_read_w), 
        .mem_to_reg_i       (ex_mem_to_reg_w),  
        .alu_i              (alu_out_w),           
        .reg_data2_i        (ex_r2_out_w),     
        .reg_write_addr_i   (ex_reg_write_addr_w),
        .thread_id_i        (ex_thread_id_w),
        .reg_write_en_o     (mem_reg_write_w),  
        .mem_write_en_o     (mem_mem_write_w),  
        //.mem_read_en_o      (mem_mem_read_w),   
        .mem_to_reg_o       (mem_mem_to_reg_w),    
        .alu_o              (mem_alu_out_w),           
        .reg_data2_o        (mem_r2_out_w),     
        .reg_write_addr_o   (mem_reg_write_addr_w), 
        .thread_id_o        (mem_thread_id_w)
    );

    //data_memory dm0 (.clka(clk), mem_alu_out_w[7:0], mem_r2_out_w, mem_mem_write_w, mem_read_data_w);
      //data_memory dm0 (.clka(clk), .clkb(clk),.addrb(mem_alu_out_w[7:0]),.addra(mem_alu_out_w[7:0]), .dina(mem_r2_out_w), .wea(mem_mem_write_w), .doutb(mem_read_data_w));
    data_memory dm0 (.clka(clk), .clkb(clk),.addrb(fifo_sram_read_addr),.addra(fifo_sram_write_addr), .dina(din_fifo_sram), .wea(fifo_sram_wen_w), .doutb(dout_fifo_sram));
		
    MEMWB #(.PROC_DATA_WIDTH(PROC_DATA_WIDTH), .PROC_REGFILE_LOG2_DEEP(PROC_REGFILE_LOG2_DEEP))
      memwb0 (
        .clk_i                  (clk),             
        .rst_i                  (reset),           
        .reg_write_en_i         (mem_reg_write_w),  
        .mem_to_reg_i           (mem_mem_to_reg_w),  
        .reg_write_addr_i       (mem_reg_write_addr_w),
        .alu_i                  (mem_alu_out_w),             
        .reg_write_en_o         (wb_reg_write_w),      
        .mem_to_reg_o           (wb_mem_to_reg_w),      
        .reg_write_addr_o       (wb_reg_write_addr_w),    
        .alu_o                  (wb_alu_out_w)
    );
   
   // if CPU wants to READ from FIFO, then first check if he wants to read some special register outside FIFO or from FIFO
   // if CPU is reading from Special Register i.e. wb_alu_out_w[8 or 9] is asserted HIGH, then pass the mem_read_data_r, else i.e. CPU is reading
   // from INSIDE the FIFO, then pass dout_fifo_sram wb_alu_out_w has the address that CPU intended to read in the PREVIOUS
   // clock cycle, I am using wb_alu_out_w address because when CPU wants to read from SRAM, there would be 1 clock delayed. in order to ensure that
   // reading operation is consistent no matter whether CPU reads from SRAM or Special register, we provide the state machine/readptr information when
   // actual instruction state is WB
   assign reg_write_data_w = (wb_mem_to_reg_w == 1'b1) ? (~(wb_alu_out_w[STATEMACHINE_STATE_ADDR_BIT] | wb_alu_out_w[READPTR_ADDR_BIT])? dout_fifo_sram[63:48] : mem_read_data_r) : wb_alu_out_w;
	 
   //--------------------------------- connections from cpu to sram ------------------------------
   always @(*) begin 
      cpu_din = mem_r2_out_w; 
      cpu_wen = mem_mem_write_w;  
      cpu_daddr = mem_alu_out_w[SRAM_LOG2_DEEP + NUM_SPECIAL_REG - 1:0];
   end 
	
   // Should we add that fact these instructions should be register writing instructions considering the fact
   // that we don't have memread signal
   // mem_read_data_r is reg-writing to incorporate the 
   // ASSUMPTION: that cpu_daddr would never use speical regiter bit position
   // during normal course of operations
   always @(posedge clk ) begin 
      if (cpu_daddr[STATEMACHINE_STATE_ADDR_BIT])
         mem_read_data_r = state;
      else if (cpu_daddr[READPTR_ADDR_BIT])
         mem_read_data_r = readptr;
   end 
   //-------------------------------------------------
   //----------------------------------- FSM -------------------------------------
   // need to relook at this logic, on whether stop_in_rdy should be logical OR or logical AND with depth
   // Secondly whether it should be clocked or combinational?
   // this is a signal to upstream module indicating readiness of IDS to accept the input
   // it is set to zero when State is CPU - this is part of the policy that we would first 
   // accept a packet from upsteram, then process it, followed by writing to downstream and
   // thereafter accept a new packet i.e. make in_rdy HIGH again
   assign in_rdy = ~stop_in_rdy & (depth < 9'h0fe) ;

   always @(*) begin 
      state_next = state;
      end_of_pkt_next = end_of_pkt;
      //cpu_mode_next_r = 1'b0;
      cpu_mode_next_r = cpu_mode_r;
      stop_in_rdy = 1'b0;
      if (in_wr && (depth <= 9'h0fe)&&((state != CPU_PROCESS) && (state != READ_READY))) begin
         case(state)
            START: begin 
	       //stop_in_rdy = 1'b0;
	       if (in_ctrl != 0) begin
	          //process_done = 1'b0;
                  state_next = HEADER;	
                  begin_pkt_next = 1'b1;
                  end_of_pkt_next = 1'b0;
               end
            end
            HEADER: begin
	       begin_pkt_next = 1'b0;
               if (in_ctrl == 0) begin
                  state_next = PAYLOAD;
               end
            end
            PAYLOAD: begin
               if (in_ctrl != 0) begin
                  end_of_pkt_next = 1'b1;
                  stop_in_rdy =1'b1;
	          // this is superflous process_done = 0 because we are already setting this to 0 in START state
		  //process_done = 1'b0;
		  state_next = CPU_PROCESS;						
               end
            end 
         endcase   
      end 
      else if (state == CPU_PROCESS ) begin
	 cpu_mode_next_r = 1'b1;
         stop_in_rdy = 1'b1; 
         if (process_done == 1'b1) begin
            //state_next = START;
	    state_next = READ_READY;
            //stop_in_rdy = 1'b0;
            cpu_mode_next_r = 1'b0;				
         end
      end
      else if (state == READ_READY) begin
         end_of_pkt_next = 1'b0;
	 stop_in_rdy = 1'b1;
	 if (headptr == readptr) begin
	 // this block ensures that when reading is compete, only then accept the new packet
	 //stop_in_rdy = 1'b0;
	 state_next = START;
	 end
      end
   end

   assign process_done = (handshake_thread_status_r == 4'b1111)? 1'b1: 1'b0;
   always @(posedge clk) begin 
      if (reset) begin 
         state                         <= START;
         begin_pkt                     <= 1'b0;
         end_of_pkt                    <= 1'b0;
         in_wr_reg                     <= 1'b0;
         in_ctrl_reg                   <= 8'b0;
         in_data_reg                   <= 64'b0;
         cpu_mode_r                    <= 1'b0; 
         handshake_thread_status_r     <= 4'b0;
         //process_done                  <= 4'd0;
      end 
      else begin 
         state <= state_next;
         begin_pkt <= begin_pkt_next;
         end_of_pkt <= end_of_pkt_next;
         in_wr_reg <= in_wr;
         in_ctrl_reg <= in_ctrl; 
         in_data_reg <= in_data;
         cpu_mode_r <= cpu_mode_next_r;
         if (state_next == START) begin
            handshake_thread_status_r     <= 4'b0;
            //process_done <= 4'd0;
         end
         if (cpu_wen & cpu_daddr[CPU_JOB_STATUS_ADDR_BIT]) begin
         // this logic ensures that when one bit is updated, other bit remains
         // unchanged
            if (mem_thread_id_w == 2'b11) begin
	       handshake_thread_status_r <= (handshake_thread_status_r & ~(1 << THREAD3_BIT_POS)) | (1'b1 << THREAD3_BIT_POS);
            end else if (mem_thread_id_w == 2'b10) begin
	       handshake_thread_status_r <= (handshake_thread_status_r & ~(1 << THREAD2_BIT_POS)) | (1'b1 << THREAD2_BIT_POS);
            end else if (mem_thread_id_w == 2'b01) begin
	       handshake_thread_status_r <= (handshake_thread_status_r & ~(1 << THREAD1_BIT_POS)) | (1'b1 << THREAD1_BIT_POS);
            end else begin
	       handshake_thread_status_r <= (handshake_thread_status_r & ~(1 << THREAD0_BIT_POS)) | (1'b1 << THREAD0_BIT_POS);
            end
         end
      end // end of else block
   end // end of always block


   //-------------- Logic Thief Integration
   wire     [95:0]   dataout_96bit_w;

   always @(*) begin
      {hw_data_ctrl, hw_data_high, hw_data_low} = {dataout_96bit_w};
   end

   logic_thief lt0(
      // inputs from fifo_sram
      .probe_data_i     (din_fifo_sram),
      .probe_addr_i     (fifo_sram_write_addr),
      .probe_wea_i      (fifo_sram_wen_w),
      // inputs from software registers
      .cmd_i            (sw_cmd),
      .addr_i           (sw_readaddr_w),
      .data_o           (dataout_96bit_w),
      .clk_i            (clk)
   );

   generic_regs
   #( 
      .UDP_REG_SRC_WIDTH   (UDP_REG_SRC_WIDTH),
      .TAG                 (`IDS_BLOCK_ADDR),          // Tag -- eg. MODULE_TAG
      .REG_ADDR_WIDTH      (`IDS_REG_ADDR_WIDTH),     // Width of block addresses -- eg. MODULE_REG_ADDR_WIDTH
      .NUM_COUNTERS        (0),                 // Number of counters
      .NUM_SOFTWARE_REGS   (2),                 // Number of sw regs
      .NUM_HARDWARE_REGS   (3)                  // Number of hw regs
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
      .software_regs    ({sw_readaddr_w,sw_cmd}),

      // --- HW regs interface
      .hardware_regs    ({hw_data_ctrl, hw_data_high, hw_data_low}),

      .clk              (clk),
      .reset            (reset)
    );

endmodule
