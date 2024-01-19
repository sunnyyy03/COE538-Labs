;********************************************************************************************
;**                                 COE538 Project                                         **
;********************************************************************************************
;**         By   : Sanchit Das, Nithursan Jeyabalasingam, Sebastian D'Costa                **
;**         Date : November 28, 2023                                                       **
;********************************************************************************************

            XDEF Entry, _Startup                
            ABSENTRY Entry                      

		INCLUDE 'derivative.inc' 


;EQUATES                                                                                  
;********************************************************************************************

LCD_DAT         EQU   PORTB                     
LCD_CNTR        EQU   PTJ                       
LCD_E           EQU   $80                       
LCD_RS          EQU   $40                       

PTH_A_INT       EQU   $C0                       
PTH_C_INT       EQU   $CA                       
PTH_D_INT       EQU   $CA                       

PTH_E_INT       EQU   $60                      
PTH_F_INT       EQU   $75                       

INC_DIS         EQU   300                       
FWD_DIS         EQU   500                      
REV_DIS         EQU   1000                      
STR_DIS         EQU   1000                      
TRN_DIS         EQU   13000                      
UTRN_DIS        EQU   12000                     

PRI_PTH_INT     EQU   0                         
SEC_PTH_INT     EQU   1                         

START           EQU   0                         
FWD             EQU   1                         
REV             EQU   2                         
RT_TRN          EQU   3                         
LT_TRN          EQU   4                         
BK_TRK          EQU   5                         
SBY             EQU   6                         

;* VARIABLES                                                                                
;********************************************************************************************

                ORG   $3850
                
CRNT_STATE      DC.B  6                         

COUNT1          DC.W  0                         
COUNT2          DC.W  0                         

A_DETN          DC.B  0                         
B_DETN          DC.B  0                         
C_DETN          DC.B  0                         
D_DETN          DC.B  0                         
E_DETN          DC.B  0                         
F_DETN          DC.B  0                         

RETURN          DC.B  0                         
NEXT_D          DC.B  1                         

TEN_THOUS       DS.B  1                         
THOUSANDS       DS.B  1                         
HUNDREDS        DS.B  1                         
TENS            DS.B  1                         
UNITS           DS.B  1                         
BCD_SPARE       DS.B  10
NO_BLANK        DS.B  1                         

SENSOR_LINE     DC.B  $0                        
SENSOR_BOW      DC.B  $0                        
SENSOR_PORT     DC.B  $0                        
SENSOR_MID      DC.B  $0                        
SENSOR_STBD     DC.B  $0                        
SENSOR_NUM      DS.B  1                         
TEMP            DS.B  1                         


;* CODE                                                                                     
;********************************************************************************************

                ORG   $4000                     
Entry:                                                                                     
_Startup:                                                                                  
                LDS   #$4000                                  
                                                                                           
                JSR   initPORTS                                                           
                                                                                           
                JSR   initAD                                      
                                                                                          
                JSR   initLCD                                          
                JSR   clrLCD                                       
                                                                                         
                JSR   initTCNT                                        
                                                                                           
                CLI                                                      
                                                                                           
                LDX   #msg1                                                   
                JSR   putsLCD                                                           
                                                                                           
                LDAA  #$8A                              
                JSR   cmd2LCD                                                          
                LDX   #msg2                                                  
                JSR   putsLCD                                                         
                                                                                          
                LDAA  #$C0                                
                JSR   cmd2LCD                                                           
                LDX   #msg3                                                   
                JSR   putsLCD                                                          
                                                                                          
                LDAA  #$C7                             
                JSR   cmd2LCD                                                         
                LDX   #msg4                                                   
                JSR   putsLCD                                                           
                                                             

                                                
          MAIN: JSR   UPDT_READING                                                         
                JSR   UPDT_DISPL                                                           
                LDAA  CRNT_STATE                                                           
                JSR   DISPATCHER                                                           
                BRA   MAIN                                                                
                                                

