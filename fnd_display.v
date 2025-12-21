`timescale 1ns / 1ps

module fnd_display(
    input CLK,
    input RESET,
    input [15:0] digit_mask,  // 표시할 데이터
    output reg [3:0] FND_COM,
    output reg [7:0] FND_DATA
);

    reg [15:0] cnt64k;
    reg [1:0] cnt4;

    // === scan counter ===
    always @(posedge CLK or posedge RESET) begin
        if (RESET)
            cnt64k <= 0;
        else if(cnt64k == 16'hffff)
            cnt64k <= 0;
        else
            cnt64k <= cnt64k + 1;
    end

    // === 자리 이동(4자리 Multiplexing) ===
    always @(posedge CLK or posedge RESET) begin
        if (RESET)
            cnt4 <= 0;
        else if(cnt64k == 16'hffff)
            cnt4 <= cnt4 + 1;
    end

    // === Common select ===
    always @ (*) begin
        case(cnt4)
            2'b00: FND_COM = 4'b1000;
            2'b01: FND_COM = 4'b0100;
            2'b10: FND_COM = 4'b0010;
            2'b11: FND_COM = 4'b0001;
        endcase
    end

    // === 숫자 인코딩 ===
    function [7:0] encode;
        input [3:0] num;
        begin
            case(num)
                4'd0: encode = 8'b00000011; // 숫자0
                default: encode = 8'b11111111; // blank
            endcase
        end
    endfunction

    // === 표시 데이터 선택 ===
    always @ (*) begin
        case(cnt4)
            2'b00: FND_DATA = encode(digit_mask[15:12]);
            2'b01: FND_DATA = encode(digit_mask[11:8]);
            2'b10: FND_DATA = encode(digit_mask[7:4]);
            2'b11: FND_DATA = encode(digit_mask[3:0]);
        endcase
    end

endmodule
