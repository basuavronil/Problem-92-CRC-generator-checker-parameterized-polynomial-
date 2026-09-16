`timescale 1ns / 1ps

module tb_crc8_right_shift;

    // Inputs
    reg       clk;
    reg       rst_n;
    reg       init;
    reg       data_in;
    reg       data_valid;

    // Outputs
    wire [7:0] crc_out;
    wire       error_flag;

    // Instantiate the Unit Under Test (UUT)
    crc8_right_shift uut (
        .clk(clk),
        .rst_n(rst_n),
        .init(init),
        .data_in(data_in),
        .data_valid(data_valid),
        .crc_out(crc_out),
        .error_flag(error_flag)
    );

    // Clock Generation: 100MHz (10ns Period)
    always #5 clk = ~clk;

    // Task to shift an 8-bit byte serially (MSB first)
    task send_byte(input [7:0] byte_data);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                data_in    = byte_data[i];
                data_valid = 1'b1;
                #10; // Wait 1 clock cycle
            end
            data_valid = 1'b0;
            data_in    = 1'b0;
        end
    endtask

    initial begin
        // 1. Setup VCD Waveform Dumping
        $dumpfile("crc8_waveform.vcd");
        $dumpvars(0, tb_crc8_right_shift);

        // 2. Setup Terminal Logging
        $monitor("Time=%0t ns | rst_n=%b | init=%b | valid=%b | in=%b | crc_out=0x%h | error=%b",
                 $time, rst_n, init, data_valid, data_in, crc_out, error_flag);

        // Initialize Signals
        clk        = 0;
        rst_n      = 0;
        init       = 0;
        data_in    = 0;
        data_valid = 0;

        // Apply Reset
        #12;
        rst_n = 1;
        #8;

        // Initialize LFSR state
        init = 1; #10;
        init = 0; #10;

        // --- Test Stream: Send Byte 0xA5 (8'b10100101) ---
        $display("\n--- Sending Data Byte 0xA5 ---");
        send_byte(8'hA5);

        #20;

        // Re-initialize for next frame
        init = 1; #10;
        init = 0; #10;

        // --- Test Stream: Send Byte 0x3C (8'b00111100) ---
        $display("\n--- Sending Data Byte 0x3C ---");
        send_byte(8'h3C);

        #30;
        $display("\nSimulation finished successfully.");
        $finish;
    end

endmodule
