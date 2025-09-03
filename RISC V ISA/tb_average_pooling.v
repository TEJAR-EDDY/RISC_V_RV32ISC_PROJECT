`timescale 1ns / 1ps

module average_pooling_tb;

    // Parameters
    parameter ADDR_WIDTH = 12;
    parameter DATA_WIDTH = 32;
    parameter DIM_WIDTH = 4;

    // Testbench signals
    reg clk;
    reg rst;
    reg valid_in;
    reg [DIM_WIDTH-1:0] pool_size;
    reg [DIM_WIDTH-1:0] stride;
    reg [ADDR_WIDTH-1:0] input_addr;
    reg [ADDR_WIDTH-1:0] output_addr;
    reg [DIM_WIDTH-1:0] dimensions;
    wire valid_out;

    // Internal variables for simulation
    integer i, j, k;

    // Instantiate the DUT
    average_pooling #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DIM_WIDTH(DIM_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .pool_size(pool_size),
        .stride(stride),
        .input_addr(input_addr),
        .output_addr(output_addr),
        .dimensions(dimensions),
        .valid_out(valid_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Memory array for simulation (mock memory)
    reg [DATA_WIDTH-1:0] memory [0:(1 << ADDR_WIDTH) - 1];

    // Initialize the memory with random values
    initial begin
        for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1) begin
            memory[i] = $random % 256; // Random values between 0 and 255
        end
    end

    // Task to simulate reading input data from memory
    task read_memory;
        input [ADDR_WIDTH-1:0] addr;
        output [DATA_WIDTH-1:0] data;
        begin
            data = memory[addr];
        end
    endtask

    // Task to simulate writing output data to memory
    task write_memory;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        begin
            memory[addr] = data;
        end
    endtask

    // Task for directed test cases
    task directed_tests;
        begin
            $display("Starting Directed Tests...");

            // Reset and initialize
            rst = 1;
            #10 rst = 0;

            // Test Case 1: Basic 2x2 pooling with stride 1
            valid_in = 1;
            pool_size = 2;
            stride = 1;
            input_addr = 12'h000;
            output_addr = 12'h100;
            dimensions = 4; // 4x4 input matrix
            #100;

            // Test Case 2: 3x3 pooling with stride 2
            valid_in = 1;
            pool_size = 3;
            stride = 2;
            input_addr = 12'h010;
            output_addr = 12'h200;
            dimensions = 6; // 6x6 input matrix
            #150;

            valid_in = 0;
            $display("Directed Tests Completed.");
        end
    endtask

    // Task for random test cases
    task random_tests;
        integer rand_pool_size, rand_stride, rand_dimensions;
        begin
            $display("Starting Random Tests...");

            for (k = 0; k < 10; k = k + 1) begin
                // Generate random parameters
                rand_pool_size = $random % 4 + 1; // Pool size between 1 and 4
                rand_stride = $random % 4 + 1;   // Stride between 1 and 4
                rand_dimensions = $random % 8 + 4; // Dimensions between 4 and 12

                // Apply random test
                valid_in = 1;
                pool_size = rand_pool_size;
                stride = rand_stride;
                input_addr = $random % (1 << ADDR_WIDTH);
                output_addr = $random % (1 << ADDR_WIDTH);
                dimensions = rand_dimensions;
                #100;
            end

            valid_in = 0;
            $display("Random Tests Completed.");
        end
    endtask

    // Task to display the contents of memory (for debugging)
    task display_memory;
        input [ADDR_WIDTH-1:0] start_addr;
        input [ADDR_WIDTH-1:0] end_addr;
        begin
            $display("Memory Dump:");
            for (j = start_addr; j <= end_addr; j = j + 1) begin
                $display("Addr %h: %h", j, memory[j]);
            end
        end
    endtask

    // Initial block to run the tests
    initial begin
        $display("Average Pooling Testbench");

        // Initialize signals
        clk = 0;
        rst = 0;
        valid_in = 0;
        pool_size = 0;
        stride = 0;
        input_addr = 0;
        output_addr = 0;
        dimensions = 0;

        // Run directed tests
        directed_tests();

        // Run random tests
        random_tests();

        // Dump memory content
        display_memory(12'h000, 12'h020);

        $display("All tests completed.");
        $stop;
    end

endmodule
