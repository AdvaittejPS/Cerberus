The Three Heads of Cerberus
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

References
Simulation Credibility Assessment Methodology With FPGA-based Hardware-in-the-Loop Platform (IEEE TIE, 2021).
On the Implementation of IoT-Based Digital Twin for Networked Microgrids Resiliency Against Cyber Attacks
An Observer-Based Event Triggered Mechanism for the Detection and Mitigation of FDI Attacks in Deep Brain Stimulation Systems
False Data Injection Attacks Against Partial Sensor Measurements of Networked Control Systems
