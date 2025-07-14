`timescale 1ns / 1ps

// 자판기 핵심 로직 모듈 (배열 포트 버전)
module vending_machine_core(
    input clk,                      // 시스템 클럭
    input reset,                    // 리셋 신호
    input [3:0] btn_pulse,          // 버튼 펄스 배열 [0]:100원, [1]:커피, [2]:반환, [3]:500원
    output [13:0] display_data,     // FND 표시 데이터
    output coffee_making_flag,      // 커피 제조 중 플래그
    output [7:0] animation_seg,     // 애니메이션 세그먼트 출력
    output [3:0] animation_an       // 애니메이션 자릿수 선택
);

    // ===== 파라미터 =====
    parameter COFFEE_PRICE = 300;           // 커피 가격 300원
    parameter COIN_100 = 100;               // 100원 동전
    parameter COIN_500 = 500;               // 500원 동전
    parameter ANIMATION_CYCLES = 200_000_000; // 2초 애니메이션 (100MHz 기준)
    parameter PATTERN_CHANGE_TIME = 30_000_000; // 0.3초 (패턴 변경 주기)
    parameter COIN_RETURN_TIME = 25_000_000; // 0.25초 (동전 반환 주기)

    // ===== 내부 신호 선언 =====
    reg [13:0] balance;                     // 현재 잔고 (0~9999원)
    
    // 커피 제조 애니메이션 관련 신호
    reg coffee_making;                      // 커피 제조 중 플래그 (내부용)
    reg [27:0] animation_counter;           // 애니메이션 카운터
    reg [27:0] pattern_timer;               // 패턴 변경 타이머
    reg [2:0] animation_pattern;            // 애니메이션 패턴 (0~5, 외곽 6개 세그먼트)
    reg [7:0] animation_seg_reg;            // 애니메이션 세그먼트 레지스터
    reg [3:0] animation_an_reg;             // 애니메이션 자릿수 레지스터
    
    // 동전 반환 애니메이션 관련 신호
    reg coin_returning;                     // 동전 반환 중 플래그
    reg [27:0] return_timer;                // 반환 타이머 (0.5초마다 100원씩 감소)

    // ===== 초기값 설정 (합성을 위한 안전한 방식) =====
    initial begin
        balance = 14'd0;
        coffee_making = 1'b0;
        animation_counter = 28'd0;
        pattern_timer = 28'd0;
        animation_pattern = 3'd0;
        animation_seg_reg = 8'b11111111;
        animation_an_reg = 4'b1111;
        coin_returning = 1'b0;
        return_timer = 28'd0;
    end

    // ===== 메인 로직 =====
    always @(posedge clk or posedge reset) begin
        // Reset 처리 (모든 신호 명시적 초기화)
        if (reset) begin
            balance <= 14'd0;
            coffee_making <= 1'b0;
            animation_counter <= 28'd0;
            pattern_timer <= 28'd0;
            animation_pattern <= 3'd0;
            coin_returning <= 1'b0;
            return_timer <= 28'd0;
        end
        
        // 일반 모드 (커피 제조도 반환도 하지 않는 상태)
        else if (!coffee_making && !coin_returning) begin
            // 100원 동전 투입 (btn_pulse[0])
            if (btn_pulse[0]) begin
                if (balance <= 14'd9899) begin  // 9999 - 100 = 9899 (오버플로우 방지)
                    balance <= balance + COIN_100;
                end
            end
            
            // 500원 동전 투입 (btn_pulse[3])
            if (btn_pulse[3]) begin
                if (balance <= 14'd9499) begin  // 9999 - 500 = 9499 (오버플로우 방지)
                    balance <= balance + COIN_500;
                end
            end
            
            // 커피 구매 (btn_pulse[1])
            if (btn_pulse[1]) begin
                if (balance >= COFFEE_PRICE) begin
                    balance <= balance - COFFEE_PRICE;
                    coffee_making <= 1'b1;       // 커피 제조 시작
                    animation_counter <= 28'd0;
                    pattern_timer <= 28'd0;
                    animation_pattern <= 3'd0;
                end
                // 잔고 부족 시 아무 동작 안함
            end
            
            // 동전 반환 (btn_pulse[2]) - 새로운 애니메이션 모드
            if (btn_pulse[2] && balance > 0) begin  // 잔고가 있을 때만 반환 시작
                coin_returning <= 1'b1;           // 동전 반환 시작
                return_timer <= 28'd0;            // 반환 타이머 초기화
            end
        end
        
        // 커피 제조 애니메이션 처리
        else if (coffee_making) begin
            animation_counter <= animation_counter + 1;
            pattern_timer <= pattern_timer + 1;
            
            // 0.3초마다 애니메이션 패턴 변경 (타이머 기반)
            if (pattern_timer >= PATTERN_CHANGE_TIME) begin
                pattern_timer <= 28'd0;         // 타이머 리셋
                if (animation_pattern >= 3'd5) begin
                    animation_pattern <= 3'd0;
                end else begin
                    animation_pattern <= animation_pattern + 1;
                end
            end
            
            // 2초 후 커피 제조 완료
            if (animation_counter >= ANIMATION_CYCLES) begin
                coffee_making <= 1'b0;
                animation_counter <= 28'd0;
                pattern_timer <= 28'd0;
                animation_pattern <= 3'd0;
            end
        end
        
        // 동전 반환 애니메이션 처리
        else if (coin_returning) begin
            return_timer <= return_timer + 1;
            
            // 0.5초마다 100원씩 감소
            if (return_timer >= COIN_RETURN_TIME) begin
                return_timer <= 28'd0;          // 타이머 리셋
                
                if (balance >= COIN_100) begin
                    balance <= balance - COIN_100;  // 100원씩 감소
                end else begin
                    balance <= 14'd0;           // 100원 미만이면 0으로
                    coin_returning <= 1'b0;     // 반환 완료
                end
            end
            
            // 잔고가 0이 되면 반환 완료
            if (balance == 0) begin
                coin_returning <= 1'b0;
                return_timer <= 28'd0;
            end
        end
    end

    // ===== 서클 애니메이션 세그먼트 패턴 생성 =====
    always @(*) begin
        // 기본값 설정
        animation_seg_reg = 8'b11111111;  // 모든 세그먼트 꺼짐
        animation_an_reg = 4'b1111;       // 모든 자릿수 비활성화
        
        // 커피 제조 중일 때만 서클 애니메이션 활성화
        if (coffee_making) begin
            // 외곽 세그먼트를 시계방향으로 회전 (a→b→c→d→e→f)
            // 7-segment 패턴: {dp, g, f, e, d, c, b, a} (Common Anode, 0=켜짐)
            case (animation_pattern)
                3'd0: animation_seg_reg = 8'b11111110;  // a 세그먼트만 켜기
                3'd1: animation_seg_reg = 8'b11111101;  // b 세그먼트만 켜기  
                3'd2: animation_seg_reg = 8'b11111011;  // c 세그먼트만 켜기
                3'd3: animation_seg_reg = 8'b11110111;  // d 세그먼트만 켜기
                3'd4: animation_seg_reg = 8'b11101111;  // e 세그먼트만 켜기
                3'd5: animation_seg_reg = 8'b11011111;  // f 세그먼트만 켜기
                default: animation_seg_reg = 8'b11111111; // 예상외 값일 때 모든 세그먼트 꺼짐
            endcase
            
            // 모든 자릿수를 동시에 켜서 전체 디스플레이에 애니메이션 표시
            animation_an_reg = 4'b0000;  // 모든 자릿수 활성화 (0=켜짐)
        end
        // 동전 반환 중이거나 일반 모드일 때는 애니메이션 비활성화
        // (FND 컨트롤러가 잔고를 정상 표시하도록 함)
    end

    // ===== 출력 할당 =====
    assign display_data = balance;              // 항상 현재 잔고 출력
    assign coffee_making_flag = coffee_making;  // 커피 제조 상태 출력
    assign animation_seg = animation_seg_reg;   // 애니메이션 세그먼트 출력
    assign animation_an = animation_an_reg;     // 애니메이션 자릿수 출력

endmodule