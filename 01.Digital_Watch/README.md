# Digital Clock & Stopwatch - BASYS-3 FPGA

BASYS-3 보드를 이용한 디지털 시계 및 스톱워치 구현 프로젝트

## 프로젝트 개요

Xilinx BASYS-3 FPGA 보드와 Vivado를 사용하여 구현한 다기능 디지털 시계입니다. 시계 모드와 스톱워치 모드를 지원하며, 4자리 7-segment 디스플레이로 시간을 표시합니다.

## 주요 기능

### 시계 모드 (기본 모드)
- 시:분 형태로 시간 표시 (HH:MM)
- 스위치를 통한 시간 설정 가능
- 실시간 시간 업데이트

### 스톱워치 모드  
- 분:초 형태로 경과 시간 표시 (MM:SS)
- 시작/정지/리셋 기능
- 정밀한 시간 측정

## 사용법

### 버튼 기능
- **Left Button (btnL)**: 시계 ↔ 스톱워치 모드 전환
- **Center Button (btnC)**: 스톱워치 시작/정지
- **Right Button (btnR)**: 스톱워치 리셋
- **Up Button (btnU)**: 전체 시스템 리셋

### 스위치 기능
- **sw[7:0]**: 시계 모드에서 시간 설정용

### 출력
- **7-segment Display**: 현재 시간 또는 경과 시간 표시
- **LED[15:0]**: 현재 모드 및 상태 표시

## 시스템 구조

```
top.v (최상위 모듈)
├── button_debounce.v (×3) - 버튼 디바운싱
├── btn_command_controller.v - 모드 제어
│   └── clock_stopwatch.v - 시계/스톱워치 로직
└── fnd_controller.v - 7-segment 제어
    ├── fnd_digit_select.v - 자릿수 선택
    ├── bin2bcd.v - 이진-BCD 변환
    └── fnd_display.v - 세그먼트 패턴 생성
```

## 주요 모듈 설명

### Core Modules
- **`btn_command_controller.v`**: 버튼 입력으로 시계/스톱워치 모드 전환
- **`button_debounce.v`**: 버튼 바운싱 제거 (10ms 디바운싱)
- **`fnd_controller.v`**: 4자리 7-segment 디스플레이 제어

### Clock Generation
- **`tick_generator.v`**: 100MHz → 1kHz 틱 생성
- **`clock_8Hz.v`**: 100MHz → 8Hz 클럭 분주
- **`D_FF.v`**: D 플립플롭 구현

## 빌드 및 실행

### 필요 환경
- **FPGA 보드**: Xilinx BASYS-3
- **개발 도구**: Vivado Design Suite
- **언어**: Verilog HDL

### 실행 단계
1. Vivado에서 새 프로젝트 생성
2. 모든 `.v` 파일을 프로젝트에 추가
3. `top.v`를 최상위 모듈로 설정
4. BASYS-3 제약 파일(.xdc) 추가
5. Synthesis → Implementation → Generate Bitstream
6. BASYS-3 보드에 프로그래밍

## 리소스 사용량

- **클럭 도메인**: 100MHz 메인 클럭
- **I/O 핀**: 버튼 4개, 스위치 8개, 7-segment 출력, LED 16개
- **내부 클럭**: 1kHz 틱, 8Hz 분주 클럭

## 특징

- **멀티플렉싱**: 4자리 7-segment 디스플레이 동시 제어
- **디바운싱**: 안정적인 버튼 입력 처리
- **모듈형 설계**: 재사용 가능한 컴포넌트 구조
- **실시간 처리**: 정확한 시간 관리

---
**개발 환경**: Xilinx Vivado | **타겟 보드**: BASYS-3 | **언어**: Verilog HDL