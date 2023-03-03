//////////////////////////////////////////////////////////////////////////////
// Adopted from EE457 file named alu_4_bit.v from Professor Gandhi Puvvada, EE-Systems, VSoE, USC
//////////////////////////////////////////////////////////////////////////////
//  We have adopted the control instruction encoding of RISC v2.0 RV32I Base format
//  in_funct7 has to be read along with in_funct3 to decode the ALU operations
//  this is done so to be compliant with RISC V processor
//  Although RV32I is a 32-bit Instruction format, but for the case of simplicity,we are going to be use
// this instruction set for our 64 bit processor
//  in_funct7       in_funct3       ALU Instruction     Brief Description
//  0000000             000         ADD
//  0100000             000         SUB                 SUB performs the subtraction of rs2 from rs1.
//  0000000             001         SLL                 
//  0000000             010         SLT                 SLT and SLTU perform signed and unsigned
//  0000000             011         SLTU                compares respectively, writing 1 to rd if rs1 < rs2, 0 otherwise.
//  0000000             100         XOR
//  0000000             101         SRL
//  0100000             101         SRA
//  0000000             110         OR
//  0000000             111         AND             
//-------------------------------------------------------------------------------

// 1-bit ALU building block alu_1_bit
`timescale 1 ns / 100 ps

module alu_64_bit
    #( parameter DATA_WIDTH=16)
    (
        input   [DATA_WIDTH-1:0]    in_rs1,
        input   [DATA_WIDTH-1:0]    in_rs2, 
        input   [2:0]   						in_funct3,
        input                  			in_funct7,
        output  reg [DATA_WIDTH-1:0]    out_rd
    );
		//reg [DATA_WIDTH-1:0] out_rd;
    //reg     [DATA_WIDTH:0] temp_result;
	 wire 	[3:0]				funct7_and_3;
    //assign out_rd = temp_result[DATA_WIDTH-1:0];
	 wire signed [DATA_WIDTH-1:0] signed_in_rs1;
    //assign out_overflow = temp_result[DATA_WIDTH];
    assign funct7_and_3 = {in_funct7,in_funct3};
	 assign signed_in_rs1 = in_rs1;
	 
    always @(*) // same as   always @(A, B, Ainv, Binv, CIN, Opr, LESS) 
    begin  : combinational_logic // named procedural block
		case (funct7_and_3)
			4'b0000	:   // Addition Function
				  begin
					out_rd = in_rs1+in_rs2; 
				  end
            4'b0110:    // OR
					begin
					 out_rd = in_rs1 | in_rs2; 
					end
				4'b1000	:   // Subtraction Function
				  begin
					out_rd = in_rs1 - in_rs2; 
				  end
		   default:    
              begin
					 out_rd = 64'hxxxx_xxxx_xxxx_xxxx; 
              end
		  endcase
	end 

endmodule //alu_64_bit
