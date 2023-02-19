`include "inst_memory.v"
`include "control_unit.v"
`include "register_file.v"
`include "alu_64_bit.v"
`include "data_memory.v"

module data_path (
    input clk_i,
    input rst_i
);


    wire [7:0]          pc1_w;
    wire [31:0]         instr_w;
    wire                reg_dest_w;
    wire                mem_read_w;
    wire                mem_to_reg_w;
    wire                mem_write_w;
    wire                reg_write_w;
    wire                load_w;
    wire                store_w;
    wire [4:0]          reg_read_addr1_w;
    wire [4:0]          reg_read_addr2_w;
    wire [4:0]          reg_write_addr_w;
    wire [63:0]         reg_write_data_w;
    wire [63:0]         reg_read_data1_w;
    wire [63:0]         reg_read_data2_w;
    wire [63:0]         sign_ext_w;
    wire [63:0]         data2_w;
    wire [2:0]          func3_intm_w;
    wire [6:0]          func7_intm_w;
    wire [63:0]         alu_out_w;
    wire [63:0]         mem_read_data_w;

    reg  [7:0]          pc_current_r;

    always @(posedge clk_i) begin
        if (rst_i == 1'b1)
            pc_current_r <= 8'd0;
        else
            pc_current_r <= pc1_w;
    end

    assign pc1_w = pc_current_r + 8'd1;

    inst_memory im0 (pc_current_r, instr_w);

    control_unit cu0 (
        .opcode_i       (instr_w[6:0]),
        .reset_i        (rst_i),
        .reg_dest_i     (reg_dest_w), 
        .mem_read_i     (mem_read_w),
        .mem_to_reg_i   (mem_to_reg_w),
        .mem_write_i    (mem_write_w),
        .reg_write_i    (reg_write_w),
        .load_i         (load_w),
        .store_i        (store_w)
    );

    assign reg_read_addr1_w = instr_w[19:15];
    assign reg_read_addr2_w = instr_w[24:20];       // ! Source register
    assign reg_write_addr_w = instr_w[11:7];

    register_file rf0 (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .write_en_i     (reg_write_w),
        .write_addr_i   (reg_write_addr_w),
        .write_data_i   (reg_write_data_w),
        .read_addr1_i   (reg_read_addr1_w),
        .read_addr2_i   (reg_read_addr2_w),
        .read_data1_o   (reg_read_data1_w),
        .read_data2_o   (reg_read_data2_w)
        );

    assign sign_ext_w = (load_w == 1'b1) ? {{52{instr_w[31]}}, instr_w[31:20]} : {{52{instr_w[31]}}, instr_w[31:25], instr_w[11:7]};
    assign data2_w = (load_w == 1'b0 && store_w == 1'b0) ? reg_read_data2_w : sign_ext_w;
    assign func3_intm_w = (load_w == 1'b0 && store_w == 1'b0) ? instr_w[14:12] : 3'b000;
    assign func7_intm_w = (load_w == 1'b0 && store_w == 1'b0) ? instr_w[31:25] : 7'b0000000;

    alu_64_bit alu0 (
        .in_rs1     (reg_read_data1_w),
        .in_rs2     (data2_w), 
        .in_funct3  (func3_intm_w),
        .in_funct7  (func7_intm_w),
        .out_rd     (alu_out_w)
        );

    data_memory dm0 (clk_i, alu_out_w[7:0], reg_read_data2_w, mem_write_w, mem_read_w, mem_read_data_w);
    
    assign reg_write_data_w = (mem_to_reg_w == 1'b1) ? mem_read_data_w : alu_out_w;

endmodule
