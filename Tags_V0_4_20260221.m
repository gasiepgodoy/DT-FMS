%
% Tags of the Station Master [20]
%
Actuators_20 = {
    "F_22_Led_On","F_22_Led_Off","F_22_Conveyor","F_24_Release_FB","F_25_Release_FB","F_26_Release_FB","F_27_Release_FB","F_28_Release_FB","F_29_Release_FB",...
};
Control_20 = {
    "C_24_CartDel","C_24_CRoute_Out","C_24_Request","C_24_CRoute_In","C_25_CartDel","C_25_CRoute_Out","C_25_Request","C_25_CRoute_In","C_26_CartDel","C_26_CRoute_Out","C_26_Request","C_26_CRoute_In","C_27_CartDel","C_27_CRoute_Out","C_27_Request","C_27_CRoute_In","C_28_CartDel","C_28_CRoute_Out","C_28_Request","C_28_CRoute_In","C_29_CartDel","C_29_CRoute_Out","C_29_Request","C_29_CRoute_In"
};
Sensors_20 = {
    "O_20_On","O_20_Off","O_20_Controler_On","O_24_Cart_Stat","O_24_Cart_Next","O_24_Optic","O_24_Count","O_24_Pist_Bck","O_25_Cart_Stat","O_25_Cart_Next","O_25_Optic","O_25_Count","O_25_Pist_Bck","O_26_Cart_Stat","O_26_Cart_Next","O_26_Optic","O_26_Count","O_26_Pist_Bck","O_27_Cart_Stat","O_27_Cart_Next","O_27_Optic","O_27_Count","O_27_Pist_Bck","O_28_Cart_Stat","O_28_Cart_Next","O_28_Optic","O_28_Count","O_28_Pist_Bck","O_29_Cart_Stat","O_29_Cart_Next","O_29_Optic","O_29_Count","O_29_Pist_Bck"
};

Var_MAST = {Actuators_20,Control_20,Sensors_20};

%
% Tags of the Station Robot [30]
%
Actuators_30 = {
	"F_33_Led_Start","F_33_Led_Reset","F_33_Led_Extra1","F_33_Led_Extra2","F_33_Spring_Cyl","F_33_Cover_Cyl"
};
ASi_30 = {
	"A_34_Request","A_34_No_Cart","A_34_Cart_Full","A_34_CRoute_Out","A_32_RoboCartID","A_34_Cart_Stat","A_34_Cart_Next","A_34_Optic","A_34_Count","A_34_Pist_Bck","A_34_Release_FB","A_34_CRoute_In"
};
Control_30 = {
	"C_30_Robot1","C_30_Robot2","C_35_Part_Del"
};
Sensors_30 = {
	"O_31_Start","O_31_Stop","O_31_Reset","O_31_Part_in_Claw","O_31_Orientation","O_32_Sp_Cyl_Bck","O_32_Sp_Cyl_Fwd","O_32_Co_Cyl_Bck","O_32_Co_Cyl_Fwd","O_32_Sp_PickUp","O_32_Co_PickUp","O_32_CoMag_Empty"
};

%
% Tags of the Station Storage [40]
%
Actuators_40 = {
	"F_43_Led_Start","F_43_Led_Reset","F_43_Led_Extra1","F_43_Led_Extra2","F_43_Panel_O4","F_43_Panel_O5","F_43_Panel_O6","F_43_Panel_O7"
};
ASi_40 = {
	"A_44_Request","A_44_No_Cart","A_44_Cart_Full","A_44_CRoute_Out","A_43_StorCartID","A_44_Cart_Stat","A_44_Cart_Next","A_44_Optic","A_44_Count","A_44_Pist_Bck","A_44_Release_FB","A_44_CRoute_In"
};
Control_40 = {
	"C_45_Initialization","C_42_Profibus","C_45_Start",	"C_45_StorePart","C_45_RetrievePart",
};
Sensors_40 = {
	"O_41_Start","O_41_Stop","O_41_Key_Pos","O_41_Reset","O_41_Panel_I4","O_41_Panel_I5","O_41_Panel_I6","O_41_Panel_I7"
};

Var_NODE = {Actuators_30,ASi_30,Control_30,Sensors_30,Actuators_40,ASi_40,Control_40,Sensors_40};

