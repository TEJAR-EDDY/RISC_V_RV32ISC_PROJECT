`timescale 1ns / 1ps

module dma_load_store #(
    parameter ADDR_WIDTH = 12,  // Address width for memory
    parameter DATA_WIDTH = 32, // Data width for data elements
    parameter SIZE_WIDTH = 8,  // Width for size of transfer
    parameter MODE_WIDTH = 4   // Width for operation mode
)(
    input clk,                           // Clock signal
    input rst,                           // Reset signal
    input valid_in,                      // Input valid signal
    input [ADDR_WIDTH-1:0] src_dst_addr, // Base address for source/destination
    input [SIZE_WIDTH-1:0] size,         // Number of transfers
    input [MODE_WIDTH-1:0] mode,         // Operation mode: 4'b0001 (Load), 4'b0010 (Store)
    output reg [DATA_WIDTH-1:0] data_out, // Data output for Load
    output reg valid_out                 // Output valid signal
);

    // Internal registers
    reg [ADDR_WIDTH-1:0] current_addr; // Current address being accessed
    reg [SIZE_WIDTH-1:0] count;        // Counter for the number of transfers

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all internal signals and outputs
            current_addr <= 0;
            count <= 0;
            data_out <= 0;
            valid_out <= 0;
        end else if (valid_in) begin
            // Initialize transfer if count is 0
            if (count == 0) begin
                current_addr <= src_dst_addr; // Set starting address
                valid_out <= 0; // Clear valid_out initially
            end

            // Perform the Load or Store operation
            if (mode == 4'b0001) begin // Load operation
                // Simulate memory read
                data_out <= 32'h00010000; // Replace with actual memory read logic
                current_addr <= current_addr + 1; // Increment address
            end else if (mode == 4'b0010) begin // Store operation
                // Simulate memory write
                // Add memory write logic here
                current_addr <= current_addr + 1; // Increment address
            end else begin
                // Invalid mode, handle as needed (e.g., ignore or set an error flag)
                valid_out <= 0;
            end

            // Update the transfer count
            count <= count + 1;

            // Check if the entire transfer is complete
            if (count == size - 1) begin
                valid_out <= 1; // Signal that the operation is complete
                count <= 0;     // Reset the count for the next operation
            end
        end
    end

endmodule
