`timescale 1ns / 1ps

// 디버깅용 LED가 추가된 전자레인지 최상위 모듈
module top_microwave(
    input clk,              // 100MHz 시스템 클럭
    input reset,            // 리셋 신호 (스위치 0번)
    
    // 버튼 입력들
    input btnC,             // 시작/일시정지 버튼
    input btnU,             // 10초 추가 버튼
    input btnR,             // 1분 추가 버튼
    input btnL,             // 문 열기/닫기 버튼
    input btnD,             // 취소/리셋 버튼
    
    // 7-Segment 디스플레이
    output [7:0] seg,       // 세그먼트 출력 (a~g + dp)
    output [3:0] an,        // 자릿수 선택
    
    // 모터 제어
    output PWM_OUT,         // DC 모터 PWM
    output [1:0] in1_in2,   // DC 모터 방향 제어
    output servo,           // 서보 모터 PWM
    
    // 부저
    output buzzer,          // 부저 출력
    
    // 디버깅용 LED
    output [15:0] led       // LED 출력
);

    // ===== 내부 신호 선언 =====
    
    // 클럭 신호
    wire w_clk_1hz;
    
    // 디바운싱된 버튼 신호들
    wire w_btnC_stable, w_btnC_pulse;
    wire w_btnU_stable, w_btnU_pulse;
    wire w_btnR_stable, w_btnR_pulse;
    wire w_btnL_stable, w_btnL_pulse;
    wire w_btnD_stable, w_btnD_pulse;
    
    // 상태 제어 신호들
    wire w_add_10sec, w_add_1min, w_set_30sec;
    wire w_start_timer, w_pause_timer, w_resume_timer, w_clear_timer;
    wire w_door_toggle, w_button_beep, w_completion_alarm;
    wire w_motor_enable, w_display_blink, w_idle_animation;  // idle_animation 신호 추가
    wire [2:0] w_current_state;
    wire [13:0] w_display_data;
    
    // 타이머 관련 신호들
    wire [11:0] w_set_time_sec, w_remaining_sec;
    wire w_timer_running, w_timer_paused, w_timer_completed;
    
    // 하드웨어 상태 신호들
    wire w_door_open;
    
    // ===== 클럭 분주기 =====
    clock_divider u_clock_divider(
        .clk(clk),
        .reset(reset),
        .clk_1hz(w_clk_1hz)
    );
    
    // ===== 버튼 디바운싱 모듈들 =====
    my_button_debounce u_btnC_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btnC),
        .o_btn_stable(w_btnC_stable),
        .o_btn_pulse(w_btnC_pulse)
    );
    
    my_button_debounce u_btnU_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btnU),
        .o_btn_stable(w_btnU_stable),
        .o_btn_pulse(w_btnU_pulse)
    );
    
    my_button_debounce u_btnR_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btnR),
        .o_btn_stable(w_btnR_stable),
        .o_btn_pulse(w_btnR_pulse)
    );
    
    my_button_debounce u_btnL_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btnL),
        .o_btn_stable(w_btnL_stable),
        .o_btn_pulse(w_btnL_pulse)
    );
    
    my_button_debounce u_btnD_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btnD),
        .o_btn_stable(w_btnD_stable),
        .o_btn_pulse(w_btnD_pulse)
    );
    
    // ===== 타이머 관리 모듈 =====
    timer_manager u_timer_manager(
        .clk(clk),
        .clk_1hz(w_clk_1hz),
        .reset(reset),
        .add_10sec(w_add_10sec),
        .add_1min(w_add_1min),
        .set_30sec(w_set_30sec),
        .start_timer(w_start_timer),
        .pause_timer(w_pause_timer),
        .resume_timer(w_resume_timer),
        .clear_timer(w_clear_timer),
        .set_time_sec(w_set_time_sec),
        .remaining_sec(w_remaining_sec),
        .timer_running(w_timer_running),
        .timer_paused(w_timer_paused),
        .timer_completed(w_timer_completed)
    );
    
    // ===== 상태 제어 모듈 =====
    state_controller u_state_controller(
        .clk(clk),
        .clk_1hz(w_clk_1hz),
        .reset(reset),
        .btnC_pulse(w_btnC_pulse),
        .btnU_pulse(w_btnU_pulse),
        .btnR_pulse(w_btnR_pulse),
        .btnL_stable(w_btnL_stable),        // 수정: stable 신호 직접 사용
        .btnD_pulse(w_btnD_pulse),
        .door_open(w_door_open),
        .timer_completed(w_timer_completed),
        .set_time_sec(w_set_time_sec),
        .remaining_sec(w_remaining_sec),
        .add_10sec(w_add_10sec),
        .add_1min(w_add_1min),
        .set_30sec(w_set_30sec),
        .start_timer(w_start_timer),
        .pause_timer(w_pause_timer),
        .resume_timer(w_resume_timer),
        .clear_timer(w_clear_timer),
        .door_toggle(w_door_toggle),
        .button_beep(w_button_beep),
        .completion_alarm(w_completion_alarm),
        .motor_enable(w_motor_enable),
        .display_blink(w_display_blink),
        .idle_animation(w_idle_animation),      // 애니메이션 신호 연결
        .current_state(w_current_state),
        .display_data(w_display_data)
    );
    
    // ===== FND 컨트롤러 =====
    // 점멸 효과를 위한 데이터 선택
    wire [13:0] final_display_data;
    assign final_display_data = w_display_blink ? w_display_data : 14'd0;
    
    // FND 컨트롤러
    fnd_controller u_fnd_controller(
        .clk(clk),
        .reset(reset),
        .input_data(final_display_data),
        .idle_animation(w_idle_animation),      // 애니메이션 신호 연결
        .seg_data(seg),
        .an(an)
    );
    
    // ===== 서보 모터 컨트롤러 =====
    servo_controller u_servo_controller(
        .clk(clk),
        .reset(reset),
        .door_toggle(w_door_toggle),
        .servo(servo),
        .door_open(w_door_open)
    );
    
    // ===== 부저 컨트롤러 =====
    buzzer_controller u_buzzer_controller(
        .clk(clk),
        .reset(reset),
        .button_pressed(w_button_beep),
        .completion_alarm(w_completion_alarm),
        .buzzer(buzzer)
    );
    
    // ===== DC 모터 컨트롤러 =====
    simple_dcmotor u_simple_dcmotor(
        .clk(clk),
        .reset(reset),
        .motor_enable(w_motor_enable),
        .PWM_OUT(PWM_OUT),
        .in1_in2(in1_in2)
    );
    
    // ===== 디버깅용 LED 할당 =====
    assign led[0] = w_btnL_stable;        // btnL 버튼 상태
    assign led[1] = 1'b0;                 // 사용 안함
    assign led[2] = w_door_toggle;        // door_toggle 신호
    assign led[3] = w_door_open;          // 문 열림 상태
    assign led[6:4] = w_current_state;    // 현재 상태
    assign led[7] = w_timer_running;      // 타이머 실행 상태
    assign led[8] = w_motor_enable;       // 모터 활성화 상태
    assign led[15:9] = w_remaining_sec[6:0]; // 남은 시간 (하위 7비트)

endmodule