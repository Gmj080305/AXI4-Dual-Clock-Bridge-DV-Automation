## Block Diagram

<img width="840" height="472" alt="image" src="https://github.com/user-attachments/assets/5a1ed8c8-67aa-4e59-8f7c-eed865fcbae9" />

## MODULES:

1. fifo1.v : this is the top-level wrapper-module that includes all clock
domains. The top module is only used as a wrapper to instantiate all of the other FIFO modules used in the
design. If this FIFO is used as part of a larger ASIC or FPGA design, this top-level wrapper would probably be
discarded to permit grouping of the other FIFO modules into their respective clock domains for improved
synthesis and static timing analysis.

2. fifomem.v : this is the FIFO memory buffer that is accessed by both the
write and read clock domains. This buffer is most likely an instantiated, synchronous dual-port RAM. Other
memory styles can be adapted to function as the FIFO buffer.

3. sync_r2w.v : this is a synchronizer module that is used to synchronize the
read pointer into the write-clock domain. The synchronized read pointer will be used by the wptr_full
module to generate the FIFO full condition. This module only contains flip-flops that are synchronized to the
write clock. No other logic is included in this module.

4. sync_w2r.v : this is a synchronizer module that is used to synchronize the
write pointer into the read-clock domain. The synchronized write pointer will be used by the rptr_empty
module to generate the FIFO empty condition. This module only contains flip-flops that are synchronized to the
read clock. No other logic is included in this module.

5. rptr_empty.v : this module is completely synchronous to the read-clock
domain and contains the FIFO read pointer and empty-flag logic.

6. wptr_full.v : this module is completely synchronous to the write-clock
domain and contains the FIFO write pointer and full-flag logic.
