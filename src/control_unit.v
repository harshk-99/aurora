// immd_i (sitting in EX stage which is select line for a mux)meant for I type instruction to select sign extended value instead of rs2
// JAL does not have any source registers therefore HDU won't ever come into play.
// have decided to go with three 2:1 64 bit wide muxes for jal, jump, and branch instr in ID stage due to less fan-in
// no possible hazard for JAL
// possible RAW hazard for JALR
module control_unit (
  input      [6:0] opcode_i,
  input            reset_i,
  input            wb_ff_i,
  output reg       mem_to_reg_i, mem_write_i, reg_write_i, load_i, store_i, immd_i, jal_i, branch_i
  
  );   

  always @(*) begin
    if (reset_i == 1'b1 || wb_ff_i) begin
      mem_to_reg_i = 1'bx;
      mem_write_i = 1'b0;
      reg_write_i = 1'b0;
      immd_i = 1'bx;
      load_i = 1'bx;
      store_i = 1'bx;
      jal_i=1'b0;
      branch_i=1'b0;
    end else begin
      case (opcode_i)
    7'b0110011: begin                // * R - Type
          mem_to_reg_i = 1'b0;
          mem_write_i = 1'b0;
          reg_write_i = 1'b1;
          immd_i = 1'b0;
          load_i = 1'b0;
          store_i = 1'b0;
          jal_i=1'b0;
          branch_i=1'b0;
          end
    7'b0010011: begin                // * I - Type (Arithmetic)
          mem_to_reg_i = 1'b0;
          mem_write_i = 1'b0;
          reg_write_i = 1'b1;
          immd_i = 1'b1;
          load_i = 1'b0;
          store_i = 1'b0;
          jal_i=1'b0;
          branch_i=1'b0;
          end
    7'b0000011: begin                // * I - Type (load)
          mem_to_reg_i = 1'b1;
          mem_write_i = 1'b0;
          reg_write_i = 1'b1;
          immd_i = 1'b1;
          load_i = 1'b1;
          store_i = 1'b0;
          jal_i=1'b0;
          branch_i=1'b0;
          end
    7'b0100011: begin                // * S - Type (store)
          mem_to_reg_i = 1'bx;
          mem_write_i = 1'b1;
          reg_write_i = 1'b0;
          immd_i = 1'b0;
          load_i = 1'b0;
          store_i = 1'b1;
          jal_i=1'b0;
          branch_i=1'b0;
          end
    7'b1100011: begin                // * SB - Type (branch)
            mem_to_reg_i = 1'b0;
            mem_write_i = 1'b0;
            reg_write_i = 1'b0;
            immd_i = 1'b0;
            load_i = 1'b0;
            store_i = 1'b0;
            jal_i=1'b0;
            branch_i=1'b1;
            end
    7'b1101111: begin                // * UJ - Type (jal)  
              mem_to_reg_i = 1'b0;
              mem_write_i = 1'b0;
              reg_write_i = 1'b1;
              immd_i = 1'bx;
              load_i = 1'bx;
              store_i = 1'bx;
              jal_i=1'b1;
              branch_i=1'b0;
              end       
    default: begin                // * nop
          mem_to_reg_i = 1'bx;
          mem_write_i = 1'b0;
          reg_write_i = 1'b0;
          immd_i = 1'bx;
          load_i = 1'bx;
          store_i = 1'bx;
          jal_i=1'b0;
          branch_i=1'b0;
            end
        endcase
      end
  end
  
endmodule
