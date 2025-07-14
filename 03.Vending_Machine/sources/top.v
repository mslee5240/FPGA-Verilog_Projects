`timescale 1ns / 1ps

// 자판기 최상위 모듈 (배열 와이어 버전)
module vending_machine_top(
    input clk,              // 100MHz 시스템 클럭
    input reset,            // Reset 버튼
    input [3:0] btn,        // 버튼 입력 [0]:L, [1]:C, [2]:R, [3]:D
    output [7:0] seg,       // 7-segment 패턴 출력
    output [3:0] an         // 자릿수 선택 출력
);

    // ===== 내부 연결 신호 =====
    // 버튼 디바운싱 출력 신호 (배열로 선언)
    wire [3:0] w_btn_pulse;             // [0]:100원, [1]:커피, [2]:반환, [3]:500원
    
    // 자판기 로직 모듈 연결 신호
    wire [13:0] w_display_data;         // 잔고 데이터 (0~9999)
    wire w_coffee_making_flag;          // 커피 제조 중 플래그
    wire [7:0] w_animation_seg;         // 애니메이션 세그먼트 패턴
    wire [3:0] w_animation_an;          // 애니메이션 자릿수 선택
    
    // FND 컨트롤러 출력 신호
    wire [7:0] w_fnd_seg;               // 일반 모드 세그먼트 패턴
    wire [3:0] w_fnd_an;                // 일반 모드 자릿수 선택

    // ===== 버튼 디바운싱 모듈 인스턴스 =====
    // btn[0]: 100원 동전 투입 버튼
    my_button_debounce u_debounce_100(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[0]),
        .o_btn_stable(),                    // 사용하지 않는 출력
        .o_btn_pulse(w_btn_pulse[0])        // 100원 투입 펄스
    );

    // btn[1]: 커피 구매 버튼
    my_button_debounce u_debounce_coffee(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[1]),
        .o_btn_stable(),                    // 사용하지 않는 출력
        .o_btn_pulse(w_btn_pulse[1])        // 커피 구매 펄스
    );

    // btn[2]: 동전 반환 버튼
    my_button_debounce u_debounce_return(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[2]),
        .o_btn_stable(),                    // 사용하지 않는 출력
        .o_btn_pulse(w_btn_pulse[2])        // 동전 반환 펄스
    );

    // btn[3]: 500원 동전 투입 버튼
    my_button_debounce u_debounce_500(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[3]),
        .o_btn_stable(),                    // 사용하지 않는 출력
        .o_btn_pulse(w_btn_pulse[3])        // 500원 투입 펄스
    );

    // ===== 자판기 핵심 로직 모듈 인스턴스 =====
    vending_machine_core u_vending_machine_core(
        .clk(clk),
        .reset(reset),
        .btn_pulse(w_btn_pulse),            // 배열 전체를 한 번에 연결!
        .display_data(w_display_data),
        .coffee_making_flag(w_coffee_making_flag),
        .animation_seg(w_animation_seg),
        .animation_an(w_animation_an)
    );

    // ===== FND 컨트롤러 모듈 인스턴스 =====
    fnd_controller u_fnd_controller(
        .clk(clk),
        .reset(reset),
        .input_data(w_display_data),
        .seg_data(w_fnd_seg),
        .an(w_fnd_an)
    );

    // ===== 출력 선택 로직 =====
    // 커피 제조 중: 애니메이션 출력 (외곽 세그먼트 회전)
    // 평상시: FND 컨트롤러 출력 (잔고 표시)
    assign seg = w_coffee_making_flag ? w_animation_seg : w_fnd_seg;
    assign an = w_coffee_making_flag ? w_animation_an : w_fnd_an;

endmodule