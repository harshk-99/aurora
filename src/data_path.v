`include "inst_memory_sim.v"
`include "control_unit.v"
`include "register_file.v"
`include "alu_64_bit.v"
`include "data_memory_sim.v"
`include "IDEX.v"
`include "EXMEM.v"
`include "MEMWB.v"
`include "hazard_detect.v"
`include "IFID.v"


module data_path (
    input clk_i,
    input rst_i
);


    wire [7:0]          pc1_w;
    wire [7:0]          hz_pc_w;
    wire                wb_ff_w;
    wire [31:0]         instr_w;
    wire                mem_to_reg_w;
    wire                mem_write_w;
    wire                reg_write_w;
    wire                immd_w;
    wire                load_w;
    wire                store_w;
    wire                jal_w;
    wire                jalr_w;
    wire                branch_w;
    wire [4:0]          reg_read_addr1_w;
    wire [4:0]          reg_read_addr2_w;
    wire [4:0]          reg_write_addr_w;
    wire [63:0]         reg_write_data_w;
    wire [63:0]         reg_read_data1_w;
    wire [63:0]         reg_read_data2_w;
    wire [63:0]         sign_ext_w;
    wire [63:0]         branch_sign_ext_w;
    wire [63:0]         sign_ext_jal_w;
    wire [63:0]         sign_ext_i_j_b_w;
    wire [63:0]         addr_adder_sum_w;
    wire [63:0]         pc_next_address_w;

    wire [63:0]         data2_w;
    wire [2:0]          func3_intm_w;
    wire                func7_intm_w;
    wire                rs2_swch_w;
    wire [63:0]         alu_out_w;
    wire [63:0]         mem_read_data_w;
    wire                hazard_w;
    wire [7:0]          id_pc_o;
    wire                id_wb_ff_w;
    wire                true_branch_w;
    wire                branch_alu_w;
    reg  [7:0]          pc_current_r;
    reg  [7:0]          pc_prev_r;

    wire                hz_reg_write_w;
    wire                hz_mem_write_w;
    wire                hz_jalr_w;
    wire                hz_branch_w;
    wire                hz_jal_w;

    wire [63:0]         adder1_w;
    wire [63:0]         adder2_w;
    wire                jump_w;  
    

    wire                ex_reg_write_w;
    wire                ex_mem_write_w;
    wire                ex_mem_to_reg_w;
    wire                ex_rs2_swch_w;
    wire [63:0]         ex_r1_out_w;
    wire [63:0]         ex_r2_out_w;
    wire [63:0]         ex_sign_ext_w;
    wire [4:0]          ex_reg_write_addr_w;
    wire [2:0]          ex_func3_w;
    wire                ex_func7_w;
    wire [63:0]         ex_data2_j;
    wire                ex_jal_w;
    wire                ex_jalr_w;
    wire                ex_branch_w;
    wire [7:0]          ex_pc_w;

    wire                mem_reg_write_w;
    wire                mem_mem_write_w;
    wire                mem_mem_to_reg_w;
    wire [63:0]         mem_alu_out_w;
    wire [63:0]         mem_r2_out_w;
    wire [4:0]          mem_reg_write_addr_w;


    wire                wb_reg_write_w;
    wire                wb_mem_to_reg_w;
    wire [4:0]          wb_reg_write_addr_w;
    wire [63:0]         wb_alu_out_w;

    always @(posedge clk_i) begin
        if (rst_i == 1'b1) begin
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

    //wristband flipflop logic
    assign wb_ff_w = jump_w;

    IFID ifid0 (
        .CLK                (clk_i),           
        .RST                (rst_i),
        .PC_in              (pc_current_r),
        .PC_out             (id_pc_o),
        .hazard             (hazard_w),
        .wb_ff_in           (wb_ff_w),
        .wb_ff_out          (id_wb_ff_w)
    );

    assign hz_pc_w = (hazard_w) ? pc_prev_r : pc_current_r;
    
    inst_memory im0 (clk_i, hz_pc_w, instr_w);

    hazard_detect hdu0 (
        .id_rs1_i        (reg_read_addr1_w),
        .id_rs2_i        (reg_read_addr2_w),
        .ex_rd_i         (ex_reg_write_addr_w),
        .mem_rd_i        (mem_reg_write_addr_w),
        .ex_reg_write_i  (ex_reg_write_w),
        .mem_reg_write_i (mem_reg_write_w),
        .jump_i          (jump_w),
        .hazard_o        (hazard_w)
    );

    control_unit cu0 (
        .opcode_i       (instr_w[6:0]),
        .reset_i        (rst_i),
        .wb_ff_i        (id_wb_ff_w),
        .mem_to_reg_i   (mem_to_reg_w),
        .mem_write_i    (mem_write_w),
        .reg_write_i    (reg_write_w),
        .immd_i         (immd_w),
        .load_i         (load_w),
        .store_i        (store_w),
        .jal_i          (jal_w),
        .jalr_i         (jalr_w),
        .branch_i       (branch_w)  
    );

    assign reg_read_addr1_w = instr_w[19:15];
    assign reg_read_addr2_w = instr_w[24:20];       // ! Source register
    assign reg_write_addr_w = instr_w[11:7];
//bubble injection logic into EX stage
    assign {hz_reg_write_w, hz_mem_write_w, hz_jalr_w, hz_branch_w, hz_jal_w} = (hazard_w == 1'b1) ? 5'b0 : {reg_write_w, mem_write_w, jalr_w, branch_w, jal_w};

    register_file rf0 (
        .clk_i          (clk_i),
        .write_en_i     (wb_reg_write_w),
        .write_addr_i   (wb_reg_write_addr_w),
        .write_data_i   (reg_write_data_w),
        .read_addr1_i   (reg_read_addr1_w),
        .read_addr2_i   (reg_read_addr2_w),
        .read_data1_o   (reg_read_data1_w),
        .read_data2_o   (reg_read_data2_w)
        );

    assign branch_sign_ext_w = {{50{instr_w[31]}},instr_w[7],instr_w[30:25], instr_w[11:8]};
    assign sign_ext_jal_w = {{45{instr_w[31]}},instr_w[19:12], instr_w[20], instr_w[30:21]};
    assign sign_ext_w = (immd_w == 1'b1) ? {{52{instr_w[31]}}, instr_w[31:20]} : {{52{instr_w[31]}}, instr_w[31:25], instr_w[11:7]};
    assign func3_intm_w = (load_w == 1'b1 || store_w == 1'b1 || hz_jal_w == 1'b1) ? 3'b000 : instr_w[14:12];                   // ? check if hz
    assign func7_intm_w = (load_w == 1'b0 && store_w == 1'b0) ? instr_w[30] : 1'b0;
// control instructions mux logic for ID stage

    assign sign_ext_i_j_b_w = hz_jalr_w ? sign_ext_w : (hz_jal_w ? sign_ext_jal_w : (hz_branch_w ? branch_sign_ext_w : sign_ext_w));

    assign rs2_swch_w = ~(load_w | store_w | immd_w);


    IDEX idex0 (
        .WRegEn_in          (hz_reg_write_w), 
        .WMemEn_in          (hz_mem_write_w), 
        .mem_to_reg_in      (mem_to_reg_w),
        .rs2_swch_in        (rs2_swch_w), 
        .R1out_in           (reg_read_data1_w), 
        .R2out_in           (reg_read_data2_w), 
        .WReg1_in           (reg_write_addr_w),
        .sign_ext_in        (sign_ext_i_j_b_w),
        .func3_in           (func3_intm_w), 
        .func7_in           (func7_intm_w),
        .jal_in             (hz_jal_w),
        .jalr_in            (hz_jalr_w),
        .br_in              (hz_branch_w),
        .pc_in              (id_pc_o),
        .CLK                (clk_i),           
        .RST                (rst_i | jump_w),
        .WRegEn_out         (ex_reg_write_w), 
        .WMemEn_out         (ex_mem_write_w), 
        .mem_to_reg_out     (ex_mem_to_reg_w), 
        .rs2_swch_out       (ex_rs2_swch_w), 
        .R1out_out          (ex_r1_out_w), 
        .R2out_out          (ex_r2_out_w),
        .sign_ext_out       (ex_sign_ext_w),
        .WReg1_out          (ex_reg_write_addr_w),
        .func3_out          (ex_func3_w),
        .func7_out          (ex_func7_w),
        .jal_out            (ex_jal_w),
        .jalr_out           (ex_jalr_w),
        .br_out             (ex_branch_w),
        .pc_out             (ex_pc_w)
    );

    assign data1_w = (ex_jal_w || ex_jalr_w) ? ex_pc_w : ex_r1_out_w;

    assign data2_w = (ex_rs2_swch_w) ? ex_r2_out_w : ex_sign_ext_w;
    assign ex_data2_j= (ex_jal_w || ex_jalr_w) ? 64'd1 : data2_w;                     // * To add PC + 1 

    assign adder1_w = ex_jalr_w ? ex_r1_out_w : ex_pc_w;
    assign addr_adder_sum_w = adder1_w + ex_sign_ext_w;



    alu_64_bit alu0 (
        .in_rs1     (ex_r1_out_w),
        .in_rs2     (ex_data2_j), 
        .in_funct3  (ex_func3_w),
        .in_funct7  (ex_func7_w),
        .out_rd     (alu_out_w)
        );

    assign true_branch_w = alu_out_w[0] & ex_branch_w;               
    assign jump_w        = true_branch_w || ex_jalr_w || ex_jal_w;

    assign pc_next_address_w = (jump_w) ? addr_adder_sum_w: pc1_w;

    EXMEM exmem0 (
        .clk_i              (clk_i),           
        .rst_i              (rst_i),           
        .reg_write_en_i     (ex_reg_write_w),  
        .mem_write_en_i     (ex_mem_write_w),          
        .mem_to_reg_i       (ex_mem_to_reg_w),  
        .alu_i              (alu_out_w),           
        .reg_data2_i        (ex_r2_out_w),     
        .reg_write_addr_i   (ex_reg_write_addr_w),
        .reg_write_en_o     (mem_reg_write_w),  
        .mem_write_en_o     (mem_mem_write_w),  
        .mem_to_reg_o       (mem_mem_to_reg_w),    
        .alu_o              (mem_alu_out_w),           
        .reg_data2_o        (mem_r2_out_w),     
        .reg_write_addr_o   (mem_reg_write_addr_w) 
    );

    data_memory dm0 (clk_i, mem_alu_out_w[7:0], mem_r2_out_w, mem_mem_write_w, mem_read_data_w);

    MEMWB memwb0 (
        .clk_i                  (clk_i),             
        .rst_i                  (rst_i),           
        .reg_write_en_i         (mem_reg_write_w),  
        .mem_to_reg_i           (mem_mem_to_reg_w),  
        .reg_write_addr_i       (mem_reg_write_addr_w),
        .alu_i                  (mem_alu_out_w),             
        .reg_write_en_o         (wb_reg_write_w),      
        .mem_to_reg_o           (wb_mem_to_reg_w),      
        .reg_write_addr_o       (wb_reg_write_addr_w),    
        .alu_o                  (wb_alu_out_w)
    );
    
    assign reg_write_data_w = (wb_mem_to_reg_w == 1'b1) ? mem_read_data_w : wb_alu_out_w;

endmodule
