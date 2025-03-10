# DT-FMS - Node-RED Code Branch
Repository of the project for the Digital Twin of Flexible Manufactring Systems. This branch has all the necessary code for the Node-RED/OPC UA Application.

Instructions for intallation:

1. Install basic Node-RED (https://nodered.org/docs/getting-started/local), than the required libraries listed at Node-Red Libraries.txt
   
2. Configuration of the PLC I/O is listed on the file "s7endpoint_CLP Mestre.csv". There all variables and addresses are listed. For every update on the code a new version of this file may exist, in the case of addition of variables. In that case, delete all the entries on the PLC I/O Configuration and Import the new file;

3. Choose the version you want to use: V5.7.3 is without AAS and V6.2.2 is with ASS (still under development)
