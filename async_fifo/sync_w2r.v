`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
//////////////////////////////////////////////////////////////////////////////////
module sync_w2r #(parameter ADDRSIZE=4)(
    input [ADDRSIZE:0] wptr,
    input rclk,rrst_n,
    
    output reg [ADDRSIZE:0] r2_wptr
    );
    
    reg [ADDRSIZE:0] r1_wptr;
    
    always @(posedge rclk or negedge rrst_n) begin
    if(!rrst_n) {r2_wptr,r1_wptr} <=0;
    else begin
        r1_wptr <=wptr;
        r2_wptr <=r1_wptr;
        end
    end
endmodule
