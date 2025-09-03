module vector_operations #(
    parameter VECTOR_LENGTH = 8, // Length of the vector
    parameter DATA_WIDTH = 32    // Bit-width of each element
)(
    input  wire [VECTOR_LENGTH*DATA_WIDTH-1:0] vector_a, // Vector A
    input  wire [VECTOR_LENGTH*DATA_WIDTH-1:0] vector_b, // Vector B or scalar
    input  wire [DATA_WIDTH-1:0] scalar,                // Scalar value
    input  wire [1:0] mode,                             // 00: VV, 01: VX, 10: VI
    input  wire [2:0] funct3,                           // Operation selector
    output reg  [VECTOR_LENGTH*DATA_WIDTH-1:0] result   // Result vector
);

    integer i;
    reg [DATA_WIDTH-1:0] element_a, element_b;

    always @(*) begin
        result = 0;
        for (i = 0; i < VECTOR_LENGTH; i = i + 1) begin
            // Extract elements
            element_a = vector_a[i*DATA_WIDTH +: DATA_WIDTH];
            element_b = (mode == 2'b00) ? vector_b[i*DATA_WIDTH +: DATA_WIDTH] : 
                         (mode == 2'b01) ? scalar : scalar;

            case (funct3)
                3'b000: result[i*DATA_WIDTH +: DATA_WIDTH] = element_a + element_b; // Addition
                3'b001: result[i*DATA_WIDTH +: DATA_WIDTH] = element_a - element_b; // Subtraction
                3'b010: result[i*DATA_WIDTH +: DATA_WIDTH] = element_a * element_b; // Multiplication
                3'b011: result[i*DATA_WIDTH +: DATA_WIDTH] = element_a & element_b; // Logical AND
                3'b100: result[i*DATA_WIDTH +: DATA_WIDTH] = element_a | element_b; // Logical OR
                default: result[i*DATA_WIDTH +: DATA_WIDTH] = 0; // Default case
            endcase
        end
    end
endmodule
