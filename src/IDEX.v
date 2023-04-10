module IDEX 
   #(parameter PROC_DATA_WIDTH=16, 
     parameter PROC_REGFILE_LOG2_DEEP=5,
     parameter INSTMEM_LOG2_DEEP=8
   )
   ( 
       input                                 WRegEn_in, 
       input                                 WMemEn_in, 
       //input                 RMemEn_in, 
       //input                 imm_in, 
       input 				     alu_src_in,
       input                                 mem_to_reg_in, 
       //input                 load_in, 
       //input                 store_in, 
       input [PROC_DATA_WIDTH-1:0]           R1out_in, 
       input [PROC_DATA_WIDTH-1:0]           R2out_in, 
       input [PROC_DATA_WIDTH-1:0]           sign_ext_in, 
       input [PROC_REGFILE_LOG2_DEEP-1:0]    WReg1_in, 
       input [2:0]                           func3_in, 
       input       			     func7_in, 
       input                                 CLK, 
       input                                 RST,
       //input                   jal_in,
       //input                   hz_jalr_in,
       input [1:0]                           thread_id_in,    
       input [INSTMEM_LOG2_DEEP-1:0]         pc_carry_baggage_i,
      
       output reg                            WRegEn_out, 
       output reg                            WMemEn_out, 
            output reg			     alu_src_out,
       //output reg            RMemEn_out, 
       output reg                            mem_to_reg_out,
       //output reg            imm_out, 
       //output reg            load_out, 
       //output reg            store_out, 
       output reg [PROC_DATA_WIDTH-1:0]      R1out_out, 
       output reg [PROC_DATA_WIDTH-1:0]      R2out_out,
       output reg [PROC_DATA_WIDTH-1:0]      sign_ext_out, 
       output reg [PROC_REGFILE_LOG2_DEEP-1:0]     WReg1_out,
       output reg [2:0]                      func3_out,
       output reg  			     func7_out,		
       output reg [1:0]                      thread_id_out,  
       output reg [INSTMEM_LOG2_DEEP-1:0]    pc_carry_baggage_o
       //output reg            jal_out,
       //output reg            hz_jalr_out
   );
    
   always @(posedge CLK ) begin
       if(RST==1'b1)
       begin
           WRegEn_out       <= 1'b0;
           WMemEn_out       <= 1'b0;
           //RMemEn_out       <= 1'b0;
           alu_src_out 	 <= 1'b0;
                     mem_to_reg_out   <= 1'b0;
           //imm_out          <= 1'b0;
           //load_out         <= 1'b0;
           //store_out        <= 1'b0;
           R1out_out        <= 16'd0;
           R2out_out        <= 16'd0;
           sign_ext_out     <= 16'd0;
           WReg1_out        <= 5'd0;
           func3_out        <= 3'd0;
           func7_out        <= 1'b0;
           thread_id_out    <= 2'b00;
           pc_carry_baggage_o <= 'b0;
           //hz_jalr_out<=1'b0;
           //jal_out<=1'b0;
       end
       else
           WRegEn_out       <= WRegEn_in;
           WMemEn_out       <= WMemEn_in;
           //RMemEn_out       <= RMemEn_in;
           mem_to_reg_out   <= mem_to_reg_in;
           alu_src_out 	 <= alu_src_in;
           //imm_out          <= imm_in;
           //load_out         <= load_in;
           //store_out        <= store_in;
           R1out_out        <= R1out_in;
           R2out_out        <= R2out_in;
           sign_ext_out     <= sign_ext_in;
           WReg1_out        <= WReg1_in;
           func3_out        <= func3_in;
           func7_out        <= func7_in;
           thread_id_out    <= thread_id_in;
           pc_carry_baggage_o <= pc_carry_baggage_i;
           //hz_jalr_out<=hz_jalr_in;
           //jal_out<=jal_in;
       end
endmodule
