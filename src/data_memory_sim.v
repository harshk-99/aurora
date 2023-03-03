module data_memory (
  input          clk,
  input  [7:0]  mem_address,
  input  [15:0]  data_in,
  input          write_en,
  output reg [15:0]  data_out
);

integer i;

reg [63:0] ram [256:0];

initial  
      begin  
          ram[0] = 16'h0003;
          ram[1] = 16'h0005;
          ram[2] = 16'h0001;
          ram[3] = 16'h0002;
          ram[4] = 16'h0004;

                for (i = 5; i <= 255; i=i+1) begin
                  ram[i] = 16'd0;
                end
                
      end


always @(posedge clk) begin
  if (write_en)
    ram[mem_address] <= data_in;
  data_out <= ram[mem_address];
end

endmodule
