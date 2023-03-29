module logic_thief (
  input [71:0] probe_data_i,
  input [7:0]  probe_addr_i,
  input        probe_wea_i,
  input [31:0] addr_i,
  input        wea,
  input        clk_i,
  input [31:0] cmd_i,
  output reg [95:0] data_o
);

  // wire [23:0]  ltworking;
  wire [71:0]  dout_w;
  reg  [7:0]   count_r;
  reg  [7:0]    beginrecording;
  

  //! Synchronous reset

  //always @(posedge clk_i) begin
  //  if (cmd_i == 32'hDEADDEAD) begin
  //    count_r <= 0;
  //    wr_en_r <= 1'b0;
  //      	data_o[95:72] <= 24'hFACADE;
  //  end
  //  else
  //    if (cmd_i == 32'hDEADCAFE && count_r != 255) begin
  //      wr_en_r <= 1'b1;
  //      count_r <= count_r + 1;
  //    end
  //  if (count_r == 255) begin
  //    wr_en_r <= 1'b0;
  //    data_o[95:72] <= 24'hDECADE;
  //  end
  //end

  //assign wr_ptr_w = count_r;
  //assign wr_en_w = wr_en_r;

  always @(posedge clk_i) begin
      if (cmd_i == 32'hDEADDEAD) begin
         count_r <= 0;
         data_o[95:72] <= 24'hFACADE;
         beginrecording <= 8'h00;
      end
      else if (cmd_i == 32'hDEADCAFE && count_r != 255) 
         if ((probe_data_i[71:64] == 8'hff) || (beginrecording == 8'hff)) begin
            beginrecording <= 8'hff;
            count_r <= count_r + 1;
         end
      if (count_r == 255) begin
         data_o[95:72] <= 24'hDECADE;
      end
   end
      
  always @(*) begin
    data_o[71:0] = dout_w;
  end
   // Dual-port memory such that port a is write only and thus connected
   // to fifo input
   // port b is read only and thus connected to hardware registers 

  dual_port_memory_9byte bram (
      .dina(probe_data_i),
      .addra(count_r),
      .wea(probe_wea_i),
      .addrb(addr_i),
      .clka(clk_i),
      .clkb(clk_i),
      .doutb(dout_w)
  );

endmodule
