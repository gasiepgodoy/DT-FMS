%
% Simulated tags of the Station Master [20]
%
SimActuators_20 = {
    "SA_20_Led_On","SA_20_Led_Off","SA_20_Conveyor","SA_24_Cart_Test","SA_25_Cart_Proc","SA_26_Cart_Visi","SA_27_Cart_Robo","SA_28_Cart_Stor","SA_29_Cart_Sort"
};
SimControl_20 = {
    "SC_21_MES_On","SC_24_Request","SC_24_CRoute_In","SC_24_CartDel","SC_24_CRoute_Out","SC_25_Request","SC_25_CRoute_In","SC_25_CartDel","SC_25_CRoute_Out","SC_26_Request","SC_26_CRoute_In","SC_26_CartDel","SC_26_CRoute_Out","SC_27_Request","SC_27_CRoute_In","SC_27_CartDel","SC_27_CRoute_Out","SC_28_Request","SC_28_CRoute_In","SC_28_CartDel","SC_28_CRoute_Out","SC_29_Request","SC_29_CRoute_In","SC_29_CartDel","SC_29_CRoute_Out"
};
SimSensors_20 = {
    "SS_20_On","SS_20_Off","SS_20_Controler_On","SS_24_Cart_Stat","SS_24_Cart_Next","SS_24_Optic","SS_24_Count","SS_24_Pist_Bck","SS_25_Cart_Stat","SS_25_Cart_Next","SS_25_Optic","SS_25_Count","SS_25_Pist_Bck","SS_26_Cart_Stat","SS_26_Cart_Next","SS_26_Optic","SS_26_Count","SS_26_Pist_Bck","SS_27_Cart_Stat","SS_27_Cart_Next","SS_27_Optic","SS_27_Count","SS_27_Pist_Bck","SS_28_Cart_Stat","SS_28_Cart_Next","SS_28_Optic","SS_28_Count","SS_28_Pist_Bck","SS_29_Cart_Stat","SS_29_Cart_Next","SS_29_Optic","SS_29_Count","SS_29_Pist_Bck"
};

Var_MAST_SIM = {SimActuators_20,SimControl_20,SimSensors_20};
Var_MAST_SIM_Names = ["SimActuators_20","SimControl_20","SimSensors_20"];

%
% Simulated tags of the Station Robot [30]
%
SimActuators_30 = {
    "SA_30_Led_Start","SA_30_Led_Reset","SA_30_Led_Extra1","SA_30_Led_Extra2","SA_30_Spring_Cyl","SA_30_Cover_Cyl"
};
SimASi_30 = {
    "SR_32_RoboCartID","SR_34_Request","SR_34_No_Cart","SR_34_Cart_Full","SR_34_CRoute_Out","SR_34_CRoute_In"
};
SimControl_30 = {
    "SC_30_Robot1","SC_30_Robot2","SC_35_Part_Del"
};
SimSensors_30 = {
    "SS_31_Start","SS_31_Stop","SS_31_Reset","SS_31_Part_in_Claw","SS_31_Orientation","SS_32_Sp_Cyl_Bck","SS_32_Sp_Cyl_Fwd","SS_32_Co_Cyl_Bck","SS_32_Co_Cyl_Fwd","SS_32_Sp_PickUp","SS_32_Co_PickUp","SS_32_CoMag_Empty"
};

%
% Simulated tags of RFID (Robot server)
%
SimRFID_RFID = {
    "SID_Ant1_R_TagID","SID_Ant1_R_UserData","SID_Ant1_W_TagID","SID_Ant1_W_UserData","SID_Ant2_R_TagID","SID_Ant2_R_UserData","SID_Ant2_W_TagID","SID_Ant2_W_UserData","SID_Ant3_R_TagID","SID_Ant3_R_UserData","SID_Ant3_W_TagID","SID_Ant3_W_UserData","SID_Ant4_R_TagID","SID_Ant4_R_UserData","SID_Ant4_W_TagID","SID_Ant4_W_UserData"
};

