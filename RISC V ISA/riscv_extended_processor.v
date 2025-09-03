module riscv_extended_processor #(
    parameter VECTOR_LENGTH = 8,           // Length of the vector (example value)
    parameter DATA_WIDTH = 32             // Bit-width of each element (example value)
)(
    input wire clk,                       // System clock
    input wire rst,                       // Reset signal
    input wire [31:0] rs1,                // Register 1 input
    input wire [31:0] rs2,                // Register 2 input
    input wire [6:0] funct7,              // Funct7 for ALU and M-extension operations
    input wire [2:0] funct3,              // Funct3 for ALU and other operations
    input wire [31:0] scalar,             // Scalar for operations like VX, VI
    input wire [VECTOR_LENGTH*DATA_WIDTH-1:0] vector_a, // Vector A input
    input wire [VECTOR_LENGTH*DATA_WIDTH-1:0] vector_b, // Vector B input
    output reg [31:0] result,             // Final result output (declared as reg)
    output wire valid,                    // Operation completion signal

    // New ports
    input wire valid_in,                  // Input valid signal for the top module
    input wire [31:0] addr,               // Address signal for DMA or memory operations
    input wire [2:0] mode,                // Mode select for VV, VX, or VI operations
    input wire aq,                         // Atomic acquire flag
    input wire rl,                         // Atomic release flag
    input wire [2:0] vector_funct3,       // Additional funct3 for vector operations
    output wire valid_out,                // Output valid signal
    output wire [31:0] result_out         // Output result for the top module
);

    // Internal signals for inter-module connections
    wire [31:0] activation_out;
    wire [31:0] pooling_out;
    wire [31:0] dma_out;
    wire [31:0] dot_product_out;
    wire [31:0] matrix_mult_out;
    wire [31:0] max_pooling_out;
    wire [31:0] mac_out;
    wire [31:0] atomic_mem_out;
    wire [31:0] fpu_out;
    wire [31:0] fpu_double_out;
    wire [31:0] alu_out;
    wire [31:0] vector_op_out;
    wire alu_div_by_zero;

    // Activation Function Submodule Instantiation
    activation_functions af_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),              // valid_in signal
        .input_addr(addr),                 // Address for input data
        .output_addr(addr),                // Address for output data
        .dimensions(4'd8),                  // Example dimension, modify as needed
        .opcode(7'h4A),                    // Example opcode for Sigmoid, modify as needed
        .result_out(activation_out),       // Output from the activation function
        .valid_out(valid_out)              // Valid output signal
    );

    // Average Pooling Submodule Instantiation
    average_pooling ap_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),              // valid_in signal
        .pool_size(4'd2),                  // Example pool size (can be adjusted)
        .stride(4'd2),                     // Example stride (can be adjusted)
        .input_addr(addr),                 // Assuming 'addr' as the input address
        .output_addr(addr),                // Assuming 'addr' as the output address
        .dimensions(4'd8),                 // Example dimensions, modify as needed
        .valid_out(valid_out)              // Valid output signal
    );

    // DMA Load/Store Submodule Instantiation (Corrected)
    dma_load_store dma_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),              // valid_in signal
        .src_dst_addr(addr),               // Corrected: Use 'src_dst_addr' instead of 'address'
        .size(8'd8),                       // Example size (modify as needed)
        .mode(4'b0001),                    // Example mode (use 4'b0001 for Load, modify as needed)
        .data_out(dma_out),                // Corrected: Use 'data_out' instead of 'data_in'
        .valid_out(valid_out)              // Output valid signal
    );

    // Dot Product Submodule Instantiation (Corrected)
    dot_product dp_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),              // valid_in signal
        .vector_a_addr(addr),              // Corrected: Use 'vector_a_addr' instead of 'vec_a'
        .vector_b_addr(addr),              // Corrected: Use 'vector_b_addr' instead of 'vec_b'
        .length(VECTOR_LENGTH),            // Corrected: Use 'length' instead of 'length'
        .result_register(5'd0),            // Example: Assign the register to store the result
        .result_out(dot_product_out),      // Output from dot product
        .valid_out(valid_out)              // Output valid signal
    );

    // Matrix Multiplication Submodule Instantiation
    matrix_multiplication mm_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),              // valid_in signal
        .matrix_a_addr(addr),              // Use matrix_a_addr instead of matrix_a
        .matrix_b_addr(addr),              // Use matrix_b_addr instead of matrix_b
        .matrix_c_addr(addr),              // Assuming addr is used for the result address (matrix C)
        .N(4'd4),                          // Number of rows for matrix A (modify as needed)
        .M(4'd4),                          // Number of columns for matrix A and rows for matrix B
        .P(4'd4),                          // Number of columns for matrix B (modify as needed)
        .result_out(matrix_mult_out),      // Output result of matrix multiplication
        .valid_out(valid_out)              // Output valid signal
    );

    // Max Pooling Submodule Instantiation (Corrected)
    max_pooling mp_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),              // valid_in signal
        .pool_size(4'd2),                  // Example pool size (can be adjusted)
        .stride(4'd2),                     // Example stride (can be adjusted)
        .input_addr(addr),                 // Corrected: Use input_addr instead of data_in
        .output_addr(addr),                // Corrected: Use output_addr instead of data_out
        .dimensions(4'd8),                 // Example dimensions, modify as needed
        .valid_out(valid_out)              // Valid output signal
    );

    // Multiply and Accumulate Submodule Instantiation (Corrected)
    multiply_and_accumulate mac_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),              // valid_in signal
        .src1_addr(addr),                  // Corrected: Use src1_addr instead of data_in
        .src2_addr(addr),                  // Corrected: Use src2_addr instead of data_in
        .accumulator_addr(addr),           // Corrected: Use accumulator_addr instead of data_out
        .result_out(mac_out),              // Output result from MAC operation
        .valid_out(valid_out)              // Output valid signal
    );

    // Atomic Memory Operations (AMO) Submodule Instantiation
atomic_memory_operations amo_inst (
    .rs1(amo_rs1),       // Address in memory
    .rs2(amo_rs2),       // Data to be operated upon
    .funct3(amo_funct3), // Operation selector
    .aq(amo_aq),         // Acquire flag
    .rl(amo_rl),         // Release flag
    .result(amo_result), // Result of the atomic operation
    .valid(amo_valid)    // Operation completion flag
);


    // Double-Precision Floating-Point Unit (FPU) Submodule Instantiation
double_precision_fpu dpfpu_inst (
    .rs1(dp_rs1),         // Source register 1 (double-precision)
    .rs2(dp_rs2),         // Source register 2 (double-precision)
    .funct3(dp_funct3),   // Operation selector (FADD.D, FSUB.D, etc.)
    .result(dp_result),   // Result of the double-precision operation
    .valid(dp_valid)      // Operation completion flag
);


    // Floating-Point Unit (FPU) Submodule Instantiation
floating_point_unit fpu_inst (
    .rs1(fp_rs1),         // Source register 1
    .rs2(fp_rs2),         // Source register 2
    .funct3(fp_funct3),   // Operation selector (FADD, FSUB, FMUL, FDIV)
    .result(fp_result),   // Result of the floating-point operation
    .valid(fp_valid)      // Operation completion flag
);


    // ALU-M Submodule Instantiation
alu_m alu_m_inst (
    .rs1(alu_rs1),          // Source register 1
    .rs2(alu_rs2),          // Source register 2
    .funct3(alu_funct3),    // ALU operation selector
    .funct7(alu_funct7),    // Extended operation selector
    .result(alu_m_result),  // ALU result
    .div_by_zero(div_zero_flag) // Division by zero flag
);

   // Vector Operations Submodule Instantiation
vector_operations #(
    .VECTOR_LENGTH(VECTOR_LENGTH),  // Length of the vector
    .DATA_WIDTH(DATA_WIDTH)         // Bit-width of each element
) vector_ops_inst (
    .vector_a(vector_a),            // Input vector A
    .vector_b(vector_b),            // Input vector B or scalar
    .scalar(scalar),                // Input scalar value
    .mode(vector_mode),             // Mode: VV, VX, or VI
    .funct3(vector_funct3),         // Operation selector
    .result(vector_op_out)          // Output result vector
);


    // Logic to determine final output based on the operation mode
    always @(*) begin
        case (funct3)
            3'b000: result = activation_out;      // Example for activation function operation
            3'b001: result = pooling_out;         // Example for pooling operation
            3'b010: result = dma_out;             // Example for DMA operation
            3'b011: result = dot_product_out;     // Example for dot product operation
            3'b100: result = matrix_mult_out;     // Example for matrix multiplication
            3'b101: result = max_pooling_out;     // Example for max pooling
            3'b110: result = mac_out;             // Example for MAC operation
            3'b111: result = atomic_mem_out;      // Example for atomic memory operations
            default: result = 32'b0;              // Default case if no operation matches
        endcase
    end

    // Final result output
    assign result_out = result;  // Assign final result to result_out
endmodule
