`timescale 1ns / 1ps

module max_pooling_tb;

    // Parameters
    parameter ADDR_WIDTH = 12;
    parameter DATA_WIDTH = 32;
    parameter DIM_WIDTH = 4;

    // Signals for DUT
    reg clk;
    reg rst;
    reg valid_in;
    reg [DIM_WIDTH-1:0] pool_size;
    reg [DIM_WIDTH-1:0] stride;
    reg [ADDR_WIDTH-1:0] input_addr;
    reg [ADDR_WIDTH-1:0] output_addr;
    reg [DIM_WIDTH-1:0] dimensions;
    wire valid_out;

    // DUT instantiation
    max_pooling #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DIM_WIDTH(DIM_WIDTH)
    ) uut (
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

    // Test input memory (Simulated)
    reg [DATA_WIDTH-1:0] input_memory [0:1023];
    reg [DATA_WIDTH-1:0] output_memory [0:1023];

    // Task to initialize input memory
    task initialize_input_memory;
        integer i;
        begin
            for (i = 0; i < 1024; i = i + 1)
                input_memory[i] = $random % 256; // Random data between 0-255
        end
    endtask

    // Task for directed test case
    task directed_test(
        input [DIM_WIDTH-1:0] test_pool_size,
        input [DIM_WIDTH-1:0] test_stride,
        input [DIM_WIDTH-1:0] test_dimensions
    );
        integer i, j, x, y, max_val, row, col;
        begin
            // Set parameters for directed test
            pool_size = test_pool_size;
            stride = test_stride;
            dimensions = test_dimensions;
            valid_in = 1;
            input_addr = 0;
            output_addr = 512; // Output memory starts at address 512
            rst = 1;
            #10 rst = 0;

            // Wait for processing to complete
            wait(valid_out);
            #10;

            // Verify results
            for (row = 0; row < dimensions; row = row + stride) begin
                for (col = 0; col < dimensions; col = col + stride) begin
                    max_val = 0;
                    for (x = 0; x < pool_size; x = x + 1) begin
                        for (y = 0; y < pool_size; y = y + 1) begin
                            i = row + x;
                            j = col + y;
                            if (i < dimensions && j < dimensions) begin
                                if (input_memory[i * dimensions + j] > max_val)
                                    max_val = input_memory[i * dimensions + j];
                            end
                        end
                    end
                    if (output_memory[(row / stride) * (dimensions / stride) + (col / stride)] !== max_val) begin
                        $display("Test Failed: Expected max = %d, Got = %d", max_val, output_memory[(row / stride) * (dimensions / stride) + (col / stride)]);
                        $stop;
                    end
                end
            end
            $display("Directed Test Passed");
        end
    endtask

    // Task for random test case
    task random_test;
        begin
            // Randomly set pool size, stride, and dimensions
            pool_size = $random % 4 + 1; // Random between 1-4
            stride = $random % pool_size + 1; // Random stride <= pool_size
            dimensions = $random % 16 + 4; // Random dimensions between 4-16

            // Call directed test for the randomly generated parameters
            directed_test(pool_size, stride, dimensions);
        end
    endtask

    // Main test sequence
    initial begin
        $display("Starting Test Bench...");
        clk = 0;
        rst = 1;
        valid_in = 0;
        pool_size = 0;
        stride = 0;
        dimensions = 0;
        input_addr = 0;
        output_addr = 0;

        // Initialize input memory
        initialize_input_memory;

        // Directed Test Case 1
        directed_test(2, 2, 8);

        // Directed Test Case 2
        directed_test(3, 1, 6);

        // Random Test Cases
        repeat(5) random_test;

        $display("All Tests Passed!");
        $stop;
    end
endmodule
