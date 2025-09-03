module double_precision_fpu (
    input  wire [63:0] rs1,     // Source register 1
    input  wire [63:0] rs2,     // Source register 2
    input  wire [2:0]  funct3,  // Operation selector (FADD.D, FSUB.D, etc.)
    output reg  [63:0] result,  // Result of the operation
    output reg         valid    // Operation completion flag
);

    // Internal registers for IEEE 754 fields
    reg [10:0] exp1, exp2;        // Exponents
    reg [52:0] mant1, mant2;      // Mantissas (implicit leading 1)
    reg sign1, sign2;             // Sign bits
    reg [105:0] mant_result;      // Mantissa result for multiplication
    reg [52:0] mant_dividend;     // Mantissa for division

    always @(*) begin
        // Decode IEEE 754 fields
        sign1 = rs1[63];
        sign2 = rs2[63];
        exp1 = rs1[62:52];
        exp2 = rs2[62:52];
        mant1 = {1'b1, rs1[51:0]}; // Add implicit 1 for normalized numbers
        mant2 = {1'b1, rs2[51:0]}; // Add implicit 1 for normalized numbers
        valid = 1'b0;

        case (funct3)
            3'b000: begin // Double-Precision Floating-Point Addition (FADD.D)
                if (exp1 > exp2) begin
                    mant2 = mant2 >> (exp1 - exp2);
                    result = {sign1, exp1, mant1 + mant2};
                end else begin
                    mant1 = mant1 >> (exp2 - exp1);
                    result = {sign2, exp2, mant1 + mant2};
                end
                valid = 1'b1;
            end

            3'b001: begin // Double-Precision Floating-Point Subtraction (FSUB.D)
                if (exp1 > exp2) begin
                    mant2 = mant2 >> (exp1 - exp2);
                    result = {sign1, exp1, mant1 - mant2};
                end else begin
                    mant1 = mant1 >> (exp2 - exp1);
                    result = {sign2, exp2, mant1 - mant2};
                end
                valid = 1'b1;
            end

            3'b010: begin // Double-Precision Floating-Point Multiplication (FMUL.D)
                mant_result = mant1 * mant2;
                result = {sign1 ^ sign2, exp1 + exp2 - 1023, mant_result[104:53]};
                valid = 1'b1;
            end

            3'b011: begin // Double-Precision Floating-Point Division (FDIV.D)
                if (mant2 == 0) begin
                    result = 64'h7FF8000000000000; // NaN for division by zero
                end else begin
                    mant_dividend = mant1 / mant2;
                    result = {sign1 ^ sign2, exp1 - exp2 + 1023, mant_dividend};
                end
                valid = 1'b1;
            end

            default: result = 64'b0; // Default case
        endcase
    end
endmodule
