//
//      0000    (0)                         Addition
//      1000    (8)                         Subtraction
//      0001    (1)                         SLL
//      0010    (2)                         SLT
//      0011    (3)                         SLTU
//      0100    (4)                         XOR
//      0101    (5)                         SRL
//      1101    (13)                        SRA
//      0110    (6)                         OR
//      0111    (7)                         AND
//      1001    (9)                         BNE
//      1010    (10)                        BEQ
//      1011    (11)                        BGE
//      1100    (12)                        BLT
//      1110    (14)                        BLTU
//      1111    (15)                        BGEU   

module structuraladd_sub (
    input a,
    input b,
    input opr,
    input cin,
    output s,
    output cout
);
wire transformedb = opr ? ~b:b;
assign {cout, s} = a + transformedb + cin;
endmodule

module alu_64_bit_slim_withbr (
    input   [63:0]        in_rs1,
    input   [63:0]        in_rs2, 
    input   [2:0]                   in_funct3,
    input                      in_funct7,
    output  reg [63:0]    out_rd
);

wire [63:0]     sum;
wire [63:0]     cout;
wire eq_w, ne_w, sltu_w, slt_w, greq_w, grequ_w;
reg cin, sub;
wire signed_overflow;
reg signed [63:0]  rs1_signed;
//reg signed [63:0]   rs2_signed;
wire [3:0] funct7_and_3; 
assign funct7_and_3 = {in_funct7,in_funct3};

assign signed_overflow = cout[63] ^ cout[62];
assign eq_w = ~(|sum);
assign ne_w = (|sum);
assign sltu_w = ~cout[63];
assign grequ_w = ~sltu_w;
assign slt_w = signed_overflow ^ sum[63];
assign greq_w = ~slt_w;

always @(*) begin
    rs1_signed = in_rs1;
//    rs2_signed = in_rs2;
end

structuraladd_sub a0 (
    .a      (in_rs1[0]),
    .b      (in_rs2[0]),
    .cin    (cin),
    .opr    (sub),
    .s      (sum[0]),
    .cout   (cout[0])
);

genvar i;
generate
    for (i = 1; i< 64; i = i+1)
    begin: structuraladd_sub
        structuraladd_sub a0 (
            .a      (in_rs1[i]),
            .b      (in_rs2[i]),
            .cin    (cout[i-1]),
            .opr    (sub),
            .s      (sum[i]),
            .cout   (cout[i])
        );
    end
endgenerate

always @(*) begin
    cin = 1'b0;
    sub = 1'b0;
    out_rd = 64'd0;
    case (funct7_and_3)
    4'b0000: begin out_rd = sum; end                                    // Addition
    4'b1000: begin                                                      // Subtraction
        cin = 1'b1;
        sub = 1'b1;
        out_rd = sum;
    end
    4'b0001:    out_rd = in_rs1 << in_rs2[4:0];                         // SLL
    4'b0010, 4'b1100: begin                                             // SLT and BLT
        cin = 1'b1;
        sub = 1'b1;
        out_rd = slt_w;
    end
    4'b0011, 4'b1110: begin                                             // SLTU and BLTU
        cin = 1'b1;
        sub = 1'b1;
        out_rd = sltu_w;
    end
    4'b0100:    out_rd = in_rs1 ^ in_rs2;                               // XOR
    4'b0101:    out_rd = in_rs1 >> in_rs2[4:0];                         // SRL
    4'b1101:    out_rd = rs1_signed >>> in_rs2[4:0];                    // SRA
    4'b0110:    out_rd = in_rs1 | in_rs2;                               // OR
    4'b0111:    out_rd = in_rs1 & in_rs2;                               // AND
    4'b1010:    begin                                                   // BEQ 
        cin = 1'b1;
        sub = 1'b1;
        out_rd = eq_w;                                          
    end
    4'b1001:    begin                                                   // BNE 
        cin = 1'b1;
        sub = 1'b1;
        out_rd = ne_w;                                          
    end
    4'b1011:    begin                                                   // BGE 
        cin = 1'b1;
        sub = 1'b1;
        out_rd = greq_w;                                          
    end
    4'b1111:    begin                                                   // BGEU 
        cin = 1'b1;
        sub = 1'b1;
        out_rd = grequ_w;                                          
    end


    default:    begin out_rd = 64'hxxxx_xxxx_xxxx_xxxx; end
    endcase
end

endmodule