;* DATA                                                                                     
;********************************************************************************************

          msg1: dc.b  "S:",0                    
          msg2: dc.b  "R:",0                    
          msg3: dc.b  "V:",0                    
          msg4: dc.b  "B:",0                    
          
           tab: dc.b  "START  ",0               
                dc.b  "FWD    ",0               
                dc.b  "REV    ",0               
                dc.b  "RT_TRN ",0               
                dc.b  "LT_TRN ",0               
                dc.b  "RETURN ",0               
                dc.b  "STANDBY",0               

;* SUBROUTINE                                                                               
;********************************************************************************************

STARON          BSET  PTT,%00100000
                RTS

STAROFF         BCLR  PTT,%00100000
                RTS

STARFWD         BCLR  PORTA,%00000010
                RTS

STARREV         BSET  PORTA,%00000010
                RTS

PORTON          BSET  PTT,%00010000
                RTS

PORTOFF         BCLR  PTT,%00010000
                RTS

PORTFWD         BCLR  PORTA,%00000001
                RTS

PORTREV         BSET  PORTA,%00000001
                RTS

;* STATES                                                                                   
;********************************************************************************************

DISPATCHER      CMPA  #START                    
                BNE   NOT_START                                                            
                JSR   START_ST                  
                RTS                             

NOT_START       CMPA  #FWD                      
                BNE   NOT_FORWARD                                                          
                JMP   FWD_ST                                  
                                           
NOT_FORWARD     CMPA  #RT_TRN                            
                BNE   NOT_RT_TRN                                                           
                JSR   RT_TRN_ST                            
                RTS                                                               
                                           
NOT_RT_TRN      CMPA  #LT_TRN                            
                BNE   NOT_LT_TRN                                                           
                JSR   LT_TRN_ST                                
                RTS                                                               
                                           
NOT_LT_TRN      CMPA  #REV                                  
                BNE   NOT_REVERSE                                                          
                JSR   REV_ST                                  
                RTS                                                               
                                           
NOT_REVERSE     CMPA  #BK_TRK                             
                BNE   NOT_BK_TRK                                                           
                JMP   BK_TRK_ST                            
                                           
NOT_BK_TRK      CMPA  #SBY                                  
                BNE   NOT_SBY                                                              
                JSR   SBY_ST                                  
                RTS                                                               
                                           
NOT_SBY         NOP                                 
DISP_EXIT       RTS                             

START_ST        BRCLR PORTAD0,$04,NO_FWD        
                JSR   INIT_FWD                  
                MOVB  #FWD,CRNT_STATE           
                BRA   START_EXIT                
                                                
NO_FWD          NOP                             
START_EXIT      RTS                           	

FWD_ST          PULD                            
                BRSET PORTAD0,$04,NO_FWD_BUMP   
                LDAA  SEC_PTH_INT               
                STAA  NEXT_D                    
                JSR   INIT_REV                  
                MOVB  #REV,CRNT_STATE           
                JMP   FWD_EXIT                  
              
NO_FWD_BUMP     BRSET PORTAD0,$08,NO_REV_BUMP    
                JMP   INIT_BK_TRK               
                MOVB  #BK_TRK,CRNT_STATE        
                JMP   FWD_EXIT                  

NO_REV_BUMP     LDAA  D_DETN                    
                BEQ   NO_RT_INTXN               
                LDAA  NEXT_D                     
                PSHA                            
                LDAA  PRI_PTH_INT               
                STAA  NEXT_D                    
                JSR   INIT_RT_TRN               
                MOVB  #RT_TRN,CRNT_STATE        
                JMP   FWD_EXIT                  

NO_RT_INTXN     LDAA  B_DETN                    
                BEQ   NO_LT_INTXN               
                LDAA  A_DETN                    
                BEQ   LT_TURN                   
                LDAA  NEXT_D                    
                PSHA                            
                LDAA  PRI_PTH_INT               
                STAA  NEXT_D                    
                BRA   NO_SHFT_LT                
