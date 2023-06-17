# aurora

## specifications
FPGA-based Intrusion Detection System for SNORT rules that offered 2.2 Gbps IDS throughput, 12x higher than software-only implementation and scalable to 11500 (25%) rules. System included dual-core, (fine multithreaded) 4-threaded, 5-stage RISC-V based (RV64I) Network Processor and an accelerator for bloom-filter/hash function-based pattern matching, flow-through SSRAM for Caches
-  Custom compiler for bare-metal binary generation and logic analyzer for debugging on the DETER testbed
-  Synthesizable design in Verilog utilizing 15k LUTs and Flip-flops on Xilinx Virtex-II Pro
-  Toolchain: Logic Analyzer output formatter on Bash, Wireshark-equivalent for packet debugging, Smart Arbiter based dual-core engine, Memory I/O based handshake mechanism
