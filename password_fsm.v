`timescale 1ns/1ps

module password_fsm(
    input CLK,              
    input RESET,
    input key_pulse,
    input [3:0] key_value,
    
    input lock_signal,      

    output reg [15:0] digit_mask,
    output reg pw_ok,
    output reg is_frozen,
    output reg [7:0] led_out 
);

    reg [3:0] pw_mem [3:0];
    reg [3:0] input_pw [3:0];
    reg [2:0] press_cnt;
    reg is_open;
    
    // Freeze 관련
    reg [1:0]  fail_cnt;      
    reg [27:0] freeze_timer;  
    
    reg [23:0] safe_timer; 

    // 8초 타이머
    parameter FREEZE_TIME = 28'd192_000_000; 
    // 1초 단위
    parameter ONE_SEC = 28'd24_000_000;

    always @(posedge CLK or posedge RESET) begin
        if(RESET) begin
            press_cnt    <= 0;
            pw_ok        <= 0;
            is_open      <= 0;
            digit_mask   <= 16'hFFFF;
            safe_timer   <= 0;
            
            fail_cnt     <= 0;
            is_frozen    <= 0;
            freeze_timer <= 0;
            
            // [수정] Active Low이므로 FF(11111111)가 꺼진 상태입니다.
            led_out      <= 8'hFF; 

            pw_mem[0] <= 4'd1; pw_mem[1] <= 4'd2;
            pw_mem[2] <= 4'd3; pw_mem[3] <= 4'd4;
        end
        else begin
            // 1. 초기 안전 타이머
            if(safe_timer < 24'd5_000_000) begin
                safe_timer <= safe_timer + 1;
            end
            
            // 2. [Freeze 상태]
            else if(is_frozen) begin
                freeze_timer <= freeze_timer + 1;
                digit_mask   <= 16'hFFFF; 
                pw_ok        <= 0;
                
                // [핵심 수정] Active Low 방식 (0: ON, 1: OFF)
                // 8초 동안 LED가 꽉 찼다가(ON) -> 하나씩 꺼짐(OFF)
                if      (freeze_timer < ONE_SEC * 1) led_out <= 8'b00000000; // 0~1초: 모두 ON (0)
                else if (freeze_timer < ONE_SEC * 2) led_out <= 8'b10000000; // 1~2초: 1개 OFF (1)
                else if (freeze_timer < ONE_SEC * 3) led_out <= 8'b11000000; // 2~3초: 2개 OFF
                else if (freeze_timer < ONE_SEC * 4) led_out <= 8'b11100000;
                else if (freeze_timer < ONE_SEC * 5) led_out <= 8'b11110000;
                else if (freeze_timer < ONE_SEC * 6) led_out <= 8'b11111000;
                else if (freeze_timer < ONE_SEC * 7) led_out <= 8'b11111100;
                else                                 led_out <= 8'b11111110; // 7~8초: 1개만 ON
                
                if(freeze_timer >= FREEZE_TIME) begin
                    is_frozen    <= 0;
                    fail_cnt     <= 0; 
                    freeze_timer <= 0;
                    press_cnt    <= 0; 
                    led_out      <= 8'hFF; // 해제되면 모두 끔 (11111111)
                end
            end
            
            // 3. [Open 상태]
            else if(is_open) begin
                 led_out <= 8'hFF; // 평소엔 끔
                 if(lock_signal) begin
                    is_open    <= 0;
                    pw_ok      <= 0;
                    digit_mask <= 16'hFFFF; 
                    press_cnt  <= 0;
                    fail_cnt   <= 0; 
                 end
                 else begin
                    digit_mask <= 16'h0000;
                    pw_ok      <= 1;
                 end
            end
            
            // 4. [입력 상태]
            else if(key_pulse) begin
                led_out <= 8'hFF; // 입력 중엔 끔
                if(press_cnt >= 4) begin
                    press_cnt  <= 1;
                    digit_mask <= 16'h0FFF;
                    input_pw[0]<= key_value;
                    pw_ok      <= 0;
                end
                else begin
                    input_pw[press_cnt] <= key_value;
                    press_cnt <= press_cnt + 1;
                    
                    case(press_cnt)
                        0: digit_mask <= 16'h0FFF;
                        1: digit_mask <= 16'h00FF;
                        2: digit_mask <= 16'h000F;
                        3: digit_mask <= 16'h0000;
                    endcase

                    if(press_cnt == 3) begin
                        if( input_pw[0] == pw_mem[0] &&
                            input_pw[1] == pw_mem[1] &&
                            input_pw[2] == pw_mem[2] &&
                            key_value   == pw_mem[3] ) begin
                            
                            pw_ok    <= 1;
                            is_open  <= 1;
                            fail_cnt <= 0; 
                        end
                        else begin
                            pw_ok <= 0;
                            if(fail_cnt >= 2) begin
                                is_frozen    <= 1; 
                                freeze_timer <= 0;
                                press_cnt    <= 0; 
                                digit_mask   <= 16'hFFFF;
                                // Freeze 시작 시 모두 켬 (00000000)
                                led_out      <= 8'h00; 
                            end
                            else begin
                                fail_cnt <= fail_cnt + 1; 
                            end
                        end
                    end
                end
            end
        end
    end
endmodule