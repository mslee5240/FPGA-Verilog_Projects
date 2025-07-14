# FPGA Digital Systems Collection - BASYS-3

BASYS-3 보드를 이용한 5가지 디지털 시스템 구현 프로젝트 모음

## 프로젝트 개요

Xilinx BASYS-3 FPGA 보드와 Vivado를 사용하여 구현한 다양한 디지털 시스템들입니다. 각 프로젝트는 독립적으로 동작하며, 디지털 논리 설계의 다양한 측면을 다룹니다.

## 프로젝트 목록

### 1. Digital Clock & Stopwatch
**시계/스톱워치 시스템**

- **기능**: 시계 모드(MM:SS), 스톱워치 모드(SS:MS) 전환
- **특징**: 백그라운드 병렬 동작, 1ms 정밀도, LED 상태 표시
- **핵심 기술**: 클럭 분주, 멀티플렉싱, 모드 전환 FSM
- **파일**: `btn_command_controller.v`, `clock_stopwatch.v`, `fnd_controller.v` 등

### 2. 7-bit Pattern Detection
**시프트 레지스터 기반 패턴 검출기**

- **기능**: "1010111" 패턴 실시간 검출
- **특징**: 7비트 슬라이딩 윈도우, 시각적 피드백
- **핵심 기술**: 시프트 레지스터, 패턴 매칭, Enable 제어
- **파일**: `top.v` (패턴 검출용), `button_debounce.v`

### 3. FSM Consecutive Bit Detector
**유한 상태 머신 기반 연속 비트 검출기**

- **기능**: "00", "11" 연속 패턴 검출
- **특징**: 3상태 FSM, 래치 메커니즘, 입력 히스토리 추적
- **핵심 기술**: FSM 설계, 상태 전이, 에지 검출
- **파일**: `top.v` (FSM용), `button_debounce.v`

### 4. Digital Vending Machine
**디지털 자판기 시스템**

- **기능**: 동전 투입(100원/500원), 커피 구매(300원), 잔돈 반환
- **특징**: 서클 애니메이션, 점진적 반환, 오버플로우 방지
- **핵심 기술**: 상태 머신, 애니메이션 제어, 안전한 거래 로직
- **파일**: `top.v` (자판기용), `vending_machine.v`, `fnd_controller.v` 등

### 5. Smart Microwave Oven Controller
**지능형 전자레인지 제어 시스템**

- **기능**: 5상태 FSM, 하드웨어 제어, 안전 기능
- **특징**: 더블클릭 퀵스타트, 문 열림 감지, 완료 알림
- **핵심 기술**: 복합 FSM, PWM 제어, 실시간 타이머
- **파일**: `top_microwave.v`, `state_controller.v`, `timer_manager.v` 등

## 기술적 특징 비교

| 프로젝트 | 주요 기술 | 복잡도 | 하드웨어 제어 | 상태 수 |
|---------|-----------|--------|---------------|---------|
| Clock/Stopwatch | 클럭 분주, 병렬 처리 | 중간 | 7-segment, LED | 2개 모드 |
| 7-bit Pattern | 시프트 레지스터 | 낮음 | LED | 단순 |
| FSM Pattern | 상태 머신 | 낮음 | LED | 3상태 |
| Vending Machine | 애니메이션, 거래 로직 | 중간 | 7-segment | 3상태 |
| Microwave Oven | 통합 제어 | 높음 | 모터, 부저, 디스플레이 | 5상태 |

## 공통 기술 요소

### 입력 처리
- **버튼 디바운싱**: 10ms 안정화 처리
- **에지 검출**: 상승/하강 엣지 인식
- **펄스 생성**: 1클럭 펄스 신호

### 디스플레이 제어
- **7-segment**: 4자리 멀티플렉싱 (1ms 주기)
- **BCD 변환**: 이진수 → 10진수 표시
- **애니메이션**: 서클 패턴, 점멸 효과

### 타이밍 제어
- **클럭 분주**: 100MHz → 다양한 주파수
- **카운터**: 정밀한 시간 측정
- **FSM**: 상태 기반 제어

## 학습 가치

### 초급 (Pattern Detection)
- 기본 디지털 논리
- 시프트 레지스터
- 간단한 상태 제어

### 중급 (Clock, Vending Machine)
- FSM 설계
- 멀티플렉싱
- 실시간 처리

### 고급 (Microwave Oven)
- 복합 시스템 설계
- 하드웨어 인터페이스
- 안전 제어

## 개발 환경

### 공통 요구사항
- **FPGA 보드**: Xilinx BASYS-3
- **개발 도구**: Vivado Design Suite
- **언어**: Verilog HDL
- **클럭**: 100MHz 시스템 클럭

### 빌드 과정
1. Vivado 프로젝트 생성
2. 해당 프로젝트 `.v` 파일들 추가
3. 최상위 모듈 설정
4. 제약 파일(.xdc) 추가
5. Synthesis → Implementation → Generate Bitstream
6. BASYS-3 보드 프로그래밍

---

**개발 환경**: Xilinx Vivado | **타겟 보드**: BASYS-3 | **언어**: Verilog HDL

각 프로젝트는 독립적으로 실행 가능하며, 디지털 시스템 설계의 다양한 측면을 학습할 수 있습니다.