LT_TURN         LDAA  NEXT_D                    
                PSHA                            
                LDAA  SEC_PTH_INT               
                STAA  NEXT_D                    
                JSR   INIT_LT_TRN               
                MOVB  #LT_TRN,CRNT_STATE        
                JMP   FWD_EXIT                  

NO_LT_INTXN     LDAA  F_DETN                    
                BEQ   NO_SHFT_RT                
                JSR   PORTON                    
RT_FWD_DIS      LDD   COUNT2                    
                CPD   #INC_DIS                  
                BLO   RT_FWD_DIS                
                JSR   INIT_FWD                  
                JMP   FWD_EXIT                  

NO_SHFT_RT      LDAA  E_DETN                    
                BEQ   NO_SHFT_LT                
                JSR   STARON                    
LT_FWD_DIS      LDD   COUNT1                    
                CPD   #INC_DIS                  
                BLO   LT_FWD_DIS                
                JSR   INIT_FWD                  
                JMP   FWD_EXIT                 

NO_SHFT_LT      JSR   STARON                  
                JSR   PORTON                 
FWD_STR_DIS     LDD   COUNT1                 
                CPD   #FWD_DIS                 
                BLO   FWD_STR_DIS             
                JSR   INIT_FWD                  
                
FWD_EXIT        JMP   MAIN                      

REV_ST          LDD   COUNT1                    
                CPD   #REV_DIS                 
                BLO   REV_ST                    
                JSR   STARFWD                   
                LDD   #0                        
                STD   COUNT1                    
                
REV_U_TRN       LDD   COUNT1                    
                CPD   #UTRN_DIS                 
                BLO   REV_U_TRN                 
                JSR   INIT_FWD                
                LDAA  RETURN                  
                BNE   BK_TRK_REV                
                MOVB  #FWD,CRNT_STATE          
                BRA   REV_EXIT                  
BK_TRK_REV      JSR   INIT_FWD                 
                MOVB  #BK_TRK,CRNT_STATE      
               
REV_EXIT        RTS                           

RT_TRN_ST       LDD   COUNT2                    
                CPD   #STR_DIS                  
                BLO   RT_TRN_ST                 
                JSR   STAROFF                   
                LDD   #0                     
                STD   COUNT2                   
                
RT_TURN_LOOP    LDD   COUNT2                 
                CPD   #TRN_DIS               
                BLO   RT_TURN_LOOP           
                JSR   INIT_FWD                
                LDAA  RETURN                 
                BNE   BK_TRK_RT_TRN         
                MOVB  #FWD,CRNT_STATE          
                BRA   RT_TRN_EXIT               
BK_TRK_RT_TRN   MOVB  #BK_TRK,CRNT_STATE      
            
RT_TRN_EXIT     RTS                          

LT_TRN_ST       LDD   COUNT1                    
                CPD   #STR_DIS                  
                BLO   LT_TRN_ST               
                JSR   PORTOFF                
                LDD   #0                        
                STD   COUNT1                    
                
LT_TURN_LOOP    LDD   COUNT1                    
                CPD   #TRN_DIS                  
                BLO   LT_TURN_LOOP            
                JSR   INIT_FWD                  
                LDAA  RETURN                     
                BNE   BK_TRK_LT_TRN             
                MOVB  #FWD,CRNT_STATE           
                BRA   LT_TRN_EXIT               
BK_TRK_LT_TRN   MOVB  #BK_TRK,CRNT_STATE        

LT_TRN_EXIT     RTS                             

BK_TRK_ST       PULD                            
                BRSET PORTAD0,$08,NO_BK_BUMP    
                JSR   INIT_SBY                  
                MOVB  #SBY,CRNT_STATE           
                JMP   BK_TRK_EXIT               

NO_BK_BUMP      LDAA  NEXT_D                    
                BEQ   REG_PATHING               
                BNE   IRREG_PATHING             

