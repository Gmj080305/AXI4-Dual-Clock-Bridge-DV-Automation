`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module fifomem #(parameter DATASIZE=8, parameter ADDRSIZE=4)(
    input [DATASIZE-1:0] wdata,
    input [ADDRSIZE-1:0] waddr,raddr,
    input wclken,wfull,wclk,
    
    output [DATASIZE-1:0] rdata
    );
    
    
    localparam DEPTH=1<<ADDRSIZE;
    reg [DATASIZE-1:0] mem[0:DEPTH-1];
    assign rdata=mem[raddr];
    always @(posedge wclk) begin
      if(wclken && !wfull) mem[waddr] <= wdata;
    end
    
   //vivado IP instead of code
   //blk_mem_gen_0 dualport_ram(
   //clka(wclk),
   //ena(wclken && !wfull),
   //wea(1'b1),
   //addra(waddr),
   //dina(wdata),
   //clkb(wclk),
   //enb(1'b1),
   //addrb(raddr),
   //doutb(rdata)
   //);
endmodule
