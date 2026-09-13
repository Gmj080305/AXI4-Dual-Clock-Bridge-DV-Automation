import random
import cocotb
from cocotb.triggers import RisingEdge, Timer, ClockCycles
from cocotb.clock import Clock
from pyuvm import *

# 1. Sequence Item
class AXIItem(uvm_sequence_item):
    def __init__(self, name="AXIItem"):
        super().__init__(name)
        self.addr = 0
        self.data = 0
        self.op_type = "WRITE"

# 2. Sequence (Using Python's random module)
class AXIWriteSeq(uvm_sequence):
    async def body(self):
        for i in range(10):
            item = AXIItem("item")
            item.addr = i * 4
            item.data = random.randint(0, 0xFFFFFFFF) # Python random generation
            await self.start_item(item)
            await self.finish_item(item)

# 3. Driver (Injects transactions into the mclk domain)
class AXIDriver(uvm_driver):
    def build_phase(self):
        self.dut = cocotb.top
        
    async def run_phase(self):
        self.dut.m_awvalid.value = 0
        self.dut.m_wvalid.value = 0
        self.dut.m_arvalid.value = 0
        self.dut.m_rready.value = 1
        self.dut.m_bready.value = 1
        
        self.dut.m_awid.value = 0
        self.dut.m_awlen.value = 0
        self.dut.m_awsize.value = 2 # 4 bytes
        self.dut.m_awburst.value = 1 # INCR
        self.dut.m_wstrb.value = 0xF
        self.dut.m_wlast.value = 1
        
        while True:
            item = await self.seq_item_port.get_next_item()
            await RisingEdge(self.dut.mclk)
            
            if item.op_type == "WRITE":
                self.dut.m_awaddr.value = item.addr
                self.dut.m_awvalid.value = 1
                self.dut.m_wdata.value = item.data
                self.dut.m_wvalid.value = 1
                
                await self.wait_for_handshake(self.dut.mclk, self.dut.m_awvalid, self.dut.m_awready)
                self.dut.m_awvalid.value = 0
                
                await self.wait_for_handshake(self.dut.mclk, self.dut.m_wvalid, self.dut.m_wready)
                self.dut.m_wvalid.value = 0
                
            self.seq_item_port.item_done()

    async def wait_for_handshake(self, clk, valid, ready):
        while True:
            await RisingEdge(clk)
            if valid.value == 1 and ready.value == 1:
                break

# 4. Monitor (Samples the sclk domain)
class AXIMonitor(uvm_monitor):
    def build_phase(self):
        self.dut = cocotb.top
        self.ap = uvm_analysis_port("ap", self)

    async def run_phase(self):
        self.dut.s_awready.value = 1 
        self.dut.s_wready.value = 1
        self.dut.s_bvalid.value = 1
        self.dut.s_bresp.value = 0
        self.dut.s_bid.value = 0
        
        while True:
            await RisingEdge(self.dut.sclk)
            
            if self.dut.s_awvalid.value == 1 and self.dut.s_awready.value == 1:
                item = AXIItem("sampled_item")
                item.addr = int(self.dut.s_awaddr.value)
                
                while not (self.dut.s_wvalid.value == 1 and self.dut.s_wready.value == 1):
                    await RisingEdge(self.dut.sclk)
                    
                item.data = int(self.dut.s_wdata.value)
                self.ap.write(item)

# 5. Scoreboard
class AXIScoreboard(uvm_component):
    def build_phase(self):
        self.fifo = uvm_tlm_analysis_fifo("fifo", self)

    async def run_phase(self):
        while True:
            actual_item = await self.fifo.get()
            cocotb.log.info(f"SCOREBOARD PASSED: Transferred CDC data -> ADDR: {hex(actual_item.addr)} | DATA: {hex(actual_item.data)}")

# 6. Env & Agent Packaging
class AXIAgent(uvm_agent):
    def build_phase(self):
        self.seqr = uvm_sequencer("seqr", self)
        self.driver = AXIDriver("driver", self)
        self.monitor = AXIMonitor("monitor", self)
    def connect_phase(self):
        self.driver.seq_item_port.connect(self.seqr.seq_item_export)

class AXIEnv(uvm_env):
    def build_phase(self):
        self.agent = AXIAgent("agent", self)
        self.scoreboard = AXIScoreboard("scoreboard", self)
    def connect_phase(self):
        self.agent.monitor.ap.connect(self.scoreboard.fifo.analysis_export)

# 7. UVM Test
class AXITest(uvm_test):
    def build_phase(self):
        self.env = AXIEnv("env", self)
    async def run_phase(self):
        self.raise_objection()
        seq = AXIWriteSeq.create("seq")
        await seq.start(self.env.agent.seqr)
        await ClockCycles(cocotb.top.sclk, 20) 
        self.drop_objection()

# 8. Cocotb Entry (Fixed 'units' to 'unit' deprecation warnings)
@cocotb.test()
async def test_cdc_bridge(dut):
    cocotb.start_soon(Clock(dut.mclk, 10.0, unit="ns").start()) # 100 MHz
    cocotb.start_soon(Clock(dut.sclk, 6.66, unit="ns").start()) # ~150 MHz
    
    dut.mrst_n.value = 0
    dut.srst_n.value = 0
    await Timer(20, unit="ns")
    
    dut.mrst_n.value = 1
    dut.srst_n.value = 1
    await Timer(20, unit="ns")
    
    await uvm_root().run_test("AXITest")
