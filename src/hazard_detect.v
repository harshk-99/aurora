// HDU with RAW protection for JALR, Branch, and NOP insertion detection
// inserted all control signals bitwise OR for NOP detection
//
// immediate values can sometimes match with rs1/rs2 as they lie in the same position of the 32bit instruction, this would lead to stalling by HDU, could have a work around, TBD!
module hazard_detect 
   # (parameter PROC_REGFILE_LOG2_DEEP=5)
   (
     input [PROC_REGFILE_LOG2_DEEP-1:0] id_rs1_i,
     input [PROC_REGFILE_LOG2_DEEP-1:0] id_rs2_i,
     input [PROC_REGFILE_LOG2_DEEP-1:0] ex_rd_i,
     input [PROC_REGFILE_LOG2_DEEP-1:0] mem_rd_i,
     input       ex_reg_write_i,
     input       mem_reg_write_i,
     input       mem_read_i, 
     input       mem_to_reg_i, 
     input       mem_write_i, 
     input       reg_write_i, 
     input       load_i, 
     input       store_i, 
     input       immd_i, 
     input       jal_i, 
     input       jalr_i, 
     input       branch_i,
     output      hazard_o
   );
assign hazard_o = (
  (ex_reg_write_i && (((ex_rd_i == id_rs1_i) && (id_rs1_i!= {PROC_REGFILE_LOG2_DEEP{1'b0}} )) || ((ex_rd_i == id_rs2_i) && (id_rs2_i!={PROC_REGFILE_LOG2_DEEP{1'b0}}))))
  ||
  (mem_reg_write_i && (((mem_rd_i == id_rs1_i) && (id_rs1_i!={PROC_REGFILE_LOG2_DEEP{1'b0}})) || ((mem_rd_i == id_rs2_i) && (id_rs2_i!={PROC_REGFILE_LOG2_DEEP{1'b0}}))))
  )   ? 1'b1 : 1'b0;
     

endmodule
//assign hazard_o = ((mem_read_i | mem_to_reg_i | mem_write_i | reg_write_i | load_i | store_i | immd_i | jal_i | jalr_i | branch_i) && (ex_reg_write_i && (((ex_rd_i == id_rs1_i) && (id_rs1_i!=5'b00000)) || ((ex_rd_i == id_rs2_i) && (id_rs2_i!=5'b00000)))) || (mem_reg_write_i && (((mem_rd_i == id_rs1_i) && (id_rs1_i=5'b00000)) || ((mem_rd_i == id_rs2_i) && (id_rs2_i=5'b00000))))) ? 1'b1 : 1'b0;
