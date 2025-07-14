// 시뮬레이션에서 사용할 시간 단위를 정의
// 1ns는 시간 단위, 1ps는 정밀도를 의미
`timescale 1ns / 1ps

// Ctrl + Shift + h : 변수 검색 단축키

// 최상위 모듈을 정의
module top(
    // 입력 포트
    input clk,
    input reset,
    input [2:0] btn,  
    input [7:0] sw,     

    // 출력 포트
    output [7:0] seg,
    output [3:0] an,
    output [15:0] led
    );

    // 모듈 간 연결선 역할을 하는 와이어들
    wire [2:0] w_btn_stable;      // 안정화된 버튼 신호
    wire [2:0] w_btn_pulse;       // 버튼 펄스 신호

    wire [13:0] w_seg_data;

    // 버튼 디바운스 모듈 (카운터 이용한 방법)
    my_button_debounce u_my_button_debounce_0(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[0]),
        .o_btn_stable(w_btn_stable[0]),
        .o_btn_pulse(w_btn_pulse[0])
    );

    my_button_debounce u_my_button_debounce_1(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[1]),
        .o_btn_stable(w_btn_stable[1]),
        .o_btn_pulse(w_btn_pulse[1])
    );

    my_button_debounce u_my_button_debounce_2(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[2]),
        .o_btn_stable(w_btn_stable[2]),
        .o_btn_pulse(w_btn_pulse[2])
    );

    btn_command_controller u_btn_command_controller(
        // 입력 포트
        .clk(clk),
        .reset(reset),        // btnU
        .btn(w_btn_pulse),         // btn[0]: L | btn[1]: C | btn[2]: R
        .sw(sw),     

        // 출력 포트
        .seg_data(w_seg_data),    // 2비트 LED 배열
        .led(led)
    );

    fnd_controller u_fnd_controller(
        .clk(clk),
        .reset(reset),
        .input_data(w_seg_data),
        .seg_data(seg),
        .an(an)
    );

endmodule
