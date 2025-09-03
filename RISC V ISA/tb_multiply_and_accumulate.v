`timescale 1ns / 1ps

module multiply_and_accumulate_tb;

    // Parameters
    parameter ADDR_WIDTH = 12;
    parameter DATA_WIDTH = 32;
    parameter ACC_WIDTH = 5;

    // Signals for DUT
    reg clk;
    reg rst;
    reg valid_in;
    reg [ADDR_WIDTH-1:0] src1_addr;
    reg [ADDR_WIDTH-1:0] src2_addr;
    reg [ACC_WIDTH-1:0] accumulator_addr;
    wire [DATA_WIDTH-1:0] result_out;
    wire valid_out;

    // DUT instantiation
    multiply_and_accumulate #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .src1_addr(src1_addr),
        .src2_addr(src2_addr),
        .accumulator_addr(accumulator_addr),
        .result_out(result_out),
        .valid_out(valid_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test input memory (Simulated)
    reg [DATA_WIDTH-1:0] src1_memory [0:1023];
    reg [DATA_WIDTH-1:0] src2_memory [0:1023];
    reg [DATA_WIDTH-1:0] accumulator_memory [0:1023];

    // Task to initialize memory
    task initialize_memory;
        integer i;
        begin
            for (i = 0; i < 1024; i = i + 1) begin
                src1_memory[i] = $random % 256;  // Random data for src1
                src2_memory[i] = $random % 256;  // Random data for src2
                accumulator_memory[i] = $random % 256; // Random data for accumulator
            end
        end
    endtask

    // Task for directed test case
    task directed_test(
        input [ADDR_WIDTH-1:0] test_src1_addr,
        input [ADDR_WIDTH-1:0] test_src2_addr,
        input [ACC_WIDTH-1:0] test_accumulator_addr,
        input [DATA_WIDTH-1:0] expected_result
    );
        begin
            // Set parameters for directed test
            src1_addr = test_src1_addr;
            src2_addr = test_src2_addr;
            accumulator_addr = test_accumulator_addr;
            valid_in = 1;
            rst = 1;
            #10 rst = 0;

            // Apply test vectors
            src1_memory[test_src1_addr] = 32'h00000010; // Test value
            src2_memory[test_src2_addr] = 32'h00000020; // Test value
            accumulator_memory[test_accumulator_addr] = 32'h00000005; // Test accumulator value

            // Wait for result
            wait(valid_out);
            #10;

            // Check if result is as expected
            if (result_out !== expected_result) begin
                $display("Test Failed: Expected %h, Got %h", expected_result, result_out);
                $stop;
            end else begin
                $display("Directed Test Passed: Expected result %h, Got %h", expected_result, result_out);
            end
        end
    endtask

    // Task for random test case
    task random_test;
        reg [DATA_WIDTH-1:0] expected_result;
        begin
            // Randomly set memory locations
            src1_addr = $random % 1024;
            src2_addr = $random % 1024;
            accumulator_addr = $random % 1024;

            // Random data for src1, src2, and accumulator
            src1_memory[src1_addr] = $random % 256;
            src2_memory[src2_addr] = $random % 256;
            accumulator_memory[accumulator_addr] = $random % 256;

            // Calculate expected result: (src1 * src2) + accumulator
            expected_result = (src1_memory[src1_addr] * src2_memory[src2_addr]) + accumulator_memory[accumulator_addr];

            // Apply test vectors
            valid_in = 1;
            rst = 1;
            #10 rst = 0;

            // Wait for result
            wait(valid_out);
            #10;

            // Check if result is as expected
            if (result_out !== expected_result) begin
                $display("Random Test Failed: Expected %h, Got %h", expected_result, result_out);
                $stop;
            end else begin
                $display("Random Test Passed: Expected result %h, Got %h", expected_result, result_out);
            end
        end
    endtask

    // Main test sequence
    initial begin
        $display("Starting Test Bench...");
        clk = 0;
        rst = 1;
        valid_in = 0;
        src1_addr = 0;
        src2_addr = 0;
        accumulator_addr = 0;

        // Initialize memory
        initialize_memory;

        // Directed Test Case 1
        directed_test(12, 13, 14, 32'h00000010 * 32'h00000020 + 32'h00000005);

        // Directed Test Case 2
        directed_test(50, 51, 52, 32'h00000001 * 32'h00000002 + 32'h00000003);

        // Random Test Cases
        repeat(5) random_test;

        $display("All Tests Passed!");
        $stop;
    end
endmodule
