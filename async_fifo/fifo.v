`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module fifo #(parameter DSIZE = 8,parameter ASIZE = 4)(

    input [DSIZE-1:0] wdata,
    input winc, wclk, wrst_n,
    input rinc, rclk, rrst_n,
 
    output [DSIZE-1:0] rdata,
    output wfull,
    output rempty
 );
 
 wire [ASIZE-1:0] waddr, raddr;
 wire [ASIZE:0] wptr, rptr, w2_rptr, r2_wptr;
 
 sync_r2w sync_r2w (
    .w2_rptr(w2_rptr), 
    .rptr(rptr),
    .wclk(wclk), 
    .wrst_n(wrst_n)
    );
    
 sync_w2r sync_w2r (
    .r2_wptr(r2_wptr), 
    .wptr(wptr),
    .rclk(rclk), 
    .rrst_n(rrst_n)
    );
    
 fifomem #(DSIZE, ASIZE) fifomem(
    .rdata(rdata), 
    .wdata(wdata),
    .waddr(waddr), 
    .raddr(raddr),
    .wclken(winc), 
    .wfull(wfull),
    .wclk(wclk)
    );
    
 rptr_empty #(ASIZE) rptr_empty (
    .rempty(rempty),
    .raddr(raddr),
    .rptr(rptr), 
    .r2_wptr(r2_wptr),
    .rinc(rinc), 
    .rclk(rclk),
    .rrst_n(rrst_n)
    );
    
 wptr_full #(ASIZE) wptr_full (
    .wfull(wfull), 
    .waddr(waddr),
    .wptr(wptr), 
    .w2_rptr(w2_rptr),
    .winc(winc), 
    .wclk(wclk),
    .wrst_n(wrst_n)
    );
endmodule
