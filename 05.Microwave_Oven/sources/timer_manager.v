`timescale 1ns / 1ps

// 수정된 타이머 관리 모듈 (간단한 방식)
module timer_manager(
    input clk,              // 100MHz 클럭
    input clk_1hz,          // 1Hz 클럭 (1초마다)
    input reset,            // 리셋 신호
    input add_10sec,        // 10초 추가
    input add_1min,         // 1분 추가
    input set_30sec,        // 30초 설정 (퀵스타트)
    input start_timer,      // 타이머 시작
    input pause_timer,      // 타이머 일시정지
    input resume_timer,     // 타이머 재시작
    input clear_timer,      // 타이머 초기화
    output reg [11:0] set_time_sec,     // 설정된 시간 (초 단위, 0~3600)
    output reg [11:0] remaining_sec,    // 남은 시간 (초 단위)
    output reg timer_running,           // 타이머 실행 상태
    output reg timer_paused,            // 타이머 일시정지 상태
    output reg timer_completed          // 타이머 완료 상태
);

    parameter MAX_TIME = 3600;  // 최대 60분 (3600초)
    
    reg timer_active = 0;
    
    // 1Hz 도메인에서 100MHz로 1초 펄스 전달
    reg clk_1hz_prev = 0;
    wire second_pulse = clk_1hz & ~clk_1hz_prev;
    
    // 1Hz 상승 에지 검출 (100MHz 도메인에서)
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            clk_1hz_prev <= 0;
        end else begin
            clk_1hz_prev <= clk_1hz;
        end
    end
    
    // 시간 설정 로직 (100MHz 도메인)
    always @(posedge clk, posedge reset) begin
        if (reset || clear_timer) begin
            set_time_sec <= 0;
        end else begin
            // 10초 추가 (최대 시간 체크)
            if (add_10sec && (set_time_sec + 10 <= MAX_TIME)) begin
                set_time_sec <= set_time_sec + 10;
            end
            // 1분 추가 (최대 시간 체크)
            else if (add_1min && (set_time_sec + 60 <= MAX_TIME)) begin
                set_time_sec <= set_time_sec + 60;
            end
            // 30초 퀵스타트
            else if (set_30sec) begin
                set_time_sec <= 30;
            end
        end
    end
    
    // 모든 타이머 로직 (100MHz 도메인)
    always @(posedge clk, posedge reset) begin
        if (reset || clear_timer) begin
            remaining_sec <= 0;
            timer_running <= 0;
            timer_paused <= 0;
            timer_completed <= 0;
            timer_active <= 0;
        end else begin
            // 타이머 시작
            if (start_timer && set_time_sec > 0 && !timer_active) begin
                remaining_sec <= set_time_sec;    // 즉시 초기화
                timer_running <= 1;
                timer_paused <= 0;
                timer_completed <= 0;
                timer_active <= 1;
            end
            // 타이머 일시정지
            else if (pause_timer && timer_running) begin
                timer_running <= 0;
                timer_paused <= 1;
            end
            // 타이머 재시작
            else if (resume_timer && timer_paused) begin
                timer_running <= 1;
                timer_paused <= 0;
            end
            // 1초 펄스가 올 때만 카운트다운
            else if (second_pulse && timer_running) begin
                if (remaining_sec > 0) begin
                    remaining_sec <= remaining_sec - 1;
                end else begin
                    // 타이머 완료
                    timer_running <= 0;
                    timer_paused <= 0;
                    timer_completed <= 1;
                    timer_active <= 0;
                end
            end
            // 일시정지 중 시간 추가 (즉시 반영)
            else if (timer_paused) begin
                if (add_10sec && (remaining_sec + 10 <= MAX_TIME)) begin
                    remaining_sec <= remaining_sec + 10;
                end else if (add_1min && (remaining_sec + 60 <= MAX_TIME)) begin
                    remaining_sec <= remaining_sec + 60;
                end
            end
        end
    end

endmodule