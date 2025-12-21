`timescale 1ns / 1ps

module textlcd(
    input        RESET,      
    input        CLK,        
    input        pw_ok,      
    input        is_frozen,   // [추가] Freeze 신호 입력
    input [3:0]  key_value,   

    output wire  LCD_RS,      
    output wire  LCD_RW,      
    output reg   LCD_EN,      
    output wire [7:0] LCD_DATA
);

    reg [31:0]  cnt;      
    reg [10:0]  delay_lcdclk;
    reg [5:0]   count_lcd;
    reg [127:0] line_1;
    reg [127:0] line_2;
    reg [8:0]   set_data;
    reg [7:0]   key_ascii; 

    // 기존 타이밍 로직들 (생략 없이 그대로 사용)
    always @ (posedge CLK or posedge RESET) begin
        if (RESET) cnt <= 25'd0;
        else if (cnt < 25'd23999999) cnt <= cnt + 25'd1;
        else cnt <= 25'd0;
    end

    always @(*) begin
        if (key_value < 10) key_ascii = 8'h30 + key_value;
        else key_ascii = 8'h41 + (key_value - 10);
    end

    always @(posedge RESET or posedge CLK) begin
        if(RESET) begin
            delay_lcdclk <= 11'd0; count_lcd <= 6'd0; LCD_EN <= 1'b0;
        end else begin
            if (delay_lcdclk < 11'd2000) delay_lcdclk <=  delay_lcdclk + 11'd1;
            else delay_lcdclk <= 11'd0;
            if (delay_lcdclk == 11'd0) begin
                if (count_lcd < 6'd40) count_lcd <= count_lcd + 6'd1;
                else count_lcd <= 6'd7;
            end
            if (delay_lcdclk == 11'd200) LCD_EN <= 1'b1;
            else if (delay_lcdclk == 11'd1800) LCD_EN <= 1'b0;
        end
    end

    // [핵심 수정] LCD 표시 내용 우선순위 설정
    always @(*) begin
        // 1순위: 리셋
        if (RESET) begin
            line_1 <= {"ENTER PASSWORD  "}; 
            line_2 <= {"                "};
        end
        // 2순위: Freeze 상태 (벽돌)
        else if (is_frozen) begin
            line_1 <= {"   !! FREEZE !! "};
            line_2 <= {"   TRY LATER    "};
        end
        // 3순위: 문 열림
        else if (pw_ok) begin
            line_1 <= {"      OPEN      "};
            line_2 <= {"                "};
        end
        // 4순위: 평소 입력 상태
        else begin
            line_1 <= {"ENTER PASSWORD  "};
            line_2 <= {"KEY VALUE : ", key_ascii, "   "}; 
        end
    end

    always @(posedge RESET or posedge CLK) begin
        if (RESET) set_data <= 9'd0;
        else begin
            case (count_lcd)
                6'd0  : set_data <= {1'b0, 8'h38}; 
                6'd1  : set_data <= {1'b0, 8'h38}; 
                6'd2  : set_data <= {1'b0, 8'h0e}; 
                6'd3  : set_data <= {1'b0, 8'h06}; 
                6'd4  : set_data <= {1'b0, 8'h02}; 
                6'd5  : set_data <= {1'b0, 8'h01}; 
                6'd6  : set_data <= {1'b0, 8'h80}; 
                6'd7  : set_data <= {1'b1, line_1[127:120]};
                6'd8  : set_data <= {1'b1, line_1[119:112]};
                6'd9  : set_data <= {1'b1, line_1[111:104]};
                6'd10 : set_data <= {1'b1, line_1[103:96]};
                6'd11 : set_data <= {1'b1, line_1[95:88]};
                6'd12 : set_data <= {1'b1, line_1[87:80]};
                6'd13 : set_data <= {1'b1, line_1[79:72]};
                6'd14 : set_data <= {1'b1, line_1[71:64]};
                6'd15 : set_data <= {1'b1, line_1[63:56]};
                6'd16 : set_data <= {1'b1, line_1[55:48]};
                6'd17 : set_data <= {1'b1, line_1[47:40]};
                6'd18 : set_data <= {1'b1, line_1[39:32]};
                6'd19 : set_data <= {1'b1, line_1[31:24]};
                6'd20 : set_data <= {1'b1, line_1[23:16]};
                6'd21 : set_data <= {1'b1, line_1[15:8]};
                6'd22 : set_data <= {1'b1, line_1[7:0]};
                6'd23 : set_data <= {1'b0, 8'hc0}; 
                6'd24 : set_data <= {1'b1, line_2[127:120]};     
                6'd25 : set_data <= {1'b1, line_2[119:112]};
                6'd26 : set_data <= {1'b1, line_2[111:104]};
                6'd27 : set_data <= {1'b1, line_2[103:96]};
                6'd28 : set_data <= {1'b1, line_2[95:88]};  
                6'd29 : set_data <= {1'b1, line_2[87:80]};
                6'd30 : set_data <= {1'b1, line_2[79:72]};
                6'd31 : set_data <= {1'b1, line_2[71:64]};
                6'd32 : set_data <= {1'b1, line_2[63:56]};     
                6'd33 : set_data <= {1'b1, line_2[55:48]};
                6'd34 : set_data <= {1'b1, line_2[47:40]};
                6'd35 : set_data <= {1'b1, line_2[39:32]};
                6'd36 : set_data <= {1'b1, line_2[31:24]};     
                6'd37 : set_data <= {1'b1, line_2[23:16]};
                6'd38 : set_data <= {1'b1, line_2[15:8]};
                6'd39 : set_data <= {1'b1, line_2[7:0]};
                default : set_data <= {1'b0, 8'h02};
            endcase
        end
    end
    assign LCD_RS = set_data[8];
    assign LCD_RW = 1'b0;
    assign LCD_DATA = set_data[7:0];
endmodule