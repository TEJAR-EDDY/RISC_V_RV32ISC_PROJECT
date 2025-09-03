`timescale 1ns / 1ps

module riscv_extended_processor_tb;

    // Parameters
    parameter VECTOR_LENGTH = 8;
    parameter DATA_WIDTH = 32;

    // Testbench signals
    reg clk;
    reg rst;
    reg [31:0] rs1;
    reg [31:0] rs2;
    reg [6:0] funct7;
    reg [2:0] funct3;
    reg [31:0] scalar;
    reg [VECTOR_LENGTH*DATA_WIDTH-1:0] vector_a;
    reg [VECTOR_LENGTH*DATA_WIDTH-1:0] vector_b;
    reg valid_in;
    reg [31:0] addr;
    reg [2:0] mode;
    reg aq;
    reg rl;
    reg [2:0] vector_funct3;

    wire [31:0] result_out;
    wire valid_out;

    // DUT instantiation
    riscv_extended_processor #(
        .VECTOR_LENGTH(VECTOR_LENGTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7),
        .funct3(funct3),
        .scalar(scalar),
        .vector_a(vector_a),
        .vector_b(vector_b),
        .valid_in(valid_in),
        .addr(addr),
        .mode(mode),
        .aq(aq),
        .rl(rl),
        .vector_funct3(vector_funct3),
        .result_out(result_out),
        .valid_out(valid_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task to apply reset
    task apply_reset;
        begin
            rst = 1;
            #20;
            rst = 0;
        end
    endtask

    // Task for manual test case
    task manual_testcase(
        input [31:0] test_rs1,
        input [31:0] test_rs2,
        input [6:0] test_funct7,
        input [2:0] test_funct3,
        input [31:0] test_scalar,
        input [VECTOR_LENGTH*DATA_WIDTH-1:0] test_vector_a,
        input [VECTOR_LENGTH*DATA_WIDTH-1:0] test_vector_b,
        input [31:0] test_addr,
        input [2:0] test_mode,
        input test_aq,
        input test_rl,
        input [2:0] test_vector_funct3
    );
        begin
            rs1 = test_rs1;
            rs2 = test_rs2;
            funct7 = test_funct7;
            funct3 = test_funct3;
            scalar = test_scalar;
            vector_a = test_vector_a;
            vector_b = test_vector_b;
            addr = test_addr;
            mode = test_mode;
            aq = test_aq;
            rl = test_rl;
            vector_funct3 = test_vector_funct3;
            valid_in = 1;
            #20;
            valid_in = 0;
        end
    endtask

    // Task for randomized test case
    task randomized_testcase;
        begin
            rs1 = $random;
            rs2 = $random;
            funct7 = $random % 128; // 7 bits
            funct3 = $random % 8;   // 3 bits
            scalar = $random;
            vector_a = {$random, $random, $random, $random};
            vector_b = {$random, $random, $random, $random};
            addr = $random;
            mode = $random % 8;     // 3 bits
            aq = $random % 2;
            rl = $random % 2;
            vector_funct3 = $random % 8; // 3 bits
            valid_in = 1;
            #20;
            valid_in = 0;
        end
    endtask

    // Monitor signals
    initial begin
        $monitor("Time=%0t | funct3=%b | funct7=%b | result_out=%h | valid_out=%b", 
                 $time, funct3, funct7, result_out, valid_out);
    end

    // Test cases
    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;
        rs1 = 0;
        rs2 = 0;
        funct7 = 0;
        funct3 = 0;
        scalar = 0;
        vector_a = 0;
        vector_b = 0;
        addr = 0;
        mode = 0;
        aq = 0;
        rl = 0;
        vector_funct3 = 0;
        valid_in = 0;

        // Apply reset
        apply_reset;

        // Test case 1: Activation function (manual)
        manual_testcase(32'd10, 32'd0, 7'h4A, 3'b000, 32'd0, 0, 0, 32'd0, 3'b000, 0, 0, 3'b000);

        // Test case 2: Matrix multiplication (manual)
        manual_testcase(32'd0, 32'd0, 7'h00, 3'b100, 32'd0, {$random, $random, $random, $random}, 
                        {$random, $random, $random, $random}, 32'd0, 3'b100, 0, 0, 3'b000);

        // Test case 3: Randomized test
        randomized_testcase;

        // Test case 4: Edge case (atomic acquire-release operation)
        manual_testcase(32'd1, 32'd2, 7'h00, 3'b111, 32'd0, 0, 0, 32'd0, 3'b111, 1, 1, 3'b000);

        // Test case 5: Randomized test
        randomized_testcase;

        // Finish simulation
        #200;
        $finish;
    end

endmodule