%
% Simulated tags of the Station Storage [40]
%
SimActuators_40 = {
    "SA_41_Led_Start","SA_41_Led_Reset","SA_41_Led_Extra1","SA_41_Led_Extra2","SA_41_Panel_O4","SA_41_Panel_O5","SA_41_Panel_O6","SA_41_Panel_O7"
};
SimASi_40 = {
    "SR_43_StorCartID","SR_44_Request","SR_44_No_Cart","SR_44_Cart_Full","SR_44_CRoute_Out","SR_44_CRoute_In"
};
SimControl_40 = {
    "SC_42_Profibus","SC_45_Initialization","SC_45_Start","SC_45_StorePart","SC_45_RetrievePart"
};
SimSensors_40 = {
    "SS_41_Start","SS_41_Stop","SS_41_Key_Pos","SS_41_Reset","SS_41_Panel_I4","SS_41_Panel_I5","SS_41_Panel_I6","SS_41_Panel_I7"
};

Var_NODE_SIM = {SimActuators_30,SimASi_30,SimControl_30,SimSensors_30,SimRFID_RFID,SimActuators_40,SimASi_40,SimControl_40,SimSensors_40};
Var_NODE_SIM_Names = ["SimActuators_30","SimASi_30","SimControl_30","SimSensors_30","SimRFID_RFID","SimActuators_40","SimASi_40","SimControl_40","SimSensors_40"];

%
% Simulated tags of the Station Handling 1 [50]
%
SimActuators_50 = {
    "SA_50_Claw_2_Del","SA_50_Claw_2_Cart","SA_50_Claw_Down","SA_50_Close_Claw","SA_51_Led_Start","SA_51_Led_Reset","SA_51_Led_Extra1","SA_51_Led_Extra2","SA_51_Panel_O4","SA_51_Panel_O5","SA_51_Panel_O6","SA_51_Panel_O7"
};
SimASi_50 = {
    "SR_53_SortCartID","SR_54_Request","SR_54_No_Cart","SR_54_Cart_Full","SR_54_CRoute_Out","SR_54_CRoute_In"
};
SimControl_50 = {
    "SC_52_Profibus","SC_55_Initialization","SC_55_Start","SC_55_PD_Sort","SC_55_Cart2Del"
};
SimSensors_50 = {
    "SS_50_Part_Reserve","SS_50_Claw_Cart","SS_50_Claw_Del","SS_50_Claw_Reserve","SS_50_Claw_Low","SS_50_Claw_High","SS_50_Part_in_Claw","SS_51_Start","SS_51_Stop","SS_51_Key_Pos","SS_51_Reset","SS_51_Panel_I4","SS_51_Panel_I5","SS_51_Panel_I6","SS_51_Panel_I7"
};

Var_HD1_SIM = {SimActuators_50,SimASi_50,SimControl_50,SimSensors_50};
Var_HD1_SIM_Names = ["SimActuators_50","SimASi_50","SimControl_50","SimSensors_50"];

%
% Simulated tags of the Station Sorting [60]
%
SimActuators_60 = {
    "SA_60_Conveyor","SA_60_P1","SA_60_P2","SA_60_Identify","SA_61_Led_Start","SA_61_Led_Reset","SA_61_Led_Extra1","SA_61_Led_Extra2","SA_61_Panel_O4","SA_61_Panel_O5","SA_61_Panel_O6","SA_61_Panel_O7"
};
SimControl_60 = {
    "SC_62_Profibus","SC_65_Initialization","SC_65_RBS_Output","SC_65_ID_1","SC_65_RSB_Output","SC_65_ID_2","SC_65_BRS_Output","SC_65_Part_Sorted","SC_65_BSR_Output","SC_65_SRB_Output","SC_65_SBR_Output"
};
SimSensors_60 = {
    "SS_60_SPart","SS_60_SInd","SS_60_SPhoto","SS_60_Part_Pass","SS_60_SL1_Bck","SS_60_SL1_Fwd","SS_60_SL2_Bck","SS_60_SL2_Fwd","SS_61_Start","SS_61_Stop","SS_61_Key_Pos","SS_61_Reset","SS_61_Panel_I4","SS_61_Panel_I5","SS_61_Panel_I6","SS_61_Panel_I7"
};

