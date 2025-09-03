`timescale 1ns / 1ps

module max_pooling #(
    parameter ADDR_WIDTH = 12,  // Address width for memory
    parameter DATA_WIDTH = 32, // Data width for data elements
    parameter DIM_WIDTH = 4    // Width for dimensions and pooling size
)(
    input clk,                          // Clock signal
    input rst,                          // Reset signal
    input valid_in,                     // Valid input signal
    input [DIM_WIDTH-1:0] pool_size,    // Pooling window size
    input [DIM_WIDTH-1:0] stride,       // Stride size
    input [ADDR_WIDTH-1:0] input_addr,  // Base input memory address
    input [ADDR_WIDTH-1:0] output_addr, // Base output memory address
    input [DIM_WIDTH-1:0] dimensions,   // Input dimension (assumes square matrix)
    output reg valid_out                // Output valid signal
);

    // Internal registers
    reg [DATA_WIDTH-1:0] input_data;
    reg [DATA_WIDTH-1:0] max_value;
    reg [DIM_WIDTH-1:0] row, col, window_row, window_col;
    reg [ADDR_WIDTH-1:0] addr_in, addr_out;

    // State variables
    reg processing_window;
    reg processing_complete;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all internal signals and outputs
            addr_in <= 0;
            addr_out <= output_addr;
            row <= 0;
            col <= 0;
            window_row <= 0;
            window_col <= 0;
            max_value <= 0;
            valid_out <= 0;
            processing_window <= 0;
            processing_complete <= 0;
        end else if (valid_in) begin
            if (!processing_window) begin
                // Start processing a new pooling window
                processing_window <= 1;
                max_value <= 0; // Reset max value for the new window
                window_row <= 0;
                window_col <= 0;
                addr_in <= input_addr + (row * dimensions + col); // Set starting address
            end

            // Simulate memory read for input data
            input_data <= 32'h00010000; // Replace this with actual memory read logic

            // Update the maximum value within the pooling window
            if (input_data > max_value)
                max_value <= input_data;

            // Move to the next element in the pooling window
            if (window_col + 1 < pool_size) begin
                window_col <= window_col + 1;
                addr_in <= addr_in + 1; // Move to the next column
            end else begin
                window_col <= 0;
                if (window_row + 1 < pool_size) begin
                    window_row <= window_row + 1;
                    addr_in <= addr_in + (dimensions - pool_size + 1); // Move to the next row
                end else begin
                    // Pooling window processing complete
                    processing_window <= 0;

                    // Simulate memory write for the max value
                    addr_out <= addr_out + 1; // Move to the next output address
                    // Add memory write logic for max_value here

                    // Move to the next window
                    if (col + stride < dimensions) begin
                        col <= col + stride;
                    end else begin
                        col <= 0;
                        if (row + stride < dimensions) begin
                            row <= row + stride;
                        end else begin
                            // All pooling windows processed
                            processing_complete <= 1;
                        end
                    end
                end
            end

            // Set valid_out when processing is complete
            valid_out <= processing_complete;
        end
    end
endmodule
