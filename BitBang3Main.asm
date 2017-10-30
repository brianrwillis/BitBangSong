/******************************************************************************
* EE244 Lab 4
* Plays the hobbit theme from LOTR but it's kinda bad
* Brian Willis, 3/10/17
******************************************************************************/
                .syntax unified        // define syntax
                .cpu cortex-m4
                .fpu fpv4-sp-d16

                .globl main

/******************************** Addresses ********************************/
.equ SIM_SCGC5, 0x40048038				// clock
.equ PORTA_PCR1, 0x40049004				// GPIO
.equ GPIOA_PDDR, 0x400FF014				// direction
.equ GPIOA_PDOR, 0x400FF000				// output


/******************************** Constants ********************************/
.equ CLOCK_DATA, 0x200					// clock on for port A
.equ PORTA_PCR1_DATA, 0x100				// set as GPIO
.equ GPIOA_PDDR_DATA, 0x2				// set direction


/****************************** Useful Equates *****************************/
.equ CLOCK_FREQ, 120
.equ INIT_DELAY, 5000000
.equ SENTINEL, 0xFFFFFFFF

// half period of square wave in microseconds to play note
.equ D_5, 852				// 5th octave
.equ C_5, 956
.equ E_5, 759
.equ F_5, 716
.equ G_5, 638
.equ A_5, 568
.equ B_5, 506
.equ C_4, 1908				// 4th octave
.equ A_4, 1136
.equ B_4, 1012
.equ D_6, 426

.equ C_FLAT_5, 506			// flat
.equ D_FLAT_5, 903
.equ E_FLAT_5, 804
.equ F_FLAT_5, 759
.equ G_FLAT_5, 676
.equ A_FLAT_5, 602
.equ B_FLAT_5, 537
.equ A_FLAT_4, 1205
.equ B_FLAT_4, 1073
.equ D_FLAT_6, 451

.equ C_SHARP_5, 903			// sharp
.equ D_SHARP_5, 804
.equ E_SHARP_5, 716
.equ F_SHARP_5, 676
.equ G_SHARP_5, 602
.equ A_SHARP_5, 537
.equ B_SHARP_5, 506

/*
.equ EIGHTH, 250000			// note duration in microseconds (120 BPM)
.equ QUARTER, 500000
.equ HALF, 1000000
.equ WHOLE, 2000000
*/

.equ EIGHTH, 125000			// note duration in microseconds (240 BPM)
.equ QUARTER, 250000
.equ HALF, 500000
.equ WHOLE, 1000000

.equ ART, 15625				// articulation duration in microseconds (draw breath)
.equ HOLD, 0				// hold breath inbetween notes (no rest)

/*
.equ EIGHTH_A, 234375		// note duration minus articulation (120 BPM)
.equ QUARTER_A, 484375
.equ HALF_A, 984375
.equ WHOLE_A, 1984375
*/

.equ EIGHTH_A, 109375			// note duration in microseconds (240 BPM)
.equ QUARTER_A, 234375
.equ HALF_A, 484375
.equ WHOLE_A, 984375

                .section .text
main:
				ldr R0, =SIM_SCGC5				// start clock
				ldr R1, =CLOCK_DATA
				str R1, [R0]

				ldr R0, =PORTA_PCR1				// set Port A as GPIO
				ldr R1, =PORTA_PCR1_DATA
				str R1, [R0]

				ldr R0, =GPIOA_PDDR				// set Port A as output
				ldr R1, =GPIOA_PDDR_DATA
				str R1, [R0]

songloop:
				ldr R6, =ShittyLOTR

noteloop:
				ldr R0, [R6], #4
				cmp R0, 0xFFFFFFFF				// if at end of song, loop back
				beq songloop

				bl Delayus						// first val is rest

				ldr R0, [R6], #4
				cmp R0, 0xFFFFFFFF
				beq songloop

				ldr R1, [R6], #4
				cmp R1, 0xFFFFFFFF
				beq songloop

				bl PlayNote						// 2nd val is note, 3rd is duration


rest:
				mov R0, R1
				bl Delayus

				b noteloop



/******************************* Subroutines *******************************/


/****************************************************************************
* void Delayus(INT32U us)
*
* Desc: This subroutine pauses the program for microseconds specified
* by its parameter.
* 120 cycles is one microsecond delay due to 120MHz clock on K22F.
* Need (us x 120) total cycles for correct delay.
*
* Params: Desired microsecond delay as 32-bit integer
* Returns: none
* MCU: K22F, system clock of 120MHz
* Brian Willis 3/07/2017
****************************************************************************/
Delayus:
				push {lr}

				ldr R3, =#CLOCK_FREQ		// 120MHz
				mul R1, R0, R3				// us x clock frequency is number of necessary cycles to delay 'us' microseconds

				ldr R2, =#0					// counter

				ldr R3, =#4					// branch takes 4 total cycles each loop
				udiv R1, R3					// number of branch loops = (120 x us)/4

branch:
				cmp R2, R1
				add R2, #1
				bne branch					// branch is 2 cycles

				pop {pc}


/****************************************************************************
* void PlayNote(INT32U h_period, INT32U us)
*
* Desc: This subroutine plays a note of specified frequency for
* specified duration.
*
* Params: Half period of note to play,
*		  Microsecond duration of note
* Returns: none
* MCU: K22F, system clock of 120MHz
* Brian Willis 3/09/2017
****************************************************************************/
PlayNote:
				push {R4, R5, R6, lr}	// cycles = us / (h_period x 2)

				mov R4, R1
				mov R3, R0

				ldr R6, =#2
				mul R3, R6
				udiv R4, R3

				ldr R5, =GPIOA_PDOR

loop:
				subs R4, #1
				beq exit

				ldr R2, =#0
				str R2, [R5]
				bl Delayus

				ldr R2, =#2
				str R2, [R5]
				bl Delayus

				b loop

exit:
				pop {R4, R5, R6, pc}


                .section .rodata

// Entries are rest, frequency of note, and note duration, respectively
// Last entry is a sentinel value of all Fs.

// This song is similar the Hobbit Theme from LOTR except it's shitty
// because I'm not a musician and also I wasn't very careful and also they use a violin I guess
ShittyLOTR:		.word INIT_DELAY		//Initial rest
				.word G_5, WHOLE_A, ART		//Measure 1
				.word F_5, HALF_A, ART, D_5, QUARTER_A, ART, F_5, QUARTER_A, ART		//2
				.word G_5, HALF, HOLD, G_5, QUARTER_A, ART, B_FLAT_5, QUARTER_A, ART		//3
				.word C_5, QUARTER_A, ART, D_5, EIGHTH_A, ART, C_5, EIGHTH_A, ART, B_FLAT_5, QUARTER_A, ART, A_5, QUARTER_A, ART		//4
				.word G_5, WHOLE		//5
				.word QUARTER, D_5, QUARTER_A, ART, G_5, QUARTER_A, ART, A_5, QUARTER_A, ART		//6
				.word A_5, WHOLE, HOLD		//7
				.word A_5, QUARTER_A, ART, B_FLAT_5, QUARTER_A, ART, C_5, QUARTER_A, ART, B_FLAT_5, EIGHTH_A, ART, F_5, EIGHTH_A, ART		//8
				.word G_5, WHOLE		//9
				.word HALF, D_5, QUARTER_A, ART, F_5, QUARTER_A, ART		//10
				.word G_5, HALF, HOLD, G_5, QUARTER_A, ART, B_FLAT_5, QUARTER_A, ART		//11
				.word C_5, QUARTER_A, ART, D_6, EIGHTH_A, ART, C_5, EIGHTH_A, ART, B_FLAT_5, QUARTER_A, ART, A_5, QUARTER_A, ART		//12
				.word G_5, WHOLE		//13
				.word QUARTER, D_5, QUARTER_A, ART, G_5, QUARTER_A, ART, A_5, QUARTER_A, ART		//14
				.word A_5, WHOLE, HOLD		//15
				.word A_5, QUARTER_A, ART, B_FLAT_5, QUARTER_A, ART, A_5, QUARTER_A, ART, B_FLAT_5, EIGHTH_A, ART, A_5, EIGHTH_A, ART		//16
				.word G_5, WHOLE		//17
				.word QUARTER, B_FLAT_5, QUARTER_A, ART, C_5, QUARTER, HOLD, C_5, EIGHTH_A, ART, A_5, EIGHTH_A, ART		//18
				.word D_6, WHOLE, HOLD		//19
				.word D_6, QUARTER_A, ART, B_FLAT_5, QUARTER_A, ART, C_5, QUARTER, HOLD, C_5, EIGHTH_A, ART, G_5, EIGHTH_A, ART		//20
				.word A_5, WHOLE, HOLD		//21
				.word A_5, QUARTER_A, ART, D_5, QUARTER_A, ART, F_5, QUARTER_A, ART, A_5, QUARTER_A, ART		//22
				.word B_FLAT_5, WHOLE, HOLD		//23
				.word B_FLAT_5, QUARTER_A, ART, C_5, EIGHTH_A, ART, B_FLAT_5, EIGHTH_A, ART, A_5, QUARTER_A, ART, F_5, QUARTER_A, ART		//24
				.word G_5, WHOLE		//25
				.word QUARTER, D_5, QUARTER_A, ART, D_5, QUARTER_A, ART, F_5, QUARTER_A, ART		//27
				.word B_FLAT_5, QUARTER_A, ART, C_5, EIGHTH_A, ART, B_FLAT_5, EIGHTH_A, ART, A_5, QUARTER_A, ART, F_5, QUARTER_A, ART		//28
				.word F_5, WHOLE		//29
				.word QUARTER, D_5, QUARTER_A, ART, G_5, QUARTER_A, ART, A_5, QUARTER_A, ART		//30
				.word A_5, QUARTER_A, ART, A_5, HALF, HOLD, A_5, QUARTER_A, ART		//31
				.word B_FLAT_5, QUARTER_A, ART, C_5, EIGHTH_A, ART, B_FLAT_5, EIGHTH_A, ART, A_5, QUARTER_A, ART, G_5, QUARTER_A, ART		//32
				.word A_5, WHOLE		//33
				.word QUARTER, B_FLAT_5, QUARTER_A, ART, C_5, QUARTER, HOLD, C_5, EIGHTH_A, ART, A_5, EIGHTH_A, ART		//34
				.word D_6, WHOLE, HOLD		//35
				.word D_6, QUARTER_A, ART, B_FLAT_5, QUARTER_A, ART, C_5, QUARTER, HOLD, C_5, EIGHTH_A, ART, G_5, EIGHTH_A, ART		//36
				.word A_5, WHOLE, HOLD		//37
				.word A_5, QUARTER_A, ART, D_5, QUARTER_A, ART, F_5, QUARTER_A, ART, A_5, QUARTER_A, ART		//38
				.word B_FLAT_5, QUARTER_A, ART, B_FLAT_5, HALF, HOLD, B_FLAT_5, QUARTER_A, ART		//39
				.word A_5, QUARTER, HOLD, A_5, EIGHTH_A, ART, F_5, EIGHTH_A, ART, G_5, HALF, HOLD		//40
				.word G_5, WHOLE, HOLD		//41
				.word SENTINEL

                .section .bss




