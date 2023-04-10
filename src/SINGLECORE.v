`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// EARLY-BRANCH DESIGN 
// PARAMETERIZED
// SINGLE-THREAD
// WITHOUT HDU
// 32 registers 16 bits wide
// 256 deep instruction memory
// 256 deep data memory
// 3 special registers
//////////////////////////////////////////////////////////////////////////////////

//`define UDP_REG_ADDR_WIDTH 16
//`define CPCI_NF2_DATA_WIDTH 16
//`define IDS_BLOCK_TAG 1
//`define IDS_REG_ADDR_WIDTH 16

module SINGLECORE
   #(
      parameter DATA_WIDTH                   = 64,
      parameter CTRL_WIDTH                   = DATA_WIDTH/8,
      parameter PROC_DATA_WIDTH              = 64,
      parameter PROC_REGFILE_LOG2_DEEP       = 5,
      parameter NUM_REGISTERS                = 2**PROC_REGFILE_LOG2_DEEP,
      parameter BMEM_LOG2_DEEP               = 8,
      parameter INSTMEM_LOG2_DEEP            = 8,
      parameter BMEM_DATA_WIDTH              = CTRL_WIDTH + DATA_WIDTH,
      parameter STATEMACHINE_STATUS_ADDR_BIT = 8,
      parameter READPTR_ADDR_BIT             = 9,
      parameter CPU_JOB_STATUS_ADDR_BIT      = 10,
      parameter THREAD0_START_ADDR           = 0,
      parameter THREAD0_UPSTREAM_STATUS_BIT_POS = 0,
      parameter SHAMT_WIDTH                  = 6
    )
    (
      input                               reset,
      input                               clk,
      input [PROC_DATA_WIDTH-1:0]         bmem_dout_in,
      input [1:0]                         state_status_in,
      input  [BMEM_LOG2_DEEP-1:0]         bmemreadptr_in,
      output                              mem_mem_write_en_out,
      output [PROC_DATA_WIDTH-1:0]        mem_r2_out_out,
      // mem_alu_out_w only BMEM_LOG2_DEEP is used in the the ids module as
      // this signal is used for address input (read and write address)
      output [PROC_DATA_WIDTH-1:0]        mem_alu_out_out,
      output [INSTMEM_LOG2_DEEP-1:0]      mem_pc_carry_baggage_w
   );

   // THREADx_DONE means that state machine would check this specific address
   // bit to see if the specific bit has completed its opeartion
   // when all these bits are set to 1, then all threads have finished their
   // respective operation
   //localparam THREAD0_UPSTREAM_STATUS_BIT_POS          = 0;
   //localparam THREAD1_UPSTREAM_STATUS_BIT_POS          = 1;
   //localparam THREAD2_UPSTREAM_STATUS_BIT_POS          = 2;
   //localparam THREAD3_UPSTREAM_STATUS_BIT_POS          = 3;
   localparam THREAD0_STATE            = 2'b00;
   localparam THREAD1_STATE            = 2'b01;
   localparam THREAD2_STATE            = 2'b10;
   localparam THREAD3_STATE            = 2'b11;
   localparam SIGNEXT_BITS             = PROC_DATA_WIDTH-12;
   //localparam THREAD1_START_ADDR       = 8'd31;
   //localparam THREAD2_START_ADDR       = 8'd61;
   //localparam THREAD3_START_ADDR       = 8'd92;
    
   
   wire [31:0]                            instr_w;
   wire [1:0]                             if_thread_id_w;
   reg [1:0]                              thread_state_r;
   wire [INSTMEM_LOG2_DEEP-1:0]           pc_current_w;
   reg  [INSTMEM_LOG2_DEEP-1:0]           thread0_pc_current_r;
   reg  [INSTMEM_LOG2_DEEP-1:0]           thread1_pc_current_r;
   reg  [INSTMEM_LOG2_DEEP-1:0]           thread2_pc_current_r;
   reg  [INSTMEM_LOG2_DEEP-1:0]           thread3_pc_current_r;
   //wire [PROC_DATA_WIDTH-1:0]            pc_next_address_w;
   wire [INSTMEM_LOG2_DEEP-1:0]           thread0_pc_next_address_w;
   //reg [INSTMEM_LOG2_DEEP-1:0]            thread1_pc_next_address_r;
   //reg [INSTMEM_LOG2_DEEP-1:0]            thread2_pc_next_address_r;
   //reg [INSTMEM_LOG2_DEEP-1:0]            thread3_pc_next_address_r;
   //wire [INSTMEM_LOG2_DEEP-1:0]          pc_plus_one_w;
   wire [INSTMEM_LOG2_DEEP-1:0]           thread0_pc_plus_one_w;
   //reg [INSTMEM_LOG2_DEEP-1:0]            thread1_pc_plus_one_r;
   //reg [INSTMEM_LOG2_DEEP-1:0]            thread2_pc_plus_one_r;
   //reg [INSTMEM_LOG2_DEEP-1:0]            thread3_pc_plus_one_r;
   wire                                   wb_ff_w;

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
   wire [PROC_DATA_WIDTH-1:0]            branch_sign_ext_w; // this may have to be changed to INSTMEM_LOG2_DEEP
   wire [PROC_DATA_WIDTH-1:0]            sign_ext_jal_w;    // this may have to be changed to INSTMEM_LOG2_DEEP
   //wire [PROC_DATA_WIDTH-1:0]            sign_ext_j_b_w;
   wire [PROC_DATA_WIDTH-1:0]            control_inst_target_address_w;    // this may have to be changed to INSTMEM_LOG2_DEEP
   // wire [INSTMEM_LOG2_DEEP-1:0]          id_pc1_w;
   wire                                  alu_src_w;
   wire [2:0]                            func3_intm_w;
   wire 				 func7_intm_w;
   //wire                                  hazard_w;
   wire [INSTMEM_LOG2_DEEP-1:0]          id_pc_carry_baggage_w;
   wire                                  id_wb_ff_w;
   wire                                  true_branch_w;
   wire                                  branch_alu_w;
   //reg  [INSTMEM_LOG2_DEEP-1:0]          pc_prev_r;
   wire [PROC_DATA_WIDTH-1:0]            sign_extender_selecter_w;

   // EX stage wires and regs
   wire [INSTMEM_LOG2_DEEP-1:0]          ex_pc_carry_baggage_w;
   wire [PROC_DATA_WIDTH-1:0]            alu_out_w;
   wire [PROC_DATA_WIDTH-1:0]            data2_w;
   wire                                  ex_alu_src_w;
   wire [1:0]                            ex_thread_id_w;
   wire                                  ex_reg_write_w;
   wire                                  ex_mem_write_w;
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
   
   // MEM stage wires and regs
   wire [1:0]                            mem_thread_id_w;
   wire                                  mem_reg_write_w;
   //wire                mem_mem_read_w;
   wire                                  mem_mem_to_reg_w;
   wire [PROC_DATA_WIDTH-1:0]            mem_r2_out_w;
   wire [PROC_REGFILE_LOG2_DEEP-1:0]     mem_reg_write_addr_w;

   // WB Stage wires and regs
   wire                                  wb_reg_write_w;
   wire                                  wb_mem_to_reg_w;
   wire [PROC_REGFILE_LOG2_DEEP-1:0]     wb_reg_write_addr_w;
   wire [PROC_DATA_WIDTH-1:0]            wb_alu_out_w;
   wire [PROC_DATA_WIDTH-1:0]            mem_read_data_w;
   //reg [PROC_DATA_WIDTH-1:0]             mem_read_data_r;

   //----------------------------------------------------------------
   // IF Stage
   //----------------------------------------------------------------
   always @(posedge clk) begin
       if (reset == 1'b1) begin
           thread_state_r              <= THREAD0_STATE;
           thread0_pc_current_r        <= THREAD0_START_ADDR;
       end
       else begin
          case(thread_state_r)
               THREAD0_STATE: begin
                  thread_state_r             <= THREAD0_STATE;
                  thread0_pc_current_r       <= thread0_pc_next_address_w;
               end
          endcase
       end
   end
   //assign pc_current_w     = thread_state_r==THREAD3_STATE ? thread3_pc_current_r : (thread_state_r==THREAD2_STATE ? thread2_pc_current_r : (thread_state_r==THREAD1_STATE ? thread1_pc_current_r : thread0_pc_current_r)) ;
   assign pc_current_w     = thread_state_r==THREAD3_STATE ? thread3_pc_current_r : (thread_state_r==THREAD2_STATE ? thread2_pc_current_r : (thread_state_r==THREAD1_STATE ? thread1_pc_current_r : thread0_pc_current_r)) ;
   assign if_thread_id_w   = thread_state_r;
   assign thread0_pc_next_address_w = (true_branch_w || jal_w) ? control_inst_target_address_w: thread0_pc_plus_one_w;

   assign thread0_pc_plus_one_w = thread0_pc_current_r + 8'd1;
   //assign pc_next_address_w= (true_branch_w || hz_jalr_w || jal_w) ? control_inst_target_address_w: pc_plus_one_w;
   
   //wristband flipflop logic
   assign wb_ff_w= (jal_w || true_branch_w);
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
       .wb_ff_in           (wb_ff_w),
       .wb_ff_out          (id_wb_ff_w),
       .thread_id_out      (id_thread_id_w)
       //.incre_pc_in        (pc_plus_one_w),
       //.incre_pc_out       (id_pc1_w)
   );
   
   //----------------------------------------------------------------
   // ID Stage
   //----------------------------------------------------------------
   assign branch_sign_ext_w= {{5{instr_w[31]}},instr_w[7],instr_w[30:25], instr_w[11:8]};
   assign sign_ext_jal_w= {instr_w[14:12], instr_w[20], instr_w[30:21]};
   //assign sign_ext_j_b_w= true_branch_w ? branch_sign_ext_w: sign_ext_w;   // this is a dead code
   //assign adder1_w= jalr_w ? reg_read_data1_w : id_pc_carry_baggage_w;
   //assign sign_extender_selecter_w= jal_w ? sign_ext_jal_w: sign_ext_j_b_w;
   assign sign_extender_selecter_w= jal_w ? sign_ext_jal_w: branch_sign_ext_w;
   //assign control_inst_target_address_w= adder1_w + sign_extender_selecter_w;
   assign control_inst_target_address_w = id_pc_carry_baggage_w + sign_extender_selecter_w;
 
   BR_ALU #(.PROC_DATA_WIDTH(PROC_DATA_WIDTH)) 
     bru0 (
       .in_rs1             (reg_read_data1_w),
       .in_rs2             (reg_read_data2_w),
       .in_funct3          (func3_intm_w),
       .out_branch         (branch_alu_w)
     );
   assign true_branch_w= branch_alu_w & cu_branch_out_w;

   control_unit cu0 (
       .opcode_i       (instr_w[6:0]),
       .reset_i        (reset),
       .wb_ff_i        (id_wb_ff_w),
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
    //assign sign_ext_w = (immd_w == 1'b1) ? {{4{instr_w[31]}}, instr_w[31:20]} : {{4{instr_w[31]}}, instr_w[31:25], instr_w[11:7]};
    assign sign_ext_w = (immd_w == 1'b1) ? {{SIGNEXT_BITS{instr_w[31]}}, instr_w[31:20]} : {{SIGNEXT_BITS{instr_w[31]}}, instr_w[31:25], instr_w[11:7]};
    assign func3_intm_w = (load_w == 1'b0 && store_w == 1'b0) ? instr_w[14:12] : 3'b000;
    assign func7_intm_w = (load_w == 1'b0 && store_w == 1'b0) ? instr_w[30] : 1'b0		;
    // control instructions mux logic for ID stage
	
    assign alu_src_w = ~(load_w | store_w | immd_w);

    IDEX #(.PROC_DATA_WIDTH         (PROC_DATA_WIDTH), 
           .PROC_REGFILE_LOG2_DEEP  (PROC_REGFILE_LOG2_DEEP),
           .INSTMEM_LOG2_DEEP       (INSTMEM_LOG2_DEEP))
      idex0 (
        .WRegEn_in          (reg_write_w), 
        .WMemEn_in          (mem_write_w), 
        //.RMemEn_in          (hz_mem_read_w), 
	.alu_src_in         (alu_src_w), 
	.mem_to_reg_in      (mem_to_reg_w),
        //.imm_in             (immd_w),
        //.load_in            (hz_load_w),
        //.store_in           (hz_store_w), 
        .R1out_in           (reg_read_data1_w), 
        .R2out_in           (reg_read_data2_w), 
        .WReg1_in           (reg_write_addr_w),
        .sign_ext_in        (sign_ext_w),
        .func3_in           (func3_intm_w), 
        .func7_in           (func7_intm_w), 
        .pc_carry_baggage_i (id_pc_carry_baggage_w),  
        .CLK                (clk),           
        .RST                (reset),
        .thread_id_in       (id_thread_id_w),
        //.jal_in             (jal_w),
        //.hz_jalr_in         (hz_jalr_w),
        .WRegEn_out         (ex_reg_write_w), 
        .WMemEn_out         (ex_mem_write_w), 
        //.RMemEn_out         (ex_mem_read_w), 
        .alu_src_out        (ex_alu_src_w),
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
        .thread_id_out       (ex_thread_id_w),
        .pc_carry_baggage_o (ex_pc_carry_baggage_w)  
        //.jal_out            (ex_jal_w),
        //.hz_jalr_out        (ex_hz_jalr_w)
    );

    assign data2_w = (ex_alu_src_w) ? ex_r2_out_w : ex_sign_ext_w;
    //assign data2_w = (ex_load_w == 1'b0 && ex_store_w == 1'b0 && ex_immd_w == 1'b0) ? ex_r2_out_w : ex_sign_ext_w;
    //assign ex_data2_j= (ex_jal_w || ex_hz_jalr_w) ? 64'h0000000000000000 : data2_w;

    ALU #(.PROC_DATA_WIDTH(PROC_DATA_WIDTH),
          .SHAMT_WIDTH(SHAMT_WIDTH)) 
      alu0 
         (
         .in_rs1     (ex_r1_out_w),
         .in_rs2     (data2_w), 
         .in_funct3  (ex_func3_w),
         .in_funct7  (ex_func7_w),
         .out_rd     (alu_out_w)
         );

    EXMEM #(.PROC_DATA_WIDTH        (PROC_DATA_WIDTH), 
            .PROC_REGFILE_LOG2_DEEP (PROC_REGFILE_LOG2_DEEP),
            .INSTMEM_LOG2_DEEP      (INSTMEM_LOG2_DEEP))
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
        .pc_carry_baggage_i (ex_pc_carry_baggage_w),  
        .reg_write_en_o     (mem_reg_write_w),  
        .mem_write_en_o     (mem_mem_write_en_out),  
        //.mem_read_en_o      (mem_mem_read_w),   
        .mem_to_reg_o       (mem_mem_to_reg_w),    
        .alu_o              (mem_alu_out_out),           
        .reg_data2_o        (mem_r2_out_out),     
        .reg_write_addr_o   (mem_reg_write_addr_w), 
        .thread_id_o        (mem_thread_id_w),
        .pc_carry_baggage_o (mem_pc_carry_baggage_w)  

    );

    //data_memory dm0 (.clka(clk), mem_alu_out_w[7:0], mem_r2_out_w, mem_mem_write_w, mem_read_data_w);
      //data_memory dm0 (.clka(clk), .clkb(clk),.addrb(mem_alu_out_w[7:0]),.addra(mem_alu_out_w[7:0]), .dina(mem_r2_out_w), .wea(mem_mem_write_w), .doutb(mem_read_data_w));
    //data_memory dm0 (.clka(clk), .clkb(clk),.addrb(fifo_sram_read_addr),.addra(fifo_sram_write_addr), .dina(din_fifo_sram), .wea(fifo_sram_wen_w), .doutb(dout_fifo_sram));
		
    MEMWB #(.PROC_DATA_WIDTH(PROC_DATA_WIDTH), .PROC_REGFILE_LOG2_DEEP(PROC_REGFILE_LOG2_DEEP))
      memwb0 (
        .clk_i                  (clk),             
        .rst_i                  (reset),           
        .reg_write_en_i         (mem_reg_write_w),  
        .mem_to_reg_i           (mem_mem_to_reg_w),  
        .reg_write_addr_i       (mem_reg_write_addr_w),
        .alu_i                  (mem_alu_out_out),             
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
   assign mem_read_data_w = wb_alu_out_w[STATEMACHINE_STATUS_ADDR_BIT]==1'b1 ? state_status_in : (wb_alu_out_w[READPTR_ADDR_BIT]==1'b1 ? bmemreadptr_in : bmem_dout_in); 
   assign reg_write_data_w = (wb_mem_to_reg_w == 1'b1) ? mem_read_data_w : wb_alu_out_w;
	 
endmodule
