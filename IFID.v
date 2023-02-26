// IFID stage register
module IFID ( 
    input [7:0]           PC_in, 
    input                 CLK, 
    input                 RST,
    input                 wb_ff_in,
    input   [7:0]              incre_pc_in,

    
    output reg  [7:0]     PC_out,
    output reg            wb_ff_out,
    output reg [7:0]        incre_pc_out
);
  
always @(posedge CLK ) begin
    if(RST==1'b1)
    begin
        PC_out          <= 8'b00000000;
        wb_ff_out       <= 1'b0;  
        incre_pc_out    <=8'b00000000;
    end
    else
        PC_out          <= PC_in;
        wb_ff_out       <= wb_ff_in;
        incre_pc_out <=incre_pc_in;
end

endmodule
