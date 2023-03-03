//////////////////////////////////////////////////////////////////////////////
// Adopted from EE457 file named alu_4_bit.v from Professor Gandhi Puvvada, EE-Systems, VSoE, USC
//////////////////////////////////////////////////////////////////////////////
//  We have adopted the control instruction encoding of RISC v2.0 RV32I Base format
//  in_funct7 has to be read along with in_funct3 to decode the ALU operations
//  this is done so to be compliant with RISC V processor
//  Although RV32I is a 32-bit Instruction format, but for the case of simplicity,we are going to be use
// this instruction set for our 64 bit processor
//         in_funct3       ALU Instruction     Brief Description
//             000         BEQ                 SUB performs the subtraction of rs2 from rs1.
//             001         BNE                 
//             100         BLT                 SLT and SLTU perform signed and unsigned
//             101         BGE                compares respectively, writing 1 to rd if rs1 < rs2, 0 otherwise.
//             110         BLTU
//             111         BGEU          
//-------------------------------------------------------------------------------

// 1-bit ALU building block alu_1_bit

module br_alu
    #( parameter DATA_WIDTH=16)
    (
        input   [DATA_WIDTH-1:0]    in_rs1,
        input   [DATA_WIDTH-1:0]    in_rs2, 
				output  reg out_branch
    );
		 
    always @(*) // same as   always @(A, B, Ainv, Binv, CIN, Opr, LESS) 
	    begin
				if ($signed(in_rs1) < $signed(in_rs2)) begin
					out_branch = 1'b1;
				end else begin
					out_branch= 1'b0;			
				end
	end 
	
endmodule 
