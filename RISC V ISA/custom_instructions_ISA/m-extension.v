module alu_m (
    input  wire [31:0] rs1,     // Source register 1
    input  wire [31:0] rs2,     // Source register 2
    input  wire [2:0]  funct3,  // ALU operation selector
    input  wire [6:0]  funct7,  // Extended operation selector
    output reg  [31:0] result,  // ALU result
    output reg         div_by_zero // Division by zero flag
);

    always @(*) begin
        // Default values
        result = 32'b0;
        div_by_zero = 1'b0;

        case (funct7)
            7'b0000001: begin // M-extension operations
                case (funct3)
                    3'b000: result = rs1 * rs2;                          // MUL
                    3'b001: result = (rs1 * rs2) >> 32;                  // MULH
                    3'b010: result = ($signed(rs1) * $unsigned(rs2)) >> 32; // MULHSU
                    3'b011: result = ($unsigned(rs1) * $unsigned(rs2)) >> 32; // MULHU
                    3'b100: begin                                         // DIV
                        if (rs2 == 0) div_by_zero = 1'b1;
                        else result = $signed(rs1) / $signed(rs2);
                    end
                    3'b101: begin                                         // DIVU
                        if (rs2 == 0) div_by_zero = 1'b1;
                        else result = rs1 / rs2;
                    end
                    3'b110: begin                                         // REM
                        if (rs2 == 0) div_by_zero = 1'b1;
                        else result = $signed(rs1) % $signed(rs2);
                    end
                    3'b111: begin                                         // REMU
                        if (rs2 == 0) div_by_zero = 1'b1;
                        else result = rs1 % rs2;
                    end
                endcase
            end
            default: result = 32'b0; // Default case for non-M-extension operations
        endcase
    end
endmodule