REG_PATHING     LDAA  D_DETN                    
                BEQ   NO_RT_TRN                
                PULA                          
                PULA                        
                STAA  NEXT_D               
                JSR   INIT_RT_TRN               
                MOVB  #RT_TRN,CRNT_STATE        
                JMP   BK_TRK_EXIT              

NO_RT_TRN       LDAA  B_DETN                 
                BEQ   RT_LINE_S             
                LDAA  A_DETN                    
                BEQ   LEFT_TURN               
                PULA                        
                PULA                         
                STAA  NEXT_D                 
                BRA   NO_LINE_S               
LEFT_TURN       PULA                           
                PULA                           
                STAA  NEXT_D                    
                JSR   INIT_LT_TRN               
                MOVB  #LT_TRN,CRNT_STATE    
                JMP   BK_TRK_EXIT               

IRREG_PATHING   LDAA  B_DETN                  
                BEQ   NO_LT_TRN                 
                PULA                            
                STAA  NEXT_D                  
                JSR   INIT_LT_TRN            
                MOVB  #LT_TRN,CRNT_STATE    
                JMP   BK_TRK_EXIT              

NO_LT_TRN       LDAA  D_DETN                 
                BEQ   RT_LINE_S              
                LDAA  A_DETN                  
                BEQ   RIGHT_TURN              
                PULA                           
                STAA  NEXT_D                
                BRA   NO_LINE_S             
RIGHT_TURN      PULA                           
                STAA  NEXT_D                    
                JSR   INIT_RT_TRN               
                MOVB  #RT_TRN,CRNT_STATE        
                JMP   BK_TRK_EXIT               

RT_LINE_S       LDAA  F_DETN                    
                BEQ   LT_LINE_S                 
                JSR   PORTON                    
RT_FWD_D        LDD   COUNT2                    
                CPD   #INC_DIS                  
                BLO   RT_FWD_D                  
                JSR   INIT_FWD                  
                JMP   BK_TRK_EXIT               

LT_LINE_S       LDAA  E_DETN                    
                BEQ   NO_LINE_S                 
                JSR   STARON                    
LT_FWD_D        LDD   COUNT1                    
                CPD   #INC_DIS                  
                BLO   LT_FWD_D                  
                JSR   INIT_FWD                  
                JMP   BK_TRK_EXIT               

NO_LINE_S       JSR   STARON                    
                JSR   PORTON                    
FWD_STR_D       LDD   COUNT1                    
                CPD   #FWD_DIS                  
                BLO   FWD_STR_D                 
                JSR   INIT_FWD                  
                
BK_TRK_EXIT     JMP   MAIN                      

SBY_ST          BRSET PORTAD0,$04,NO_START      
                BCLR  PTT,%00110000             
                MOVB  #START,CRNT_STATE         
                BRA   SBY_EXIT                  
                                                
NO_START        NOP                             
SBY_EXIT        RTS                             

;* STATE INITIALIZATION                                                                     
;********************************************************************************************

INIT_FWD        BCLR  PTT,%00110000             
                LDD   #0                        
                STD   COUNT1                    
                STD   COUNT2                    
                BCLR  PORTA,%00000011           
                RTS

INIT_REV        BSET  PORTA,%00000011           
                LDD   #0                        
                STD   COUNT1                    
                BSET  PTT,%00110000             
                RTS

INIT_RT_TRN     BCLR  PORTA,%00000011           
                LDD   #0                        
                STD   COUNT2                    
                BSET  PTT,%00110000             
                RTS

INIT_LT_TRN     BCLR  PORTA,%00000011           
                LDD   #0                        
                STD   COUNT1                    
                BSET  PTT,%00110000             
                RTS

INIT_BK_TRK     INC   RETURN                    
                PULA                            
                STAA  NEXT_D                    
                JSR   INIT_REV                 
                JSR   REV_ST                    
                JMP   MAIN

INIT_SBY        BCLR  PTT,%00110000             
                RTS
                
