`timescale 1ns / 1ps

module buzzer_ctrl(
    input CLK,              
    input RESET,
    input trigger_open,     
    input trigger_freeze,   
    output reg BUZZER       
);

    parameter [15:0] NOTE_DO      = 16'd11659; 
    parameter [15:0] NOTE_MI      = 16'd9253;  
    parameter [15:0] NOTE_SOL     = 16'd7782;  
    parameter [15:0] NOTE_HIGH_DO = 16'd5827;  
    parameter [15:0] NOTE_ALARM   = 16'd5192;  
    parameter [15:0] SILENCE      = 16'd0;     

    reg [2:0] state;
    parameter S_IDLE        = 3'd0;
    parameter S_PLAY_OPEN   = 3'd1;
    parameter S_PLAY_FREEZE = 3'd2;
    parameter S_DONE        = 3'd3; 

    reg [15:0] tone_cnt;      
    reg [15:0] tone_max;      
    reg [27:0] duration_cnt;  
    reg [2:0]  note_index;    

    parameter TIME_0_1S = 28'd2_400_000;
    parameter TIME_0_2S = 28'd4_800_000;

    // ====================================================
    // 1. 주파수 생성 로직 (수정됨)
    // ====================================================
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            tone_cnt <= 0;
            BUZZER   <= 1; // [수정] 리셋 시 1 (조용함)
        end
        else begin
            if (tone_max == 0) begin
                BUZZER   <= 1; // [수정] 소리 끄기 = 1 (High)
                tone_cnt <= 0;
            end
            else begin
                if (tone_cnt >= tone_max) begin
                    tone_cnt <= 0;
                    BUZZER <= ~BUZZER; // 주파수에 맞춰 토글
                end
                else begin
                    tone_cnt <= tone_cnt + 1;
                end
            end
        end
    end

    // ====================================================
    // 2. 멜로디 시퀀서 (기존 동일)
    // ====================================================
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            state        <= S_IDLE;
            duration_cnt <= 0;
            note_index   <= 0;
            tone_max     <= SILENCE;
        end
        else begin
            case (state)
                S_IDLE: begin
                    tone_max <= SILENCE;
                    duration_cnt <= 0;
                    note_index <= 0;

                    if (trigger_freeze) begin
                        state <= S_PLAY_FREEZE;
                    end
                    else if (trigger_open) begin
                        state <= S_PLAY_OPEN;
                    end
                end

                S_PLAY_OPEN: begin
                    duration_cnt <= duration_cnt + 1;
                    if (duration_cnt >= TIME_0_1S) begin
                        duration_cnt <= 0;
                        note_index <= note_index + 1;
                    end

                    case (note_index)
                        0: tone_max <= NOTE_DO;
                        1: tone_max <= NOTE_MI;
                        2: tone_max <= NOTE_SOL;
                        3: tone_max <= NOTE_HIGH_DO;
                        4: begin 
                            tone_max <= SILENCE;
                            state <= S_DONE; 
                           end
                    endcase
                end

                S_PLAY_FREEZE: begin
                    if (!trigger_freeze) begin
                        state <= S_IDLE;
                    end
                    else begin
                        duration_cnt <= duration_cnt + 1;
                        if (duration_cnt < TIME_0_2S) 
                            tone_max <= NOTE_ALARM; 
                        else if (duration_cnt < (TIME_0_2S * 2)) 
                            tone_max <= SILENCE;    
                        else 
                            duration_cnt <= 0;      
                    end
                end

                S_DONE: begin
                    tone_max <= SILENCE;
                    if (!trigger_open) begin
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end

endmodule