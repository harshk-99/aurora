module thread_selector #( parameter INSTMEM_LOG2_DEEP=8)
(
    input [INSTMEM_LOG2_DEEP-1:0]       PC0,
    input [INSTMEM_LOG2_DEEP-1:0]       PC1,
    input [INSTMEM_LOG2_DEEP-1:0]       PC2,
    input [INSTMEM_LOG2_DEEP-1:0]       PC3,
    input                               clk_i,
    input                               rst_i,
    output [1:0]                        thread_id,
    output [INSTMEM_LOG2_DEEP-1:0]      PC_select
);


localparam THREAD0 = 2'b00;
localparam THREAD1 = 2'b01;
localparam THREAD2 = 2'b10;
localparam THREAD3 = 2'b11;

reg [1:0] state;

assign thread_id= state==THREAD3 ? THREAD3 : (state==THREAD2 ? THREAD2: (state==THREAD1 ? THREAD1: THREAD0));
assign PC_select= state==THREAD3 ? PC3 : (state==THREAD2 ? PC2 : (state==THREAD1 ? PC1 : PC0));

always @(posedge clk_i) begin
    if(rst_i) begin
        state<=THREAD0;
        
    end
    else begin
        case (state)
           THREAD0: begin
                state<= THREAD1;   
                
            end
            THREAD1: begin
                state<=THREAD2;
              
            end
            THREAD2: begin
                state<=THREAD3;
            end
            THREAD3: begin
                state<=THREAD0;
            end 
        endcase
    end            
end
endmodule
