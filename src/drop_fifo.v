module drop_fifo
   (
      input                clk,
      input                drop_pkt,
      input                fiforead,
      input                fifowrite,
      input                firstword,
      input [71:0]         in_fifo,
      input                lastword,
      input                rst,
      output [71:0]        out_fifo,
      output reg           valid_data
   );
   
   reg [71:0]        din_r;
   reg               fifowrite_r;
   reg [7:0]         writeptr_r;
   reg [7:0]         readptr_r;
   wire              readptr_en;
   assign validdata_w = fiforead & (readptr_r != writeptr_r);
   

   always @(posedge clk) begin
      if (rst) begin
         din_r          <= 'b0;
         fifowrite_r    <= 'b0;
         writeptr_r     <= 'b0;
         readptr_r      <= 'b0;
         valid_data     <= 'b0;
      end
      else begin
         din_r          <= in_fifo;
         fifowrite_r    <= fifowrite;
         if (fifowrite_r) begin
            writeptr_r     <= writeptr_r + 1;
         end
         valid_data     <= validdata_w;
         if (validdata_w)
            readptr_r      <= readptr_r + 1;
      end
   end   // always block
   
   dual_port_memory_9byte
      XLXI_14 (
               .addra      (writeptr_r),
               .addrb      (readptr_r),
               .clka       (clk),
               .clkb       (clk),
               .dina       (din_r),
               .wea        (fifowrite_r),
               .doutb      (out_fifo[71:0])
               );
endmodule
               
