module crc8_transmitter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       init,
    input  wire       data_in,
    input  wire       data_valid,
    output wire [7:0] crc_out,
    output wire       error_flag
);

    reg [7:0] lfsr_reg;
    wire      feedback;

    // LSB-first feedback generation (Standard CRC-8 polynomial 0xE0)
    assign feedback = data_in ^ lfsr_reg[0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg <= 8'hFF;
        end else if (init) begin
            lfsr_reg <= 8'hFF;
        end else if (data_valid) begin
            lfsr_reg[7] <= feedback;
            lfsr_reg[6] <= lfsr_reg[7] ^ feedback;
            lfsr_reg[5] <= lfsr_reg[6] ^ feedback;
            lfsr_reg[4] <= lfsr_reg[5];
            lfsr_reg[3] <= lfsr_reg[4];
            lfsr_reg[2] <= lfsr_reg[3];
            lfsr_reg[1] <= lfsr_reg[2];
            lfsr_reg[0] <= lfsr_reg[1];
        end
    end

    assign crc_out    = lfsr_reg;
    // On TX side, crc_out holds the checksum to transmit.
    // error_flag is low (0) during normal operation.
    assign error_flag = 1'b0;

endmodule
