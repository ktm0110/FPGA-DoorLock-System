`timescale 1ns / 1ps

module key_filter(
    input clk,
    input rst,
    input [8:0] sw_in,
    output reg [8:0] sw_out
);

    reg [8:0] sw_reg;
    reg [15:0] cnt;
    reg [23:0] wait_cnt;   // 초기 안정화 타이머

    wire sw_any = ~(|sw_in); // 하나라도 눌리면 1

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sw_reg   <= 9'b111111111;
            sw_out   <= 1'b0;
            cnt      <= 0;
            wait_cnt <= 24'd0;
        end else begin
            // === 초기 안정화 (대략 50ms 기다림) ===
            if(wait_cnt < 24'd1_200_000) begin
                wait_cnt <= wait_cnt + 1'b1;
                sw_out <= 1'b0;    // 어떤 경우에도 KEY 이벤트 발생 금지
            end
            else begin
                // === 본격 필터 시작 ===
                if (sw_in != sw_reg) begin
                    cnt <= cnt + 1;

                    if (cnt == 16'hffff) begin
                        sw_reg <= sw_in;
                        sw_out <= sw_any;
                    end
                end else begin
                    cnt <= 0;
                    sw_out <= 1'b0;
                end
            end
        end
    end
endmodule
