`timescale 1ns / 1ps

module tb_simple();

    //==========================================================================
    // 신호 선언
    //==========================================================================
    reg clk;
    reg reset;
    reg btn0_pulse;  // 0 입력
    reg btn2_pulse;  // 1 입력
    
    wire detected_00;
    wire detected_11;

    //==========================================================================
    // DUT (Device Under Test)
    //==========================================================================
    consecutive_bit_detector_fsm dut(
        .clk(clk),
        .reset(reset),
        .btn0_pulse(btn0_pulse),
        .btn2_pulse(btn2_pulse),
        .detected_00(detected_00),
        .detected_11(detected_11)
    );

    //==========================================================================
    // 클럭 생성 (100MHz)
    //==========================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //==========================================================================
    // 테스트 시퀀스
    //==========================================================================
    initial begin
        // 초기화
        reset = 1;
        btn0_pulse = 0;
        btn2_pulse = 0;
        
        #20 reset = 0;
        #10;
        
        // 불규칙한 0, 1 입력 시퀀스
        // 1
        #10 btn2_pulse = 1; #10 btn2_pulse = 0;
        
        // 0  
        #20 btn0_pulse = 1; #10 btn0_pulse = 0;
        
        // 0 (00 패턴 검출 예상)
        #20 btn0_pulse = 1; #10 btn0_pulse = 0;
        
        #30;
        
        // 1
        #10 btn2_pulse = 1; #10 btn2_pulse = 0;
        
        // 1 (11 패턴 검출 예상)
        #20 btn2_pulse = 1; #10 btn2_pulse = 0;
        
        #30;
        
        // 0
        #10 btn0_pulse = 1; #10 btn0_pulse = 0;
        
        // 1
        #20 btn2_pulse = 1; #10 btn2_pulse = 0;
        
        // 1 (11 패턴 검출 예상)
        #20 btn2_pulse = 1; #10 btn2_pulse = 0;
        
        #30;
        
        // 0
        #10 btn0_pulse = 1; #10 btn0_pulse = 0;
        
        // 0 (00 패턴 검출 예상)
        #20 btn0_pulse = 1; #10 btn0_pulse = 0;
        
        // 0 (00 패턴 검출 예상)
        #20 btn0_pulse = 1; #10 btn0_pulse = 0;
        
        #50;
        $finish;
    end

endmodule