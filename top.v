`timescale 1ns / 1ps

module top(
    input clock_12MHz,
    input RESET,
    input [8:0] KEY,      
    input Mode_Switch,

    output [7:0] LED,
    output [3:0] MOTOR_OUT, 
    output [3:0] FND_COM,
    output [7:0] FND_DATA,

    // [추가] 부저 출력
    output BUZZER,

    output LCD_RS,
    output LCD_RW,
    output LCD_EN,
    output [7:0] LCD_DATA
);

    wire clock_24MHz;
    PLL24X2 pll(
        .RESET(RESET),
        .CLK_IN1(clock_12MHz),
        .CLK_OUT1(clock_24MHz)
    );

    // 1. 키 입력 처리
    reg [17:0] debounce_cnt; 
    reg [8:0] key_filtered;    
    always @(posedge clock_24MHz or posedge RESET) begin
        if(RESET) begin
            debounce_cnt <= 0;
            key_filtered <= 9'd0;
        end
        else begin
            debounce_cnt <= debounce_cnt + 1;
            if (debounce_cnt == 18'd240000) begin
                debounce_cnt <= 0;
                key_filtered <= KEY; 
            end
        end
    end

    reg [8:0] key_prev;
    always @(posedge clock_24MHz or posedge RESET) begin
        if(RESET) key_prev <= 9'd0;
        else      key_prev <= key_filtered; 
    end
    wire [8:0] key_edge_bus = (key_filtered & ~key_prev);
    wire key_pulse = |key_edge_bus; 

    // 2. 값 변환 및 기억
    reg [3:0] key_value_fsm;
    always @(*) begin
        key_value_fsm = 4'd0;
        if      (key_filtered[0]) key_value_fsm = 4'd1;
        else if (key_filtered[1]) key_value_fsm = 4'd2;
        else if (key_filtered[2]) key_value_fsm = 4'd3;
        else if (key_filtered[3]) key_value_fsm = 4'd4;
        else if (key_filtered[4]) key_value_fsm = 4'd5;
        else if (key_filtered[5]) key_value_fsm = 4'd6;
        else if (key_filtered[6]) key_value_fsm = 4'd7;
        else if (key_filtered[7]) key_value_fsm = 4'd8;
        else if (key_filtered[8]) key_value_fsm = 4'd9;
    end

    reg [3:0] key_value_lcd;
    always @(posedge clock_24MHz or posedge RESET) begin
        if(RESET) key_value_lcd <= 4'd0;
        else if(key_pulse) key_value_lcd <= key_value_fsm; 
    end

    // 3. 모듈 연결
    wire [15:0] digit_mask;
    wire pw_ok;
    wire motor_finish_flag; 
    wire is_frozen_flag;
    
    password_fsm PWFSM(
        .CLK(clock_24MHz),
        .RESET(RESET),
        .key_pulse(key_pulse), 
        .key_value(key_value_fsm), 
        .lock_signal(motor_finish_flag), 
        .digit_mask(digit_mask),
        .pw_ok(pw_ok),
        .is_frozen(is_frozen_flag),
        .led_out(LED)
    );

    fnd_display FND(
        .CLK(clock_24MHz),
        .RESET(RESET),
        .digit_mask(digit_mask),
        .FND_COM(FND_COM),
        .FND_DATA(FND_DATA)
    );

    textlcd LCD(
        .RESET(RESET),
        .CLK(clock_24MHz),
        .pw_ok(pw_ok),
        .is_frozen(is_frozen_flag),
        .key_value(key_value_lcd),
        .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW),
        .LCD_EN(LCD_EN),
        .LCD_DATA(LCD_DATA)
    );

    door_lock_motor MOTOR(
        .CLK(clock_24MHz),
        .RESET(RESET),
        .TRIGGER(pw_ok),
        .MOTOR_OUT(MOTOR_OUT),
        .sequence_done(motor_finish_flag) 
    );

    // [추가] 부저 컨트롤러 연결
    buzzer_ctrl BUZZER_UNIT(
        .CLK(clock_24MHz),
        .RESET(RESET),
        .trigger_open(pw_ok),        // 문 열림 신호
        .trigger_freeze(is_frozen_flag), // Freeze 신호
        .BUZZER(BUZZER)
    );

endmodule