%
% Tags of the Station Handling 1 [50]
%
Actuators_50 = {
    "F_52_Claw_2_Del","F_52_Claw_2_Cart","F_52_Claw_Down","F_52_Close_Claw","F_53_Led_Start","F_53_Led_Reset","F_53_Led_Extra1","F_53_Led_Extra2","F_53_Panel_O4","F_53_Panel_O5","F_53_Panel_O6","F_53_Panel_O7"
};
ASi_50 = {
	"A_54_Request","A_54_No_Cart","A_54_Cart_Full","A_54_CRoute_Out","A_53_SortCartID","A_54_Cart_Stat","A_54_Cart_Next","A_54_Optic","A_54_Count","A_54_Pist_Bck","A_54_Release_FB","A_54_CRoute_In"
};
Control_50 = {
    "C_55_Initialization","C_55_PD_Sort","C_52_Profibus","C_55_Start","C_55_Cart2Del"
};
Sensors_50 = {
    "O_50_Part_Reserve","O_50_Claw_Cart","O_50_Claw_Del","O_50_Claw_Reserve","O_50_Claw_Low","O_50_Claw_High","O_50_Part_in_Claw","O_51_Start","O_51_Stop","O_51_Key_Pos","O_51_Reset","O_51_Panel_I4","O_51_Panel_I5","O_51_Panel_I6","O_51_Panel_I7"
};

Var_HD1 = {Actuators_50,ASi_50,Control_50,Sensors_50};

%
% Tags of the Station Sorting [60]
%
Actuators_60 = {
    "F_62_Conveyor","F_62_P1","F_62_P2","F_62_Identify","F_63_Led_Start","F_63_Led_Reset","F_63_Led_Extra1","F_63_Led_Extra2","F_63_Panel_O4","F_63_Panel_O5","F_63_Panel_O6","F_63_Panel_O7"
};
Control_60 = {
    "C_65_Initialization","C_65_ID_1","C_65_ID_2","C_65_Part_Sorted","C_62_Profibus","C_65_RBS_Output","C_65_RSB_Output","C_65_BRS_Output","C_65_BSR_Output","C_65_SRB_Output","C_65_SBR_Output"
};
Sensors_60 = {
    "O_60_SPart","O_60_SInd","O_60_SPhoto","O_60_Part_Pass","O_60_SL1_Bck","O_60_SL1_Fwd","O_60_SL2_Bck","O_60_SL2_Fwd","O_61_Start","O_61_Stop","O_61_Key_Pos","O_61_Reset","O_61_Panel_I4","O_61_Panel_I5","O_61_Panel_I6","O_61_Panel_I7"
};
Var_SORT = {Actuators_60,Control_60,Sensors_60};

%
% Tags of the Station Testing [70]
%
Actuators_70 = {
    "F_72_Elev_Down","F_72_Elev_Up","F_72_Eject_Part","F_72_Air_On","F_73_Led_Start","F_73_Led_Reset","F_73_Led_Extra1","F_73_Led_Extra2","F_73_Panel_O4","F_73_Panel_O5","F_73_Panel_O6","F_73_Panel_O7"	
};
ASi_70 = {
    "A_74_Request","A_74_No_Cart","A_74_Cart_Full","A_74_CRoute_Out","A_74_CRoute_In80","A_73_TestCartID","A_74_Cart_Stat","A_74_Cart_Next","A_74_Optic","A_74_Count","A_74_Pist_Bck","A_74_Release_FB","A_74_CRoute_In",
};
Control_70 = {
    "C_75_Initialization","C_75_ID_Delivery1","C_75_ID_Delivery2","C_75_Part_Del","C_75_RQ_Part_Del","C_75_RQ_Wrong","C_75_Identified80","C_75_Requested80","C_72_Profibus","C_75_RQ_Delivery1","C_75_RQ_Delivery2","C_75_Identified","C_75_Requested"
};
Sensors_70 = {
    "O_70_SInductive","O_70_SPart","O_70_SStation","O_70_SPart_Height","O_70_Elev_High","O_70_Elev_Low","O_70_Pist_Bck","O_71_Start","O_71_Stop","O_71_Key_Pos","O_71_Reset","O_71_Panel_I4","O_71_Panel_I5","O_71_Panel_I6","O_71_Panel_I7"
};
Var_TEST = {Actuators_70,ASi_70,Control_70,Sensors_70};

