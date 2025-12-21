module key_input(
    input CLK,
    input RESET,
    input [8:0] KEY,      

    output reg key_pulse,
    output reg [3:0] key_value
);

    reg [8:0] key_ff1, key_ff2;
    reg key_state;  // 1 = idle, 0 = pressed

    always @(posedge CLK or posedge RESET) begin
        if(RESET) begin
            key_ff1   <= 9'b111_111_111;
            key_ff2   <= 9'b111_111_111;
            key_state <= 1'b1;
            key_pulse <= 1'b0;
        end else begin
            key_ff1 <= KEY;
            key_ff2 <= key_ff1;

            if(key_state && (key_ff2 != 9'b111_111_111)) begin
                key_state <= 1'b0;   // pressed
                key_pulse <= 1'b1;

                casez(key_ff2)
                    9'b111111110: key_value <= 4'd1;
                    9'b111111101: key_value <= 4'd2;
                    9'b111111011: key_value <= 4'd3;
                    9'b111110111: key_value <= 4'd4;
                    9'b111101111: key_value <= 4'd5;
                    9'b111011111: key_value <= 4'd6;
                    9'b110111111: key_value <= 4'd7;
                    9'b101111111: key_value <= 4'd8;
                    9'b011111111: key_value <= 4'd9;
                    default: key_value <= 4'd0;
                endcase
            end
            else begin
                key_pulse <= 1'b0;
                if(key_ff2 == 9'b111_111_111)
                    key_state <= 1'b1; // released
            end
        end
    end
endmodule
