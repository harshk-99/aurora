// immd_o (sitting in EX stage which is select line for a mux)meant for I type instruction to select sign extended value instead of rs2
// JAL does not have any source registers therefore HDU won't ever come into play.
// have decided to go with three 2:1 64 bit wide muxes for jal, jump, and branch instr in ID stage due to less fan-in
// no possible hazard for JAL
// possible RAW hazard for JALR
module control_unit (
     input [6:0]        opcode_i,
     input              reset_i,
     input              wb_ff_i,
     output reg         mem_to_reg_o, 
     output reg         mem_write_o, 
     output reg         reg_write_o, 
     output reg         load_o, 
     output reg         store_o, 
     output reg         immd_o, 
     output reg         jal_o, 
     output reg         branch_o
  );   

  always @(*) begin
    if (reset_i == 1'b1 || wb_ff_i) begin
         //mem_read_i = 1'b0;
         mem_to_reg_o = 1'b0;
         mem_write_o = 1'b0;
         reg_write_o = 1'b0;
         immd_o = 1'b0;
         load_o = 1'b0;
         store_o = 1'b0;
         jal_o=1'b0;
         //jalr_i=1'b0;
         branch_o=1'b0;
   end 
   else begin
      case (opcode_i)
    7'b0110011: begin                // * R - Type
          //mem_read_i = 1'b0;
          mem_to_reg_o = 1'b0;
          mem_write_o = 1'b0;
          reg_write_o = 1'b1;
          immd_o = 1'b0;
          load_o = 1'b0;
          store_o = 1'b0;
          jal_o=1'b0;
          //jalr_i=1'b0;
          branch_o=1'b0;
          end
    7'b0010011: begin                // * I - Type (Arithmetic)
          //mem_read_i = 1'b0;
          mem_to_reg_o = 1'b0;
          mem_write_o = 1'b0;
          reg_write_o = 1'b1;
          immd_o = 1'b1;
          load_o = 1'b0;
          store_o = 1'b0;
          jal_o=1'b0;
          //jalr_i=1'b0;
          branch_o=1'b0;
          end
    7'b0000011: begin                // * I - Type (load)
          //mem_read_i = 1'b1;
          mem_to_reg_o = 1'b1;
          mem_write_o = 1'b0;
          reg_write_o = 1'b1;
          immd_o = 1'b1;
          load_o = 1'b1;
          store_o = 1'b0;
          jal_o=1'b0;
          //	jalr_i=1'b0;
          branch_o=1'b0;
          end
    7'b0100011: begin                // * S - Type (store)
          //mem_read_i = 1'b0;
          mem_to_reg_o = 1'bx;
          mem_write_o = 1'b1;
          reg_write_o = 1'b0;
          immd_o = 1'b0;
          load_o = 1'b0;
          store_o = 1'b1;
          jal_o=1'b0;
          //jalr_i=1'b0;
          branch_o=1'b0;
          end
    7'b1100011: begin                // * SB - Type (branch)
            //mem_read_i = 1'b0;
            mem_to_reg_o = 1'b0;
            mem_write_o = 1'b0;
            reg_write_o = 1'b0;
            immd_o = 1'b0;
            load_o = 1'b0;
            store_o = 1'b0;
            jal_o=1'b0;
            //jalr_i=1'b0;
            branch_o=1'b1;
            end
    7'b1101111: begin                // * UJ - Type (jal)  
              //mem_read_i = 1'b0;
              mem_to_reg_o = 1'b0;
              mem_write_o = 1'b0;
              reg_write_o = 1'b1;
              immd_o = 1'bx;
              load_o = 1'bx;
              store_o = 1'bx;
              jal_o=1'b1;
              //jalr_i=1'b0;
              branch_o=1'b0;
              end       
    //7'b1100111: begin                // * I - Type (jalr)
                //mem_read_i = 1'b0;
                //mem_to_reg_o = 1'b0;
                //mem_write_o = 1'b0;
                //reg_write_o = 1'b1;
                //immd_o = 1'b0;           // it can be don't care also
                //load_o = 1'b0;
                //store_o = 1'b0;
                //jal_o=1'b0;
                //jalr_i=1'b1;
                //branch_o=1'b0;
                //end         
    default: begin                // * nop
          //mem_read_i = 1'b0;
          mem_to_reg_o = 1'bx;
          mem_write_o = 1'b0;
          reg_write_o = 1'b0;
          immd_o = 1'bx;
          load_o = 1'bx;
          store_o = 1'bx;
          jal_o=1'b0;
          //jalr_i=1'b0;
          branch_o=1'b0;
            end
        endcase
      end
  end
  
endmodule
