module crc8_right_shift (
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

    // Feedback generated from LSB for a right-shifting LFSR
    assign feedback = data_in ^ lfsr_reg[0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg <= 8'hFF;
        end else if (init) begin
            lfsr_reg <= 8'hFF;
        end else if (data_valid) begin
            // Right shift operation: bits move towards LSB [0]
            lfsr_reg[7] <= feedback;
            lfsr_reg[6] <= lfsr_reg[7];
            lfsr_reg[5] <= lfsr_reg[6];
            lfsr_reg[4] <= lfsr_reg[5];
            lfsr_reg[3] <= lfsr_reg[4];
            lfsr_reg[2] <= lfsr_reg[3];
            lfsr_reg[1] <= lfsr_reg[2] ^ feedback;
            lfsr_reg[0] <= lfsr_reg[1] ^ feedback;
        end
    end

    assign crc_out    = lfsr_reg;
    assign error_flag = (lfsr_reg != 8'h00);

endmodule
