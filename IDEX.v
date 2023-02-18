module IDEX ( input WRegEn_in, 
input WMemEn_in, 
input[63:0] R1out_in, 
input [63:0] R2out_in, 
input [4:0] WReg1_in, 
input CLK, 
input RST,
output reg WRegEn_out, 
output reg WMemEn_out, 
output reg [63:0] R1out_out, 
output reg [63:0] R2out_out, 
output reg [4:0] WReg1_out
);
    
always @(posedge clk ) begin
    if(RST=1'b1)
    begin
        WRegEn_out<= 1'd0; 
        WMemEn_out<= 1'd0;
        R1out_out <= 64'd0;
        R2out_out <= 64'd0;
        WReg1_out <= 5'd0;
    end
    else
        WRegEn_out<= WMemEn_in; 
        WMemEn_out<= WMemEn_in;
        R1out_out <= R1out_in;
        R2out_out <= R2out_in;
        WReg1_out <= WReg1_in;
end

endmodule