# DT-FMS
Repository of the project "Production Control of Legacy Flexible Manufacturing Systems using Asset Administration Shell and Digital Twin".
This repository is organized as follows:
  The main branch contains files that are common to all projects. Folders in the main branch are of publications related to the project. 
  Codes are setup on Branches, to have individual contributions if necessary.

This repository contains several separete codes and informations regarding the project. There are four main codes: 

1. Node-RED - Responsible for the integration layer of the Legacy System and the technologies of Industry 4.0. There are 2 current version being used, one that uses AAS (V 6.1.2) and on that uses the old structure without AAS (V5.7.8) - (https://github.com/gasiepgodoy/DT-FMS/tree/Node-Red-Software)

2. Siemens S7 - Responsible for the programming of the individual stations and the conveyor. It includes the PROFIBUS and AS-i necessary codes to integrate all signals at the "Master PLC" that is resposible for communication with Node-RED. Current Version is V3.0.7 - (https://github.com/gasiepgodoy/DT-FMS/tree/Siemens-S7-300-Software)

3. AAS - the Asset administration Shell files resposible for the standardization of information structure. It contains the main .aasx file being used. Curent Version is V1.2. (https://github.com/gasiepgodoy/DT-FMS/tree/Asset-Administration-Shell)

4. State Transition Table Model - The digital model, made in State Transition Table, of the FMS stations. (https://github.com/gasiepgodoy/DT-FMS/tree/Digital-Model---State-Transtion-Table)
