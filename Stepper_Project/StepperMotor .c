/******************************************************************************
 * MECE E4058 Spring 2017
 * Case Study 3
 * Team 7:
 *  - Alex Chen     |   ac4099
 *  - Ori Kedar     |   oak2106
 *  - Yan-Song Chen |   yc3240
 *
 * StepperMotor.c
 * This program controls a pair of unipolor and bipolor stepper motors.
 * 
 * The functionality consists of four modes.
 * 
 * # Mode 1: rotate the stepper motors between interrupters sequentially.
 * # Mode 2: rotate the stepper motors by opposite directions.
 * # Mode 3: rotate the stepper motors between interrutpers throught the longest
 *           path (3/4 cycle).
 * # Mode 4: whereas mode 1 ~ 3 uses full step, this mode drives the motors by
 *           half step commands. The movement is similar to move 2.
 * 
 ******************************************************************************/
#include <xc.h> 
#include <pic.h>
#pragma config  FOSC=HS, CP=OFF, DEBUG=OFF, BORV=20, BOREN=0, MCLRE=ON, PWRTE=ON, WDTE=OFF 
#pragma config  BORSEN=OFF, IESO=OFF, FCMEN=0
#define PORTBIT(adr,bit) ((unsigned)(&adr)*8+(bit))

// Variable declaration
static bit greenButton @ PORTBIT(PORTC,0);  // alias of RC0
static bit redButton @ PORTBIT(PORTC,1);    // alias of RC1

int biState = 1;							// state variable for bipolar motor
int uniState = 1;							// state variable for unipolar motor
int waveState=1;							// state variable for wave drive control
int uniNum;								    // signal to actuate the unipolar motor
int biNum=0b01000000;						// signal to actuate the bipolar motor
int step=1;								    // state variable for each mode
short octal;								// variable for reading the octal switch

void SwitchDelay (void)
{	
	int i;
	for (i=2000; i > 0; i--) {}             // 2000 machine cycle delay
}

void SwitchDelay2 (void)					// 1000 machine cycle delay
{	
	int i;
	for (i=1000; i > 0; i--) {}
}

void unipolar_cw_full(void)					// Move the unipolar motor with full stepping clockwise
{
	switch( uniState)
	{
		case 1:
		{
			uniNum = 0b00000011;
			uniState++;
			return;
		}
		case 2:
		{
			uniNum = 0b00000110;
			uniState++;
			return;
		}
	
		case 3:
		{
			uniNum = 0b00001100;
			uniState++;
			return;
		}
	
		case 4:
		{
			uniNum = 0b00001001;
			uniState = 1;					// Back to state 1
			return;
		}
	}
}

void unipolar_ccw_full(void)				// Move the unipolar motor with full stepping counterclockwise
{
	switch( uniState)
	{
		case 1:
		{
			uniNum = 0b00000011;
			uniState++;
			return;
		}
		case 2:
		{
			uniNum = 0b00001001;
			uniState++;
			return;						
		}
	
		case 3:
		{
			uniNum = 0b00001100;				
			uniState++;
			return;
		}
	
		case 4:
		{
			uniNum = 0b00000110;				
			uniState = 1;
			return;
		}
	}
}

void unipolar_cw_wave(void)					// Move the unipolar motor with wave driver clockwise
{
	switch( uniState)
	{
		case 1:
		{
			uniNum = 0b00000001;
			uniState++;
			return;
		}
		case 2:
		{
			uniNum = 0b00000010;
			uniState++;
			return;
		}
	
		case 3:
		{
			uniNum = 0b00000100;				
			uniState++;
			return;
		}
	
		case 4:
		{
			uniNum = 0b00001000;				
			uniState = 1;
			return;
		}
	}
}

void unipolar_ccw_wave(void)					// Move the unipolar motor with wave driver counterclockwise
{
	switch( uniState)
	{
		case 1:
		{
			uniNum = 0b00000001;
			uniState++;
			return;
		}
		case 2:
		{
			uniNum = 0b00001000;
			uniState++;
			return;
		}
	
		case 3:
		{
			uniNum = 0b00000100;				
			uniState++;
			return;
		}
	
		case 4:
		{
			uniNum = 0b00000010;				
			uniState = 1;
			return;
		}
	}
}

void bipolar_cw_full(void)					// Move the bipolar motor with full stepping clockwise
{
	switch( biState)
	{
		case 1:
		{
			biNum = 0b01000000;
			biState++;
			return;
		}
		case 2:
		{
			biNum = 0b00000000;
			biState++;
			return;
		}
	
		case 3:
		{
			biNum = 0b00010000;				
			biState++;
			return;
		}
	
		case 4:
		{
			biNum = 0b01010000;				
			biState = 1;
			return;
		}
	}
}

