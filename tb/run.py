import os
from pathlib import Path

from cocotb_tools.runner import get_runner

def test_axi_runner():
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent

    # Convert paths to absolute strings for Windows Icarus compatibility
    src_files = [
        str((proj_path / "../async_fifo/fifo.v").resolve()),
        str((proj_path / "../async_fifo/fifomem.v").resolve()),
        str((proj_path / "../async_fifo/rptr_empty.v").resolve()),
        str((proj_path / "../async_fifo/sync_r2w.v").resolve()),
        str((proj_path / "../async_fifo/sync_w2r.v").resolve()),
        str((proj_path / "../async_fifo/wptr_full.v").resolve()),
        str((proj_path / "../AXI_CDC_WRAPPER/AXI_CDC_Wrapper.v").resolve()),
    ]

    # TODO: Ensure "AXI_CDC_Wrapper" matches the EXACT case of the module in your .v file
    TOPLEVEL_NAME = "axi_cdc_wrapper" 

    runner = get_runner(sim)
    runner.build(
        sources=src_files, # Fixed deprecation warning
        hdl_toplevel=TOPLEVEL_NAME,
        always=True,
    )
    runner.test(
        hdl_toplevel=TOPLEVEL_NAME,
        test_module="test_axi",
    )

if __name__ == "__main__":
    test_axi_runner()
