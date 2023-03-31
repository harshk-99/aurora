///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: module_template 2008-03-13 gac1 $
//
// Module: ids.v
// Project: NF2.1
// Description: Defines a simple ids module for the user data path.  The
// modules reads a 64-bit register that contains a pattern to match and
// counts how many packets match.  The register contents are 7 bytes of
// pattern and one byte of mask.  The mask bits are set to one for each
// byte of the pattern that should be included in the mask -- zero bits
// mean "don't care".
// This file has been modified and now mimics ids_sim file
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module ids 
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter UDP_REG_SRC_WIDTH = 2
   )
   (
      input  [DATA_WIDTH-1:0]             in_data,
      input  [CTRL_WIDTH-1:0]             in_ctrl,
      input                               in_wr,
      output                              in_rdy,

      output [DATA_WIDTH-1:0]             out_data,
      output [CTRL_WIDTH-1:0]             out_ctrl,
      output                              out_wr,
      input                               out_rdy,
      
      // --- Register interface
      input                               reg_req_in,
      input                               reg_ack_in,
      input                               reg_rd_wr_L_in,
      input  [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr_in,
      input  [`CPCI_NF2_DATA_WIDTH-1:0]   reg_data_in,
      input  [UDP_REG_SRC_WIDTH-1:0]      reg_src_in,

      output                              reg_req_out,
      output                              reg_ack_out,
      output                              reg_rd_wr_L_out,
      output  [`UDP_REG_ADDR_WIDTH-1:0]   reg_addr_out,
      output  [`CPCI_NF2_DATA_WIDTH-1:0]  reg_data_out,
      output  [UDP_REG_SRC_WIDTH-1:0]     reg_src_out,

      // misc
      input                                reset,
      input                                clk
   );

   // Define the log2 function
   // `LOG2_FUNC

   //------------------------- Parameters-------------------------------
   parameter INSTMEM_LOG2_DEEP=8;
   //------------------------- Signals-------------------------------
   
   //wire [DATA_WIDTH-1:0]         in_fifo_data;
   //wire [CTRL_WIDTH-1:0]         in_fifo_ctrl;
   wire [DATA_WIDTH-1:0]         in_fifo_data_p;
   wire [CTRL_WIDTH-1:0]         in_fifo_ctrl_p;   // decide the movement of state machine
	
   reg [DATA_WIDTH-1:0]         in_fifo_data;
   reg [CTRL_WIDTH-1:0]         in_fifo_ctrl;

   wire                          ftsf_nearly_full;
   wire                          ftsf_empty_w;     // fall through small fifo - ftsf
   reg [7:0]                     temp_counter_next_w;
   reg [7:0]                     temp_counter_r;
   reg                           ftsf_rd_en_w;
   reg                           in_fifo_wr_messenger_r;
   wire                          smgen_out_rdy_w;     // state machine generated out_rdy
   reg			         in_fifo_wr_messenger_next;
   // software registers 
   wire [31:0]                   pattern_high;
   wire [31:0]                   pattern_low;
   wire [31:0]                   ids_cmd;
   // hardware registers
   reg [31:0]                    matches;

   // internal state
   reg [1:0]                        state, state_next;
   wire                             out_wr_w;
   reg [CTRL_WIDTH+DATA_WIDTH-1:0]  din_r;
   reg                              out_wr_r;
   reg [INSTMEM_LOG2_DEEP-1:0]      readptr_r;
   reg [INSTMEM_LOG2_DEEP-1:0]      writeptr_r;
   reg                              fifowrite_r;
   // local parameter
   parameter                     START = 2'b00;
   parameter                     PAYLOAD = 2'b01;
   parameter                     CPU_PROCESS = 2'b11;
   parameter                     READ_READY = 2'b10;

 
   //------------------------- Modules-------------------------------

   fallthrough_small_fifo #(
      .WIDTH(CTRL_WIDTH+DATA_WIDTH),
      .MAX_DEPTH_BITS(2)
   ) input_fifo (
      .din           ({in_ctrl, in_data}),   // Data in
      .wr_en         (in_wr),                // Write enable
      .rd_en         (ftsf_rd_en_w),        // Read the next word 
      //.dout          ({in_fifo_ctrl, in_fifo_data}),
      .dout          ({in_fifo_ctrl_p, in_fifo_data_p}),
      .full          (),
      .nearly_full   (ftsf_nearly_full),
      .empty         (ftsf_empty_w),
      .reset         (reset),
      .clk           (clk)
   );

   // BRAM READ WRITE FUNCTIONALITY INTEGRATION
   
   always @(posedge clk) begin
       if (reset) begin
          din_r          <= 'b0;
          fifowrite_r    <= 'b0;
          writeptr_r     <= 'b0;
          readptr_r      <= 'b0;
          out_wr_r       <= 'b0;
       end
       else begin
          din_r          <= {in_fifo_ctrl,in_fifo_data};
          fifowrite_r    <= in_fifo_wr_messenger_r;
          if (fifowrite_r) begin
             writeptr_r     <= writeptr_r + 1;
          end
          out_wr_r     <= out_wr_w;
          if (out_wr_w)
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
                .doutb      ({out_ctrl,out_data})
                );
   generic_regs
   #( 
      .UDP_REG_SRC_WIDTH   (UDP_REG_SRC_WIDTH),
      .TAG                 (`IDS_BLOCK_ADDR),          // Tag -- eg. MODULE_TAG
      .REG_ADDR_WIDTH      (`IDS_REG_ADDR_WIDTH),     // Width of block addresses -- eg. MODULE_REG_ADDR_WIDTH
      .NUM_COUNTERS        (0),                 // Number of counters
      .NUM_SOFTWARE_REGS   (3),                 // Number of sw regs
      .NUM_HARDWARE_REGS   (1)                  // Number of hw regs
   ) module_regs (
      .reg_req_in       (reg_req_in),
      .reg_ack_in       (reg_ack_in),
      .reg_rd_wr_L_in   (reg_rd_wr_L_in),
      .reg_addr_in      (reg_addr_in),
      .reg_data_in      (reg_data_in),
      .reg_src_in       (reg_src_in),

      .reg_req_out      (reg_req_out),
      .reg_ack_out      (reg_ack_out),
      .reg_rd_wr_L_out  (reg_rd_wr_L_out),
      .reg_addr_out     (reg_addr_out),
      .reg_data_out     (reg_data_out),
      .reg_src_out      (reg_src_out),

      // --- counters interface
      .counter_updates  (),
      .counter_decrement(),

      // --- SW regs interface
      .software_regs    ({ids_cmd,pattern_low,pattern_high}),

      // --- HW regs interface
      .hardware_regs    (matches),

      .clk              (clk),
      .reset            (reset)
    );



   //------------------------- Logic-------------------------------
   assign in_rdy     = !ftsf_nearly_full & (!(state_next == CPU_PROCESS | state_next == READ_READY));
   assign out_wr_w   = out_rdy & (readptr_r != writeptr_r) & (state == READ_READY);
   assign out_wr     = out_wr_r;
   
   always @(*) begin
      state_next = state;
      ftsf_rd_en_w = 0;
      in_fifo_wr_messenger_next = 0;
      temp_counter_next_w = temp_counter_r;
      
      if (!ftsf_empty_w && out_rdy) begin
         in_fifo_wr_messenger_next = 1;
         ftsf_rd_en_w = 1;
         
         case(state)
            START: begin
               if (in_fifo_ctrl_p != 0) begin
                  state_next = PAYLOAD;
                  temp_counter_next_w = 0;
               end
            end
            PAYLOAD: begin
               if (in_fifo_ctrl_p != 0) begin
                  state_next = CPU_PROCESS;
               end
               else begin
               end
            end
         endcase // case(state)
      end
      if (state == CPU_PROCESS) begin
         // first empty out all the contents of ftsf to data memory
         if (!ftsf_empty_w)  begin
            in_fifo_wr_messenger_next = 1;
            ftsf_rd_en_w = 1;
         end   // end of ftsf_empty
         else begin
            temp_counter_next_w = temp_counter_r + 1;
            if (temp_counter_r == 8'd10) begin
               state_next = READ_READY;
            end
         end   // now perform some operation
      end // end of CPU_PROCESS_STATE
      if (state == READ_READY) begin
         if (readptr_r == writeptr_r) begin
            state_next = START;
         end   
      end // end of READ_READY state
   end // always @ (*)
   
   always @(posedge clk) begin
      if(reset) begin
         matches <= 0;
         state <= START;
	 in_fifo_ctrl      <= 0;
	 in_fifo_data      <= 0;
         temp_counter_r    <= 0;
      end
      else begin
         state <= state_next;
	 in_fifo_ctrl <= in_fifo_ctrl_p;
	 in_fifo_data <= in_fifo_data_p;
	 in_fifo_wr_messenger_r <= in_fifo_wr_messenger_next;
         temp_counter_r <= temp_counter_next_w;   
      end // else: !if(reset)
   end // always @ (posedge clk)   


endmodule 
