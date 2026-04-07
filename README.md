<img width="1919" height="1134" alt="image" src="https://github.com/user-attachments/assets/2bcfe9cb-c27f-4f1a-805d-6bcab2bd5d02" />

## The Three Heads of Cerberus
1. Identity Layer: RO-PUF Gatekeeper
  - Module: ro_puf.v
  - Function: Utilizes a Ring Oscillator Physical Unclonable Function (RO-PUF) to generate a hardware-intrinsic fingerprint.
  - Acts as a cryptographic gatekeeper, ensuring only authenticated microcontrollers can issue commands to the motor drive.
2. Mitigation Layer: Physics-Based Digital Twin
  - Module: hil_defense.v
  - Function: Executes a real-time, Q16.16 fixed-point state-space model ($x[k+1] = Ax[k] + Bu[k]$) of the actuator physics.
  - Detects anomalies by calculating the Residual between reported sensor data and physical possibility. In the event of an attack, it instantly masks the compromised sensor and provides clean, estimated data to the controller.
3. Forensic Layer: Sliding Mode Observer (SMO)
  - Module: hil_defense.v (integrated)
  - Function: Reconstructs the magnitude of injected False Data Injection (FDI) signals ($\hat{\alpha}$) for post-attack diagnostics.
  - Features a Linear Boundary Layer using arithmetic right-shifts (>>> 3) to eliminate high-frequency chattering without the silicon overhead of complex calculus.
  - Provides a forensic timeline of exactly how much drift or ramp a hacker injected into the system.

## Project Limitations and Future Scope
1. PUF Reliability and Environmental Noise
  - Current Limitation: The current Ring Oscillator PUF implementation proves uniqueness (inter-chip variation) but assumes perfect reliability. In real-world deployments, RO-PUF frequencies are highly susceptible to thermal fluctuations and voltage degradation (aging), which can cause bit-flips in the response and lead to false authentication failures.
  - Future Work: Future iterations must integrate Error Correction Codes (ECC), such as Hamming or Bose-Chaudhuri-Hocquenghem (BCH) codes, or a Fuzzy Extractor to stabilize the PUF response against environmental noise before cryptographic hashing.
2. Susceptibility to 'Perfect' Stealthy Attacks
  - Current Limitation: The Digital Twin effectively mitigates standard False Data Injection (FDI) drift and Denial of Service (DoS) attacks by monitoring the residual. However, it is theoretically vulnerable to "Zero-Dynamics" or perfect stealthy attacks. If an attacker possesses perfect knowledge of the system's state-space matrices ($A$, $B$, $C$), they can inject an attack vector that perfectly mimics the expected system dynamics, keeping the residual at zero and bypassing the threshold detector.
  - Future Work: To counter stealthy attacks, Active Physical Watermarking should be implemented. This involves injecting a hidden, pseudo-random high-frequency noise signal into the motor voltage and verifying its echo in the sensor feedback.
3. Hardcoded Static Thresholding
  - Current Limitation: The anomaly detection mechanism relies on a static, hardcoded threshold (THRESHOLD = 32'd327680; // 5.0 rad/s). In industrial environments, sudden mechanical load changes, bearing wear, or sensor noise can cause temporary residual spikes, leading to "False Positives" where the system assumes it is under attack.
  - Future Work: The static threshold should be replaced with an Adaptive Statistical Threshold (e.g., CUSUM algorithm) or a lightweight machine learning anomaly detector that dynamically adjusts the threshold based on the motor's real-time operating noise floor.
4. Linearization of Non-Linear Physics
  - Current Limitation: The state-space matrices used in the Q16.16 Digital Twin represent a linearized model of the motor physics. Real-world actuators exhibit severe non-linearities, such as magnetic core saturation, dead-time effects in the inverter, and nonlinear stiction/friction.
  - Future Work: Over time, these unmodeled dynamics could cause the Digital Twin's prediction to drift from the physical motor. Future models should incorporate piecewise-linear models or an Extended Kalman Filter (EKF) to better track non-linear regions.
5. Q16.16 Quantization Errors in Extreme Scenarios
  - Current Limitation: While the 32-bit Q16.16 fixed-point arithmetic achieved a 95.64% computational fidelity, the 4.36% error represents quantization noise. In highly dynamic, high-RPM scenarios, fixed-point truncation can lead to integrator windup or slight deviations in the Sliding Mode Observer's forensic tracking.
  - Future Work: A dynamic radix point (floating-point alternative like block floating-point) or increasing the word length to 64-bit fixed-point (Q32.32) could be explored for systems requiring aerospace-grade precision.
6. Shared Silicon Vulnerability (Hardware Fault Injection)
  - Current Limitation: Currently, the motor controller, the PUF, and the Digital Twin all share the same clock tree and FPGA silicon fabric. A physical attacker with localized access could use Clock Glitching, Voltage Fault Injection, or Laser Fault Injection to disrupt the FPGA fabric, simultaneously taking down both the primary controller and the Digital Twin defense.
  - Future Work: True physical isolation requires running the Digital Twin on an isolated power and clock domain, or utilizing a heterogeneous SoC architecture (e.g., placing the controller on an ARM core and the Twin on isolated programmable logic) with anti-tamper meshes.

## References
Simulation Credibility Assessment Methodology With FPGA-based Hardware-in-the-Loop Platform (IEEE TIE, 2021).
On the Implementation of IoT-Based Digital Twin for Networked Microgrids Resiliency Against Cyber Attacks
An Observer-Based Event Triggered Mechanism for the Detection and Mitigation of FDI Attacks in Deep Brain Stimulation Systems
False Data Injection Attacks Against Partial Sensor Measurements of Networked Control Systems
