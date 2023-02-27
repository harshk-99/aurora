module data_memory (
  input          clk,
  input  [7:0]  mem_address,
  input  [63:0]  data_in,
  input          write_en,
  output reg [63:0]  data_out
);

integer i;

reg [63:0] ram [256:0];

initial  
      begin  
          ram[0] = 64'h0000000000000003;
          ram[1] = 64'h0000000000000005;
          ram[2] = 64'h0000000000000001;
          ram[3] = 64'h0000000000000002;
          ram[4] = 64'h0000000000000004;

                for (i = 5; i <= 255; i=i+1) begin
                  ram[i] = 64'd0;
                end
                
      end


always @(posedge clk) begin
  if (write_en)
    ram[mem_address] <= data_in;
  data_out <= ram[mem_address];
end

endmodule