void bipolar_ccw_full(void)					// Move the bipolar motor with full stepping counterclockwise
{
	switch( biState)
	{
		case 1:
		{
			biNum = 0b01000000;
			biState++;
			return;
		}
		case 2:
		{
			biNum = 0b01010000;
			biState++;
			return;
		}
	
		case 3:
		{
			biNum = 0b00010000;				
			biState++;
			return;
		}
	
		case 4:
		{
			biNum = 0b00000000;				
			biState = 1;
			return;
		}
	}
}


void bipolar_cw_wave(void)					// Move the bipolar motor with wave driver clockwise
{
	switch( biState)
	{
		case 1:
		{
			if( waveState==1 )
            {
				biNum = 0b01010000;			// The first state of bipolar wave driver
				waveState=2;
				return;
			}
			
            if( waveState==2 )
            {
				biNum = 0b01100000;			// The second state of bipolar wave driver
				biState++;
				waveState=1;
				return;
			}
		}
		case 2:
		{
			if( waveState==1 )
            {
				biNum = 0b01000000;			// The third state of bipolar wave driver
				waveState=2;
				return;
			}
			
            if( waveState==2 )
            {
				biNum = 0b10000000;			// The fourth state of bipolar wave driver
				biState++;
				waveState=1;
				return;
			}
			
		}
	
		case 3:
		{
			if( waveState==1 )
            {
				biNum = 0b00000000;			// The fifth state of bipolar wave driver
				waveState=2;
				return;
			}
			
            if( waveState==2 )
            {
				biNum = 0b00110000;			// The sixth state of bipolar wave driver
				biState++;				
				waveState=1;
				return;
			}
		}
	
		case 4:
		{
			if( waveState==1 )
            {
				biNum = 0b00010000;			// The seventh state of bipolar wave driver
				waveState=2;
				return;
			}
			
            if( waveState==2 )
            {
				biNum = 0b11010000;			// The eighth state of bipolar wave driver
				biState=1;
				waveState=1;
				return;
			}
		}
	}
}

void bipolar_ccw_wave(void)					// Move the bipolar motor with wave driver counterclockwise
{
	switch( biState)
	{
		case 1:
		{
			if( waveState==1 )
            {
				biNum = 0b00010000;			// Reverse the sequence of states to move in opposite direction
				waveState=2;
				return;
			}
			
            if( waveState==2 )
            {
				biNum = 0b00100000;
				biState++;
				waveState=1;
				return;
			}
		}
		case 2:
		{
			if( waveState==1 )
            {
				biNum = 0b00000000;
				waveState=2;
				return;
			}
			
            if( waveState==2 )
            {
				biNum = 0b11000000;
				biState++;
				waveState=1;
				return;
			}
			
		}
	
		case 3:
		{
			if( waveState==1 )
            {
				biNum = 0b01000000;
				waveState=2;
				return;
			}
			
            if( waveState==2 )
            {
				biNum = 0b01110000;
				biState++;				
				waveState=1;
				return;
			}

		}
	
		case 4:
		{
			if( waveState==1 )
            {
				biNum = 0b01010000;
				waveState=2;
				return;
			}
			
            if( waveState==2 )
            {
				biNum = 0b10010000;
				biState=1;
				waveState=1;
				return;
			}
		}
	}
}

void mode1(void)
{
	switch( step )
	{
		case 1:
		{
			while( !RB5 )                   // move unipolor motor to vertical interrupter
			{
				unipolar_ccw_full();
				PORTD = uniNum;
				SwitchDelay();
			}
			step++;
			return;
		}
		case 2:
		{
			while( !RB6 )                   // move bipolor motor to vertical interrupter
			{
				bipolar_cw_full();
				PORTD = biNum;
				SwitchDelay();
			}
			step++;
			return;
		}
		case 3:
		{
			while( !RB4 )                   // move unipolar motor to horizontal interrupter
			{
				unipolar_cw_full();
				PORTD = uniNum;
				SwitchDelay();
			}
			step++;
			return;
		}
		case 4:
		{
			while( !RB7 )                   // move bipolar motor to vertical interrupter
			{
				bipolar_ccw_full();
				PORTD = biNum;
				SwitchDelay();
			}
			step = 1;
			return;
		}
	}
}

void mode2(void)
{
	switch( step )
	{
		case 1:
		{
			while(!RB5 || !RB6)             // move two motors to vertical interrupters
			{
				if( !RB5 )
					unipolar_ccw_full();
				if( !RB6 )
					bipolar_cw_full();
				PORTD = uniNum + biNum;     // actuation command is the summation of two codes
				SwitchDelay();
			}
			step++;
			return;
		}

		case 2:
		{
			while(!RB4 || !RB7)             // move two motors to horizontal interrupters
			{
				if(!RB4)
					unipolar_cw_full();
				if(!RB7)
					bipolar_ccw_full();
				PORTD = uniNum + biNum;
				SwitchDelay();
			}
			step = 1;
			return;
		}
	}
}

