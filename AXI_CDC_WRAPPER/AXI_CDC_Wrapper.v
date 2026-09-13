`timescale 1ns / 1ps

//-----------------------------------------------------------------------------
// Module: axi_cdc_wrapper
// Description: 
//   Point-to-point AXI4 Clock Domain Crossing (CDC) bridge using 5 asynchronous 
//   FIFOs (AW, W, B, AR, R). Passes AXI ID signals transparently through the 
//   bridge under the assumption that the downstream slave manages ID tracking.
//-----------------------------------------------------------------------------

module axi_cdc_wrapper #(
    parameter ID_WIDTH   = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter FIFO_ASIZE = 4    // FIFO depth = 2^FIFO_ASIZE
)(
    //-------------------------------------------------------------------------
    // Master Interface (mclk domain)
    //-------------------------------------------------------------------------
    input  wire                  mclk,
    input  wire                  mrst_n,

    // Write Address Channel
    input  wire [ID_WIDTH-1:0]   m_awid,
    input  wire [ADDR_WIDTH-1:0] m_awaddr,
    input  wire [7:0]            m_awlen,
    input  wire [2:0]            m_awsize,
    input  wire [1:0]            m_awburst,
    input  wire                  m_awvalid,
    output wire                  m_awready,

    // Write Data Channel
    input  wire [DATA_WIDTH-1:0] m_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] m_wstrb,
    input  wire                  m_wlast,
    input  wire                  m_wvalid,
    output wire                  m_wready,

    // Write Response Channel
    output wire [ID_WIDTH-1:0]   m_bid,
    output wire [1:0]            m_bresp,
    output wire                  m_bvalid,
    input  wire                  m_bready,

    // Read Address Channel
    input  wire [ID_WIDTH-1:0]   m_arid,
    input  wire [ADDR_WIDTH-1:0] m_araddr,
    input  wire [7:0]            m_arlen,
    input  wire [2:0]            m_arsize,
    input  wire [1:0]            m_arburst,
    input  wire                  m_arvalid,
    output wire                  m_arready,

    // Read Data Channel
    output wire [ID_WIDTH-1:0]   m_rid,
    output wire [DATA_WIDTH-1:0] m_rdata,
    output wire [1:0]            m_rresp,
    output wire                  m_rlast,
    output wire                  m_rvalid,
    input  wire                  m_rready,

    //-------------------------------------------------------------------------
    // Slave Interface (sclk domain)
    //-------------------------------------------------------------------------
    input  wire                  sclk,
    input  wire                  srst_n,

    // Write Address Channel
    output wire [ID_WIDTH-1:0]   s_awid,
    output wire [ADDR_WIDTH-1:0] s_awaddr,
    output wire [7:0]            s_awlen,
    output wire [2:0]            s_awsize,
    output wire [1:0]            s_awburst,
    output wire                  s_awvalid,
    input  wire                  s_awready,

    // Write Data Channel
    output wire [DATA_WIDTH-1:0] s_wdata,
    output wire [(DATA_WIDTH/8)-1:0] s_wstrb,
    output wire                  s_wlast,
    output wire                  s_wvalid,
    input  wire                  s_wready,

    // Write Response Channel
    input  wire [ID_WIDTH-1:0]   s_bid,
    input  wire [1:0]            s_bresp,
    input  wire                  s_bvalid,
    output wire                  s_bready,

    // Read Address Channel
    output wire [ID_WIDTH-1:0]   s_arid,
    output wire [ADDR_WIDTH-1:0] s_araddr,
    output wire [7:0]            s_arlen,
    output wire [2:0]            s_arsize,
    output wire [1:0]            s_arburst,
    output wire                  s_arvalid,
    input  wire                  s_arready,

    // Read Data Channel
    input  wire [ID_WIDTH-1:0]   s_rid,
    input  wire [DATA_WIDTH-1:0] s_rdata,
    input  wire [1:0]            s_rresp,
    input  wire                  s_rlast,
    input  wire                  s_rvalid,
    output wire                  s_rready
);

    // Channel payload bit widths
    localparam AW_W = ID_WIDTH + ADDR_WIDTH + 8 + 3 + 2;
    localparam W_W  = DATA_WIDTH + (DATA_WIDTH / 8) + 1;
    localparam B_W  = ID_WIDTH + 2;
    localparam AR_W = AW_W;
    localparam R_W  = ID_WIDTH + DATA_WIDTH + 2 + 1;

    //-------------------------------------------------------------------------
    // AW Channel (mclk -> sclk)
    //-------------------------------------------------------------------------
    wire aw_wfull, aw_rempty;
    wire [AW_W-1:0] aw_wpkt = {m_awid, m_awaddr, m_awlen, m_awsize, m_awburst};
    wire [AW_W-1:0] aw_rpkt;

    assign m_awready = ~aw_wfull;
    wire   aw_winc   = m_awvalid & m_awready;

    assign s_awvalid = ~aw_rempty;
    wire   aw_rinc   = s_awvalid & s_awready;

    fifo #(
        .DSIZE (AW_W),
        .ASIZE (FIFO_ASIZE)
    ) u_aw_fifo (
        .wclk   (mclk),
        .wrst_n (mrst_n),
        .winc   (aw_winc),
        .wdata  (aw_wpkt),
        .wfull  (aw_wfull),
        .rclk   (sclk),
        .rrst_n (srst_n),
        .rinc   (aw_rinc),
        .rdata  (aw_rpkt),
        .rempty (aw_rempty)
    );

    assign {s_awid, s_awaddr, s_awlen, s_awsize, s_awburst} = aw_rpkt;

    //-------------------------------------------------------------------------
    // W Channel (mclk -> sclk)
    //-------------------------------------------------------------------------
    wire w_wfull, w_rempty;
    wire [W_W-1:0] w_wpkt = {m_wdata, m_wstrb, m_wlast};
    wire [W_W-1:0] w_rpkt;

    assign m_wready = ~w_wfull;
    wire   w_winc   = m_wvalid & m_wready;

    assign s_wvalid = ~w_rempty;
    wire   w_rinc   = s_wvalid & s_wready;

    fifo #(
        .DSIZE (W_W),
        .ASIZE (FIFO_ASIZE)
    ) u_w_fifo (
        .wclk   (mclk),
        .wrst_n (mrst_n),
        .winc   (w_winc),
        .wdata  (w_wpkt),
        .wfull  (w_wfull),
        .rclk   (sclk),
        .rrst_n (srst_n),
        .rinc   (w_rinc),
        .rdata  (w_rpkt),
        .rempty (w_rempty)
    );

    assign {s_wdata, s_wstrb, s_wlast} = w_rpkt;

    //-------------------------------------------------------------------------
    // B Channel (sclk -> mclk)
    //-------------------------------------------------------------------------
    wire b_wfull, b_rempty;
    wire [B_W-1:0] b_wpkt = {s_bid, s_bresp};
    wire [B_W-1:0] b_rpkt;

    assign s_bready = ~b_wfull;
    wire   b_winc   = s_bvalid & s_bready;

    assign m_bvalid = ~b_rempty;
    wire   b_rinc   = m_bvalid & m_bready;

    fifo #(
        .DSIZE (B_W),
        .ASIZE (FIFO_ASIZE)
    ) u_b_fifo (
        .wclk   (sclk),
        .wrst_n (srst_n),
        .winc   (b_winc),
        .wdata  (b_wpkt),
        .wfull  (b_wfull),
        .rclk   (mclk),
        .rrst_n (mrst_n),
        .rinc   (b_rinc),
        .rdata  (b_rpkt),
        .rempty (b_rempty)
    );

    assign {m_bid, m_bresp} = b_rpkt;

    //-------------------------------------------------------------------------
    // AR Channel (mclk -> sclk)
    //-------------------------------------------------------------------------
    wire ar_wfull, ar_rempty;
    wire [AR_W-1:0] ar_wpkt = {m_arid, m_araddr, m_arlen, m_arsize, m_arburst};
    wire [AR_W-1:0] ar_rpkt;

    assign m_arready = ~ar_wfull;
    wire   ar_winc   = m_arvalid & m_arready;

    assign s_arvalid = ~ar_rempty;
    wire   ar_rinc   = s_arvalid & s_arready;

    fifo #(
        .DSIZE (AR_W),
        .ASIZE (FIFO_ASIZE)
    ) u_ar_fifo (
        .wclk   (mclk),
        .wrst_n (mrst_n),
        .winc   (ar_winc),
        .wdata  (ar_wpkt),
        .wfull  (ar_wfull),
        .rclk   (sclk),
        .rrst_n (srst_n),
        .rinc   (ar_rinc),
        .rdata  (ar_rpkt),
        .rempty (ar_rempty)
    );

    assign {s_arid, s_araddr, s_arlen, s_arsize, s_arburst} = ar_rpkt;

    //-------------------------------------------------------------------------
    // R Channel (sclk -> mclk)
    //-------------------------------------------------------------------------
    wire r_wfull, r_rempty;
    wire [R_W-1:0] r_wpkt = {s_rid, s_rdata, s_rresp, s_rlast};
    wire [R_W-1:0] r_rpkt;

    assign s_rready = ~r_wfull;
    wire   r_winc   = s_rvalid & s_rready;

    assign m_rvalid = ~r_rempty;
    wire   r_rinc   = m_rvalid & m_rready;

    fifo #(
        .DSIZE (R_W),
        .ASIZE (FIFO_ASIZE)
    ) u_r_fifo (
        .wclk   (sclk),
        .wrst_n (srst_n),
        .winc   (r_winc),
        .wdata  (r_wpkt),
        .wfull  (r_wfull),
        .rclk   (mclk),
        .rrst_n (mrst_n),
        .rinc   (r_rinc),
        .rdata  (r_rpkt),
        .rempty (r_rempty)
    );

    assign {m_rid, m_rdata, m_rresp, m_rlast} = r_rpkt;

endmodule