Var_SORT_SIM = {SimActuators_60,SimControl_60,SimSensors_60};
Var_SORT_SIM_Names = ["SimActuators_60","SimControl_60","SimSensors_60"];

%
% Simulated tags of the Station Testing [70]
%
SimActuators_70 = {
    "SA_70_Elev_Down","SA_70_Elev_Up","SA_70_Eject_Part","SA_70_Air_On","SA_71_Led_Start","SA_71_Led_Reset","SA_71_Led_Extra1","SA_71_Led_Extra2","SA_71_Panel_O4","SA_71_Panel_O5","SA_71_Panel_O6","SA_71_Panel_O7"
};
SimASi_70 = {
    "SR_73_TestCartID","SR_74_Request","SR_74_No_Cart","SR_74_Cart_Full","SR_74_CRoute_Out","SR_74_CRoute_In"
};
SimControl_70 = {
    "SC_72_Profibus","SC_75_Initialization","SC_75_RQ_Delivery1","SC_75_ID_Delivery1","SC_75_RQ_Delivery2","SC_75_ID_Delivery2","SC_75_Identified","SC_75_Part_Del","SC_75_Requested","SC_75_RQ_Part_Del","SC_75_RQ_Wrong","SC_75_Identified80","SC_75_Requested80"
};
SimSensors_70 = {
    "SS_70_SInductive","SS_70_SPart","SS_70_SStation","SS_70_SPart_Height","SS_70_Elev_High","SS_70_Elev_Low","SS_70_Pist_Bck","SS_71_Start","SS_71_Stop","SS_71_Key_Pos","SS_71_Reset","SS_71_Panel_I4","SS_71_Panel_I5","SS_71_Panel_I6","SS_71_Panel_I7"
};

Var_TEST_SIM = {SimActuators_70,SimASi_70,SimControl_70,SimSensors_70};
Var_TEST_SIM_Names = ["SimActuators_70","SimASi_70","SimControl_70","SimSensors_70"];

%
% Simulated tags of the Station Distribution [80]
%
SimActuators_80 = {
    "SA_80_Pist_Adv","SA_80_Suction_On","SA_80_Suction_Off","SA_80_Arm_2_Del","SA_80_Arm_2_Mag","SA_81_Led_Start","SA_81_Led_Reset","SA_81_Led_Extra1","SA_81_Led_Extra2","SA_81_Panel_O4","SA_81_Panel_O5","SA_81_Panel_O6","SA_81_Panel_O7"
};
SimControl_80 = {
    "SC_82_Profibus","SC_83_RQ_Parts","SC_85_Initialization","SC_85_Start","SC_85_Part_Del","SC_85_Single","SC_85_Part_Mag","SC_85_Continuous","SC_85_Counted","SC_86_Mag_Parts","SC_87_RQ_MParts"
};
SimSensors_80 = {
    "SS_80_Mag_Full","SS_80_Pist_Bck","SS_80_Pist_Fwd","SS_80_Part_Stuck","SS_80_Arm_Mag","SS_80_Arm_Del","SS_80_Mag_Empty","SS_81_Start","SS_81_Stop","SS_81_Key_Pos","SS_81_Reset","SS_81_Panel_I4","SS_81_Panel_I5","SS_81_Panel_I6","SS_81_Panel_I7"
};

Var_DIST_SIM = {SimActuators_80,SimControl_80,SimSensors_80};
Var_DIST_SIM_Names = ["SimActuators_80","SimControl_80","SimSensors_80"];

