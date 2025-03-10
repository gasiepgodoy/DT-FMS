# DT-FMS - SIEMENS S7 Code

Repository of the project for the Digital Twin of Flexible Manufactring Systems

Use SIMATIC SETP7 Version 5.6 SP2 for the sotware to proper run everything.

Program is based on the premise that all communication must go through the Main PLC that has the ethernet CPU. This forces all PROFIBUS variables to be mapped at that Master. System also has an AS-i network for the sensors and actuators of the main conveyor belt. These are mapped under address [30] of the PROFIBUS network as well as the remote I/O of the Robot station. The details of the network are below:

![image](https://github.com/user-attachments/assets/8cc29822-14a0-470f-9abd-95e7756df787)
