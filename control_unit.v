module control_unit (
  input      [6:0] opcode_i,
  input            reset_i,
  
  output reg       mem_read_i, mem_to_reg_i, mem_write_i, reg_write_i, load_i, store_i
);

  always @(*) begin
    if (reset_i == 1'b1) begin
      mem_read_i = 1'b0;
      mem_to_reg_i = 1'b0;
      mem_write_i = 1'b0;
      reg_write_i = 1'b0;
      load_i = 1'b0;
      store_i = 1'b0;
    end else begin
      case (opcode_i)
    7'b0110011: begin            // * R - Type
          mem_read_i = 1'b0;
          mem_to_reg_i = 1'b0;
          mem_write_i = 1'b0;
          reg_write_i = 1'b1;
          load_i = 1'b0;
          store_i = 1'b0;
          end
    7'b0000011: begin                // * I - Type (load)
          mem_read_i = 1'b1;
          mem_to_reg_i = 1'b1;
          mem_write_i = 1'b0;
          reg_write_i = 1'b1;
          load_i = 1'b1;
          store_i = 1'b0;
          end
    7'b0100011: begin                // * S - Type (store)
          mem_read_i = 1'b0;
          mem_to_reg_i = 1'bx;
          mem_write_i = 1'b1;
          reg_write_i = 1'b0;
          load_i = 1'b0;
          store_i = 1'b1;
          end
    default: begin                // * nop
          mem_read_i = 1'b0;
          mem_to_reg_i = 1'b0;
          mem_write_i = 1'b0;
          reg_write_i = 1'b0;
          load_i = 1'b0;
          store_i = 1'b0;
            end
        endcase
      end
  end
  
endmodule
