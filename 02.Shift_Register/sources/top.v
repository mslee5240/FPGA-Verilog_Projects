// 시뮬레이션에서 사용할 시간 단위를 정의
// 1ns는 시간 단위, 1ps는 정밀도를 의미
`timescale 1ns / 1ps

// Ctrl + Shift + h : 변수 검색 단축키

//==============================================================================
// 패턴 검출 모듈 (enable 신호 추가)
//==============================================================================
module sr7_pattern_detect (
    input rst, clk, din, enable,
    output dout,
    output [6:0] sr7_out  // shift register 출력 추가
);

    reg [6:0] sr7;

    always @(negedge rst, posedge clk) begin
        if (rst == 0)
            sr7 <= 0;
        else if (enable)  // enable이 활성화될 때만 shift
            sr7 <= {sr7[5:0], din};
    end     

    assign dout = (sr7 == 7'b1010111) ? 1 : 0;
    assign sr7_out = sr7;  // 내부 shift register를 외부로 출력

endmodule

//==============================================================================
// 최상위 모듈
//==============================================================================
module top(
    // 입력 포트
    input clk,
    input reset,
    input [1:0] btn,        // btn[0]: '1' 입력 | btn[1]: '0' 입력   

    // 출력 포트
    output [15:0] led
);

    //==========================================================================
    // 신호 선언
    //==========================================================================
    
    // 패턴 검출용 신호들
    reg din = 1'b0;
    wire pattern_detected;
    wire shift_enable;
    
    // 디바운스된 버튼 신호들
    wire btn0_stable, btn0_pulse;  // btn[0] 디바운스 신호
    wire btn1_stable, btn1_pulse;  // btn[1] 디바운스 신호
    
    // 실시간 shift register 추적용
    wire [6:0] current_sr7;

    //==========================================================================
    // 버튼 디바운스 모듈들
    //==========================================================================
    
    // btn[0] ('1' 입력) 디바운스 처리
    my_button_debounce u_btn0_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[0]),
        .o_btn_stable(btn0_stable),
        .o_btn_pulse(btn0_pulse)
    );
    
    // btn[1] ('0' 입력) 디바운스 처리  
    my_button_debounce u_btn1_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[1]),
        .o_btn_stable(btn1_stable),
        .o_btn_pulse(btn1_pulse)
    );

    //==========================================================================
    // 패턴 검출 로직
    //==========================================================================
    
    // 버튼 입력에 따른 din 및 enable 신호 생성
    reg shift_enable_delayed;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            din <= 1'b0;
            shift_enable_delayed <= 1'b0;
        end else begin
            if (btn0_pulse)
                din <= 1'b1;      // btn[0] 눌림 펄스 시 1 입력
            else if (btn1_pulse)
                din <= 1'b0;      // btn[1] 눌림 펄스 시 0 입력
                
            // enable 신호를 한 클락 늦게 활성화
            shift_enable_delayed <= btn0_pulse | btn1_pulse;
        end
    end
    
    // 지연된 enable 신호 사용
    assign shift_enable = shift_enable_delayed;
    
    // 패턴 검출기 인스턴스 (enable 신호 추가)
    sr7_pattern_detect pattern_detector (
        .rst(~reset),              // reset 신호 반전 (active low)
        .clk(clk),
        .din(din),
        .enable(shift_enable),     // 버튼 눌림 시에만 활성화
        .dout(pattern_detected),
        .sr7_out(current_sr7)      // shift register 출력 연결
    );

    //==========================================================================
    // LED 출력 제어
    //==========================================================================
    
    // LED 배치:
    // LED[15]    : 패턴 "1010111" 검출 결과
    // LED[14:8]  : 사용 안함 (꺼짐)
    // LED[6:0]   : 현재 Shift Register 내용 (7비트 실시간 표시)
    
    assign led[15] = pattern_detected;        // 패턴 검출 결과
    assign led[14:7] = 8'b00000000;          // 사용 안함 (꺼짐)
    assign led[6:0] = current_sr7;           // Shift Register 실시간 내용

endmodule