;* SENSOR SUBROUTINE                                                                        
;********************************************************************************************

UPDT_READING    JSR   G_LEDS_ON                 
                JSR   READ_SENSORS              
                JSR   G_LEDS_OFF                
                
                LDAA  #0                        
                STAA  A_DETN                    
                STAA  B_DETN                    
                STAA  C_DETN                    
                STAA  D_DETN                    
                STAA  E_DETN                    
                STAA  F_DETN                    
                
CHECK_A         LDAA  SENSOR_BOW                
                CMPA  #PTH_A_INT                
                BLO   CHECK_B                  
                INC   A_DETN                    

CHECK_B         LDAA  SENSOR_PORT                            
                BLO   CHECK_C                   
                INC   B_DETN                    

CHECK_C         LDAA  SENSOR_MID                
                CMPA  #PTH_C_INT                
                BLO   CHECK_D                   
                INC   C_DETN                    
                
CHECK_D         LDAA  SENSOR_STBD               
                CMPA  #PTH_D_INT                
                BLO   CHECK_E                  
                INC   D_DETN                    

CHECK_E         LDAA  SENSOR_LINE               
                CMPA  #PTH_E_INT                
                BHI   CHECK_F                   
                INC   E_DETN                    
                
CHECK_F         LDAA  SENSOR_LINE               
                CMPA  #PTH_F_INT                
                BLO   UPDT_DONE                 
                INC   F_DETN                    
                
UPDT_DONE       RTS

G_LEDS_ON       BSET  PORTA,%00100000           
                RTS

G_LEDS_OFF      BCLR  PORTA,%00100000           
                RTS

READ_SENSORS    CLR   SENSOR_NUM                
                LDX   #SENSOR_LINE              
  RS_MAIN_LOOP: LDAA  SENSOR_NUM               
                JSR   SELECT_SENSOR             
                LDY   #400                      
                JSR   del_50us                  
                LDAA  #%10000001               
                STAA  ATDCTL5
                BRCLR ATDSTAT0,$80,*           
                LDAA  ATDDR0L                   
                STAA  0,X                       
                CPX   #SENSOR_STBD              
                BEQ   RS_EXIT                   
                INC   SENSOR_NUM               
                INX                             
                BRA   RS_MAIN_LOOP              
       RS_EXIT: RTS

SELECT_SENSOR   PSHA                            
                LDAA  PORTA                     
                ANDA  #%11100011                
                STAA  TEMP                     
                PULA                            
                ASLA                            
                ASLA
                ANDA  #%00011100               
                ORAA  TEMP                      
                STAA  PORTA                     
                RTS

;* UTILITY SUBROUTINE                                                                       
;********************************************************************************************

del_50us:       PSHX                            
eloop:          LDX   #300                      
iloop:          NOP                             
                DBNE  X,iloop                   
                DBNE  Y,eloop                   
                PULX                            
                RTS                             

cmd2LCD:        BCLR  LCD_CNTR,LCD_RS           
                JSR   dataMov                   
      	        RTS

putsLCD         LDAA  1,X+                      
                BEQ   donePS                    
                JSR   putcLCD
                BRA   putsLCD
donePS 	        RTS

putcLCD         BSET  LCD_CNTR,LCD_RS           
                JSR   dataMov                   
                RTS

dataMov         BSET  LCD_CNTR,LCD_E            
                STAA  LCD_DAT                   
                BCLR  LCD_CNTR,LCD_E           
                LSLA                            
                LSLA                            
                LSLA                           
                LSLA                           
                BSET  LCD_CNTR,LCD_E            
                STAA  LCD_DAT                 
                BCLR  LCD_CNTR,LCD_E            
                LDY   #1                        
                JSR   del_50us                  
                RTS

