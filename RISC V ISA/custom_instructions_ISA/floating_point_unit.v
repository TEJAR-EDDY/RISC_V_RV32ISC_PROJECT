module floating_point_unit (
    input  wire [31:0] rs1,     // Source register 1
    input  wire [31:0] rs2,     // Source register 2
    input  wire [2:0]  funct3,  // Operation selector (FADD, FSUB, FMUL, FDIV)
    output reg  [31:0] result,  // Result of the operation
    output reg         valid    // Operation completion flag
);

    // Internal registers for IEEE 754 fields
    reg [7:0] exp1, exp2;        // Exponents
    reg [23:0] mant1, mant2;     // Mantissas (implicit leading 1)
    reg sign1, sign2;            // Sign bits
    reg [47:0] mant_result;      // Mantissa result for multiplication
    reg [23:0] mant_dividend;    // Mantissa for division

    always @(*) begin
        // Decode IEEE 754 fields
        sign1 = rs1[31];
        sign2 = rs2[31];
        exp1 = rs1[30:23];
        exp2 = rs2[30:23];
        mant1 = {1'b1, rs1[22:0]}; // Add implicit 1 for normalized numbers
        mant2 = {1'b1, rs2[22:0]}; // Add implicit 1 for normalized numbers
        valid = 1'b0;

        case (funct3)
            3'b000: begin // Floating-Point Addition (FADD)
                if (exp1 > exp2) begin
                    mant2 = mant2 >> (exp1 - exp2);
                    result = {sign1, exp1, mant1 + mant2};
                end else begin
                    mant1 = mant1 >> (exp2 - exp1);
                    result = {sign2, exp2, mant1 + mant2};
                end
                valid = 1'b1;
            end

            3'b001: begin // Floating-Point Subtraction (FSUB)
                if (exp1 > exp2) begin
                    mant2 = mant2 >> (exp1 - exp2);
                    result = {sign1, exp1, mant1 - mant2};
                end else begin
                    mant1 = mant1 >> (exp2 - exp1);
                    result = {sign2, exp2, mant1 - mant2};
                end
                valid = 1'b1;
            end

            3'b010: begin // Floating-Point Multiplication (FMUL)
                mant_result = mant1 * mant2;
                result = {sign1 ^ sign2, exp1 + exp2 - 127, mant_result[46:23]};
                valid = 1'b1;
            end

            3'b011: begin // Floating-Point Division (FDIV)
                if (mant2 == 0) begin
                    result = 32'h7FC00000; // NaN for division by zero
                end else begin
                    mant_dividend = mant1 / mant2;
                    result = {sign1 ^ sign2, exp1 - exp2 + 127, mant_dividend};
                end
                valid = 1'b1;
            end

            default: result = 32'b0; // Default case
        endcase
    end
endmodule
