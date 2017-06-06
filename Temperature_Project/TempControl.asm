;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; MECE 4058 Spring 2017
; Mechatronics and Embedded Microcomputer Control
; Case study 4 Thermal Control
; Team 7
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	LIST P=16F747
	title "Thermal Control"
	#include <P16F747.INC>
	__CONFIG _CONFIG1, _FOSC_HS & _CP_OFF & _DEBUG_OFF & _VBOR_2_0 & _BOREN_0 & _MCLR_ON &_PWRTE_ON & _WDT_OFF
	__CONFIG _CONFIG2, _BORSEN_0 & _IESO_OFF & _FCMEN_OFF

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;Variables Declaration
ambient  equ 20h					; averaged ambient measurement
ambient1 equ 28h
feedback equ 21h 					; averaged feeback measurement
feedback1 equ 22h
timer0 equ 23h 						; timer storage variable
timer1 equ 24h 						; timer storage variable
lowerBound equ 26h
upperBound equ 27h
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; Inline methods
bank0 macro
	bcf STATUS,RP0
	bcf STATUS,RP1
endm

bank1 macro
	bsf STATUS,RP0
	bcf STATUS,RP1
endm

choosePin1 macro
	bsf ADCON0, CHS0
	bcf ADCON0, CHS1
endm

choosePin2 macro
	bcf ADCON0, CHS0
	bcf ADCON0, CHS1
endm
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	org 00h 						; Reset Vector
	goto initConfig 				; goto start of routine
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;Port A Pin 1 – Ambient Sensor 
;Port A Pin 2 – Plate Sensor 
;Port A Pin 3 – Reference Voltage
;Port C Pin 5 – Toggle Switch
;Port D Pin 0 – Red LED 
;Port D Pin 1 – Yellow LED 
;Port D Pin 2 – Green LED 
;Port D Pin 3 – Blue LED (on / off) 
;Port D Pin 6 – Heater (on -= low) 
;Port D Pin 7 – Fan (on -= low)
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
initConfig
	bank1
	movlw B'00100000'					
	movwf TRISC								; Toggle switch as input
	clrf TRISD								; Make all of PORTD(LEDs) outputs							; 
initPort
	bank0
	clrf PORTA								; Clear the value of PORTA(Sensors) 
	clrf PORTC								; Clear the value of PORTC(Toggle switch) 
	movlw B'11000000'
	movwf PORTD								; Turn off the LEDs, heater, and the fan

	; clear variables
	clrf ambient
	clrf feedback

	clrf timer0
	clrf timer1

InitAD
	bank1
	; RA1,RA2 will be the analog inputs
	movlw B'00010011'
	movwf ADCON1
	bank0
	; select 8 * oscillator / RA1 / AD converter on
	movlw B'01001001'
	movwf ADCON0

;=================
;	bcf PORTD, 6
;TestReading
;	call ReadFeedback
;	goto TestReading
;=================



WaitToogleOn
	btfss PORTC, 5										;  Hold the control until the toggle switch turned on 
	goto WaitToogleOn

ControlMode
	; Compare to Upper Bounds(Read value-2)
	call ReadAmbient
	call ReadFeedback
	movlw D'2'
	subwf ambient,0
	subwf feedback,0
	btfss STATUS, C
	goto Heat											; If feedback < lowerBound: Heat up
	
	; Compare to Upper Bounds(Read value+20)
	call ReadAmbient
	call ReadFeedback	
	movlw D'20'
	addwf ambient,0
	subwf feedback,0
	btfsc STATUS, C
	goto Cool											; If feedback > upperBound: Cool down 
	movlw B'11001100'									; Turn on green LED
	movwf PORTD
ContinueControl
	; Check control toogle switch
	btfsc PORTC, 5										;Turn off the toggle switch to stop control,
	goto ControlMode									
	goto StopControlMode

Heat
	movlw B'10001001'							; Turn the heater on, fan off
	movwf PORTD									
	goto ContinueControl

Cool
	movlw B'01001010'							; Turn the heater off, fan on
	movwf PORTD
	goto ContinueControl


StopControlMode
	movlw B'11000000'							; Turn the heater and fan both off
	movwf PORTD
	goto WaitToogleOn


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; Public methods

ReadAmbient
	;choosePin1
	bsf ADCON0, CHS0
	bcf ADCON0, CHS1
	bsf ADCON0, GO								; Start conversion
	call WaitConversion							; Make sure the conversion was done then move on
	movf ADRESH,W
	movwf ambient
	rrf ambient,1								; Divide the first read value by 2

	bsf ADCON0, CHS0							; Read again for averaging
	bcf ADCON0, CHS1
	bsf ADCON0, GO								; Start conversion
	call WaitConversion							; Make sure the conversion was done then move on
	movf ADRESH,W
	movwf ambient
	rrf ambient1,1								; Divide the second read value by 2	
	movf ambient1,W
	addwf ambient,1								; Add up the two divided read value to get an averaged
												; Divide first then add up prevents overflow
	return

ReadFeedback
	;choosePin2
	bcf ADCON0, CHS0
	bsf ADCON0, CHS1
	bsf ADCON0, GO								; Start conversion
	call WaitConversion							; Make sure the conversion was done then move on
	movf ADRESH,W
	movwf feedback
	rrf feedback,1								; Divide the first read value by 2

	bcf ADCON0, CHS0							; Read again for averaging
	bsf ADCON0, CHS1
	bsf ADCON0, GO								; Start conversion
	call WaitConversion							; Make sure the conversion was done then move on
	movf ADRESH,W
	movwf feedback1
	rrf feedback1,1								; Divide the second read value by 2
	movf feedback1,W
	addwf feedback,1							; Add up the two divided read value to get an averaged
												; Divide first then add up prevents overflow

	return

WaitConversion
	btfsc ADCON0,GO ;checks if convertion is done
	goto WaitConversion ;not done
	btfsc ADCON0,GO ;checks again
	goto WaitConversion ;not ready
	return


Hysteresis
	movfw ambient
	addlw B'00010010'							; The upperbound will be the read temperature plus 18
	movwf upperBound
	movwf PORTB

	sublw B'00010100'							; The lowerbound will be the upperbound minus 20, 
	movwf lowerBound							; or the read temperature minus 2
	return
	
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; Timing Sub-Routines
Wait100ms
	call Reload100ms
Count100ms
	decfsz timer0, F ; Delay loop
	goto Count100ms
	decfsz timer1, F ; Delay loop
	goto Count100ms
	return
Reload100ms
	movlw 26h ; get next most significant hex value
	movwf timer1 ; store it in count register
	movlw 25h ; get least significant hex value
	movwf timer0 ; store it in count register
	return
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
err
	goto err

isrService
	goto isrService ; error - - stay here


end