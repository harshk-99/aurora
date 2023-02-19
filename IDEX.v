module IDEX ( 
    input                 WRegEn_in, 
    input                 WMemEn_in, 
    input                 RMemEn_in, 
    input                 mem_to_reg_in, 
    input                 load_in, 
    input                 store_in, 
    input       [63:0]    R1out_in, 
    input       [63:0]    R2out_in, 
    input       [63:0]    sign_ext_in, 
    input       [4:0]     WReg1_in, 
    input       [2:0]     func3_in, 
    input       [6:0]     func7_in, 
    input                 CLK, 
    input                 RST,

    output reg            WRegEn_out, 
    output reg            WMemEn_out, 
    output reg            RMemEn_out, 
    output reg            mem_to_reg_out, 
    output reg            load_out, 
    output reg            store_out, 
    output reg  [63:0]    R1out_out, 
    output reg  [63:0]    R2out_out,
    output reg  [63:0]    sign_ext_out, 
    output reg  [4:0]     WReg1_out,
    output reg  [2:0]     func3_out,
    output reg  [6:0]     func7_out
);
    
always @(posedge CLK ) begin
    if(RST==1'b1)
    begin
        WRegEn_out       <= 1'b0;
        WMemEn_out       <= 1'b0;
        RMemEn_out       <= 1'b0;
        mem_to_reg_out   <= 1'b0;
        load_out         <= 1'b0;
        store_out        <= 1'b0;
        R1out_out        <= 64'd0;
        R2out_out        <= 64'd0;
        sign_ext_out     <= 64'd0;
        WReg1_out        <= 5'd0;
        func3_out        <= 3'd0;
        func7_out        <= 7'd0;
    end
    else
        WRegEn_out       <= WRegEn_in;
        WMemEn_out       <= WMemEn_in;
        RMemEn_out       <= RMemEn_in;
        mem_to_reg_out   <= mem_to_reg_in;
        load_out         <= load_in;
        store_out        <= store_in;
        R1out_out        <= R1out_in;
        R2out_out        <= R2out_in;
        sign_ext_out     <= sign_ext_in;
        WReg1_out        <= WReg1_in;
        func3_out        <= func3_in;
        func7_out        <= func7_in;
end

endmodule