void mode3(void)
{
	switch( step )
	{
		case 1:
		{
			while(!RB4 || !RB6)             // move unipolar motor to horizontal, bipolar motor to vertical
			{
				if(!RB4)
					unipolar_ccw_full();
				if(!RB6)
					bipolar_ccw_full();
				PORTD = uniNum + biNum;
				SwitchDelay();
			}
			step++;
			return;
		}
		case 2:
		{
			while(!RB5 || !RB7)             // move unipolor motro to vertical, bipolor motor to horizontal
			{
				if(!RB5)
					unipolar_cw_full();
				if(!RB7)
					bipolar_cw_full();
				PORTD = uniNum + biNum;
				SwitchDelay();
			}
			step = 1;
			return;
		}
	}
}

void mode4(void)
{
	switch( step )
	{
		case 1:
		{
			while(!RB5 || !RB6)
			{
				if(!RB5)
					unipolar_ccw_wave();
				if(!RB6)
					bipolar_cw_wave();
				PORTD = uniNum + biNum;
				SwitchDelay2();
				if(!RB6)
					bipolar_cw_wave();
				PORTD = uniNum + biNum;
				SwitchDelay2();
			}
			step++;
			return;
		}
		case 2:
		{
			while(!RB4 || !RB7)
			{
				if(!RB4)
					unipolar_cw_wave();
				if(!RB7)
					bipolar_ccw_wave();
				PORTD = uniNum + biNum;
				SwitchDelay2();
				if(!RB7)
					bipolar_ccw_wave();
				PORTD = uniNum + biNum;
				SwitchDelay2();
			}
			step = 1;
			return;
		}
	}
}

void err(void)                              // turn on error LED
{
	PORTB = octal+0b1000;
	while(1){}
}

void init( void )
{

	while(!RB4 || !RB7)
	{
		if(!RB4)
			unipolar_ccw_full();
		if(!RB7)
			bipolar_ccw_full();
		SwitchDelay();
		PORTD = uniNum + biNum;
	}

	return;
}

void check_mode(void)
{
	if (octal == 1)                 // mode 1
	{
		while(1)
		{
			while(!redButton)       // wait for red button press
			{
				if(greenButton)
				{
					// whenever greenbutton is press during this period, terminate 
                    // the function call.
					while(!greenButton){} 
					return;
				}	
			}	
			while( redButton){}		// wait for red button release
			
			mode1();
		}
	}

	else if (octal == 2)            // mode 2
	{
		init();
		uniState = 1;
		biState = 1;
		step = 1;
		while(1)
		{
			while(!redButton)		// wait for red button press
			{
				if(greenButton)
				{
					while(!greenButton){} 
					return;
				}	
			}
			while(redButton){}		// wait for red button release

			while(!redButton)		// keep moving until red button is pressed again
				mode2();	
			while(redButton){}		// wait for red button release
		}
	}

	else if (octal == 3)            // mode 3
	{
		// starting location to mode 3
		while (!RB5||!RB7)
		{
			if(!RB5)
				unipolar_ccw_full();
			if(!RB7)
				bipolar_ccw_full();
			PORTD = uniNum + biNum;
			SwitchDelay();
		}
		uniState = 1;
		biState = 1;
		step = 1;
		while(1)
		{
			while(!redButton)		// wait for red button press
			{
				if(greenButton)
				{
					while(!greenButton){} 
					return;
				}	
			}
			while(redButton){}		// wait for red button release

			while(!redButton)		// keep moving until red button is pressed again
				mode3();	
			while(redButton){}		// wait for red button release
		}
	}

	else if (octal == 4)
	{
		while(!RB4||!RB7)           // initialize horizontal postion with wave drive sequence
		{
			if(!RB4)
				unipolar_cw_wave();
			if(!RB7)
				bipolar_cw_wave();
			PORTD = uniNum + biNum;
			SwitchDelay();
		}

		
		uniState = 1;
		biState = 1;
		step = 1;
		while(1)
		{
			while(!redButton)		// wait for red button press
			{
				if(greenButton)
				{
					while(!greenButton){} 
					return;
				}	
			}
			while(redButton){}		// wait for red button release

			while(!redButton)		// keep moving until red button is pressed again
				mode4();	
			while(redButton){}		// wait for red button release
		}	
	}

	else
	{
		err();
	}
}


//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
void main(void)
{
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	// configurations
	TRISB = 0b11110000;	            // Interrupter Sensor
	TRISC = 0b00000011;	            // Button
	TRISD = 0b00000000;	            // Motor Control
	TRISE = 0b00001111;             //
	ADCON1 = 0b11111111;            // disable analog's

	PORTB = 0b00000000;             // clear PORTB
	PORTC = 0b00000000;             // clear PORTC
	PORTD = 0b00000000;             // clear PORTD

	init();                         // recover default motor postion
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	while(!greenButton){}  		    // wait for green button press
	while( greenButton){}		    // Wait for green button release
	SwitchDelay(); 				    // Let switch debounce
	
	while(1)                        // re-read octal swtich upon every green button press
	{
		octal = ~(PORTE);           // take complement
		octal = octal & 0b00000111; // extract last three bits
		PORTB = octal;              // display octal on PORTB
		check_mode();
	}
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
}