int2BCD         XGDX                            
                LDAA  #0                        
                STAA  TEN_THOUS
                STAA  THOUSANDS
                STAA  HUNDREDS
                STAA  TENS
                STAA  UNITS
                STAA  BCD_SPARE
                STAA  BCD_SPARE+1

                CPX   #0                        
                BEQ   CON_EXIT                  

                XGDX                            
                LDX   #10                       
                IDIV                            
                STAB  UNITS                     
                CPX   #0                        
                BEQ   CON_EXIT                  

                XGDX                            
                LDX   #10                       
                IDIV
                STAB  TENS
                CPX   #0
                BEQ   CON_EXIT

                XGDX                            
                LDX   #10                       
                IDIV
                STAB  HUNDREDS
                CPX   #0
                BEQ   CON_EXIT

                XGDX                            
                LDX   #10                       
                IDIV
                STAB  THOUSANDS
                CPX   #0
                BEQ   CON_EXIT

                XGDX                            
                LDX   #10                       
                IDIV
                STAB  TEN_THOUS

      CON_EXIT: RTS                             

BCD2ASC         LDAA  #$0                       
                STAA  NO_BLANK

       C_TTHOU: LDAA  TEN_THOUS                 
                ORAA  NO_BLANK
                BNE   NOT_BLANK1

      ISBLANK1: LDAA  #$20                     
                STAA  TEN_THOUS                 
                BRA   C_THOU                    

    NOT_BLANK1: LDAA  TEN_THOUS                 
                ORAA  #$30                      
                STAA  TEN_THOUS
                LDAA  #$1                       
                STAA  NO_BLANK

        C_THOU: LDAA  THOUSANDS                 
                ORAA  NO_BLANK                  
                BNE   NOT_BLANK2
                     
      ISBLANK2: LDAA  #$30                      
                STAA  THOUSANDS                 
                BRA   C_HUNS                   

    NOT_BLANK2: LDAA  THOUSANDS                 
                ORAA  #$30
                STAA  THOUSANDS
                LDAA  #$1
                STAA  NO_BLANK

        C_HUNS: LDAA  HUNDREDS                  
                ORAA  NO_BLANK                  
                BNE   NOT_BLANK3

      ISBLANK3: LDAA  #$20                      
                STAA  HUNDREDS                  
                BRA   C_TENS                    
                     
    NOT_BLANK3: LDAA  HUNDREDS                  
                ORAA  #$30
                STAA  HUNDREDS
                LDAA  #$1
                STAA  NO_BLANK

        C_TENS: LDAA  TENS                      
                ORAA  NO_BLANK                  
                BNE   NOT_BLANK4
                     
      ISBLANK4: LDAA  #$20                      
                STAA  TENS                      
                BRA   C_UNITS                   

    NOT_BLANK4: LDAA  TENS                      
                ORAA  #$30
                STAA  TENS

       C_UNITS: LDAA  UNITS                     
                ORAA  #$30
                STAA  UNITS

                RTS                             

HEX_TABLE       FCC '0123456789ABCDEF'          
BIN2ASC         PSHA                            
                TAB                            
                ANDB #%00001111                 
                CLRA                            
                ADDD #HEX_TABLE                 
                XGDX                
                LDAA 0,X                        
                PULB                            
                PSHA                            
                RORB                            
                RORB                            
                RORB
                RORB 
                ANDB #%00001111                 
                CLRA                            
                ADDD #HEX_TABLE                 
                XGDX                                                               
                LDAA 0,X                        
                PULB                            
                RTS
                
;* DISPLAY UPDATE                                                                           
;********************************************************************************************

