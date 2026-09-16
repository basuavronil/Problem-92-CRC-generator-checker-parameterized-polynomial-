## CRC-8 Generator and Checker — Key Architecture Concepts
This design uses a right-shifting (LSB-first) LFSR based on the standard CRC-8 polynomial ($x^8 + x^2 + x^1 + 1).

### 1. Serial XOR Division & Remainder Accumulation
* **Bit-by-Bit Processing:** Incoming data bits stream into the module serially on successive clock cycles (`data_in`).
* **Polynomial Division:** On every clock tick, the incoming bit is XORed with the top register (`lfsr_reg[7]`) to perform binary polynomial long division in hardware.
* **Remainder Accumulation:** The intermediate division remainder continually shifts across the 8 internal LFSR flip-flops (`lfsr_reg[7:0]`). Once the last data bit is processed, the values trapped in these registers form the final **8-bit CRC checksum**.
* **Error Detection:** Transmitters append this 8-bit remainder to the end of the original data frame. When the receiver processes the combined **Data + CRC** stream through the same hardware, clean data will reduce the register contents to `8'h00` (`error_flag = 0`). Any non-zero value indicates bit corruption.

---

### 2. Operational Logic: `feedback` Signal Behavior
The calculation is governed by the 1-bit feedback wire:  
`feedback = data_in ^ lfsr_reg[7]`

* **When `feedback == 0` (Plain Shift):**  
  The polynomial divisor does not fit into the top bit. The LFSR acts as a standard shift register, sliding every bit left by 1 position ($X \oplus 0 = X$).
* **When `feedback == 1` (XOR Subtraction):**  
  The polynomial divisor fits. The shift register inverts/flips the bits at polynomial tap locations (**Registers 1 and 2**) while shifting ($X \oplus 1 = \text{NOT}(X)$), executing binary XOR subtraction in parallel.

---

### 3. Register Capacity & Serial Constraints
* **8-Bit Storage Capacity:** The module uses exactly 8 flip-flops (`lfsr_reg`), meaning it can only hold an 8-bit remainder state at any given instant.
* **Serial Streaming:** Data must enter sequentially—one bit per clock cycle—allowing the register chain to evaluate the running remainder over time without needing large parallel XOR trees.

### 4. Hardware Architecture: Right-Shift LFSR Block Diagram

In this right-shift configuration, data moves from left to right (`lfsr_reg[7]` down to `lfsr_reg[0]`). Incoming bits are XORed with the top register (`Reg 7`) to form the feedback signal, which enters directly at the MSB and drives the polynomial XOR taps as bits propagate down toward the LSB (`Reg 0`).

```text
 (MSB / LHS)                                                                             (LSB / RHS)
 +-------+    +-------+    +-------+    +-------+    +-------+    +-------+    +-------+    +-------+
 | Reg 7 |--->| Reg 6 |--->| Reg 5 |--->| Reg 4 |--->| Reg 3 |--->| Reg 2 |--->| Reg 1 |--->| Reg 0 |
 +---+---+    +-------+    +-------+    +-------+    +-------+    +---+---+    +---+---+    +-------+
     |                                                                ^            ^
     v                                                                |            |
  +-----+                                                          +-(+)-+      +-(+)-+
  | XOR |<--- data_in                                              | XOR |      | XOR |
  +--+--+                                                          +-----+      +-----+
     |                                                                ^            ^
     |                                                                |            |
     +----------------------------------------------------------------+------------+
                                  FEEDBACK WIRE: (data_in ^ Reg 7)

```
### 5. Output
#### Waveform 
<img width="958" height="229" alt="image" src="https://github.com/user-attachments/assets/9788fd63-970d-476e-a746-c30cb2afdf7f" />
#### Simulation terminal 
<img width="723" height="413" alt="image" src="https://github.com/user-attachments/assets/39bd2b02-197c-4404-b93b-45153f1ef600" />


## 6. Transmitter Side (`crc8_transmitter`)

* **Operation:** 
  Stream the raw message payload bits into `data_in` one bit per clock cycle while driving `data_valid` high.
* **Output:** 
  Once all data bits have been processed, the calculated CRC resides in `crc_out`.
* **Behavior:** 
  * `crc_out` will typically be a **non-zero 8-bit value**.
  * Append this 8-bit `crc_out` value to the end of your data payload before transmitting over the bus.
  * `error_flag` remains continuously tied to `1'b0` since error checking occurs on the receiver.

---

## 7. Receiver Side (`crc8_receiver`)

* **Operation:** 
  Stream the incoming raw message bits into `data_in`, **followed immediately by the 8 received CRC bits** (LSB first).
* **Output:** 
  Check the status of `error_flag` on the clock cycle immediately following the final CRC bit.
* **Behavior:** 
  * If the message was received without corruption, polynomial division cancels out the remainder, reducing `lfsr_reg` to `8'h00`.
  * `error_flag == 1'b0` (`lfsr_reg == 8'h00`): **Data clean / No error**.
  * `error_flag == 1'b1` (`lfsr_reg != 8'h00`): **Data corrupted / Error detected**.