%
% Tags of the Station Distribution [80]
%
Actuators_80 = {
    "F_82_Pist_Adv","F_82_Suction_On","F_82_Suction_Off","F_82_Arm_2_Del","F_82_Arm_2_Mag","F_83_Led_Start","F_83_Led_Reset","F_83_Led_Extra1","F_83_Led_Extra2","F_83_Panel_O4","F_83_Panel_O5","F_83_Panel_O6","F_83_Panel_O7"
};
Control_80 = {
    "C_85_Initialization","C_85_Part_Del","C_85_Part_Mag","C_86_Mag_Parts","C_87_RQ_MParts","C_82_Profibus","C_83_RQ_Parts","C_85_Start","C_85_Single","C_85_Continuous","C_85_Counted"
};
Sensors_80 = {
    "O_80_Mag_Full","O_80_Pist_Bck","O_80_Pist_Fwd","O_80_Part_Stuck","O_80_Arm_Mag","O_80_Arm_Del","O_80_Mag_Empty","O_81_Start","O_81_Stop","O_81_Key_Pos","O_81_Reset","O_81_Panel_I4","O_81_Panel_I5","O_81_Panel_I6","O_81_Panel_I7"
};
Var_DIST = {Actuators_80,Control_80,Sensors_80};


%
% Tags of the Station Handling 2 [90]
%
Actuators_90 = {
    "F_92_Claw_2_Cart","F_92_Claw_2_Del","F_92_Claw_Down","F_92_Close_Claw","F_93_Led_Start","F_93_Led_Reset","F_93_Led_Extra1","F_93_Led_Extra2","F_93_Panel_O4","F_93_Panel_O5","F_93_Panel_O6","F_93_Panel_O7"
};
ASi_90 = {
    "A_94_Request","A_94_No_Cart","A_94_Cart_Full","A_94_CRoute_Out","A_93_ProcCartID","A_94_Cart_Stat","A_94_Cart_Next","A_94_Optic","A_94_Count","A_94_Pist_Bck","A_94_Release_FB","A_94_CRoute_In"
};
Control_90 = {
    "C_95_Initialization","C_95_PD_Proc","C_95_PD_Cart","C_92_Profibus","C_95_Start","C_95_Cart2Del","C_95_Del2Cart"
};
Sensors_90 = {
    "O_90_Part_Reserve","O_90_Claw_Del","O_90_Claw_Cart","O_90_Claw_Reserve","O_90_Claw_Low","O_90_Claw_High","O_90_Part_in_Claw","O_91_Start","O_91_Stop","O_91_Key_Pos","O_91_Reset","O_91_Panel_I4","O_91_Panel_I5","O_91_Panel_I6","O_91_Panel_I7"
};
Var_HD2 = {Actuators_90,ASi_90,Control_90,Sensors_90};

%
% Tags of the Station Processing [100]
%
Actuators_100 = {
    "F_102_Drill_On","F_102_RT_On","F_102_Drill_Down","F_102_Drill_Up","F_102_Drill_Pin","F_102_Test_Pin","F_103_Led_Start","F_103_Led_Reset","F_103_Led_Extra1","F_103_Led_Extra2","F_103_Panel_O4","F_103_Panel_O5","F_103_Panel_O6","F_103_Panel_O7"
};
Control_100 = {
    "C_105_Initialization","C_105_Part_ready","C_105_Test_Ok","C_105_Test_Fail","C_106_RT_Counter","C_102_Profibus","C_103_RQ_Turns","C_105_Start","C_105_Test","C_105_TestDrill","C_105_Rotation"
};
Sensors_100 = {
    "O_100_PInit_Pos","O_100_PDrill_Pos","O_100_PTest_Pos","O_100_SDrill_High","O_100_SDrill_Low","O_100_RT_Sensor","O_100_PTest_Ok","O_101_Start","O_101_Stop","O_101_Key_Pos","O_101_Reset","O_101_Panel_I4","O_101_Panel_I5","O_101_Panel_I6","O_101_Panel_I7"
};
Var_PROC = {Actuators_100,Control_100,Sensors_100};


%
% Creates the Matriz with all variables
%

AllVariables = { ...
    Var_MAST, ...
    Var_NODE, ...
    Var_HD1, ...
    Var_SORT, ...
    Var_TEST, ...
    Var_DIST, ...
    Var_HD2, ...
    Var_PROC ...
};

save('Tags_OPCUA.mat', 'AllVariables')