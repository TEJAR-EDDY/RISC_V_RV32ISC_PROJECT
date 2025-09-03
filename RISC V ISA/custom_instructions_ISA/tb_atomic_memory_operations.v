module atomic_memory_operations_tb;

    // Testbench signals
    reg [31:0] rs1;
    reg [31:0] rs2;
    reg [2:0]  funct3;
    reg        aq;
    reg        rl;
    wire [31:0] result;
    wire valid;

    // Instantiate the DUT
    atomic_memory_operations dut (
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .aq(aq),
        .rl(rl),
        .result(result),
        .valid(valid)
    );

    // Task to display test case results
    task display_result;
        begin
            $display("Time: %0t | rs1: %h | rs2: %h | funct3: %b | aq: %b | rl: %b | result: %h | valid: %b",
                     $time, rs1, rs2, funct3, aq, rl, result, valid);
        end
    endtask

    // Directed Test Cases to cover each operation in the AMO (Atomic Memory Operations)
    task directed_tests;
        begin
            $display("Starting Directed Tests...");

            // AMOADD (Atomic Add)
            funct3 = 3'b000;
            rs1 = 32'h00000010; // Memory address
            rs2 = 32'h00000005; // Data to add
            #10 display_result(); // Expect memory[rs1] + rs2

            // AMOSWAP (Atomic Swap)
            funct3 = 3'b001;
            rs1 = 32'h00000010; // Memory address
            rs2 = 32'h000000FF; // Data to swap
            #10 display_result(); // Expect memory[rs1] to swap with rs2

            // AMOAND (Atomic AND)
            funct3 = 3'b010;
            rs1 = 32'h00000010; // Memory address
            rs2 = 32'h0000000F; // Data to AND
            #10 display_result(); // Expect memory[rs1] & rs2

            // AMOOR (Atomic OR)
            funct3 = 3'b011;
            rs1 = 32'h00000010; // Memory address
            rs2 = 32'h000000F0; // Data to OR
            #10 display_result(); // Expect memory[rs1] | rs2

            // Test Acquire (aq) flag
            aq = 1'b1; // Set acquire flag
            funct3 = 3'b000; // AMOADD
            rs1 = 32'h00000010;
            rs2 = 32'h00000005;
            #10 display_result(); // Test with acquire flag

            // Test Release (rl) flag
            aq = 1'b0; // Clear acquire flag
            rl = 1'b1; // Set release flag
            funct3 = 3'b001; // AMOSWAP
            rs1 = 32'h00000010;
            rs2 = 32'h000000FF;
            #10 display_result(); // Test with release flag

            // Reset flags for further tests
            aq = 1'b0;
            rl = 1'b0;

        end
    endtask

    // Random Test Cases to cover edge cases and ensure robustness
    task random_tests;
        integer i;
        begin
            $display("Starting Random Tests...");

            for (i = 0; i < 20; i = i + 1) begin
                // Randomize inputs
                rs1 = $random % 256;    // Random memory address between 0 and 255
                rs2 = $random;          // Random 32-bit value for rs2
                funct3 = $random % 4;   // Random funct3 (0 to 3)
                aq = $random % 2;       // Random aq flag
                rl = $random % 2;       // Random rl flag
                #10 display_result();    // Run the test and display the result
            end
        end
    endtask

    // Initial block to control simulation
    initial begin
        $display("Atomic Memory Operations Testbench");

        // Initialize memory to known state
        dut.memory[16] = 32'h00000000;  // Initialize memory at address 16 to 0

        // Run directed tests
        directed_tests(); 

        // Run random tests
        random_tests(); 

        $display("All tests completed.");
        $stop;
    end

endmodule
