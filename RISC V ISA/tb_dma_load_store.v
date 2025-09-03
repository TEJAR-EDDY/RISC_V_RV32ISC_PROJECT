`timescale 1ns / 1ps

module dma_load_store_tb;

    // Parameters
    parameter ADDR_WIDTH = 12;
    parameter DATA_WIDTH = 32;
    parameter SIZE_WIDTH = 8;
    parameter MODE_WIDTH = 4;

    // Testbench signals
    reg clk;
    reg rst;
    reg valid_in;
    reg [ADDR_WIDTH-1:0] src_dst_addr;
    reg [SIZE_WIDTH-1:0] size;
    reg [MODE_WIDTH-1:0] mode;
    wire [DATA_WIDTH-1:0] data_out;
    wire valid_out;

    // Memory array for simulation
    reg [DATA_WIDTH-1:0] memory [0:(1 << ADDR_WIDTH) - 1];

    // Instantiate the DUT
    dma_load_store #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .SIZE_WIDTH(SIZE_WIDTH),
        .MODE_WIDTH(MODE_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .src_dst_addr(src_dst_addr),
        .size(size),
        .mode(mode),
        .data_out(data_out),
        .valid_out(valid_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task to simulate memory read
    task read_memory;
        input [ADDR_WIDTH-1:0] addr;
        output [DATA_WIDTH-1:0] data;
        begin
            data = memory[addr];
        end
    endtask

    // Task to simulate memory write
    task write_memory;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        begin
            memory[addr] = data;
        end
    endtask

    // Task for directed test cases
    task directed_tests;
        integer i;
        begin
            $display("Starting Directed Tests...");

            // Test Case 1: Load operation
            rst = 1;
            #10 rst = 0;
            valid_in = 1;
            src_dst_addr = 12'h100;
            size = 8; // 8 data transfers
            mode = 4'b0001; // Load
            #100;

            // Verify memory reads
            for (i = 0; i < size; i = i + 1) begin
                $display("Load Test - Addr: %h, Data: %h", src_dst_addr + i, memory[src_dst_addr + i]);
            end

            // Test Case 2: Store operation
            rst = 1;
            #10 rst = 0;
            valid_in = 1;
            src_dst_addr = 12'h200;
            size = 4; // 4 data transfers
            mode = 4'b0010; // Store
            #50;

            // Verify memory writes
            for (i = 0; i < size; i = i + 1) begin
                $display("Store Test - Addr: %h, Data: %h", src_dst_addr + i, memory[src_dst_addr + i]);
            end

            valid_in = 0;
            $display("Directed Tests Completed.");
        end
    endtask

    // Task for random test cases
    task random_tests;
        integer j, rand_size, rand_mode, rand_addr;
        begin
            $display("Starting Random Tests...");

            for (j = 0; j < 5; j = j + 1) begin
                rand_size = $random % 16 + 1; // Random size between 1 and 16
                rand_mode = (j % 2 == 0) ? 4'b0001 : 4'b0010; // Alternating Load and Store
                rand_addr = $random % (1 << ADDR_WIDTH); // Random starting address

                // Apply random parameters
                valid_in = 1;
                size = rand_size;
                mode = rand_mode;
                src_dst_addr = rand_addr;

                #(rand_size * 10); // Allow time for random operation to complete


                // Validate results
                if (rand_mode == 4'b0001) begin
                    $display("Random Load Test - Addr: %h, Size: %0d", rand_addr, rand_size);
                end else begin
                    $display("Random Store Test - Addr: %h, Size: %0d", rand_addr, rand_size);
                end
            end

            valid_in = 0;
            $display("Random Tests Completed.");
        end
    endtask

    // Initial block to run the tests
    integer k; // Declare loop variable outside the `for` loop
    initial begin
        $display("DMA Load/Store Testbench");

        // Initialize signals
        clk = 0;
        rst = 0;
        valid_in = 0;
        src_dst_addr = 0;
        size = 0;
        mode = 0;

        // Initialize memory with known values
        for (k = 0; k < (1 << ADDR_WIDTH); k = k + 1) begin
            memory[k] = $random % 256; // Random values between 0 and 255
        end

        // Run directed tests
        directed_tests();

        // Run random tests
        random_tests();

        $display("All tests completed.");
        $stop;
    end

endmodule
