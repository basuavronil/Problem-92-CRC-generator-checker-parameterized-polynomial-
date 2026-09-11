## CRC-8 Generator and Checker — Key Architecture Concepts

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

### 4. Hardware Architecture: LFSR Block Diagram

The CRC-8 calculation is performed using a Linear Feedback Shift Register (LFSR). In this diagram, the Most Significant Bit (`lfsr[7]`) is on the left. Data shifts from right to left, while the 1-bit `feedback` signal runs across the bottom to drive the XOR taps for the polynomial $x^8 + x^2 + x^1 + 1$.

```text
 (MSB)                                                                                   (LSB)
 +-------+    +-------+    +-------+    +-------+    +-------+    +-------+    +-------+    +-------+
 | Reg 7 |<---| Reg 6 |<---| Reg 5 |<---| Reg 4 |<---| Reg 3 |<---| Reg 2 |<---| Reg 1 |<---| Reg 0 |<---+
 +-------+    +-------+    +-------+    +-------+    +-------+    +-------+    +-------+    +-------+   |
     |                                                                ^            ^            ^       |
     |                                                                |            |            |       |
     v                                                             +-(+)-+      +-(+)-+         |       |
 +-(+)-+                                                           | XOR |      | XOR |         |       |
 | XOR |<--- data_in                                               +-----+      +-----+         |       |
 +-----+                                                              |            |            |       |
     |                                                                |            |            |       |
     +----------------------------------------------------------------+------------+------------+-------+
                                     FEEDBACK WIRE: (data_in ^ Reg 7)
