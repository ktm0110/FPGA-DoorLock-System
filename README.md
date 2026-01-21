# FPGA DoorLock System
A digital door lock system implemented on FPGA using Verilog HDL.

## 프로젝트 개요 (Project Overview)

이 프로젝트는 **FPGA(Verilog HDL)**를 활용하여 구현한 **보안 강화형 스마트 도어락 시스템**이다.
단순한 비밀번호 입력 기능을 넘어, 기계식 버튼의 노이즈 제거(Debouncing), 오토 락(Auto-lock), 그리고 3회 오류 시 시스템을 마비시키는 **Freeze 보안 기능**까지 포함된 완성형 임베디드 시스템 설계 프로젝트이다.

---

[![Video Label](http://img.youtube.com/vi/BCqgMWNaQ3E/0.jpg)](https://youtu.be/BCqgMWNaQ3E)
click to watch video

## 주요 기능 (Key Features)

### 1. 패스워드 입력 및 검증

* **기본 비밀번호:** `1-2-3-4`
* **FND 디스플레이:** 입력 시 숫자가 노출되지 않도록 `____`에서 `0000`으로 마스킹 처리하여 표시.
* **LCD 상태 표시:** `ENTER PASSWORD`, `OPEN`, `FREEZE` 등 현재 상태를 직관적으로 텍스트로 출력.

### 2. 자동 개폐 시스템 (Auto-Lock)

* 비밀번호 일치 시(`OPEN`), 스텝 모터가 자동으로 **[문 열림(좌회전) → 대기 → 문 잠김(우회전)]** 동작을 수행.
* **Handshake 프로토콜:** 모터 동작이 물리적으로 완료된 후 FSM(제어부)에 신호를 보내 초기화함으로써, 중복 실행이나 타이밍 오류 방지.

### 3. 보안 Freeze 모드 (Anti-Hacking)

* 비밀번호 **3회 연속 오류 시** 즉시 시스템이 **8초간 동결(Freeze)**.
* **시각 효과:** 8개의 LED가 모두 켜진 뒤, 1초마다 하나씩 꺼지며 카운트다운(Active Low 제어).
* **청각 효과:** 부저(Piezo)를 통해 경고음(`삑- 삑-`) 송출.
* Freeze 시간 동안에는 어떠한 키 입력도 받지 않음.

### 4. 시청각 피드백 (Buzzer & LED)

* **성공 시:** "도-미-솔-도(High)" 멜로디 출력.
* **경고 시:** 단속적인 경고음 출력.
* **입력 안정화:** 10ms 샘플링 필터를 적용하여 버튼의 채터링(Chattering) 현상 완벽 제거.

---

## 시스템 구조 (System Architecture)

이 시스템은 최상위 모듈인 `top.v`를 중심으로 제어부(Control)와 구동부(Drive)로 나뉜다.

> `![System Hierarchy](./images/hierarchy.png)`

### 모듈 설명 (Module Description)

| 모듈명 | 역할 | 설명 |
| --- | --- | --- |
| **`top.v`** | **System Top** | 전체 시스템 통합, PLL 클럭 생성, 10ms 디바운싱(Debouncing) 필터 내장, 모듈 간 신호 연결. |
| **`password_fsm.v`** | **Main Control** | 시스템의 두뇌. 비밀번호 비교, 상태 전이(Idle/Open/Freeze), 8초 타이머 및 LED 제어 담당. |
| **`door_lock_motor.v`** | **Actuator** | 스텝 모터 시퀀서. Open 신호를 받으면 정해진 각도로 회전 후 복귀하며, 완료 시 `Done` 신호를 보냄. |
| **`buzzer_ctrl.v`** | **Sound** | 상황별 주파수 생성기. Open 시 멜로디, Freeze 시 경고음을 생성. |
| **`textlcd.v`** | **Display 1** | 16x2 Character LCD 드라이버. 현재 상태에 맞는 문자열 출력. |
| **`fnd_display.v`** | **Display 2** | 7-Segment 제어. 입력된 키의 개수 및 마스킹 처리 표시. |

---

## 하드웨어 연결 (Pin Constraint)

*사용하는 FPGA 보드에 따라 `top.ucf` 파일의 핀 번호는 다를 수 있다.*

* **CLK:** 12MHz (Internal PLL -> 24MHz)
* **KEY Input:** 4x4 Matrix Keypad (or Tact Switch)
* **Actuators:** Stepper Motor (4-phase), Piezo Buzzer
* **Displays:** Text LCD, 7-Segment (FND), 8x LEDs

---

## 동작 시나리오 (Operation Flow)

1. **초기 상태 (Idle):**
* LCD: `ENTER PASSWORD`
* FND: `____`
* LED/Buzzer: OFF


2. **비밀번호 입력:**
* 키패드 입력 시 FND에 `0`이 하나씩 채워짐.
* LCD에 `KEY VALUE : [숫자]` 표시 (Latch 기능으로 마지막 입력값 유지).


3. **잠금 해제 (Success):**
* `1-2-3-4` 입력 성공.
* LCD: `OPEN`
* Buzzer: 멜로디 연주
* Motor: 좌회전(열림) -> 1초 대기 -> 우회전(닫힘) -> **자동 초기화**.


4. **보안 모드 (Failure & Freeze):**
* 비밀번호 3회 오류 발생.
* LCD: `!! FREEZE !!` / `TRY LATER`
* LED: 8개 점등 후 1초마다 하나씩 소등 (8초 카운트다운).
* Buzzer: 경고음 발생
* 8초 후 자동으로 초기 상태 복귀.



---

## 개발 환경 (Environment)

* **OS:** Windows 11
* **IDE:** Xilinx ISE Design Suite 14.7
* **Language:** Verilog HDL
* **Simulation:** ISim

---

## License

This project is for educational purposes.
