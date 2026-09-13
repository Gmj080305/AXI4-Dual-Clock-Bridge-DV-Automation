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

# 2. Sequence
class AXIWriteSeq(uvm_sequence):
    async def body(self):
        for i in range(10):
            item = AXIItem("item")
            item.randomize()
            item.addr = i * 4
            item.data = 0xDEADBEEF + i
            await self.start_item(item)
            await self.finish_item(item)

# 3. Driver (Injects transactions into Slave port)
class AXIDriver(uvm_driver):
    def build_phase(self):
        self.dut = cocotb.top
        
    async def run_phase(self):
        # Initialize
        self.dut.s_axi_awvalid.value = 0
        self.dut.s_axi_wvalid.value = 0
        
        while True:
            item = await self.seq_item_port.get_next_item()
            await RisingEdge(self.dut.s_axi_aclk)
            
            if item.op_type == "WRITE":
                self.dut.s_axi_awaddr.value = item.addr
                self.dut.s_axi_awvalid.value = 1
                self.dut.s_axi_wdata.value = item.data
                self.dut.s_axi_wvalid.value = 1
                
                await self.wait_for_handshake(self.dut.s_axi_awvalid, self.dut.s_axi_awready)
                self.dut.s_axi_awvalid.value = 0
                
                await self.wait_for_handshake(self.dut.s_axi_wvalid, self.dut.s_axi_wready)
                self.dut.s_axi_wvalid.value = 0
                
            self.seq_item_port.item_done()

    async def wait_for_handshake(self, valid, ready):
        while True:
            await RisingEdge(self.dut.s_axi_aclk)
            if valid.value == 1 and ready.value == 1:
                break

# 4. Monitor (Samples the Master port)
class AXIMonitor(uvm_monitor):
    def build_phase(self):
        self.dut = cocotb.top
        self.ap = uvm_analysis_port("ap", self)

    async def run_phase(self):
        self.dut.m_axi_awready.value = 1 
        self.dut.m_axi_wready.value = 1
        
        while True:
            await RisingEdge(self.dut.m_axi_aclk)
            if self.dut.m_axi_awvalid.value == 1 and self.dut.m_axi_awready.value == 1:
                item = AXIItem("sampled_item")
                item.addr = int(self.dut.m_axi_awaddr.value)
                
                while not (self.dut.m_axi_wvalid.value == 1 and self.dut.m_axi_wready.value == 1):
                    await RisingEdge(self.dut.m_axi_aclk)
                    
                item.data = int(self.dut.m_axi_wdata.value)
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
        await ClockCycles(cocotb.top.m_axi_aclk, 20)
        self.drop_objection()

# 8. Cocotb Entry
@cocotb.test()
async def test_cdc_bridge(dut):
    # Asynchronous clocks (100MHz vs 150MHz)
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10.0, units="ns").start())
    cocotb.start_soon(Clock(dut.m_axi_aclk, 6.66, units="ns").start())
    
    # Reset
    dut.s_axi_aresetn.value = 0
    dut.m_axi_aresetn.value = 0
    await Timer(20, units="ns")
    dut.s_axi_aresetn.value = 1
    dut.m_axi_aresetn.value = 1
    await Timer(20, units="ns")
    
    await uvm_root().run_test("AXITest")
