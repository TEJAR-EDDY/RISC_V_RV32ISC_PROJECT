`timescale 1ns / 1ps

module dot_product_tb;

    // Parameters
    parameter ADDR_WIDTH = 12;
    parameter DATA_WIDTH = 32;
    parameter VECTOR_LENGTH = 8;
    parameter RESULT_WIDTH = 64;

    // DUT inputs
    reg clk;
    reg rst;
    reg valid_in;
    reg [ADDR_WIDTH-1:0] vector_a_addr;
    reg [ADDR_WIDTH-1:0] vector_b_addr;
    reg [VECTOR_LENGTH-1:0] length;
    reg [4:0] result_register;

    // DUT outputs
    wire [RESULT_WIDTH-1:0] result_out;
    wire valid_out;

    // Memory for test vectors
    reg [DATA_WIDTH-1:0] memory_a [0:VECTOR_LENGTH-1];
    reg [DATA_WIDTH-1:0] memory_b [0:VECTOR_LENGTH-1];

    // Instantiate the DUT
    dot_product #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .VECTOR_LENGTH(VECTOR_LENGTH),
        .RESULT_WIDTH(RESULT_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .vector_a_addr(vector_a_addr),
        .vector_b_addr(vector_b_addr),
        .length(length),
        .result_register(result_register),
        .result_out(result_out),
        .valid_out(valid_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task for memory initialization
    task initialize_memory;
        input integer seed;
        integer i;
        begin
            $display("Initializing Memory...");
            for (i = 0; i < VECTOR_LENGTH; i = i + 1) begin
                memory_a[i] = $random(seed) % 256;
                memory_b[i] = $random(seed + 1) % 256;
            end
            $display("Memory Initialization Complete.");
        end
    endtask

    // Task for applying directed test
    task directed_test;
        input [VECTOR_LENGTH-1:0] test_length;
        integer i;
        reg [RESULT_WIDTH-1:0] expected_result;
        begin
            $display("Starting Directed Test...");
            rst = 1;
            #10 rst = 0;
            valid_in = 1;
            vector_a_addr = 0;
            vector_b_addr = 0;
            length = test_length;
            result_register = 5'b00001;

            // Initialize accumulator for expected result
            expected_result = 0;

            for (i = 0; i < test_length; i = i + 1) begin
                #10; // Wait for one clock cycle
                expected_result = expected_result + (memory_a[i] * memory_b[i]);
            end

            #10; // Wait for computation to finish
            valid_in = 0;

            if (result_out == expected_result && valid_out) begin
                $display("Directed Test Passed! Result: %d", result_out);
            end else begin
                $display("Directed Test Failed! Expected: %d, Got: %d", expected_result, result_out);
            end
        end
    endtask

    // Task for applying random tests
    task random_tests;
        integer rand_seed, test_length, i;
        reg [RESULT_WIDTH-1:0] expected_result;
        begin
            $display("Starting Random Tests...");
            rand_seed = $time;

            repeat (5) begin
                // Randomize test length
                test_length = $random(rand_seed) % VECTOR_LENGTH + 1;

                // Initialize memory
                initialize_memory(rand_seed);

                rst = 1;
                #10 rst = 0;
                valid_in = 1;
                vector_a_addr = 0;
                vector_b_addr = 0;
                length = test_length;
                result_register = 5'b00010;

                // Compute expected result
                expected_result = 0;
                for (i = 0; i < test_length; i = i + 1) begin
                    expected_result = expected_result + (memory_a[i] * memory_b[i]);
                end

                #10; // Wait for computation to finish
                valid_in = 0;

                if (result_out == expected_result && valid_out) begin
                    $display("Random Test Passed! Result: %d", result_out);
                end else begin
                    $display("Random Test Failed! Expected: %d, Got: %d", expected_result, result_out);
                end

                rand_seed = rand_seed + 1; // Update seed for the next iteration
            end

            $display("Random Tests Completed.");
        end
    endtask

    // Initial block for running tests
    initial begin
        $display("Starting Testbench...");
        clk = 0;
        rst = 0;
        valid_in = 0;
        vector_a_addr = 0;
        vector_b_addr = 0;
        length = 0;
        result_register = 0;

        // Run tests
        initialize_memory(32'hDEADBEEF); // Initialize memory with a fixed seed
        directed_test(8);               // Directed test with full vector length
        random_tests();                 // Perform random tests

        $display("All Tests Completed.");
        $finish;
    end

endmodule
