`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:59:34 03/09/2023 
// Design Name: 
// Module Name:    ids_sim 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
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
      input    in_wr,
      output	in_rdy,

      output [DATA_WIDTH-1:0]	out_data,
      output [CTRL_WIDTH-1:0]	out_ctrl,
      output	out_wr,
      input	   out_rdy,

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
   parameter PROC_DATA_WIDTH=64;
   parameter PROC_REGFILE_LOG2_DEEP=5;
   parameter SRAM_LOG2_DEEP=8;
   parameter INSTMEM_LOG2_DEEP=8;
   localparam SRAM_DATA_WIDTH=CTRL_WIDTH+DATA_WIDTH;
   parameter STATE_STATUS_ADDR_BIT=8;
   parameter READPTR_ADDR_BIT=9;
   // THREADx_DONE means that state machine would check this specific address
   // bit to see if the specific bit has completed its opeartion
   // when all these bits are set to 1, then all threads have finished their
   // respective operation
   parameter THREAD0_DONE=10;
   parameter THREAD1_DONE=11;
   parameter THREAD2_DONE=12;
   parameter THREAD3_DONE=13;
 
   
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
   reg cpu_mode_r, cpu_mode_next_r, stop_in_rdy, process_done; 
   
   parameter START = 3'b000;
   parameter HEADER = 3'b001; 
   parameter PAYLOAD = 3'b010;
   parameter READ_READY = 3'b011;
   parameter CPU_PROCESS = 3'b111;
   
   reg [SRAM_LOG2_DEEP-1:0] headptr, readptr, writeptr_r;
   reg [SRAM_LOG2_DEEP:0] depth; 
   // fiforead goes high as soon as state changes to READ_READY, this allows read_ptr to be deposited with new value
   // Since cpu_mode_next_r goes LOW at the posedge clk when process_complete is written into
   // making cpu_mode LOW in the next clock
   // cpu_mode_r LOW means out_wr is asserted HIGH immmediately
   // headptr, writeptr_r, readptr, depth can be incremented
   // fifo_sram_waddr, fifo_sram_raddr, din_fifo_sram, fifo_sram_wen_w start listening to fifo operations
   reg out_wr_next_r;

   ////////////////////////////////////////////////
   // FIFO SRAM OPERATIONS
   ////////////////////////////////////////////////
   wire full = (depth == 9'h100);  //size 
   wire empty = (depth == 9'h0);
   wire fiforead  = (state == READ_READY) & out_rdy & (headptr != readptr) & (writeptr_r != readptr) & ~empty; 
   wire fifowrite_w = in_wr_reg & ~full & ~process_done; 
   // This is to ensure that downstream doesn't reads till the time CPU is processing
   assign out_wr = ~cpu_mode_r & out_wr_next_r; //add this 
   always @(posedge clk) begin 
      if (reset) begin
         headptr <= 8'b0; 
         readptr <= 8'b0; 
         writeptr_r <= 8'b0; 
         out_wr_next_r <= 1'b0; 
         depth <= 9'b0;
      end
      else if (~cpu_mode_r) begin
         if (begin_pkt | end_of_pkt)   //come back later ;might only need writeptr_r
            headptr <= writeptr_r; 
         if (fifowrite_w)
            writeptr_r <= writeptr_r + 1;
         if (fiforead)
            readptr <= readptr + 1;
         if (fifowrite_w & ~fiforead)
            depth <= depth + 1;
         if (~fifowrite_w & fiforead)
            depth <= depth - 1;
         out_wr_next_r <= fiforead;
      end
   end
 

   //cpu wires to SRAM
   reg [PROC_DATA_WIDTH-1:0]           cpu_din; //cpu data in
   reg                                 cpu_wen; //cpu write enable 
   // 13:0 = 14 bits is SUM of SRAM_LOG2_DEEP + 6 Special Registers
   reg [13:0]                          cpu_daddr; //cpu address in  wire [13:8] are for accessing special regs 
   reg [SRAM_DATA_WIDTH-1:0]           temp_data_oneclkdel;
   reg                                 cpu_read_mem;
   //////////////////////////////////////
   //mux to control the mode 
   //////////////////////////////////////
   wire [SRAM_LOG2_DEEP-1:0]           fifo_sram_write_addr = cpu_mode_r ? cpu_daddr[SRAM_LOG2_DEEP-1:0] : writeptr_r;
   wire [SRAM_LOG2_DEEP-1:0]           fifo_sram_read_addr = cpu_mode_r ? cpu_daddr[SRAM_LOG2_DEEP-1:0] : readptr;
   wire [SRAM_DATA_WIDTH-1:0]          din_fifo_sram = cpu_mode_r ? {temp_data_oneclkdel[71:64],cpu_din,temp_data_oneclkdel[47:0]} : {in_ctrl_reg, in_data_reg};
   wire [SRAM_DATA_WIDTH-1:0]          dout_fifo_sram;  //output from fifo_sram
   // inside CPU mode as well, WEN should be asserted only if we are NOT
   // writing to speical registers
   wire fifo_sram_wen_w = cpu_mode_r ? (cpu_wen & ~cpu_daddr[13] & ~cpu_daddr[12] & ~cpu_daddr[11] & ~cpu_daddr[10]) : fifowrite_w; 
   assign {out_ctrl, out_data} = dout_fifo_sram;
   
   //output to cpu  written on the bottom
   //if 
   //cpi_dadder[10] readptr 
   //cpi_dadder[9] state
   //else 
   //    dout_fifo_sram[some 16 bits]

   //cpu to process complete 
   //[8] make process complete to 1 
   //assign process_done = cpu_wen & cpu_daddr[8];

   //-------------------------------DATA PATH

   // local variables
   // IF stage wires and regs
   wire [INSTMEM_LOG2_DEEP-1:0]          pc1_w;
   wire [INSTMEM_LOG2_DEEP-1:0]          hz_pc_w;
   wire                                  wb_ff_w;
   wire [31:0]                           instr_w;

   // ID stage wires and regs
    //wire                mem_read_w;
   wire                                  mem_to_reg_w;
   wire                                  mem_write_w;
   wire                                  reg_write_w;
   wire                                  immd_w;
   wire                                  load_w;
   wire                                  store_w;
   wire                                  jal_w;
   //wire                jalr_w;
   wire                                  branch_w;
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
   wire [PROC_DATA_WIDTH-1:0]            addr_adder_sum_w;
   wire [PROC_DATA_WIDTH-1:0]            pc_next_address_w;
   // wire [INSTMEM_LOG2_DEEP-1:0]          id_pc1_w;
   wire                                  rs2_swch_w;
   wire                                  ex_rs2_swch_w;
   wire [PROC_DATA_WIDTH-1:0]            data2_w;
   wire [2:0]                            func3_intm_w;
   wire 				 func7_intm_w;
   wire [PROC_DATA_WIDTH-1:0]            alu_out_w;
   reg [PROC_DATA_WIDTH-1:0]             mem_read_data_r;
   wire                                  hazard_w;
   wire [INSTMEM_LOG2_DEEP-1:0]          id_pc_o;
   wire                                  id_wb_ff_w;
   wire                                  true_branch_w;
   wire                                  branch_alu_w;
   reg  [INSTMEM_LOG2_DEEP-1:0]          pc_current_r;
   reg  [INSTMEM_LOG2_DEEP-1:0]          pc_prev_r;
   wire                                  hz_reg_write_w;
   wire                                  hz_mem_write_w;
   //wire                                  hz_mem_read_w;
   wire                                  hz_mem_to_reg_w;
   wire                                  hz_load_w;
   wire                                  hz_store_w;
   //wire                                  hz_jalr_w;
   wire                                  hz_branch_w;
   wire [PROC_DATA_WIDTH-1:0]            adder1_w;
   wire [PROC_DATA_WIDTH-1:0]            adder2_w;

   // EX stage wires and regs
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
   wire [PROC_DATA_WIDTH-1:0]            ex_data2_j;
   wire                                  ex_jal_w;
   //wire                ex_hz_jalr_w;
   
   // MEM stage wires and regs
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
            pc_current_r <= 8'd0;
            pc_prev_r    <= 8'd0;
        end
        else if (hazard_w != 1'b1) begin
            pc_current_r <= pc_next_address_w;
            pc_prev_r    <= pc_current_r;
        end
        else begin
            pc_current_r <= pc_current_r;
            pc_prev_r    <= pc_prev_r;
        end
    end

    assign pc1_w = pc_current_r + 8'd1;
   
    assign true_branch_w= branch_alu_w & hz_branch_w;

   //wristband flipflop logic
   //assign wb_ff_w= (hz_jalr_w || jal_w || true_branch_w);
   assign wb_ff_w= (jal_w || true_branch_w);

   IFID #(.INSTMEM_LOG2_DEEP(INSTMEM_LOG2_DEEP))
     ifid0 (
       .CLK                (clk),           
       .RST                (reset),
       .PC_in              (pc_current_r),
       .PC_out             (id_pc_o),
       .hazard             (hazard_w),
       .wb_ff_in           (wb_ff_w),
       .wb_ff_out          (id_wb_ff_w)
       //.incre_pc_in        (pc1_w),
       //.incre_pc_out       (id_pc1_w)
   );
   
   //----------------------------------------------------------------
   // ID Stage
   //----------------------------------------------------------------
   assign branch_sign_ext_w= {{5{instr_w[31]}},instr_w[7],instr_w[30:25], instr_w[11:8]};
   assign sign_ext_jal_w= {instr_w[14:12], instr_w[20], instr_w[30:21]};
   assign sign_ext_j_b_w= true_branch_w ? branch_sign_ext_w: sign_ext_w;
   //assign adder1_w= jalr_w ? reg_read_data1_w : id_pc_o;
   assign adder2_w= jal_w ? sign_ext_jal_w: sign_ext_j_b_w;
   //assign addr_adder_sum_w= adder1_w + adder2_w;
   assign addr_adder_sum_w= id_pc_o + adder2_w;
   //assign pc_next_address_w= ( true_branch_w || hz_jalr_w || jal_w) ? addr_adder_sum_w: pc1_w;
   assign pc_next_address_w= ( true_branch_w || jal_w) ? addr_adder_sum_w: pc1_w;
 
   br_alu #(.PROC_DATA_WIDTH(PROC_DATA_WIDTH)) 
     bru0 (
       .in_rs1             (reg_read_data1_w),
       .in_rs2             (reg_read_data2_w),
       //.in_funct3          (func3_intm_w),
       .out_branch         (branch_alu_w)
     );

   assign hz_pc_w = (hazard_w) ? pc_prev_r : pc_current_r;
   
   inst_memory im0 (.clk(clk), .addr(hz_pc_w), .dout(instr_w));

   hazard_detect #(.PROC_REGFILE_LOG2_DEEP(PROC_REGFILE_LOG2_DEEP)) 
   hdu0 (
       .id_rs1_i        (reg_read_addr1_w),
       .id_rs2_i        (reg_read_addr2_w),
       .ex_rd_i         (ex_reg_write_addr_w[PROC_REGFILE_LOG2_DEEP-1:0]),
       .mem_rd_i        (mem_reg_write_addr_w[PROC_REGFILE_LOG2_DEEP-1:0]),
       .ex_reg_write_i  (ex_reg_write_w),
       .mem_reg_write_i (mem_reg_write_w),
       .hazard_o        (hazard_w)
   );

   control_unit cu0 (
       .opcode_i       (instr_w[6:0]),
       .reset_i        (reset),
       .wb_ff_i        (id_wb_ff_w),
       		//	.mem_read_i     (mem_read_w),
       .mem_to_reg_i   (mem_to_reg_w),
       .mem_write_i    (mem_write_w),
       .reg_write_i    (reg_write_w),
       .immd_i         (immd_w),
       .load_i         (load_w),
       .store_i        (store_w),
       .jal_i          (jal_w),
       //.jalr_i         (jalr_w),
       .branch_i       (branch_w)  
   );

   assign reg_read_addr1_w = instr_w[18:15];
   assign reg_read_addr2_w = instr_w[23:20];       // ! Source register
   assign reg_write_addr_w = instr_w[10:7];
//bubble injection logic into EX stage
    //assign {hz_reg_write_w, hz_mem_write_w, hz_mem_read_w, hz_mem_to_reg_w, hz_load_w, hz_store_w, hz_jalr_w, hz_branch_w} = (hazard_w == 1'b1) ? 6'b0 : {reg_write_w, mem_write_w, mem_read_w, mem_to_reg_w, load_w, store_w, jalr_w, branch_w};
    assign {hz_reg_write_w, hz_mem_write_w, hz_branch_w} = (hazard_w == 1'b1) ? 3'b0 : {reg_write_w, mem_write_w, branch_w};
	
    register_file #(.PROC_DATA_WIDTH(PROC_DATA_WIDTH),.PROC_REGFILE_LOG2_DEEP(PROC_REGFILE_LOG2_DEEP))
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
    assign sign_ext_w = (immd_w == 1'b1) ? {{4{instr_w[31]}}, instr_w[31:20]} : {{4{instr_w[31]}}, instr_w[31:25], instr_w[11:7]};
    assign func3_intm_w = (load_w == 1'b0 && store_w == 1'b0) ? instr_w[14:12] : 3'b000;
    assign func7_intm_w = (load_w == 1'b0 && store_w == 1'b0) ? instr_w[30] : 1'b0		;
// control instructions mux logic for ID stage
	
    assign rs2_swch_w = ~(load_w | store_w | immd_w);



    IDEX #(.PROC_DATA_WIDTH(PROC_DATA_WIDTH), .PROC_REGFILE_LOG2_DEEP(PROC_REGFILE_LOG2_DEEP))
      idex0 (
        .WRegEn_in          (hz_reg_write_w), 
        .WMemEn_in          (hz_mem_write_w), 
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
        .func7_out          (ex_func7_w)
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
        .reg_write_en_o     (mem_reg_write_w),  
        .mem_write_en_o     (mem_mem_write_w),  
        //.mem_read_en_o      (mem_mem_read_w),   
        .mem_to_reg_o       (mem_mem_to_reg_w),    
        .alu_o              (mem_alu_out_w),           
        .reg_data2_o        (mem_r2_out_w),     
        .reg_write_addr_o   (mem_reg_write_addr_w) 
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
   
   // if CPU wants to READ from FIFO, then first check if he wants to read
   // some special register outside FIFO or from FIFO
   // if CPU is reading from Special Register i.e. wb_alu_out_w[8 or 9] is
   // asserted HIGH, then pass the mem_read_data_r, else i.e. CPU is reading
   // from INSIDE the FIFO, then pass dout_fifo_sram 
   // wb_alu_out_w has the address that CPU intended to read in the PREVIOUS
   // clock cycle
    assign reg_write_data_w = (wb_mem_to_reg_w == 1'b1) ? (~(wb_alu_out_w[8] | wb_alu_out_w[9])? dout_fifo_sram[63:48] : mem_read_data_r) : wb_alu_out_w;
	 
   //--------------------------------- connections from cpu to sram ------------------------------
   always @(*) begin 
      cpu_din = mem_r2_out_w; 
      cpu_wen = mem_mem_write_w;  
      cpu_daddr = mem_alu_out_w[10:0];
   end 
	
   // Should we add that fact these instructions should be register writing instructions considering the fact
   // that we don't have memread signal
   // mem_read_data_r is reg-writing to incorporate the 
   always @(posedge clk ) begin 
      if (cpu_daddr[9])
         mem_read_data_r = state;
      else if (cpu_daddr[10])
         mem_read_data_r = readptr;
	 // This else block is removed and instead a condition is added to the WB Stage
         //else 
         // mem_read_data_r = dout_fifo_sram[15:0];
   end 
   //-------------------------------------------------
   //----------------------------------- FSM -------------------------------------
   // need to relook at this logic, on whether stop_in_rdy should be logical OR or logical AND with depth
   // Secondly whetehr it should be clocked or combinational?
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
         if (process_done) begin
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

//-------------------------------------------------
   always @(posedge clk) begin 
      if (reset) begin 
         state <= START;
         begin_pkt <= 1'b0;
         end_of_pkt <= 1'b0;
         in_wr_reg <= 1'b0;
         in_ctrl_reg <= 8'b0;
         in_data_reg <= 64'b0;
         cpu_mode_r <= 1'b0; 
         process_done <= 1'b0;
         cpu_read_mem <= 0;
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
            process_done <= 1'b0;
         end
         if (cpu_wen & cpu_daddr[8]) begin
	    process_done <= 1'b1;
         end
         if (~cpu_wen & ~cpu_daddr[10] & ~cpu_daddr [9] & ~cpu_daddr[8] & cpu_mode_r &(cpu_daddr == readptr + 5)) begin //need to change some value
            cpu_read_mem <= 1;
         end
         if (cpu_read_mem) begin 
            temp_data_oneclkdel <= dout_fifo_sram;
            cpu_read_mem <= 0;
         end 
      end 
   end 



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
