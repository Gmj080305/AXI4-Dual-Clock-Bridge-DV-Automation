import os
from pathlib import Path
from cocotb.runner import get_runner

def test_axi_runner():
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent

    sources = [
        proj_path / "../async_fifo/fifo.v",
        proj_path / "../async_fifo/fifomem.v",
        proj_path / "../async_fifo/rptr_empty.v",
        proj_path / "../async_fifo/sync_r2w.v",
        proj_path / "../async_fifo/sync_w2r.v",
        proj_path / "../async_fifo/wptr_full.v",
        proj_path / "../AXI_CDC_WRAPPER/AXI_CDC_Wrapper.v",
    ]

    runner = get_runner(sim)
    runner.build(
        verilog_sources=sources,
        hdl_toplevel="AXI_CDC_Wrapper",
        always=True,
    )
    runner.test(
        hdl_toplevel="AXI_CDC_Wrapper",
        test_module="test_axi",
    )

if __name__ == "__main__":
    test_axi_runner()
