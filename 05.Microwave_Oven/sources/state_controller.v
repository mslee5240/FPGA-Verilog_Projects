`timescale 1ns / 1ps

// 개선된 전자레인지 상태 제어 모듈 (door_toggle 신호 수정)
module state_controller(
    input clk,                  // 100MHz 클럭
    input clk_1hz,              // 1Hz 클럭
    input reset,                // 리셋 신호
    
    // 버튼 입력들
    input btnC_pulse,           // 시작/일시정지 버튼
    input btnU_pulse,           // 10초 추가 버튼
    input btnR_pulse,           // 1분 추가 버튼  
    input btnL_stable,          // 문 열기/닫기 버튼 (stable 신호 직접 사용)
    input btnD_pulse,           // 취소/리셋 버튼
    
    // 하드웨어 상태
    input door_open,            // 문 열림 상태
    input timer_completed,      // 타이머 완료 신호
    input [11:0] set_time_sec,  // 설정된 시간
    input [11:0] remaining_sec, // 남은 시간
    
    // 제어 출력들
    output reg add_10sec,       // 10초 추가 신호
    output reg add_1min,        // 1분 추가 신호
    output reg set_30sec,       // 30초 설정 신호
    output reg start_timer,     // 타이머 시작 신호
    output reg pause_timer,     // 타이머 일시정지 신호
    output reg resume_timer,    // 타이머 재시작 신호
    output reg clear_timer,     // 타이머 초기화 신호
    output reg door_toggle,     // 문 토글 신호
    output reg button_beep,     // 버튼 비프음 신호
    output reg completion_alarm,// 완료 알림음 신호
    output reg motor_enable,    // 모터 활성화 신호
    output reg display_blink,   // 디스플레이 점멸 신호
    output reg idle_animation,  // IDLE 상태 애니메이션 신호 (새로 추가)
    
    // 상태 정보
    output reg [2:0] current_state,  // 현재 상태
    output reg [13:0] display_data   // FND 표시 데이터
);

    // 상태 정의
    parameter IDLE = 3'b000;        // 기본 상태
    parameter SETTING = 3'b001;     // 시간 설정 중
    parameter RUNNING = 3'b010;     // 작동 중
    parameter PAUSED = 3'b011;      // 일시정지
    parameter COMPLETE = 3'b100;    // 완료 알림
    
    reg [2:0] state = IDLE;
    reg [2:0] next_state;
    
    // 개선된 BtnC 더블클릭 감지
    reg [25:0] btnC_timer = 0;
    reg btnC_first_click = 0;
    reg btnC_double_click = 0;
    parameter DOUBLE_CLICK_WINDOW = 50_000_000; // 0.5초
    
    // btnL_stable 에지 검출
    reg btnL_prev = 0;
    wire btnL_edge = btnL_stable & ~btnL_prev;
    
    // 완료 점멸 제어 변수들
    reg [3:0] blink_count = 0;      // 점멸 횟수 카운터 (0~10)
    reg [25:0] blink_timer = 0;     // 점멸 타이머
    reg blink_state = 0;            // 점멸 상태
    reg completion_alarm_active = 0; // 완료 알림 활성화 상태
    parameter BLINK_PERIOD = 50_000_000; // 0.5초
    parameter MAX_BLINKS = 10;      // 5회 점멸 = 10개의 토글
    
    // 상태 업데이트 및 btnL 에지 검출
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            current_state <= IDLE;
            btnL_prev <= 0;
        end else begin
            state <= next_state;
            current_state <= next_state;
            btnL_prev <= btnL_stable;  // btnL_stable의 이전 값 저장
        end
    end
    
    // 개선된 BtnC 더블클릭 감지 로직
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            btnC_timer <= 0;
            btnC_first_click <= 0;
            btnC_double_click <= 0;
        end else begin
            btnC_double_click <= 0;  // 기본값
            
            if (btnC_pulse && state == IDLE && set_time_sec == 0) begin
                if (!btnC_first_click) begin
                    // 첫 번째 클릭
                    btnC_first_click <= 1;
                    btnC_timer <= 0;
                end else if (btnC_timer < DOUBLE_CLICK_WINDOW) begin
                    // 두 번째 클릭 (더블클릭 성공)
                    btnC_double_click <= 1;
                    btnC_first_click <= 0;
                    btnC_timer <= 0;
                end
            end else if (btnC_first_click) begin
                if (btnC_timer < DOUBLE_CLICK_WINDOW) begin
                    btnC_timer <= btnC_timer + 1;
                end else begin
                    // 타임아웃 - 싱글클릭으로 처리
                    btnC_first_click <= 0;
                    btnC_timer <= 0;
                end
            end
        end
    end
    
    // 완료 점멸 제어
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            blink_count <= 0;
            blink_timer <= 0;
            blink_state <= 0;
            completion_alarm_active <= 0;
        end else if (state == COMPLETE) begin
            if (blink_count < MAX_BLINKS) begin
                if (blink_timer < BLINK_PERIOD - 1) begin
                    blink_timer <= blink_timer + 1;
                end else begin
                    blink_timer <= 0;
                    blink_state <= ~blink_state;
                    blink_count <= blink_count + 1;
                    
                    // 첫 번째 토글에서 알림음 시작
                    if (blink_count == 0) begin
                        completion_alarm_active <= 1;
                    end
                end
            end else begin
                completion_alarm_active <= 0;
            end
        end else begin
            blink_count <= 0;
            blink_timer <= 0;
            blink_state <= 0;
            completion_alarm_active <= 0;
        end
    end
    
    // 상태 전환 로직
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (btnD_pulse) begin
                    next_state = IDLE;
                end else if (btnU_pulse || btnR_pulse) begin
                    next_state = SETTING;
                end else if (btnC_pulse && set_time_sec == 0) begin
                    // 더블클릭이면 바로 RUNNING으로, 아니면 SETTING으로
                    next_state = btnC_double_click ? RUNNING : SETTING;
                end else if (btnC_pulse && set_time_sec > 0 && !door_open) begin
                    next_state = RUNNING;
                end
            end
            
            SETTING: begin
                if (btnD_pulse) begin
                    next_state = IDLE;
                end else if (btnC_pulse && set_time_sec > 0 && !door_open) begin
                    next_state = RUNNING;
                end
            end
            
            RUNNING: begin
                if (btnD_pulse) begin
                    next_state = IDLE;
                end else if (btnC_pulse || door_open) begin
                    next_state = PAUSED;
                end else if (timer_completed) begin
                    next_state = COMPLETE;
                end
            end
            
            PAUSED: begin
                if (btnD_pulse) begin
                    next_state = IDLE;
                end else if (btnC_pulse && !door_open) begin
                    next_state = RUNNING;
                end
            end
            
            COMPLETE: begin
                if (btnD_pulse || (blink_count >= MAX_BLINKS)) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 출력 신호 생성 (애니메이션 추가된 버전)
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            add_10sec <= 0;
            add_1min <= 0;
            set_30sec <= 0;
            start_timer <= 0;
            pause_timer <= 0;
            resume_timer <= 0;
            clear_timer <= 0;
            door_toggle <= 0;
            button_beep <= 0;
            completion_alarm <= 0;
            motor_enable <= 0;
            display_blink <= 1; // 기본적으로 표시
            idle_animation <= 0; // 초기에는 애니메이션 비활성화
        end else begin
            // 기본값으로 리셋 (펄스 신호들)
            add_10sec <= 0;
            add_1min <= 0;
            set_30sec <= 0;
            start_timer <= 0;
            pause_timer <= 0;
            resume_timer <= 0;
            clear_timer <= 0;
            door_toggle <= 0;      // 매 클럭마다 0으로 리셋
            button_beep <= 0;
            completion_alarm <= 0;
            
            // 점멸, 모터, 애니메이션 제어
            display_blink <= (state == COMPLETE) ? blink_state : 1'b1;
            motor_enable <= (state == RUNNING) ? 1'b1 : 1'b0;
            idle_animation <= (state == IDLE && set_time_sec == 0) ? 1'b1 : 1'b0; // IDLE 상태이고 시간이 설정되지 않았을 때만 애니메이션
            
            // 완료 알림음
            completion_alarm <= completion_alarm_active;
            
            // === 버튼 처리 (개별적으로 처리) ===
            
            // btnU 처리
            if (btnU_pulse) begin
                button_beep <= 1;
                if (state == SETTING || state == PAUSED) begin
                    add_10sec <= 1;
                end
            end
            
            // btnR 처리
            if (btnR_pulse) begin
                button_beep <= 1;
                if (state == SETTING || state == PAUSED) begin
                    add_1min <= 1;
                end
            end
            
            // btnL 처리 - stable 신호를 직접 door_toggle로 사용
            door_toggle <= btnL_stable;  // 직접 연결로 테스트
            if (btnL_stable) begin
                button_beep <= 1;
            end
            
            // btnD 처리
            if (btnD_pulse) begin
                button_beep <= 1;
                clear_timer <= 1;
            end
            
            // btnC 처리
            if (btnC_pulse) begin
                button_beep <= 1;
                case (state)
                    IDLE: begin
                        if (set_time_sec == 0) begin
                            set_30sec <= 1;
                            if (btnC_double_click) begin
                                start_timer <= 1;
                            end
                        end else if (!door_open) begin
                            start_timer <= 1;
                        end
                    end
                    SETTING: begin
                        if (set_time_sec > 0 && !door_open) begin
                            start_timer <= 1;
                        end
                    end
                    RUNNING: begin
                        pause_timer <= 1;
                    end
                    PAUSED: begin
                        if (!door_open) begin
                            resume_timer <= 1;
                        end
                    end
                endcase
            end
            
            // 문 열림으로 인한 자동 일시정지
            if (state == RUNNING && door_open) begin
                pause_timer <= 1;
            end
        end
    end
    
    // 디스플레이 데이터 생성 (변환 없이 원본 숫자 전달)
    always @(*) begin
        case (state)
            IDLE: begin
                display_data = 14'd0;  // 0000 표시
            end
            SETTING: begin
                // 설정 시간을 그대로 전달 (초 단위)
                display_data = set_time_sec;
            end
            RUNNING, PAUSED: begin
                // 남은 시간을 그대로 전달 (초 단위)
                display_data = remaining_sec;
            end
            COMPLETE: begin
                display_data = 14'd0;  // 0000 표시
            end
            default: begin
                display_data = 14'd0;
            end
        endcase
    end

endmodule