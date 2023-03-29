module THREADSELECTOR 
    #( parameter INSTMEM_LOG2_DEEP=8)
    (
        input [INSTMEM_LOG2_DEEP-1:0]       thread0_pc_i,
        input [INSTMEM_LOG2_DEEP-1:0]       thread1_pc_i,
        input [INSTMEM_LOG2_DEEP-1:0]       thread2_pc_i,
        input [INSTMEM_LOG2_DEEP-1:0]       thread3_pc_i,
        input                               clk_i,
        input                               rst_i,
        output [1:0]                        thread_id_o,
        output [INSTMEM_LOG2_DEEP-1:0]      pc_select_o
    );

    localparam THREAD0 = 2'b00;
    localparam THREAD1 = 2'b01;
    localparam THREAD2 = 2'b10;
    localparam THREAD3 = 2'b11;

    reg [1:0] state;

    assign thread_id_o= state==THREAD3 ? THREAD3 : (state==THREAD2 ? THREAD2: (state==THREAD1 ? THREAD1: THREAD0));
    assign pc_select_o= state==THREAD3 ? thread3_pc_i : (state==THREAD2 ? thread2_pc_i : (state==THREAD1 ? thread1_pc_i : thread0_pc_i));

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
