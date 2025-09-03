module double_precision_fpu_tb;

    // Testbench signals
    reg [63:0] rs1;
    reg [63:0] rs2;
    reg [2:0]  funct3;
    wire [63:0] result;
    wire valid;

    // Instantiate the DUT
    double_precision_fpu dut (
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .result(result),
        .valid(valid)
    );

    // Task to display test case results
    task display_result;
        begin
            $display("Time: %0t | rs1: %h | rs2: %h | funct3: %b | result: %h | valid: %b",
                     $time, rs1, rs2, funct3, result, valid);
        end
    endtask

    // Task for directed tests
    task directed_tests;
        begin
            $display("Starting Directed Tests...");

            // Double-Precision Floating-Point Addition (FADD.D)
            funct3 = 3'b000;
            rs1 = 64'h3FF0000000000000; // 1.0
            rs2 = 64'h4000000000000000; // 2.0
            #10 display_result(); // Expect 3.0 (0x4008000000000000)

            rs1 = 64'hBFF0000000000000; // -1.0
            rs2 = 64'h3FF0000000000000; // 1.0
            #10 display_result(); // Expect 0.0 (0x0000000000000000)

            // Double-Precision Floating-Point Subtraction (FSUB.D)
            funct3 = 3'b001;
            rs1 = 64'h4000000000000000; // 2.0
            rs2 = 64'h3FF0000000000000; // 1.0
            #10 display_result(); // Expect 1.0 (0x3FF0000000000000)

            rs1 = 64'h3FF0000000000000; // 1.0
            rs2 = 64'hBFF0000000000000; // -1.0
            #10 display_result(); // Expect 2.0 (0x4000000000000000)

            // Double-Precision Floating-Point Multiplication (FMUL.D)
            funct3 = 3'b010;
            rs1 = 64'h3FF0000000000000; // 1.0
            rs2 = 64'h4000000000000000; // 2.0
            #10 display_result(); // Expect 2.0 (0x4000000000000000)

            rs1 = 64'hBFF0000000000000; // -1.0
            rs2 = 64'h4000000000000000; // 2.0
            #10 display_result(); // Expect -2.0 (0xC000000000000000)

            // Double-Precision Floating-Point Division (FDIV.D)
            funct3 = 3'b011;
            rs1 = 64'h4000000000000000; // 2.0
            rs2 = 64'h3FF0000000000000; // 1.0
            #10 display_result(); // Expect 2.0 (0x4000000000000000)

            rs1 = 64'h4000000000000000; // 2.0
            rs2 = 64'h0000000000000000; // 0.0
            #10 display_result(); // Expect NaN (0x7FF8000000000000)
        end
    endtask

    // Task for random tests
    task random_tests;
        integer i;
        begin
            $display("Starting Random Tests...");

            for (i = 0; i < 20; i = i + 1) begin
                rs1 = $random;
                rs2 = $random;
                funct3 = $random % 4; // Random funct3 (0 to 3)
                #10 display_result();
            end
        end
    endtask

    // Initial block to control simulation
    initial begin
        $display("Double Precision FPU Testbench");

        directed_tests(); // Run directed tests
        random_tests();   // Run random tests

        $display("All tests completed.");
        $stop;
    end

endmodule
