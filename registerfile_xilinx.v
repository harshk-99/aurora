`include "registerfile_writeportonly.v"


module registerfile_xilinx(
    input          clk_i,
    input          write_en_i,
    input  [4:0]   write_addr_i,
    input  [63:0]  write_data_i,
    input  [4:0]   read_addr1_i,
    input  [4:0]   read_addr2_i,
    output [63:0]  read_data1_o,
    output [63:0]  read_data2_o);

    wire [63:0] x0data;
    wire [63:0] x1data;
    wire [63:0] x2data;
    wire [63:0] x3data;
    wire [63:0] x4data;
    wire [63:0] x5data;
    wire [63:0] x6data;
    wire [63:0] x7data;
    wire [63:0] x8data;
    wire [63:0] x9data;
    wire [63:0] x10data;
    wire [63:0] x11data;
    wire [63:0] x12data;
    wire [63:0] x13data;
    wire [63:0] x14data;
    wire [63:0] x15data;
    wire [63:0] x16data;
    wire [63:0] x17data;
    wire [63:0] x18data;
    wire [63:0] x19data;
    wire [63:0] x20data;
    wire [63:0] x21data;
    wire [63:0] x22data;
    wire [63:0] x23data;
    wire [63:0] x24data;
    wire [63:0] x25data;
    wire [63:0] x26data;
    wire [63:0] x27data;
    wire [63:0] x28data;
    wire [63:0] x29data;
    wire [63:0] x30data;
    wire [63:0] x31data;

registerfile_writeportonly registerfile_writeportonly(
   
   .clk(clk_i),
   .waddr(write_addr_i),
   .wdata(write_data_i),
   .wena(write_en_i),
   .x0data(x0data),
   .x1data(x1data),
   .x2data(x2data),
   .x3data(x3data),
   .x4data(x4data),
   .x5data(x5data),
   .x6data(x6data),
   .x7data(x7data),
   .x8data(x8data),
   .x9data(x9data),
   .x10data(x10data),
   .x11data(x11data),
   .x12data(x12data),
   .x13data(x13data),
   .x14data(x14data),
   .x15data(x15data),
   .x16data(x16data),
   .x17data(x17data),
   .x18data(x18data),
   .x19data(x19data),
   .x20data(x20data),
   .x21data(x21data),
   .x22data(x22data),
   .x23data(x23data),
   .x24data(x24data),
   .x25data(x25data),
   .x26data(x26data),
   .x27data(x27data),
   .x28data(x28data),
   .x29data(x29data),
   .x30data(x30data),
   .x31data(x31data)
);

always @(*) begin : r0data_mux
    case (read_addr1_i)
    5'b00000:
    read_data1_o=x0data;
    5'b00001:
    read_data1_o=x1data;
    5'b00010:
    read_data1_o=x2data;
    5'b00011:
    read_data1_o=x3data;
    5'b00100:
    read_data1_o=x4data;
    5'b00101:
    read_data1_o=x5data;
    5'b00110:
    read_data1_o=x6data;
    5'b00111:
    read_data1_o=x7data;
    5'b01000:
    read_data1_o=x8data;
    5'b01001:
    read_data1_o=x9data;
    5'b01010:
    read_data1_o=x10data;
    5'b01011:
    read_data1_o=x11data;
    5'b01100:
    read_data1_o=x12data;
    5'b01101:
    read_data1_o=x13data;
    5'b01110:
    read_data1_o=x14data;
    5'b01111:
    read_data1_o=x15data;
    5'b10000:
    read_data1_o=x16data;
    5'b10001:
    read_data1_o=x17data;
    5'b10010:
    read_data1_o=x18data;
    5'b10011:
    read_data1_o=x19data;
    5'b10100:
    read_data1_o=x20data;
    5'b10101:
    read_data1_o=x21data;
    5'b10110:
    read_data1_o=x22data;
    5'b10111:
    read_data1_o=x23data;
    5'b11000:
    read_data1_o=x24data;
    5'b11001:
    read_data1_o=x25data;
    5'b11010:
    read_data1_o=x26data;
    5'b11011:
    read_data1_o=x27data;
    5'b11100:
    read_data1_o=x28data;
    5'b11101:
    read_data1_o=x29data;
    5'b11110:
    read_data1_o=x30data;
    5'b11111:
    read_data1_o=x31data;
        default: 
        read_data1_o=64'hxxxx_xxxx_xxxx_xxxx;
    endcase
    
end

always @(*) begin : r1data_mux
    case (read_addr2_i)
    5'b00000:
    read_data2_o=x0data;
    5'b00001:
    read_data2_o=x1data;
    5'b00010:
    read_data2_o=x2data;
    5'b00011:
    read_data2_o=x3data;
    5'b00100:
    read_data2_o=x4data;
    5'b00101:
    read_data2_o=x5data;
    5'b00110:
    read_data2_o=x6data;
    5'b00111:
    read_data2_o=x7data;
    5'b01000:
    read_data2_o=x8data;
    5'b01001:
    read_data2_o=x9data;
    5'b01010:
    read_data2_o=x10data;
    5'b01011:
    read_data2_o=x11data;
    5'b01100:
    read_data2_o=x12data;
    5'b01101:
    read_data2_o=x13data;
    5'b01110:
    read_data2_o=x14data;
    5'b01111:
    read_data2_o=x15data;
    5'b10000:
    read_data2_o=x16data;
    5'b10001:
    read_data2_o=x17data;
    5'b10010:
    read_data2_o=x18data;
    5'b10011:
    read_data2_o=x19data;
    5'b10100:
    read_data2_o=x20data;
    5'b10101:
    read_data2_o=x21data;
    5'b10110:
    read_data2_o=x22data;
    5'b10111:
    read_data2_o=x23data;
    5'b11000:
    read_data2_o=x24data;
    5'b11001:
    read_data2_o=x25data;
    5'b11010:
    read_data2_o=x26data;
    5'b11011:
    read_data2_o=x27data;
    5'b11100:
    read_data2_o=x28data;
    5'b11101:
    read_data2_o=x29data;
    5'b11110:
    read_data2_o=x30data;
    5'b11111:
    read_data2_o=x31data;
        default: 
        read_data2_o=64'hxxxx_xxxx_xxxx_xxxx;
    endcase
end

endmodule

