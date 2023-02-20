module hazard_detect (
  input [4:0] id_rs1_i,
  input [4:0] id_rs2_i,
  input [4:0] ex_rd_i,
  input [4:0] mem_rd_i,
  input       ex_reg_write_i,
  input       mem_reg_write_i,

  output      hazard_o
);

  assign hazard_o = ((ex_reg_write_i && (ex_rd_i == id_rs1_i || ex_rd_i == id_rs2_i)) || (mem_reg_write_i && (mem_rd_i == id_rs1_i || mem_rd_i == id_rs2_i))) ? 1'b1 : 1'b0;

endmodule
