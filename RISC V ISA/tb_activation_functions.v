`timescale 1ns / 1ps

module activation_functions_tb;

    // Parameters
    parameter ADDR_WIDTH = 12;
    parameter DATA_WIDTH = 32;
    parameter DIM_WIDTH = 4;

    // Testbench signals
    reg clk;
    reg rst;
    reg valid_in;
    reg [ADDR_WIDTH-1:0] input_addr;
    reg [ADDR_WIDTH-1:0] output_addr;
    reg [DIM_WIDTH-1:0] dimensions;
    reg [6:0] opcode; // Opcode: 0x4A for Sigmoid, 0x4B for Tanh
    wire [DATA_WIDTH-1:0] result_out;
    wire valid_out;

    // Instantiate the DUT
    activation_functions #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DIM_WIDTH(DIM_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .input_addr(input_addr),
        .output_addr(output_addr),
        .dimensions(dimensions),
        .opcode(opcode),
        .result_out(result_out),
        .valid_out(valid_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task to display test results
    task display_result;
        begin
            $display("Time: %0t | Opcode: %h | Input Address: %h | Output Address: %h | Dimensions: %h | Result: %h | Valid Out: %b",
                     $time, opcode, input_addr, output_addr, dimensions, result_out, valid_out);
        end
    endtask

    // Directed test cases
    task directed_tests;
        begin
            $display("Starting Directed Tests...");

            // Reset the system
            rst = 1;
            #10 rst = 0;

            // Test Sigmoid Function (Opcode: 0x4A)
            valid_in = 1;
            input_addr = 12'h001;
            output_addr = 12'h010;
            dimensions = 4'd4;
            opcode = 7'h4A; // Sigmoid
            #20 display_result();

            // Test Tanh Function (Opcode: 0x4B)
            valid_in = 1;
            input_addr = 12'h002;
            output_addr = 12'h011;
            dimensions = 4'd4;
            opcode = 7'h4B; // Tanh
            #20 display_result();

            // Test invalid opcode
            valid_in = 1;
            input_addr = 12'h003;
            output_addr = 12'h012;
            dimensions = 4'd4;
            opcode = 7'h00; // Invalid opcode
            #20 display_result();

            valid_in = 0;
            $display("Directed Tests Completed.");
        end
    endtask

    // Random test cases
    task random_tests;
        integer i;
        reg [DATA_WIDTH-1:0] random_data;
        begin
            $display("Starting Random Tests...");

            for (i = 0; i < 20; i = i + 1) begin
                // Randomize inputs
                valid_in = 1;
                input_addr = $random % (1 << ADDR_WIDTH);
                output_addr = $random % (1 << ADDR_WIDTH);
                dimensions = $random % (1 << DIM_WIDTH);
                opcode = ($random % 2) ? 7'h4A : 7'h4B; // Randomly select Sigmoid or Tanh

                // Simulate input data
                random_data = $random;
                #10 display_result();
            end

            valid_in = 0;
            $display("Random Tests Completed.");
        end
    endtask

    // Initial block for simulation
    initial begin
        $display("Activation Functions Testbench");

        // Initialize signals
        clk = 0;
        rst = 0;
        valid_in = 0;
        input_addr = 0;
        output_addr = 0;
        dimensions = 0;
        opcode = 0;

        // Run directed tests
        directed_tests();

        // Run random tests
        random_tests();

        $display("All tests completed.");
        $stop;
    end
endmodule
