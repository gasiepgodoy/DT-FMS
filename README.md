# DT-FMS - SIEMENS S7 Code

Repository of the project for the Digital Twin of Flexible Manufactring Systems
Use SIMATIC SETP7 Version 5.6 SP2 for the sotware to proper run everything.

Current version: 3.2.1 from 24/09/2025

Program is based on the premise that all communication must go through the Main PLC that has the ethernet CPU. This forces all PROFIBUS variables to be mapped at that Master. System also has an AS-i network for the sensors and actuators of the main conveyor belt. These are mapped under address [20] as they are a parte of the "Master" of the PROFIBUS network. The remote I/O of the Robot station is mapped under address [30]. The details of the network are shown in the picture are below:

![image](https://github.com/user-attachments/assets/5e69164c-aa29-4623-8116-65cf2ca5179e)
