`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

module rptr_empty #(ADDRSIZE=4)(
    input [ADDRSIZE:0] r2_wptr,
    input rinc,rclk,rrst_n,
    
    output reg rempty,
    output reg [ADDRSIZE:0] rptr,
    output [ADDRSIZE-1:0] raddr
    );
    
 reg [ADDRSIZE:0] rbin;
 wire [ADDRSIZE:0] rgraynext, rbinnext;

 always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) {rbin, rptr} <= 0;
    else {rbin, rptr} <= {rbinnext, rgraynext};
 end
 
 assign raddr = rbin[ADDRSIZE-1:0];
 assign rbinnext = rbin + (rinc & ~rempty);
 assign rgraynext = (rbinnext>>1) ^ rbinnext;
 assign rempty_val = (rgraynext == r2_wptr);
 
 always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) rempty <= 1'b1;
    else rempty <= rempty_val;
 end
endmodule
