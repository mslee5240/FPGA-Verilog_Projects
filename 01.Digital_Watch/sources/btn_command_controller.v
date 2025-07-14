`timescale 1ns / 1ps

// 버튼으로 시계/스톱워치 모드를 전환하는 컨트롤러 모듈
// 이전에 만든 clock_stopwatch 모듈을 사용하는 상위 모듈입니다
module btn_command_controller(
    // ===== 입력 포트 =====
    input clk,              // 100MHz 시스템 클럭
    input reset,            // 전체 리셋 신호 (btnU - 위쪽 버튼)
    input [2:0] btn,        // 3개 버튼: [0]=L(왼쪽), [1]=C(가운데), [2]=R(오른쪽)
    input [7:0] sw,         // 8개 스위치 (시간 설정용)

    // ===== 출력 포트 =====
    output [13:0] seg_data, // 7-segment 디스플레이 데이터
    output [15:0] led       // 16개 LED (모드 및 상태 표시)
    );

    // ===== 모드 정의 (이전 모듈과 동일) =====
    parameter CLOCK_MODE = 1'b0;        // 시계 모드 = 0
    parameter STOPWATCH_MODE = 1'b1;    // 스톱워치 모드 = 1

    // ===== 내부 신호 =====
    reg mode = CLOCK_MODE;      // 현재 모드 저장 (기본값: 시계 모드)
    reg prev_btn0 = 0;          // btn[0]의 이전 상태 (엣지 검출용)
    
    // ===== 하위 모듈과 연결할 와이어 =====
    wire [13:0] clock_seg_data; // 시계 모듈의 7-segment 데이터
    wire [15:0] clock_led;      // 시계 모듈의 LED 데이터

    // ===== 모드 전환 로직 =====
    // btn[0] (왼쪽 버튼)을 눌렀을 때 모드 전환
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            // 리셋 시 기본값으로 초기화
            mode <= CLOCK_MODE;     // 시계 모드로 설정
            prev_btn0 <= 0;         // 이전 버튼 상태 초기화
        end else begin
            // btn[0]이 눌렸을 때 (0→1 변화) 모드 전환
            if (btn[0] && !prev_btn0) begin
                mode <= ~mode;      // 모드 반전 (0→1, 1→0)
            end
            prev_btn0 <= btn[0];    // 현재 버튼 상태를 이전 상태로 저장
        end
    end

    // ===== 시계/스톱워치 모듈 인스턴스 =====
    // 이전에 만든 clock_stopwatch 모듈을 사용
    clock_stopwatch u_clock_stopwatch(
        .clk(clk),                      // 클럭 연결
        .reset(reset),                  // 리셋 연결
        .mode(mode),                    // 현재 모드 전달
        .btn(btn),                      // 모든 버튼 전달
        .sw(sw),                        // 모든 스위치 전달
        .seg_data(clock_seg_data),      // 7-segment 데이터 받기
        .led(clock_led)                 // LED 데이터 받기
    );

    // ===== 출력 할당 =====
    // 7-segment 디스플레이는 하위 모듈 데이터를 그대로 사용
    assign seg_data = clock_seg_data;
    
    // ===== LED 출력 =====
    // 하위 모듈의 LED 출력을 그대로 사용
    // clock_stopwatch 모듈에서 이미 모든 LED 제어를 담당
    assign led = clock_led;

endmodule