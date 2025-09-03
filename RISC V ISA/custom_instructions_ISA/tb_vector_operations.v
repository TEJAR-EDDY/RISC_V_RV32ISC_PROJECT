module vector_operations_tb;

    // Parameters
    parameter VECTOR_LENGTH = 8;
    parameter DATA_WIDTH = 32;

    // Testbench signals
    reg [VECTOR_LENGTH*DATA_WIDTH-1:0] vector_a;
    reg [VECTOR_LENGTH*DATA_WIDTH-1:0] vector_b;
    reg [DATA_WIDTH-1:0] scalar;
    reg [1:0] mode;
    reg [2:0] funct3;
    wire [VECTOR_LENGTH*DATA_WIDTH-1:0] result;

    // Instantiate the DUT
    vector_operations #(
        .VECTOR_LENGTH(VECTOR_LENGTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .vector_a(vector_a),
        .vector_b(vector_b),
        .scalar(scalar),
        .mode(mode),
        .funct3(funct3),
        .result(result)
    );

    // Task to display the results
    task display_result;
        integer i;
        reg [DATA_WIDTH-1:0] res_element;
        begin
            $display("Mode: %b, Funct3: %b", mode, funct3);
            $display("Vector A: %h", vector_a);
            $display("Vector B: %h, Scalar: %h", vector_b, scalar);
            $display("Result: %h", result);
            for (i = 0; i < VECTOR_LENGTH; i = i + 1) begin
                res_element = result[i*DATA_WIDTH +: DATA_WIDTH];
                $display("Result[%0d]: %h", i, res_element);
            end
            $display("------------------------------------------");
        end
    endtask

    // Generate directed test cases
    task directed_test;
        begin
            // Initialize test cases
            vector_a = {8'h1, 8'h2, 8'h3, 8'h4, 8'h5, 8'h6, 8'h7, 8'h8};
            vector_b = {8'hA, 8'hB, 8'hC, 8'hD, 8'hE, 8'hF, 8'h10, 8'h11};
            scalar = 8'h5;

            // Test VV mode
            mode = 2'b00;
            funct3 = 3'b000; #10; display_result(); // Addition
            funct3 = 3'b001; #10; display_result(); // Subtraction
            funct3 = 3'b010; #10; display_result(); // Multiplication
            funct3 = 3'b011; #10; display_result(); // AND
            funct3 = 3'b100; #10; display_result(); // OR

            // Test VX mode
            mode = 2'b01;
            funct3 = 3'b000; #10; display_result(); // Addition with scalar
            funct3 = 3'b001; #10; display_result(); // Subtraction with scalar

            // Test VI mode
            mode = 2'b10;
            funct3 = 3'b011; #10; display_result(); // AND with scalar
            funct3 = 3'b100; #10; display_result(); // OR with scalar
        end
    endtask

    // Generate random test cases
    task random_test;
        integer i;
        begin
            for (i = 0; i < 10; i = i + 1) begin
                vector_a = $random;
                vector_b = $random;
                scalar = $random;
                mode = $random % 3;
                funct3 = $random % 5;

                #10 display_result();
            end
        end
    endtask

    // Testbench control
    initial begin
        $display("Starting Directed Tests...");
        directed_test();

        $display("Starting Random Tests...");
        random_test();

        $display("All tests completed.");
        $stop;
    end

endmodule
