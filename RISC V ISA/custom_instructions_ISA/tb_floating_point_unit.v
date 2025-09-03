module floating_point_unit_tb;

    // Testbench signals
    reg [31:0] rs1;
    reg [31:0] rs2;
    reg [2:0]  funct3;
    wire [31:0] result;
    wire valid;

    // Instantiate the DUT
    floating_point_unit dut (
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

            // Floating-Point Addition (FADD)
            funct3 = 3'b000;
            rs1 = 32'h3F800000; // 1.0
            rs2 = 32'h40000000; // 2.0
            #10 display_result(); // Expect 3.0 (0x40400000)

            rs1 = 32'hBF800000; // -1.0
            rs2 = 32'h3F800000; // 1.0
            #10 display_result(); // Expect 0.0 (0x00000000)

            // Floating-Point Subtraction (FSUB)
            funct3 = 3'b001;
            rs1 = 32'h40000000; // 2.0
            rs2 = 32'h3F800000; // 1.0
            #10 display_result(); // Expect 1.0 (0x3F800000)

            rs1 = 32'h3F800000; // 1.0
            rs2 = 32'hBF800000; // -1.0
            #10 display_result(); // Expect 2.0 (0x40000000)

            // Floating-Point Multiplication (FMUL)
            funct3 = 3'b010;
            rs1 = 32'h3F800000; // 1.0
            rs2 = 32'h40000000; // 2.0
            #10 display_result(); // Expect 2.0 (0x40000000)

            rs1 = 32'hBF800000; // -1.0
            rs2 = 32'h40000000; // 2.0
            #10 display_result(); // Expect -2.0 (0xC0000000)

            // Floating-Point Division (FDIV)
            funct3 = 3'b011;
            rs1 = 32'h40000000; // 2.0
            rs2 = 32'h3F800000; // 1.0
            #10 display_result(); // Expect 2.0 (0x40000000)

            rs1 = 32'h40000000; // 2.0
            rs2 = 32'h00000000; // 0.0
            #10 display_result(); // Expect NaN (0x7FC00000)
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
        $display("Floating Point Unit Testbench");

        directed_tests(); // Run directed tests
        random_tests();   // Run random tests

        $display("All tests completed.");
        $stop;
    end

endmodule
