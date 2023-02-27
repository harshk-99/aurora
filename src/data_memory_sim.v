module data_memory (
  input          clk,
  input          rst,
  input  [7:0]  mem_address,
  input  [63:0]  data_in,
  input          write_en,
  input          read_en,
  output reg [63:0]  data_out
);

integer i;

reg [63:0] ram [256:0];

initial  
      begin  
          ram[0] = 64'h0000000000000001;
          ram[1] = 64'h0000000000000002;
          ram[2] = 64'h0000000000000003;
          ram[3] = 64'h0000000000000004;
          ram[4] = 64'h0000000000000005;
          ram[5] = 64'h0000000000000006;
          ram[6] = 64'h0000000000000007;
          ram[7] = 64'h0000000000000008;
          ram[8] = 64'h0000000000000009;
          ram[9] = 64'h000000000000000a;
          ram[10] = 64'h000000000000000b;
          ram[11] = 64'h000000000000000c;
          ram[12] = 64'h000000000000000d;
          ram[13] = 64'h000000000000000e;
          ram[14] = 64'h000000000000000f;
          ram[15] = 64'h0000000000000010;
          ram[16] = 64'h0000000000000011;
          ram[17] = 64'h0000000000000030;
          ram[18] = 64'h0000000000000040;
          ram[19] = 64'h0000000000000050;
          ram[20] = 64'h0000000000000060;
          ram[21] = 64'h0000000000000070;
          ram[22] = 64'h0000000000000080;
          ram[23] = 64'h0000000000000090;
          ram[24] = 64'h00000000000000a0;
          ram[25] = 64'h00000000000000b0;
          ram[26] = 64'h00000000000000c0;
          ram[27] = 64'h00000000000000d0;
          ram[28] = 64'h00000000000000e0;
          ram[29] = 64'hff00000000000000;
          ram[30] = 64'h0000000000000000;
          ram[31] = 64'hff000000000000f0;

                for (i = 32; i <= 255; i=i+1) begin
                  ram[i] = 64'd0;
                end
                
      end


always @(posedge clk) begin
  if (write_en && !rst)
    ram[mem_address] <= data_in;
  else if (read_en && !rst)
    data_out <= ram[mem_address];
end

endmodule
