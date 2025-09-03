module atomic_memory_operations (
    input  wire [31:0] rs1,        // Address in memory
    input  wire [31:0] rs2,        // Data to be operated upon
    input  wire [2:0]  funct3,     // Operation selector
    input  wire        aq,         // Acquire flag
    input  wire        rl,         // Release flag
    output reg  [31:0] result,     // Result of the operation
    output reg         valid       // Operation completion flag
);

    // Simulated shared memory (256 memory locations)
    reg [31:0] memory [0:255];

    // Initial block to set up some initial values in memory
    initial begin
        memory[16] = 32'h00000000;  // Initialize memory at address 16 to 0
    end

    always @(*) begin
        // Default values
        valid = 1'b0;
        result = 32'b0;

        // Print Acquire/Release flags when set
        if (aq) 
            $display("Acquire semantics applied.");
        if (rl) 
            $display("Release semantics applied.");

        // Ensure address rs1 is within valid memory range (0 to 255)
        if (rs1 > 255) begin
            $display("Error: Invalid memory address rs1 = %h", rs1);
            valid = 1'b0;
            result = 32'b0;
        end else begin
            // Perform atomic operations based on funct3
            case (funct3)
                3'b000: begin // AMOADD (Atomic Add)
                    result = memory[rs1] + rs2;
                    valid = 1'b1;
                end

                3'b001: begin // AMOSWAP (Atomic Swap)
                    result = memory[rs1];
                    memory[rs1] = rs2; // Swap data in memory
                    valid = 1'b1;
                end

                3'b010: begin // AMOAND (Atomic AND)
                    result = memory[rs1] & rs2;
                    valid = 1'b1;
                end

                3'b011: begin // AMOOR (Atomic OR)
                    result = memory[rs1] | rs2;
                    valid = 1'b1;
                end

                default: begin // Default case for invalid funct3
                    result = 32'b0; // Set result to zero on invalid funct3
                    valid = 1'b0;
                end
            endcase

            // Write back the result to memory for all operations
            if (valid)
                memory[rs1] = result;  // Memory update after operation
        end
    end
endmodule
