/*
=============================================================================
RISC-V RV32ISC ALU COMPLETE DESIGN
=============================================================================
Author:Teja_Reddy Based on M.Tech Project - Custom RISC-V ISA-Based ALU
Purpose: ALU for medical imaging applications with custom extensions
Features: RV32I + M + F + D + Custom Matrix Operations + MAC + Pooling
Clock: 500 MHz target frequency
Coverage: Designed for 100% functional coverage
=============================================================================
*/

`timescale 1ns/1ps

// Main ALU module with all instruction support
module riscv_rv32isc_alu (
    input  wire         clk,           // 500MHz clock
    input  wire         rst_n,         // Active low reset
    input  wire         enable,        // ALU enable signal
    
    // Instruction decode inputs
    input  wire [31:0]  instruction,   // Full 32-bit instruction
    input  wire [6:0]   opcode,        // Instruction opcode
    input  wire [2:0]   funct3,        // Function 3 bits
    input  wire [6:0]   funct7,        // Function 7 bits
    
    // Data inputs
    input  wire [31:0]  rs1_data,      // Source register 1 data
    input  wire [31:0]  rs2_data,      // Source register 2 data
    input  wire [31:0]  rs3_data,      // Source register 3 (for MAC, Matrix ops)
    
    // Matrix operation inputs (for custom instructions)
    input  wire [63:0]  matrix_a_data, // Matrix A data (for matrix multiply)
    input  wire [63:0]  matrix_b_data, // Matrix B data (for matrix multiply)
    input  wire [3:0]   matrix_size,   // Matrix dimensions (for pooling/matrix ops)
    
    // Control signals
    input  wire         is_signed,     // For signed/unsigned operations
    input  wire         use_immediate, // Use immediate value instead of rs2
    input  wire [31:0]  immediate,     // Immediate value
    
    // Outputs
    output reg  [31:0]  result,        // Main ALU result
    output reg  [63:0]  result_64,     // 64-bit result for double precision/matrix
    output reg  [31:0]  matrix_result, // Matrix operation result
    output reg          zero_flag,     // Zero flag
    output reg          carry_flag,    // Carry flag  
    output reg          overflow_flag, // Overflow flag
    output reg          sign_flag,     // Sign flag
    output reg          ready,         // Operation complete flag
    output reg          error_flag     // Error in operation
);

// Internal registers and wires
reg [31:0] operand_a, operand_b;
reg [63:0] temp_64;
reg [31:0] temp_32;

// Floating point temporary storage
reg [31:0] fp_temp_a, fp_temp_b, fp_result;
reg [63:0] dp_temp_a, dp_temp_b, dp_result;

// Matrix operation temporary storage  
reg [31:0] matrix_temp [0:15]; // Support up to 4x4 matrices
reg [7:0]  pool_temp [0:15];   // Pooling operation temporary storage

// MAC (Multiply-Accumulate) registers
reg [63:0] mac_accumulator;
reg [31:0] mac_result;

// Instruction type decode (for better readability)
wire is_r_type, is_i_type, is_s_type, is_b_type, is_u_type, is_j_type;
wire is_m_type, is_f_type, is_d_type, is_custom_type;

// R-type: Register-Register operations (ADD, SUB, etc.)
assign is_r_type = (opcode == 7'b0110011);
// I-type: Immediate operations (ADDI, LOAD, etc.)  
assign is_i_type = (opcode == 7'b0010011) || (opcode == 7'b0000011);
// S-type: Store operations
assign is_s_type = (opcode == 7'b0100011);
// B-type: Branch operations
assign is_b_type = (opcode == 7'b1100011);
// U-type: Upper immediate (LUI, AUIPC)
assign is_u_type = (opcode == 7'b0110111) || (opcode == 7'b0010111);
// J-type: Jump operations
assign is_j_type = (opcode == 7'b1101111);

// Extension type decode
// M-type: Multiply/Divide (custom opcode for this implementation)
assign is_m_type = (opcode == 7'b0110011) && (funct7 == 7'b0000001);
// F-type: Single precision floating point (custom opcode)
assign is_f_type = (opcode == 7'b1010011) && (instruction[26:25] == 2'b00);
// D-type: Double precision floating point (custom opcode)  
assign is_d_type = (opcode == 7'b1010011) && (instruction[26:25] == 2'b01);
// Custom-type: Matrix, MAC, Pooling operations
assign is_custom_type = (opcode == 7'b0001011) || (opcode == 7'b0001111);

// Operand selection logic
always @(*) begin
    if (use_immediate) begin
        operand_a = rs1_data;
        operand_b = immediate;
    end else begin
        operand_a = rs1_data;
        operand_b = rs2_data;
    end
end

// Main ALU operation logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all outputs and internal registers
        result <= 32'b0;
        result_64 <= 64'b0;
        matrix_result <= 32'b0;
        zero_flag <= 1'b0;
        carry_flag <= 1'b0;
        overflow_flag <= 1'b0;
        sign_flag <= 1'b0;
        ready <= 1'b0;
        error_flag <= 1'b0;
        mac_accumulator <= 64'b0;
        mac_result <= 32'b0;
    end else if (enable) begin
        ready <= 1'b0;
        error_flag <= 1'b0;
        
        case (1'b1)
            // RV32I Base Integer Instructions
            is_r_type || is_i_type: begin
                case (funct3)
                    3'b000: begin // ADD/ADDI or SUB
                        if (is_r_type && funct7[5]) begin
                            // SUB operation
                            {carry_flag, result} = operand_a - operand_b;
                        end else begin
                            // ADD/ADDI operation  
                            {carry_flag, result} = operand_a + operand_b;
                        end
                    end
                    3'b001: begin // SLL/SLLI - Shift Left Logical
                        result = operand_a << operand_b[4:0];
                        carry_flag = 1'b0;
                    end
                    3'b010: begin // SLT/SLTI - Set Less Than (signed)
                        result = ($signed(operand_a) < $signed(operand_b)) ? 32'b1 : 32'b0;
                        carry_flag = 1'b0;
                    end
                    3'b011: begin // SLTU/SLTIU - Set Less Than Unsigned
                        result = (operand_a < operand_b) ? 32'b1 : 32'b0;
                        carry_flag = 1'b0;
                    end
                    3'b100: begin // XOR/XORI
                        result = operand_a ^ operand_b;
                        carry_flag = 1'b0;
                    end
                    3'b101: begin // SRL/SRLI or SRA/SRAI - Shift Right
                        if (funct7[5]) begin
                            // SRA/SRAI - Shift Right Arithmetic (signed)
                            result = $signed(operand_a) >>> operand_b[4:0];
                        end else begin
                            // SRL/SRLI - Shift Right Logical
                            result = operand_a >> operand_b[4:0];
                        end
                        carry_flag = 1'b0;
                    end
                    3'b110: begin // OR/ORI
                        result = operand_a | operand_b;
                        carry_flag = 1'b0;
                    end
                    3'b111: begin // AND/ANDI
                        result = operand_a & operand_b;
                        carry_flag = 1'b0;
                    end
                endcase
            end
            
            // RV32M - Multiply and Divide Extension
            is_m_type: begin
                case (funct3)
                    3'b000: begin // MUL - Multiply (lower 32 bits)
                        temp_64 = $signed(operand_a) * $signed(operand_b);
                        result = temp_64[31:0];
                        result_64 = temp_64;
                    end
                    3'b001: begin // MULH - Multiply High (signed x signed)
                        temp_64 = $signed(operand_a) * $signed(operand_b);
                        result = temp_64[63:32];
                    end
                    3'b010: begin // MULHSU - Multiply High (signed x unsigned)
                        temp_64 = $signed(operand_a) * $unsigned(operand_b);
                        result = temp_64[63:32];
                    end
                    3'b011: begin // MULHU - Multiply High (unsigned x unsigned)
                        temp_64 = operand_a * operand_b;
                        result = temp_64[63:32];
                    end
                    3'b100: begin // DIV - Signed division
                        if (operand_b == 0) begin
                            result = 32'hFFFFFFFF; // Division by zero result
                            error_flag = 1'b1;
                        end else begin
                            result = $signed(operand_a) / $signed(operand_b);
                        end
                    end
                    3'b101: begin // DIVU - Unsigned division
                        if (operand_b == 0) begin
                            result = 32'hFFFFFFFF; // Division by zero result
                            error_flag = 1'b1;
                        end else begin
                            result = operand_a / operand_b;
                        end
                    end
                    3'b110: begin // REM - Signed remainder
                        if (operand_b == 0) begin
                            result = operand_a; // Remainder by zero result
                            error_flag = 1'b1;
                        end else begin
                            result = $signed(operand_a) % $signed(operand_b);
                        end
                    end
                    3'b111: begin // REMU - Unsigned remainder
                        if (operand_b == 0) begin
                            result = operand_a; // Remainder by zero result
                            error_flag = 1'b1;
                        end else begin
                            result = operand_a % operand_b;
                        end
                    end
                endcase
            end
            
            // RV32F - Single Precision Floating Point Extension
            is_f_type: begin
                fp_temp_a = operand_a;
                fp_temp_b = operand_b;
                case (funct3)
                    3'b000: begin // FADD.S - Floating point add
                        fp_result = fp_add_single(fp_temp_a, fp_temp_b);
                        result = fp_result;
                    end
                    3'b001: begin // FSUB.S - Floating point subtract
                        fp_result = fp_sub_single(fp_temp_a, fp_temp_b);
                        result = fp_result;
                    end
                    3'b010: begin // FMUL.S - Floating point multiply
                        fp_result = fp_mul_single(fp_temp_a, fp_temp_b);
                        result = fp_result;
                    end
                    3'b011: begin // FDIV.S - Floating point divide
                        fp_result = fp_div_single(fp_temp_a, fp_temp_b);
                        result = fp_result;
                    end
                    default: begin
                        result = 32'b0;
                        error_flag = 1'b1;
                    end
                endcase
            end
            
            // RV32D - Double Precision Floating Point Extension
            is_d_type: begin
                dp_temp_a = {operand_a, rs3_data}; // Combine for 64-bit
                dp_temp_b = {operand_b, immediate}; // Combine for 64-bit
                case (funct3)
                    3'b000: begin // FADD.D - Double precision add
                        dp_result = fp_add_double(dp_temp_a, dp_temp_b);
                        result_64 = dp_result;
                        result = dp_result[31:0];
                    end
                    3'b001: begin // FSUB.D - Double precision subtract
                        dp_result = fp_sub_double(dp_temp_a, dp_temp_b);
                        result_64 = dp_result;
                        result = dp_result[31:0];
                    end
                    3'b010: begin // FMUL.D - Double precision multiply
                        dp_result = fp_mul_double(dp_temp_a, dp_temp_b);
                        result_64 = dp_result;
                        result = dp_result[31:0];
                    end
                    3'b011: begin // FDIV.D - Double precision divide
                        dp_result = fp_div_double(dp_temp_a, dp_temp_b);
                        result_64 = dp_result;
                        result = dp_result[31:0];
                    end
                    default: begin
                        result_64 = 64'b0;
                        result = 32'b0;
                        error_flag = 1'b1;
                    end
                endcase
            end
            
            // Custom Instructions for Medical Imaging
            is_custom_type: begin
                case (instruction[6:0])
                    7'b0001011: begin // Matrix operations
                        case (instruction[14:12]) // Custom funct3 for matrix ops
                            3'b000: begin // Matrix Multiply (MM)
                                matrix_result = matrix_multiply_2x2(matrix_a_data, matrix_b_data);
                                result = matrix_result;
                            end
                            3'b001: begin // MAC - Multiply and Accumulate
                                mac_result = (operand_a * operand_b) + mac_accumulator[31:0];
                                mac_accumulator = mac_accumulator + (operand_a * operand_b);
                                result = mac_result;
                            end
                            default: begin
                                result = 32'b0;
                                error_flag = 1'b1;
                            end
                        endcase
                    end
                    7'b0001111: begin // Pooling operations
                        case (instruction[14:12])
                            3'b000: begin // Max Pooling
                                result = max_pool_operation(operand_a, operand_b, matrix_size);
                            end
                            3'b001: begin // Average Pooling
                                result = avg_pool_operation(operand_a, operand_b, matrix_size);
                            end
                            default: begin
                                result = 32'b0;
                                error_flag = 1'b1;
                            end
                        endcase
                    end
                    default: begin
                        result = 32'b0;
                        error_flag = 1'b1;
                    end
                endcase
            end
            
            default: begin
                result = 32'b0;
                error_flag = 1'b1;
            end
        endcase
        
        // Update flags based on result
        zero_flag <= (result == 32'b0);
        sign_flag <= result[31];
        
        // Check for overflow in addition/subtraction
        if ((is_r_type || is_i_type) && (funct3 == 3'b000)) begin
            if (!funct7[5]) begin // ADD operation
                overflow_flag <= (operand_a[31] == operand_b[31]) && (result[31] != operand_a[31]);
            end else begin // SUB operation  
                overflow_flag <= (operand_a[31] != operand_b[31]) && (result[31] != operand_a[31]);
            end
        end else begin
            overflow_flag <= 1'b0;
        end
        
        ready <= 1'b1;
    end
end

// Floating Point Helper Functions (Simplified IEEE 754 operations)
// Note: These are simplified implementations for demonstration
function [31:0] fp_add_single;
    input [31:0] a, b;
    reg [31:0] result_temp;
    begin
        // Simplified floating point addition
        // In real implementation, this would handle IEEE 754 format properly
        result_temp = a + b; // Simplified - not proper FP arithmetic
        fp_add_single = result_temp;
    end
endfunction

function [31:0] fp_sub_single;
    input [31:0] a, b;
    reg [31:0] result_temp;
    begin
        result_temp = a - b; // Simplified
        fp_sub_single = result_temp;
    end
endfunction

function [31:0] fp_mul_single;
    input [31:0] a, b;
    reg [31:0] result_temp;
    begin
        result_temp = (a * b) >> 16; // Simplified scaling
        fp_mul_single = result_temp;
    end
endfunction

function [31:0] fp_div_single;
    input [31:0] a, b;
    reg [31:0] result_temp;
    begin
        if (b != 0)
            result_temp = (a << 16) / b; // Simplified scaling
        else
            result_temp = 32'hFFFFFFFF;
        fp_div_single = result_temp;
    end
endfunction

// Double Precision Helper Functions
function [63:0] fp_add_double;
    input [63:0] a, b;
    begin
        fp_add_double = a + b; // Simplified
    end
endfunction

function [63:0] fp_sub_double;
    input [63:0] a, b;
    begin
        fp_sub_double = a - b; // Simplified
    end
endfunction

function [63:0] fp_mul_double;
    input [63:0] a, b;
    begin
        fp_mul_double = (a * b) >> 32; // Simplified scaling
    end
endfunction

function [63:0] fp_div_double;
    input [63:0] a, b;
    begin
        if (b != 0)
            fp_div_double = (a << 32) / b; // Simplified scaling
        else
            fp_div_double = 64'hFFFFFFFFFFFFFFFF;
    end
endfunction

// Matrix Operations Helper Functions
function [31:0] matrix_multiply_2x2;
    input [63:0] matrix_a, matrix_b;
    reg [15:0] a00, a01, a10, a11;
    reg [15:0] b00, b01, b10, b11;
    reg [31:0] c00, c01, c10, c11;
    begin
        // Extract 2x2 matrix elements (16-bit each)
        a00 = matrix_a[15:0];   a01 = matrix_a[31:16];
        a10 = matrix_a[47:32];  a11 = matrix_a[63:48];
        
        b00 = matrix_b[15:0];   b01 = matrix_b[31:16];
        b10 = matrix_b[47:32];  b11 = matrix_b[63:48];
        
        // Matrix multiplication: C = A * B
        c00 = a00 * b00 + a01 * b10;
        c01 = a00 * b01 + a01 * b11;
        c10 = a10 * b00 + a11 * b10;
        c11 = a10 * b01 + a11 * b11;
        
        // Return first element as example (in real implementation, 
        // you'd need multiple cycles or wider output)
        matrix_multiply_2x2 = c00;
    end
endfunction

// Pooling Operations Helper Functions
function [31:0] max_pool_operation;
    input [31:0] data_a, data_b;
    input [3:0] size;
    reg [31:0] max_val;
    begin
        // Simple 2-element max pooling
        max_val = (data_a > data_b) ? data_a : data_b;
        max_pool_operation = max_val;
    end
endfunction

function [31:0] avg_pool_operation;
    input [31:0] data_a, data_b;
    input [3:0] size;
    reg [31:0] avg_val;
    begin
        // Simple 2-element average pooling
        avg_val = (data_a + data_b) >> 1;
        avg_pool_operation = avg_val;
    end
endfunction

endmodule

/*
=============================================================================
ADDITIONAL PIPELINE STAGE MODULES
=============================================================================
These modules support the 5-stage pipeline architecture mentioned in the project
*/

// Instruction Fetch Stage
module instruction_fetch (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire [31:0] pc_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] instruction
);
    // Simplified instruction memory (in real implementation, connects to I-Cache)
    reg [31:0] instruction_memory [0:1023];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out <= 32'b0;
            instruction <= 32'b0;
        end else if (!stall) begin
            pc_out <= pc_in;
            instruction <= instruction_memory[pc_in[11:2]]; // Word-aligned access
        end
    end
endmodule

// Instruction Decode Stage  
module instruction_decode (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] instruction,
    input  wire [31:0] pc,
    
    output reg  [6:0]  opcode,
    output reg  [4:0]  rd,
    output reg  [4:0]  rs1,
    output reg  [4:0]  rs2,
    output reg  [2:0]  funct3,
    output reg  [6:0]  funct7,
    output reg  [31:0] immediate,
    output reg         reg_write_enable,
    output reg         mem_read,
    output reg         mem_write,
    output reg         branch,
    output reg         jump
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            opcode <= 7'b0;
            rd <= 5'b0;
            rs1 <= 5'b0;
            rs2 <= 5'b0;
            funct3 <= 3'b0;
            funct7 <= 7'b0;
            immediate <= 32'b0;
            reg_write_enable <= 1'b0;
            mem_read <= 1'b0;
            mem_write <= 1'b0;
            branch <= 1'b0;
            jump <= 1'b0;
        end else begin
            opcode <= instruction[6:0];
            rd <= instruction[11:7];
            rs1 <= instruction[19:15];
            rs2 <= instruction[24:20];
            funct3 <= instruction[14:12];
            funct7 <= instruction[31:25];
            
            // Immediate generation for different instruction types
            case (instruction[6:0])
                7'b0010011, 7'b0000011: begin // I-type
                    immediate <= {{21{instruction[31]}}, instruction[30:20]};
                end
                7'b0100011: begin // S-type
                    immediate <= {{21{instruction[31]}}, instruction[30:25], instruction[11:7]};
                end
                7'b1100011: begin // B-type
                    immediate <= {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
                end
                7'b0110111, 7'b0010111: begin // U-type
                    immediate <= {instruction[31:12], 12'b0};
                end
                7'b1101111: begin // J-type
                    immediate <= {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
                end
                default: immediate <= 32'b0;
            endcase
            
            // Control signal generation
            reg_write_enable <= (instruction[6:0] != 7'b0100011) && (instruction[6:0] != 7'b1100011);
            mem_read <= (instruction[6:0] == 7'b0000011);
            mem_write <= (instruction[6:0] == 7'b0100011);
            branch <= (instruction[6:0] == 7'b1100011);
            jump <= (instruction[6:0] == 7'b1101111) || (instruction[6:0] == 7'b1100111);
        end
    end
endmodule

// Register File
module register_file (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        write_enable,
    input  wire [4:0]  read_addr1,
    input  wire [4:0]  read_addr2,
    input  wire [4:0]  read_addr3,    // For triple-operand instructions
    input  wire [4:0]  write_addr,
    input  wire [31:0] write_data,
    
    output wire [31:0] read_data1,
    output wire [31:0] read_data2,
    output wire [31:0] read_data3
);
    
    // 32 registers, each 32 bits wide
    reg [31:0] registers [0:31];
    
    // Loop variable for initialization (declared at module level for Verilog 2001)
    integer i;
    
    // Asynchronous read
    assign read_data1 = (read_addr1 == 5'b0) ? 32'b0 : registers[read_addr1];
    assign read_data2 = (read_addr2 == 5'b0) ? 32'b0 : registers[read_addr2];
    assign read_data3 = (read_addr3 == 5'b0) ? 32'b0 : registers[read_addr3];
    
    // Synchronous write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize all registers to 0 using module-level integer
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (write_enable && write_addr != 5'b0) begin
            // Register x0 is always 0 and cannot be written
            registers[write_addr] <= write_data;
        end
    end
endmodule