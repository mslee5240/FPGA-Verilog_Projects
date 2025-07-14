`timescale 1ns / 1ps

//==============================================================================
// 간단한 3상태 FSM 기반 연속 비트 검출기
//==============================================================================
module consecutive_bit_detector_fsm(
    input clk,
    input reset,
    input btn0_pulse,    // 0 입력 버튼 펄스
    input btn2_pulse,    // 1 입력 버튼 펄스
    output reg detected_00,
    output reg detected_11
);

    // 상태 정의
    localparam IDLE = 2'b00;
    localparam STATE_0 = 2'b01;  // 이전에 0을 받은 상태
    localparam STATE_1 = 2'b10;  // 이전에 1을 받은 상태
    
    reg [1:0] current_state;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            detected_00 <= 1'b0;
            detected_11 <= 1'b0;
        end else begin
            // 기본적으로 검출 신호는 0
            detected_00 <= 1'b0;
            detected_11 <= 1'b0;
            
            if (btn0_pulse) begin  // 0 입력
                case (current_state)
                    IDLE: begin
                        current_state <= STATE_0;
                        // 출력 0
                    end
                    STATE_0: begin
                        current_state <= STATE_0;
                        detected_00 <= 1'b1;  // 00 패턴 검출!
                    end
                    STATE_1: begin
                        current_state <= STATE_0;
                        // 출력 0
                    end
                endcase
            end
            else if (btn2_pulse) begin  // 1 입력
                case (current_state)
                    IDLE: begin
                        current_state <= STATE_1;
                        // 출력 0
                    end
                    STATE_0: begin
                        current_state <= STATE_1;
                        // 출력 0
                    end
                    STATE_1: begin
                        current_state <= STATE_1;
                        detected_11 <= 1'b1;  // 11 패턴 검출!
                    end
                endcase
            end
        end
    end

endmodule

//==============================================================================
// 최상위 모듈
//==============================================================================
module top(
    input clk,
    input reset,
    input [2:0] btn,    // btn[0]: 0 입력, btn[2]: 1 입력
    output [15:0] led
);

    // 디바운스된 버튼 신호들
    wire btn0_stable, btn0_pulse;
    wire btn2_stable, btn2_pulse;
    
    // FSM 출력
    wire fsm_detected_00, fsm_detected_11;
    
    // 검출 결과 래치
    reg detected_00_latch, detected_11_latch;
    
    // 입력 히스토리
    reg [6:0] shift_reg;

    //==========================================================================
    // 버튼 디바운스
    //==========================================================================
    my_button_debounce u_btn0_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[0]),
        .o_btn_stable(btn0_stable),
        .o_btn_pulse(btn0_pulse)
    );
    
    my_button_debounce u_btn2_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[2]),
        .o_btn_stable(btn2_stable),
        .o_btn_pulse(btn2_pulse)
    );

    //==========================================================================
    // FSM 인스턴스
    //==========================================================================
    consecutive_bit_detector_fsm u_fsm(
        .clk(clk),
        .reset(reset),
        .btn0_pulse(btn0_pulse),
        .btn2_pulse(btn2_pulse),
        .detected_00(fsm_detected_00),
        .detected_11(fsm_detected_11)
    );

    //==========================================================================
    // 시프트 레지스터 및 래치 로직
    //==========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_reg <= 7'b0000000;
            detected_00_latch <= 1'b0;
            detected_11_latch <= 1'b0;
        end else begin
            // 새 입력이 있으면 먼저 검출 결과 클리어
            if (btn0_pulse || btn2_pulse) begin
                detected_00_latch <= 1'b0;
                detected_11_latch <= 1'b0;
            end
            
            // 시프트 레지스터 업데이트
            if (btn0_pulse) begin
                shift_reg <= {shift_reg[5:0], 1'b0};
            end else if (btn2_pulse) begin
                shift_reg <= {shift_reg[5:0], 1'b1};
            end
            
            // 검출 결과 래치
            if (fsm_detected_00) begin
                detected_00_latch <= 1'b1;
            end
            if (fsm_detected_11) begin
                detected_11_latch <= 1'b1;
            end
        end
    end

    //==========================================================================
    // LED 출력
    //==========================================================================
    assign led[15] = detected_00_latch;  // 00 패턴 검출
    assign led[14] = detected_11_latch;  // 11 패턴 검출
    assign led[13:7] = 7'b0000000;      // 사용 안함
    assign led[6:0] = shift_reg;        // 입력 히스토리

endmodule