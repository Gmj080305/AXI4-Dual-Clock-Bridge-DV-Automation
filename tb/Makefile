# tb/Makefile
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Point to ALL your Verilog directories
VERILOG_SOURCES += $(PWD)/../async_fifo/fifo.v
VERILOG_SOURCES += $(PWD)/../async_fifo/fifomem.v
VERILOG_SOURCES += $(PWD)/../async_fifo/rptr_empty.v
VERILOG_SOURCES += $(PWD)/../async_fifo/sync_r2w.v
VERILOG_SOURCES += $(PWD)/../async_fifo/sync_w2r.v
VERILOG_SOURCES += $(PWD)/../async_fifo/wptr_full.v
VERILOG_SOURCES += $(PWD)/../AXI_CDC_WRAPPER/AXI_CDC_Wrapper.v

# Ensure this exactly matches the module name inside AXI_CDC_Wrapper.v
TOPLEVEL = AXI_CDC_Wrapper 

# The name of your Python test file (without the .py)
MODULE = test_axi

include $(shell cocotb-config --makefiles)/Makefile.sim
