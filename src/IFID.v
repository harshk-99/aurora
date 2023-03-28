// IFID stage register
module IFID 
   #(parameter INSTMEM_LOG2_DEEP=8)   
   ( 
    input [INSTMEM_LOG2_DEEP-1:0]           PC_in, 
    input                                   CLK, 
    input                                   RST,
    input                                   wb_ff_in,
    input                                   hazard,
    input [1:0]                             thread_id_in,
    //input   [INSTMEM_LOG2_DEEP-1:0]              incre_pc_in,
    
    output reg  [INSTMEM_LOG2_DEEP-1:0]     PC_out,
    output reg                              wb_ff_out,
    output reg [1:0]                        thread_id_out
    //output reg [INSTMEM_LOG2_DEEP-1:0]        incre_pc_out
);
  
always @(posedge CLK ) begin
    if(RST==1'b1)
    begin
        PC_out          <= 8'b00000000;
        wb_ff_out       <= 1'b0;  
        thread_id_out   <= 2'b00;
        //incre_pc_out    <=8'b00000000;
    end
    else if (hazard) begin
        PC_out          <= PC_out;
        wb_ff_out       <= wb_ff_out;
    end
    else
        PC_out          <= PC_in;
        wb_ff_out       <= wb_ff_in;
        thread_id_out   <= thread_id_in;
        //incre_pc_out <=incre_pc_in;
end

endmodule
