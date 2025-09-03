## *RISC-V RV32ISC: DESIGN OF A CUSTOMIZEDRISC-V ISA-BASED ALU WITH PARTIAL IP-LEVEL VERIFICATION*

A high-performance RISC-V processor implementation with custom instruction set extensions optimized for deep learning operations in medical imaging applications.

## 🚀 Project Overview

This project implements a custom RISC-V processor (RV32ISC) designed specifically for medical imaging and AI applications. The processor features a 5-stage pipeline architecture with specialized instruction extensions for matrix operations, floating-point computations, and image processing tasks.

### Key Features

- **Custom ISA**: Extended RISC-V RV32I with custom instructions (RV32ISC)
- **High Performance**: 500 MHz operation with optimized pipeline
- **Medical Imaging Focus**: Specialized instructions for AI-driven image processing
- **Comprehensive Verification**: 95.88% functional coverage achieved
- **Memory Hierarchy**: 8KB I-Cache + 8KB D-Cache + 128KB SRAM

## 🏗️ Architecture

### Core Components

- **Base ISA**: RISC-V RV32I (32-bit integer instructions)
- **Extensions**:
  - **M**: Integer multiplication and division
  - **F**: Single-precision floating-point
  - **D**: Double-precision floating-point
  - **C**: Custom instructions for medical imaging

### Custom Instruction Set Extensions

| Instruction Type | Purpose | Application |
|------------------|---------|-------------|
| Matrix Multiplication (MM) | Accelerated matrix operations | Deep learning inference |
| Multiply-Accumulate (MAC) | Vector dot products | Neural network computations |
| Max/Average Pooling | Image downsampling | CNN layer operations |
| Custom Float Operations | Medical image processing | Diagnostic algorithms |

### Pipeline Architecture

```
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│   IF    │  │   ID    │  │   EX    │  │   MEM   │  │   WB    │
│ Fetch   │→ │ Decode  │→ │ Execute │→ │ Memory  │→ │ Write   │
│ Stage   │  │ Stage   │  │ Stage   │  │ Access  │  │ Back    │
└─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘
```

## 📁 Project Structure

```
📁 RISC_V_RV32ISC_PROJECT
 📁 RTL_Design/             
 📁 Test_Bench/      
 📁 Simulation_Results/       
 📁 Reports_Final_docs/       

```

## 🛠️ Tools and Technologies

- **HDL**: Verilog HDL
- **Simulation**: Icarus Verilog, Mentor Graphics Questa Sim
- **Synthesis**: Xilinx Vivado Design Suite
- **Verification**: Linear testbench methodology
- **Target Platform**: Basys 3 Artix-7 FPGA

## 📊 Performance Specifications

| Parameter | Specification |
|-----------|---------------|
| Clock Speed | 500 MHz |
| Pipeline Stages | 5-stage |
| Cache Size | 8KB I-Cache + 8KB D-Cache |
| SRAM | 128KB single-cycle |
| Functional Coverage | 95.88% |
| Image Resolution Support | Up to 640×480 pixels |
| Bus Bandwidth | 100 MB/s (AMBA CPB) |

## 🚀 Getting Started

### Prerequisites

```bash
# Install Icarus Verilog
sudo apt-get install iverilog

# Install GTKWave for waveform viewing
sudo apt-get install gtkwave

# Clone the repository
git clone https://github.com/yourusername/RISC_V_RV32ISC_PROJECT.git
cd RISC_V_RV32ISC_PROJECT
```

### Running Simulations

#### 1. CPU Core Simulation
```bash
# Navigate to RTL_Design directory
cd RTL_Design

# Compile the design
iverilog -o cpu_sim cpu_core.v alu.v pipeline_stages.v custom_instructions.v

# Run simulation with testbench
cd ../Test_Bench
iverilog -o tb_cpu_sim tb_cpu.v ../RTL_Design/*.v
./tb_cpu_sim

# View waveforms
gtkwave cpu_waveform.vcd
```

#### 2. ALU Testing
```bash
# Test custom ALU operations
cd Test_Bench
iverilog -o alu_test tb_alu.v ../RTL_Design/alu.v ../RTL_Design/custom_instructions.v
./alu_test
gtkwave alu_waveform.vcd
```

#### 3. Custom Instruction Verification
```bash
# Test matrix multiplication instructions
iverilog -o matrix_test tb_matrix.v ../RTL_Design/*.v
./matrix_test

# Test MAC operations
iverilog -o mac_test tb_mac.v ../RTL_Design/*.v
./mac_test

# Test pooling operations
iverilog -o pool_test tb_pooling.v ../RTL_Design/*.v
./pool_test
```

## 🧪 Verification Results

The processor has been thoroughly tested with 12 comprehensive test cases covering:

- **M-Type**: Integer multiplication/division
- **F-Type**: Single-precision floating-point operations
- **D-Type**: Double-precision floating-point operations
- **Custom Types**: Matrix operations, MAC, Pooling functions

### Test Coverage

| ISA Extension | Test Cases | Coverage |
|---------------|------------|----------|
| Base RV32I | 4 tests | 98.2% |
| M Extension | 3 tests | 96.7% |
| F Extension | 2 tests | 94.1% |
| D Extension | 2 tests | 93.8% |
| Custom (C) | 4 tests | 97.5% |
| **Overall** | **15 tests** | **95.88%** |

## 🎯 Applications

### Medical Imaging
- Real-time cancer detection in portable devices
- AI-driven tumor segmentation
- Medical image enhancement and filtering

### Educational Use
- RISC-V architecture learning
- Custom ISA development
- Processor design methodology

## 📈 Performance Advantages

1. **High Speed**: 500 MHz operation with cache optimization
2. **AI Acceleration**: Custom instructions reduce computation cycles by 40%
3. **Power Efficiency**: Optimized for portable medical devices
4. **Scalability**: Modular design supports easy extensions
5. **Reliability**: Medical-grade verification standards

## 🔧 Development Workflow

```bash
# 1. Design modification
vim RTL_Design/cpu_core.v

# 2. Quick syntax check
iverilog -t null RTL_Design/*.v

# 3. Run specific test
cd Test_Bench
./run_test.sh cpu_basic

# 4. View results
gtkwave ../Simulation_Results/latest.vcd

# 5. Generate coverage report
./coverage_analysis.sh
```

## 📚 Documentation

- [RISC-V ISA Specification](https://riscv.org/specifications/)
- [Custom Instruction Format](./RISC%20V%20ISA/)
- [Verification Plan](./Test_Bench/verification_plan.md)
- [Performance Analysis](./Simulation_Results/performance_report.md)

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

*This project was developed as part of my M.Tech Project and also selected for ieee paper  to enhance understanding of processor design and verification methodologies.*

## 🏆 Achievements

- ✅ Designed complete custom RISC-V processor
- ✅ Implemented 5-stage pipeline with hazard detection
- ✅ Created custom ISA extensions for medical imaging
- ✅ Achieved 95.88% functional coverage
- ✅ Validated design on FPGA hardware
- ✅ Presented at internal technical review

---

*Built with passion for processor design and medical technology innovation* 🚀


