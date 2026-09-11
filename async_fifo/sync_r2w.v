`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module sync_r2w #(parameter ADDRSIZE=4)(
    input [ADDRSIZE:0]rptr,
    input wclk,wrst_n,
    
    output reg [ADDRSIZE:0] w2_rptr
    );
    
    reg [ADDRSIZE:0] w1_rptr;
    
    always @(posedge wclk or negedge wrst_n) begin
        if(!wrst_n){w2_rptr,w1_rptr} <=0;
        else begin
            w1_rptr<=rptr;
            w2_rptr<=w1_rptr;
            end
    end
endmodule
