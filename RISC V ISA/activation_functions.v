`timescale 1ns / 1ps

module activation_functions #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32,
    parameter DIM_WIDTH = 4
)(
    input clk,
    input rst,
    input valid_in,
    input [ADDR_WIDTH-1:0] input_addr,
    input [ADDR_WIDTH-1:0] output_addr,
    input [DIM_WIDTH-1:0] dimensions,
    input [6:0] opcode, // 7-bit opcode: 0x4A for Sigmoid, 0x4B for Tanh
    output reg [DATA_WIDTH-1:0] result_out,
    output reg valid_out
);

    // Internal registers and wires
    reg [DATA_WIDTH-1:0] input_data;
    reg [DATA_WIDTH-1:0] output_data;
    reg [ADDR_WIDTH-1:0] addr_in, addr_out;
    reg [DIM_WIDTH-1:0] index;

    // Sigmoid approximation
    function [DATA_WIDTH-1:0] sigmoid;
        input [DATA_WIDTH-1:0] x;
        begin
            // Simple fixed-point approximation for sigmoid
            if (x > 32'h00010000) // Threshold example
                sigmoid = 32'h0001FFFF; // Approximation of 1
            else if (x < -32'h00010000) // Threshold example
                sigmoid = 32'h00000001; // Approximation of 0
            else
                sigmoid = x / (1 + x); // Simple approximation
        end
    endfunction

    // Tanh approximation
    function [DATA_WIDTH-1:0] tanh;
        input [DATA_WIDTH-1:0] x;
        begin
            // Simple fixed-point approximation for tanh
            if (x > 32'h00010000) // Threshold example
                tanh = 32'h0001FFFF; // Approximation of 1
            else if (x < -32'h00010000) // Threshold example
                tanh = -32'h0001FFFF; // Approximation of -1
            else
                tanh = x - ((x * x * x) >> 2); // Simplified approximation
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_in <= 0;
            addr_out <= 0;
            index <= 0;
            valid_out <= 0;
            result_out <= 0;
        end else if (valid_in) begin
            // Simulate memory read for input data
            input_data <= 32'h00010000; // Replace with actual memory read logic

            // Perform activation function based on opcode
            case (opcode)
                7'h4A: output_data <= sigmoid(input_data); // Sigmoid
                7'h4B: output_data <= tanh(input_data);    // Tanh
                default: output_data <= 0;
            endcase

            // Simulate memory write for output data
            addr_out <= addr_out + 1;
            index <= index + 1;

            // Output result
            result_out <= output_data;

            // Check if all data processed
            if (index == dimensions - 1) begin
                valid_out <= 1;
            end else begin
                valid_out <= 0;
            end
        end
    end
endmodule
