`timescale 1ns / 1ps

// 100MHz 클럭을 1Hz로 분주하는 모듈
module clock_divider(
    input clk,              // 100MHz 입력 클럭
    input reset,            // 리셋 신호
    output reg clk_1hz      // 1Hz 출력 클럭
);

    // 100MHz를 1Hz로 분주하려면 100,000,000 카운트 필요
    // 하지만 토글 방식이므로 50,000,000 카운트마다 토글
    parameter COUNT_MAX = 50_000_000 - 1;
    
    reg [25:0] counter = 0;  // 50,000,000을 세기 위한 26비트 카운터
    
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_1hz <= 0;
        end else begin
            if (counter == COUNT_MAX) begin
                counter <= 0;
                clk_1hz <= ~clk_1hz;  // 1초마다 토글
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule