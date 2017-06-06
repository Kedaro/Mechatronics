	LIST P=16F747
	title "Counting program"
	#include <P16F747.INC>
	__CONFIG _CONFIG1, _FOSC_HS & _CP_OFF & _DEBUG_OFF & _VBOR_2_0 & _BOREN_0 & _MCLR_ON &_PWRTE_ON & _WDT_OFF
	__CONFIG _CONFIG2, _BORSEN_0 & _IESO_OFF & _FCMEN_OFF

;*****************************************************

;	MECHATRONICS CASE STUDY 3, GROUP 7

;   This code is written by Alex Chen, Yan Chen, and Ori Kedar
;   for Mechatronics Spring 2017
;   The code demonstrates on-off control for a solenoid
;
;   There are 4 modes that are chosen by an Octal switch
;   Each mode has its own control rules
;   This lab includes AtoD conversion, timer loops, value comparison
;   solenoid actuation and sensor reading




;*****************************************************

;   Variable Declarations
PotVal equ 30h              ; where AtoD converted potentiometer value stored
Mode equ 31h                ; stores mode currently operating
Octal equ 32h               ; stores value of octal switch 
Timer2 equ 20h              ; timer storage variable 
Timer1 equ 21h              ; timer storage variable
Timer0 equ 22h              ; timer storage variable 
Timer equ 23h               ; calculated number of secs from potVal


	org 00h                 ; Reset Vector
	goto main         		; goto start of routine

	clrf PORTB     			; clear PORTB values 
	bsf PORTB,1    			; set PORTB pin 1 to input


;   Setting up all the possible banks to work with

bank0 macro             	; switch to bank 0
	bcf STATUS,RP0
	bcf STATUS,RP1
endm

bank1 macro             	; switch to bank 1
	bsf STATUS,RP0
	bcf STATUS,RP1
endm



;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

;   main: start of the program, include mode selection

main

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;   Initializing PORTS

initPort
	clrf PORTC				; clear PORT C (Red/Green Button)
	clrf PORTD 				; clear Port D (Solenoid)
	clrf PORTB 				; clear Port B (For Octal LED)
	clrf PORTE 				; clear octal switch
	clrf Timer   			; clear variable timer
	clrf Octal   			; clear octal switch stored value



	bank1              		; sets bank 1
	movlw B'11111111'  		; set all pins PORTC to input
	movwf TRISC
	movlw B'1111'      		; set all pins PORTE to input
	movwf TRISE        		; only 4 bits
	
;   PORTD must have the appropriate pin assignment
;   Pin 0: main transistor, output
;   Pin 1: hold transistor, output
;   Pin 2: sensor, input

	movlw B'10100100'  		; set PORTD to input/output above
	movwf TRISD ;

	clrf TRISB         		; set PORTB to all output for Mode LEDs 
	
	bank0              		; return to Bank 0
	call InitAD        		; initializes A to D conversion

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	call Disengage     		; ensure solenoid disengaged

									
waitPressMain               ; check for button press
	btfsc PORTC,0 			; see if green button pressed
	goto GreenPressMain 	; green button is pressed - goto routine
	goto waitPressMain 		; keep checking


GreenPressMain            	; if green button pressed
	btfss PORTC,0      	  	; see if green button still pressed
	goto waitPressMain    	; noise - button not pressed - keep checking


GreenReleaseMain          	; ensure button is released
	btfsc PORTC,0      		; see if green button released, if so, continue
	goto GreenReleaseMain 	; no - keep waiting

ReadOctal                   ; reads value from octal
	comf PORTE, W        	; take compliment from octal
	andlw B'00000111 
	movwf Octal           	; and with 111 to clear uncessary pins
	movwf PORTB           	; indicate mode read on PORTB LED's


CheckMode0                  ; check if in mode 0
	movlw B'11111111
	andwf Octal,W          	; compare to complement of 0
	btfsc STATUS,Z        
	goto err               	; if ocatl is 0, go to error mode


