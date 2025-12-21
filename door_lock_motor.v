`timescale 1ns / 1ps

module door_lock_motor(
    input        CLK,        
    input        RESET,
    input        TRIGGER,    // pw_ok 신호
    output reg [3:0] MOTOR_OUT,
    output reg   sequence_done 
);

    parameter SPEED_DELAY = 100000; 
    parameter ROTATE_STEPS = 512; 
    parameter WAIT_DELAY = 24000000;

    reg [2:0] state;
    parameter S_IDLE  = 3'd0;
    parameter S_LEFT  = 3'd1; 
    parameter S_WAIT  = 3'd2; 
    parameter S_RIGHT = 3'd3; 
    parameter S_STOP  = 3'd4; 

    reg [31:0] clk_cnt;   
    reg [31:0] step_cnt;  
    reg [2:0]  phase_idx; 

    // 모터 위상 출력
    always @(*) begin
        case (phase_idx)
            3'd0: MOTOR_OUT = 4'b1001;
            3'd1: MOTOR_OUT = 4'b1010;
            3'd2: MOTOR_OUT = 4'b0110;
            3'd3: MOTOR_OUT = 4'b0101;
            default: MOTOR_OUT = 4'b0000;
        endcase
    end

    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            state     <= S_IDLE;
            clk_cnt   <= 0;
            step_cnt  <= 0;
            phase_idx <= 0;
            sequence_done <= 0;
        end
        else begin
            case (state)
                S_IDLE: begin
                    sequence_done <= 0; 
                    if (TRIGGER) begin  // 신호가 오면 출발
                        state    <= S_LEFT;
                        clk_cnt  <= 0;
                        step_cnt <= 0;
                    end
                end

                S_LEFT: begin
                    clk_cnt <= clk_cnt + 1;
                    if (clk_cnt >= SPEED_DELAY) begin
                        clk_cnt <= 0;
                        phase_idx <= phase_idx + 1;
                        if (phase_idx == 3) phase_idx <= 0;
                        
                        step_cnt <= step_cnt + 1;
                        if (step_cnt >= ROTATE_STEPS) begin
                            state <= S_WAIT; 
                            clk_cnt <= 0;
                        end
                    end
                end

                S_WAIT: begin
                    clk_cnt <= clk_cnt + 1;
                    if (clk_cnt >= WAIT_DELAY) begin
                        state    <= S_RIGHT;
                        clk_cnt  <= 0;
                        step_cnt <= 0;
                    end
                end

                S_RIGHT: begin
                    clk_cnt <= clk_cnt + 1;
                    if (clk_cnt >= SPEED_DELAY) begin
                        clk_cnt <= 0;
                        if (phase_idx == 0) phase_idx <= 3;
                        else phase_idx <= phase_idx - 1;
                        
                        step_cnt <= step_cnt + 1;
                        if (step_cnt >= ROTATE_STEPS) begin
                            state <= S_STOP; 
                        end
                    end
                end

                // [핵심 수정] Handshake 로직 적용
                S_STOP: begin
                    sequence_done <= 1; // "나 끝났어!" 신호 보냄
                    
                    // FSM이 신호를 받고 pw_ok(TRIGGER)를 0으로 끌 때까지 여기서 기다립니다.
                    // pw_ok가 꺼지면 -> 그때 비로소 IDLE로 돌아갑니다.
                    if (!TRIGGER) begin 
                        state <= S_IDLE;
                        sequence_done <= 0; // 완료 신호도 끔
                    end
                    // TRIGGER가 아직 1이면? -> 계속 S_STOP에 머무르며 대기 (중복 실행 방지)
                end
            endcase
        end
    end

endmodule