module alu_m_tb;

    // Testbench signals
    reg [31:0] rs1;
    reg [31:0] rs2;
    reg [2:0] funct3;
    reg [6:0] funct7;
    wire [31:0] result;
    wire div_by_zero;

    // Instantiate the DUT
    alu_m dut (
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .funct7(funct7),
        .result(result),
        .div_by_zero(div_by_zero)
    );

    // Task to display results
    task display_result;
        begin
            $display("Time: %0t | rs1: %0d | rs2: %0d | funct7: %b | funct3: %b | result: %0d | div_by_zero: %b",
                     $time, rs1, rs2, funct7, funct3, result, div_by_zero);
        end
    endtask

    // Task for directed tests
    task directed_tests;
        begin
            $display("Starting Directed Tests...");

            // Initialize funct7 for M-extension operations
            funct7 = 7'b0000001;

            // Test MUL
            funct3 = 3'b000; rs1 = 10; rs2 = 20; #10; display_result();
            funct3 = 3'b000; rs1 = -10; rs2 = 5; #10; display_result();

            // Test MULH
            funct3 = 3'b001; rs1 = 32'h12345678; rs2 = 32'h9abcdef0; #10; display_result();

            // Test MULHSU
            funct3 = 3'b010; rs1 = -100; rs2 = 200; #10; display_result();

            // Test MULHU
            funct3 = 3'b011; rs1 = 32'hFFFFFFFF; rs2 = 32'hFFFFFFFF; #10; display_result();

            // Test DIV
            funct3 = 3'b100; rs1 = 100; rs2 = 20; #10; display_result();
            funct3 = 3'b100; rs1 = 100; rs2 = 0; #10; display_result(); // Division by zero

            // Test DIVU
            funct3 = 3'b101; rs1 = 100; rs2 = 3; #10; display_result();

            // Test REM
            funct3 = 3'b110; rs1 = 35; rs2 = 6; #10; display_result();
            funct3 = 3'b110; rs1 = 35; rs2 = 0; #10; display_result(); // Remainder by zero

            // Test REMU
            funct3 = 3'b111; rs1 = 35; rs2 = 4; #10; display_result();
        end
    endtask

    // Task for random tests
    task random_tests;
        integer i;
        begin
            $display("Starting Random Tests...");
            funct7 = 7'b0000001;

            for (i = 0; i < 20; i = i + 1) begin
                rs1 = $random;
                rs2 = $random;
                funct3 = $random % 8; // Random funct3 within valid range
                #10 display_result();
            end
        end
    endtask

    // Initial block to control the simulation
    initial begin
        $display("ALU_M Testbench");

        directed_tests(); // Run directed tests
        random_tests();   // Run random tests

        $display("All tests completed.");
        $stop;
    end

endmodule