CheckMode1                  ;check in in mode 1
	movlw B'11111110
	andwf Octal,W           ; and with complement of 1
	btfsc STATUS,Z
	goto Mode1              ; if octal set to 1, go to mode 1


;   Repeat the process above for other possible modes

CheckMode2      
	movlw B'11111101
	andwf Octal,W
	btfsc STATUS,Z          ;check if Octal is Two
	goto Mode2

CheckMode3
	movlw B'11111100
	andwf Octal,W
	btfsc STATUS,Z          ;check if Octal is Three
	goto Mode2

CheckMode4
	movlw B'11111011
	andwf Octal,W
	btfsc STATUS,Z          ; check if conta is Four
	goto Mode4
	goto err       			; if octal is not 1-4 go to error mode

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&






;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;MODE1
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Mode1                       ; enter Mode 1 
	goto WaitPress          ; wait in loop until button pressed

Mode1Return                 ; return point from waiting for button press
	btfsc PORTD,0           ; determine state of solenoid by checking main transistor
	goto ToggleDisengage      
	goto ToggleEngage          

ToggleEngage                ; entered if solenoid currently disengaged
	call Engage             ; engage solenoid
	goto Mode1              ; return to Mode 1 loop

ToggleDisengage             ; entered if solenoid currently engaged
	call Disengage          ; disengage solenoid
	goto Mode1              ; return to Mode 1 loop



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;MODE2
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



Mode2	
	goto WaitPress          ; enter loop until button pressed
Mode2Return                 ; return point for button press
	call ReadAD             ; read potentiometer and convert
	call DivideBy4          ; divides value of pot by 4

	movlw B'11111111'       ; make sure pot/4 is not equal to 0         
	andwf PotVal,W
	btfsc STATUS,Z
	goto err                ; if zero enter error mode

	movwf Timer             ; move pot value/4 to timer variable

	call Engage             ; engage solenoid


StartTimerMode2             ; return point if timer interrupted
	call ReloadOneSecond    ; loads appropriate timer varaibles for 1 second loop

CountDown2
	btfsc PORTC,1           ; Check for red button for interrupt
	goto ResetPotVal        ; if red button pressed, restart timer 
	decfsz Timer0, F        ; Delay loop
	goto CountDown2
	decfsz Timer1, F        ; Delay loop
	goto CountDown2
	decfsz Timer2, F        ; Delay loop
	goto CountDown2
	decfsz Timer, F         ; Delay loop
	goto StartTimerMode2
	call Disengage	       	; at end of timer, disengage solenoid
	goto Mode2              ; return to Mode 2 loop

ResetPotVal                 ; return point if red button pressed durring timer
	btfsc PORTC,1           ; check if red button released
	goto ResetPotVal        ; stay in loop until red button released
	goto Mode2Return        ; once released, restart timer



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;MODE3
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Mode3                       ; enter Mode 3
	goto WaitPress       	; wait in loop until button pressed

Mode3Return                 ; return point once control mode is entered  

;   we created a blinkng lights in PODTB to indicate control mode engaged
     
	bcf PORTB,0                    
	bcf PORTB,1
	call Wait1mSecond      	; 1 msecond timer
	bsf PORTB,0
	bsf PORTB,1
	call Wait1mSecond      	; 1 msecond timer


	call ReadAD            	; convert pot value to digital
	movf B'11111111'       
	andwf PotVal   
	btfsc STATUS, Z        	; check if pot value is equal to zero
	goto err               	; if zero enter error mode
	
	movlw 70h
	subwf PotVal,w         	; compare potval to 70h
	
  
	btfsc STATUS,C	    	; check carry bit, to see if value is larger or smaller than PotVal
	goto PotIsLarger       	; enter mode if larger 
	goto PotIsSmaller      	; enter mode if smaller

PotIsLarger                 ; if value larger than 70h, engage solenoid
	call Engage            
	goto RedPressMode3      ; check if red button pressed to exit control mode

PotIsSmaller                ; if value smaller than 70h, disengage solenoid
	call Disengage	
	goto RedPressMode3     	; check if red button pressed to exit control mode

RedPressMode3               ; checks if red button pressed to exit control mode
	btfss PORTC, 1
	goto Mode3Return        ; if not stay in control mode loop
RedReleaseMode3             ; if pressed, wait for release
	btfsc PORTC, 1         
	goto RedReleaseMode3    ; check for release, if not released stay in loop

	call Disengage          ; if control mode exited, disengage solenoid
	goto Mode3


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;MODE4
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Mode4                       ; enter Mode 4
	goto WaitPress          ; wait for button press to continue

Mode4Return                 ; return point for Mode 4

	call ReadAD             ; converts pot value to digital
	call DivideBy4          ;divides value of pot by 4

	movlw B'11111111'      
	andwf PotVal,W
	btfsc STATUS,Z          ; check if pot value/4 = 0
	goto err                ; if so, enter error mode


Restart4                    ; return point if Mode 4 interrupted
	call Engage             ; engage solenoid
	call WaitSensorHigh     ; check if sensor is high, indicating solenoid is engaged

	call Hold               ; turns on hold transistor, and turns off main
	
	movfw PotVal            ; move pot value/4 to timer variable for appropriate length
	movwf Timer


StartTimerPart2             ; starts timer once solenoid engaged and hold transistor on
	call ReloadOneSecond    ; load timer variables for 1 second inner loop
CountDownPart2
	decfsz Timer0, F        ; delay loop
	goto CountDownPart2
	decfsz Timer1, F        ; delay loop
	goto CountDownPart2
	decfsz Timer2, F        ; delay loop
	goto CountDownPart2
	btfss PORTD,2           ; check if light sensor high
	goto CheckRestart       ; if low, check if first restart   
	decfsz Timer, F         ; outer delay loop
	goto StartTimerPart2       
	
	call Disengage          ; at end of timer (uninterrupted) disengage solenoid
	bcf PORTD,5             ; clear restart flag, which idicates first or second restart
	call WaitSensorLow      ; ensures sensor goes low, before 10 seconds are up
	goto Mode4              ; if all is well, return to Mode 4

	

WaitSensorHigh              ; checks to ensure solenoid properly engaged
	movlw B'00001010' 
	movwf Timer             ; set Timer to 10 seconds
StartTimerTen
	call ReloadOneSecond    ; set inner loop timer variables for 1 second
CountDownTen                ; start timer
	decfsz Timer0, F        ; delay loop
	goto CountDownTen
	decfsz Timer1, F        ; delay loop
	goto CountDownTen
	decfsz Timer2, F        ; delay loop
	goto CountDownTen
	btfsc PORTD,2           ; check if light Sensor High
	return                  ; if so, continue mode 4
	decfsz Timer, F         ; outer delay loop
	goto StartTimerTen       
	goto err                ; if sensor is never high, and timer finishes, go to error mode



WaitSensorLow               ; check if solenoid properly disengages
	movlw B'00001010' 
	movwf Timer             ; set Timer variable to 10 seconds
StartTimerTenLow
	call ReloadOneSecond    ; set inner loop timer variables for 1 second
CountDownTenLow
	decfsz Timer0, F        ; delay loop
	goto CountDownTenLow
	decfsz Timer1, F        ; delay loop
	goto CountDownTenLow
	decfsz Timer2, F        ; delay loop
	goto CountDownTenLow
	btfss PORTD,2           ; check if light Sensor Low
	return                  ; if low, return to Mode 4
	decfsz Timer, F         ; outer delay loop
	goto StartTimerTenLow
	goto err                ; if timer finished and still low, go to error