%
% Simulated tags of the Station Handling 2 [90]
%
SimActuators_90 = {
    "SA_90_Claw_2_Cart","SA_90_Claw_2_Del","SA_90_Claw_Down","SA_90_Close_Claw","SA_91_Led_Start","SA_91_Led_Reset","SA_91_Led_Extra1","SA_91_Led_Extra2","SA_91_Panel_O4","SA_91_Panel_O5","SA_91_Panel_O6","SA_91_Panel_O7"
};
SimASi_90 = {
    "SR_93_ProcCartID","SR_94_Request","SR_94_No_Cart","SR_94_Cart_Full","SR_94_CRoute_Out","SR_94_CRoute_In"
};
SimControl_90 = {
    "SC_92_Profibus","SC_95_Initialization","SC_95_Start","SC_95_PD_Proc","SC_95_Cart2Del","SC_95_PD_Cart","SC_95_Del2Cart"
};
SimSensors_90 = {
    "SS_90_Part_Reserve","SS_90_Claw_Del","SS_90_Claw_Cart","SS_90_Claw_Reserve","SS_90_Claw_Low","SS_90_Claw_High","SS_90_Part_in_Claw","SS_91_Start","SS_91_Stop","SS_91_Key_Pos","SS_91_Reset","SS_91_Panel_I4","SS_91_Panel_I5","SS_91_Panel_I6","SS_91_Panel_I7"
};

Var_HD2_SIM = {SimActuators_90,SimASi_90,SimControl_90,SimSensors_90};
Var_HD2_SIM_Names = ["SimActuators_90","SimASi_90","SimControl_90","SimSensors_90"];

%
% Simulated tags of the Station Processing [100]
%
SimActuators_100 = {
    "SA_100_Drill_On","SA_100_RT_On","SA_100_Drill_Down","SA_100_Drill_Up","SA_100_Drill_Pin","SA_100_Test_Pin","SA_101_Led_Start","SA_101_Led_Reset","SA_101_Led_Extra1","SA_101_Led_Extra2","SA_101_Panel_O4","SA_101_Panel_O5","SA_101_Panel_O6","SA_101_Panel_O7"
};
SimControl_100 = {
    "SC_102_Profibus","SC_103_RQ_Turns","SC_105_Initialization","SC_105_Start","SC_105_Part_ready","SC_105_Test","SC_105_Test_Ok","SC_105_TestDrill","SC_105_Test_Fail","SC_105_Rotation","SC_106_RT_Counter"
};
SimSensors_100 = {
    "SS_100_PInit_Pos","SS_100_PDrill_Pos","SS_100_PTest_Pos","SS_100_SDrill_High","SS_100_SDrill_Low","SS_100_RT_Sensor","SS_100_PTest_Ok","SS_101_Start","SS_101_Stop","SS_101_Key_Pos","SS_101_Reset","SS_101_Panel_I4","SS_101_Panel_I5","SS_101_Panel_I6","SS_101_Panel_I7"
};

Var_PROC_SIM = {SimActuators_100,SimControl_100,SimSensors_100};
Var_PROC_SIM_Names = ["SimActuators_100","SimControl_100","SimSensors_100"];

%
% Matrix with all simulated variables (same order as the OPC UA Write blocks)
%
AllVariablesSim = { ...
    Var_MAST_SIM, ...
    Var_NODE_SIM, ...
    Var_HD1_SIM, ...
    Var_SORT_SIM, ...
    Var_TEST_SIM, ...
    Var_DIST_SIM, ...
    Var_HD2_SIM, ...
    Var_PROC_SIM, ...
};
AllVariablesSimNames = { ...
    Var_MAST_SIM_Names, ...
    Var_NODE_SIM_Names, ...
    Var_HD1_SIM_Names, ...
    Var_SORT_SIM_Names, ...
    Var_TEST_SIM_Names, ...
    Var_DIST_SIM_Names, ...
    Var_HD2_SIM_Names, ...
    Var_PROC_SIM_Names, ...
};