UPDT_DISPL      LDAA  #$82                      
                JSR   cmd2LCD                 
                
                LDAB  CRNT_STATE               
                LSLB                          
                LSLB                          
                LSLB                         
                LDX   #tab                      
                ABX                         
                JSR   putsLCD                  
               
                LDAA  #$8F                    
                JSR   cmd2LCD              
                LDAA  SENSOR_BOW                
                JSR   BIN2ASC                
                JSR   putcLCD                
                JSR   putcLCD                

                LDAA  #$92                       
                JSR   cmd2LCD                 
                LDAA  SENSOR_LINE              
                JSR   BIN2ASC              
                JSR   putcLCD             
                EXG   A,B                   
                JSR   putcLCD                

                LDAA  #$CC                    
                JSR   cmd2LCD                 
                LDAA  SENSOR_PORT              
                JSR   BIN2ASC                   
                JSR   putcLCD               
                EXG   A,B                    
                JSR   putcLCD                 

                LDAA  #$CF                    
                JSR   cmd2LCD               
                LDAA  SENSOR_MID                
                JSR   BIN2ASC                
                JSR   putcLCD                
                EXG   A,B                      
                JSR   putcLCD                   

                LDAA  #$D2                       
                JSR   cmd2LCD                   
                LDAA  SENSOR_STBD               
                JSR   BIN2ASC                   
                JSR   putcLCD                 
                EXG   A,B                       
                JSR   putcLCD                   
           
                MOVB  #$90,ATDCTL5              
                BRCLR ATDSTAT0,$80,*        
                LDAA  ATDDR0L                 
                LDAB  #39                   
                MUL                             
                ADDD  #600                     
                JSR   int2BCD
                JSR   BCD2ASC
                LDAA  #$C2                     
                JSR   cmd2LCD                     
                LDAA  TEN_THOUS               
                JSR   putcLCD                  
                LDAA  THOUSANDS                 
                JSR   putcLCD                  
                LDAA  #$2E                      
                JSR   putcLCD                
                LDAA  HUNDREDS                  
                JSR   putcLCD                                   

                LDAA  #$C9                     
                JSR   cmd2LCD
                
                BRCLR PORTAD0,#%00000100,bowON  
                LDAA  #$20                    
                JSR   putcLCD                  
                BRA   stern_bump              
         bowON: LDAA  #$42                   
                JSR   putcLCD               
          
    stern_bump: BRCLR PORTAD0,#%00001000,sternON
                LDAA  #$20                      
                JSR   putcLCD                  
                BRA   UPDT_DISPL_EXIT         
       sternON: LDAA  #$53                   
                JSR   putcLCD                 
UPDT_DISPL_EXIT RTS                             
                
;* INITIALIZATION SUBROUTINE                                                                
;********************************************************************************************

initPORTS       BCLR  DDRAD,$FF                 
                BSET  DDRA, $FF                 
                BSET  DDRT, $30                 
                RTS
        
initAD          MOVB  #$C0,ATDCTL2              
                JSR   del_50us                  
                MOVB  #$00,ATDCTL3              
                MOVB  #$85,ATDCTL4              
                BSET  ATDDIEN,$0C               
                RTS   

initLCD         BSET  DDRB,%11111111            
                BSET  DDRJ,%11000000            
                LDY   #2000                     
                JSR   del_50us                  
                LDAA  #$28                      
                JSR   cmd2LCD                   
                LDAA  #$0C                      
                JSR   cmd2LCD                   
                LDAA  #$06                     
                JSR   cmd2LCD                 
                RTS

clrLCD          LDAA  #$01                      
                JSR   cmd2LCD                   
                LDY   #40                      
                JSR   del_50us               
                RTS

initTCNT        MOVB  #$80,TSCR1                
                MOVB  #$00,TSCR2                
                MOVB  #$FC,TIOS                 
                MOVB  #$05,TCTL4                
                MOVB  #$03,TFLG1                
                MOVB  #$03,TIE                 
                RTS

;* INTERRUPT SERVICE ROUTINES                                                               
;********************************************************************************************

ISR1            MOVB  #$01,TFLG1                
                INC   COUNT1                    
                RTI

ISR2            MOVB  #$02,TFLG1                
                INC   COUNT2                     
                RTI
                
;* Interrupt Vectors                                                                        
;********************************************************************************************

                ORG   $FFFE
                DC.W  Entry                     

                ORG   $FFEE
                DC.W  ISR1                      

                ORG   $FFEC
                DC.W  ISR2                      