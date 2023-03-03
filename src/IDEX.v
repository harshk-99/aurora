module IDEX ( 
    input                 WRegEn_in, 
    input                 WMemEn_in, 
    input                 mem_to_reg_in, 
    input                 rs2_swch_in, 
    input       [15:0]    R1out_in, 
    input       [15:0]    R2out_in, 
    input       [15:0]    sign_ext_in, 
    input       [3:0]     WReg1_in, 
    input       [2:0]     func3_in, 
    input                 func7_in, 
    input                 CLK, 
    input                 RST,

    output reg            WRegEn_out, 
    output reg            WMemEn_out, 
    output reg            mem_to_reg_out,
    output reg            rs2_swch_out, 
    output reg  [15:0]    R1out_out, 
    output reg  [15:0]    R2out_out,
    output reg  [15:0]    sign_ext_out, 
    output reg  [3:0]     WReg1_out,
    output reg  [2:0]     func3_out,
    output reg            func7_out
);
    
always @(posedge CLK ) begin
    if(RST==1'b1)
    begin
        WRegEn_out       <= 1'b0;
        WMemEn_out       <= 1'b0;
        mem_to_reg_out   <= 1'b0;
        rs2_swch_out     <= 1'b0;
        R1out_out        <= 16'd0;
        R2out_out        <= 16'd0;
        sign_ext_out     <= 16'd0;
        WReg1_out        <= 4'd0;
        func3_out        <= 3'd0;
        func7_out        <= 1'b0;
    end
    else begin
        WRegEn_out       <= WRegEn_in;
        WMemEn_out       <= WMemEn_in;
        mem_to_reg_out   <= mem_to_reg_in;
        rs2_swch_out     <= rs2_swch_in;
        R1out_out        <= R1out_in;
        R2out_out        <= R2out_in;
        sign_ext_out     <= sign_ext_in;
        WReg1_out        <= WReg1_in;
        func3_out        <= func3_in;
        func7_out        <= func7_in;
    end
end

endmodule
