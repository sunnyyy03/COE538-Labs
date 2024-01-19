;*************************************************
;* Multiplies two 8-bit unsigned numbers*      
;*************************************************

; export symbols
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point



; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 

;********************************************
 ;*Code Section*
;********************************************

; variable/data section

            ORG $3000
 
MULTIPLICAND FCB $6       ; First number 
MULTIPLIER   FCB $2       ; Second number
PRODUCT      RMB  2       ; result of the multiplication
  
;********************************************
;*Actual program here*
;********************************************

            ORG   $4000

Entry:
_Startup:
            LDAA MULTIPLICAND   ; Load the first number into register A
            LDAB MULTIPLIER     ; Load the second number into register B
            MUL                 ; Multiply 8-bit num in register A with the 8-bit num in register B and store the 16-bit result in register D
            STD PRODUCT         ; Store the product in register D into product
            SWI                 ; break to the monitor
            
;**********************************************
;*Interrupt Vectors*
;**********************************************
            ORG   $FFFE
            FDB   Entry      ;Reset Vector
