`timescale 1 ns/100 ps

module data_path #(clk,rst
    parameters
) (
    ports
);

reg [7:0] PC_OUT;
reg [7:0] PC_IN;
wire [7:0] PC_increment;
reg [31:0] I_memory [0:255]; // instruction memory 256x32
wire [31:0] IF_INSTR_combinational;

    // reg pipe_reg_IF_TD, pipe_reg_ID_EX, pipe_reg_EX/MEM, pipe_reg_MEM_WB [63:0] [4:0];
assign PC_increment= 1+ PC_IN;
assign IF_INSTR_combinational=I_memory[PC_OUT]
always @(posedge clk ) begin
    PC_OUT<=PC_IN;
end

endmodule