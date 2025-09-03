`timescale 1ns / 1ps

module matrix_multiplication_tb;

    // Parameters
    parameter ADDR_WIDTH = 12;
    parameter DATA_WIDTH = 32;
    parameter DIM_WIDTH = 4;

    // DUT inputs
    reg clk;
    reg rst;
    reg valid_in;
    reg [ADDR_WIDTH-1:0] matrix_a_addr;
    reg [ADDR_WIDTH-1:0] matrix_b_addr;
    reg [ADDR_WIDTH-1:0] matrix_c_addr;
    reg [DIM_WIDTH-1:0] N; // Rows of Matrix A and Matrix C
    reg [DIM_WIDTH-1:0] M; // Columns of Matrix A and Rows of Matrix B
    reg [DIM_WIDTH-1:0] P; // Columns of Matrix B and Matrix C

    // DUT outputs
    wire [DATA_WIDTH-1:0] result_out;
    wire valid_out;

    // Memory to hold test matrices
    reg [DATA_WIDTH-1:0] matrix_a [0:15][0:15]; // Matrix A
    reg [DATA_WIDTH-1:0] matrix_b [0:15][0:15]; // Matrix B
    reg [DATA_WIDTH-1:0] matrix_c [0:15][0:15]; // Matrix C (expected results)

    // Instantiate DUT
    matrix_multiplication #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DIM_WIDTH(DIM_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .matrix_a_addr(matrix_a_addr),
        .matrix_b_addr(matrix_b_addr),
        .matrix_c_addr(matrix_c_addr),
        .N(N),
        .M(M),
        .P(P),
        .result_out(result_out),
        .valid_out(valid_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task to initialize matrices
    task initialize_matrices;
        input integer seed;
        integer i, j;
        begin
            $display("Initializing Matrices...");
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    matrix_a[i][j] = $random(seed) % 10; // Random values between 0 and 9
                    matrix_b[i][j] = $random(seed + 1) % 10;
                    matrix_c[i][j] = 0; // Initialize result matrix to zero
                end
            end
            $display("Matrix Initialization Complete.");
        end
    endtask

    // Task to compute expected results
    task compute_expected_results;
        integer i, j, k;
        begin
            $display("Computing Expected Results...");
            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < P; j = j + 1) begin
                    for (k = 0; k < M; k = k + 1) begin
                        matrix_c[i][j] = matrix_c[i][j] + (matrix_a[i][k] * matrix_b[k][j]);
                    end
                end
            end
            $display("Expected Results Computation Complete.");
        end
    endtask

    // Directed test
    task directed_test;
        integer i, j, k;
        begin
            $display("Starting Directed Test...");
            rst = 1;
            #10 rst = 0;

            valid_in = 1;
            matrix_a_addr = 0;
            matrix_b_addr = 0;
            matrix_c_addr = 0;

            // Wait for computation to complete
            wait (valid_out);

            // Verify results
            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < P; j = j + 1) begin
                    if (result_out !== matrix_c[i][j]) begin
                        $display("Test Failed: Mismatch at C[%d][%d], Expected: %d, Got: %d", i, j, matrix_c[i][j], result_out);
                        $stop;
                    end
                end
            end

            $display("Directed Test Passed.");
        end
    endtask

    // Randomized test
    task random_test;
        integer rand_seed;
        begin
            $display("Starting Random Test...");
            rand_seed = $time;
            initialize_matrices(rand_seed);

            // Set dimensions
            N = 4;
            M = 4;
            P = 4;

            compute_expected_results();
            directed_test();
            $display("Random Test Passed.");
        end
    endtask

    // Initial block
    initial begin
        clk = 0;
        rst = 0;
        valid_in = 0;
        matrix_a_addr = 0;
        matrix_b_addr = 0;
        matrix_c_addr = 0;
        N = 0;
        M = 0;
        P = 0;

        // Perform tests
        initialize_matrices(32'hDEADBEEF);
        compute_expected_results();
        directed_test();
        random_test();

        $display("All Tests Completed.");
        $finish;
    end

endmodule
