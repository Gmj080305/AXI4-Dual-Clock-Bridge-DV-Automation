`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

module wptr_full #(parameter ADDRSIZE = 4) (
    input [ADDRSIZE :0] w2_rptr,
    input winc, wclk, wrst_n,
    output reg wfull,
    output [ADDRSIZE-1:0] waddr,
    output reg [ADDRSIZE :0] wptr
    );
 reg [ADDRSIZE:0] wbin;
 wire [ADDRSIZE:0] wgraynext, wbinnext;

 always @(posedge wclk or negedge wrst_n)
 if (!wrst_n) {wbin, wptr} <= 0;
 else {wbin, wptr} <= {wbinnext, wgraynext};

 assign waddr = wbin[ADDRSIZE-1:0];
 assign wbinnext = wbin + (winc & ~wfull);
 assign wgraynext = (wbinnext>>1) ^ wbinnext;
 
 assign wfull_val=((wgraynext[ADDRSIZE] !=w2_rptr[ADDRSIZE] ) && (wgraynext[ADDRSIZE-1] !=w2_rptr[ADDRSIZE-1]) &&(wgraynext[ADDRSIZE-2:0]==w2_rptr[ADDRSIZE-2:0]));

 always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) wfull <= 1'b0;
    else wfull <= wfull_val;
 end
endmodule
