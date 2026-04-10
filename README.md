# Carry Chain Logic Locking

## Authors: Jonathan Gerard and Tanmay Deshmukh

## Project Description
This project implements a Hardware Security Primitive designed to protect Intellectual Property (IP) through timing-based obfuscation. The design features a 16-bit synchronous logic lock that controls a 24-bit counter.

This design employs **Carry-Chain Poisoning**. If an incorrect key is provided, the counter's carry logic is XORed, causing the output frequency to shift to an unstable high-frequency state. This renders the functional stage useless to an unauthorized user while appearing to remain active.

## Logic Diagram
![Logic Diagram](docs/logic_diagram.png)

## How it Works
1. **Key Loading:** The system accepts a 16-bit serial key via `key_data` (ui[0]) synchronized by rising edges on `key_shift` (ui[1]).
2. **Comparison:** The internal shift register is compared against a hardcoded Master Key: `16'hA5C3`.
3. **Obfuscation States:**
   * **Unlocked:** `is_locked` drops to 0. The XOR gate becomes transparent, allowing the 1Hz blink to resume on `uo[1]`.
   * **Locked (Default):** `is_locked` remains 1. The carry signal is inverted via the XOR gate, forcing the functional counter to increment on nearly every clock cycle, creating a high-speed flicker.

## Transient Behavior during Key Entry
The device remains in a "Locked" state throughout the entire loading process. Because the 16-bit internal state is updated bit-by-bit, any state that does not exactly match `16'hA5C3` keeps the carry-chain poisoned. This ensures that the output remains scrambled and provides no "partial-match" feedback to an attacker while they are entering a key.

## Pinout Mapping
| Pin | Name | Description |
| :--- | :--- | :--- |
| ui[0] | key_data | Serial data bit for the 16-bit key. |
| ui[1] | key_shift | Trigger to shift in the data bit. |
| uo[0] | unlocked_led | High when the correct key is loaded. |
| uo[1] | blinker_output | Functional 1Hz blink (Unlocked) / High-freq noise (Locked). |
