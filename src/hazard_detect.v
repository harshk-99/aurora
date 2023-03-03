// HDU with RAW protection for JALR, Branch, and NOP insertion detection
// inserted all control signals bitwise OR for NOP detection
//
// immediate values can sometimes match with rs1/rs2 as they lie in the same position of the 32bit instruction, this would lead to stalling by HDU, could have a work around, TBD!
module hazard_detect (
  input [4:0] id_rs1_i,
  input [4:0] id_rs2_i,
  input [4:0] ex_rd_i,
  input [4:0] mem_rd_i,
  input       ex_reg_write_i,
  input       mem_reg_write_i,
  input       jump_i,
  output      hazard_o
);
assign hazard_o = (
  (~jump_i && ((ex_reg_write_i && (((ex_rd_i == id_rs1_i) && (id_rs1_i!=5'b00000)) || ((ex_rd_i == id_rs2_i) && (id_rs2_i!=5'b00000))))
  ||
  (mem_reg_write_i && (((mem_rd_i == id_rs1_i) && (id_rs1_i!=5'b00000)) || ((mem_rd_i == id_rs2_i) && (id_rs2_i!=5'b00000)))))
  ))   ? 1'b1 : 1'b0;
     

endmodule
//assign hazard_o = ((mem_read_i | mem_to_reg_i | mem_write_i | reg_write_i | load_i | store_i | immd_i | jal_i | jalr_i | branch_i) && (ex_reg_write_i && (((ex_rd_i == id_rs1_i) && (id_rs1_i!=5'b00000)) || ((ex_rd_i == id_rs2_i) && (id_rs2_i!=5'b00000)))) || (mem_reg_write_i && (((mem_rd_i == id_rs1_i) && (id_rs1_i=5'b00000)) || ((mem_rd_i == id_rs2_i) && (id_rs2_i=5'b00000))))) ? 1'b1 : 1'b0;