CheckRestart
	btfss PORTD, 5          ; check restart flag to see if first restart
	goto SetRestart         ; if first go to SetRestart
	goto err	            ; if second restart, go to error
SetRestart
	bsf PORTD,5             ; set restart flag
	call Disengage          ; disengage
	goto Restart4             


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; Common sub-routines
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


DivideBy4                   ; make the division of the value read on the pot
	bcf STATUS,0            ; zero carry
	rrf PotVal,f            ; divides by two by shift binary value to the right
	bcf STATUS,0            ; zero carry
	rrf PotVal,f            ; divides by two by shift binary value to the right
	return



Engage
	bsf PORTD,1		        ; set reduced transistor
	bsf PORTD,0		        ; set main transistor
	return

Disengage
	bcf PORTD,0             ; clear reduced and main transistors
	bcf PORTD,1
	return
Hold
	bsf PORTD,1             ; set reduced transistor, wait 100m seconds    
	call Reload100mSecond   ; set timer variables for 100m second pause
	call Wait1mSecond
	bcf PORTD,0             ;clear main transistor
	return


ReloadOneSecond             ; loads timer variables for 1 second timer
	movlw 06h               ; get most significant hex value + 1
	movwf Timer2            ; store it in count register
	movlw 16h               ; get next most significant hex value
	movwf Timer1            ; store it in count register
	movlw 15h               ; get least significant hex value
	movwf Timer0            ; store it in count register
	return

Reload100mSecond            ; loads timer variables for 100m second timer
	movlw 26h 
	movwf Timer1 
	movlw 25h 
	movwf Timer0 
	return

Wait1mSecond                ;1 msecond timer loop
	decfsz Timer0, F 
	goto Wait1mSecond
	decfsz Timer1, F 
	goto Wait1mSecond
	call Reload100mSecond
	
	return


;   Class Exercise INITAD
InitAD
	bank1
	movlw B'00001110' 		; RA0,RA1,RA3 analog inputs, all other digital
	movwf ADCON1 			; move to special function A/D register
	bank0
	movlw B'01000001' 		; select 8 * oscillator, analog input 0, turn on
	movwf ADCON0 			; move to special function A/D register
	return


;   These are used in reading the AtoD value	
ReadAD
	bsf ADCON0,GO 			; starts converting
WaitConversion
	btfsc ADCON0,GO 		; checks if convertion is done
	goto WaitConversion 	; not done
	btfsc ADCON0,GO 		; checks again
	goto WaitConversion 	; not ready

	clrf PotVal
	movf ADRESH,W 			; reads value from the pot
	movwf PotVal 			; stores value
	return

;   These mothods check to see if red or green button pressed and wait for release
WaitPress
	btfsc PORTC,0 			; see if green button pressed
	goto GreenPress 		; green button is pressed - goto routine
	btfsc PORTC,1 			; see if red button pressed
	goto RedPress 			; red button is pressed - goto routine
	goto WaitPress 			; keep checking

GreenPress
	btfss PORTC,0 			; see if green button still pressed
	goto WaitPress 			; noise - button not pressed - keep checking

GreenRelease
	btfsc PORTC,0 			; see if green button released
	goto GreenRelease 		; no - keep waiting
	call Disengage
	goto main   			; reset
RedPress
	btfss PORTC,1 			; see if red button still pressed
	goto WaitPress 			; noise - button not pressed - keep checking

RedRelease
	btfsc PORTC,1 			; see if red button released
	goto RedRelease 		; no - keep waiting



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;Error Mode
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;   Error mode, entered if pot=0, wrong mode is selected, or solenoid
;   failure in Mode 4.  Infinite loop that requires hard restart to exit
err
	bsf PORTB, 3   			; Turn on 4th LED port B
	call Disengage 			; Disengage solenoid
	goto err       			; Enter Infinite loop



;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;   Dummy interrupt service

isrService
	goto isrService ; error - - stay here

end
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~