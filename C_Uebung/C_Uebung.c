/********************************************************************/
/*  Hochschule fuer Technik und Wirtschaft                          */
/*  Fakultät fuer Ingenieurwissenschaften                           */
/*  Labor fuer Eingebettete Systeme                                 */
/*  Mikroprozessortechnik                                           */
/********************************************************************/
/*                                                                  */
/*  C_Übung.C:                                                      */
/*	  Programmrumpf fuer C-Programme mit dem Keil                   */
/*    Entwicklungsprogramm uVision fuer ARM-Mikrocontroller         */
/*                                                                  */
/********************************************************************/
/*  Aufgaben-Nr.:        *                                          */
/*                       *                                          */
/********************************************************************/
/*  Gruppen-Nr.: 	       *                                          */
/*                       *                                          */
/********************************************************************/
/*  Name / Matrikel-Nr.: *                                          */
/*                       *                                          */
/*                       *                                          */
/********************************************************************/
/* 	Abgabedatum:         *                                          */
/*                       *                                          */
/********************************************************************/

#include <LPC21xx.H>		/* LPC21xx Definitionen                     */

// GPIO 0 masks
#define SEG7_MASK 		(0x01FC0000)
#define BCD_MASK			(0x00003C00)
#define S1_MASK				(0x00010000)
#define S2_MASK				(0x00020000)

// GPIO 1 masks
#define LED_MASK 			(0x00FF0000)
#define S3_MASK				(0x02000000)


// Timer match interrupt
void T0_Match_ISR(void) __irq;

// LED functions
void led_init(void);
void led_display(unsigned long bcd_wert);
void led_clear(void);
void led_walk(unsigned long led_count);


// BCD functions
void bcd_init(void);
unsigned long bcd_read(void);


// SEG7 display functions
void seg7_init(void); 
void seg7_display(unsigned long bcd_wert);
void seg7_clear(void);


// Switch functions
void switch_init();

// Timer functions
void timer_init(void);
void timer_start(void);
void timer_stop(void);
void timer_reset(void);
void timer_set_period(unsigned long);
void timer_update_period(unsigned long period);



static unsigned long led_count = 0;
static int seg7_count = 0;


const unsigned long seg7_table[] = {
   0x00FC0000, // 0
   0x00180000, // 1
   0x016C0000, // 2
   0x013C0000, // 3
   0x01980000, // 4
   0x01B40000, // 5
   0x01F40000, // 6
   0x001C0000, // 7
   0x01FC0000, // 8
   0x01BC0000  // 9
};
	
const unsigned long bcd_period_table[] = {
	2,
	5,
	10,
	25,
	50,
	100,
	250,
	500,
	750,
	1000
};


int main (void)  
{
	/* Initialisierung */
	VICVectAddr0 = (unsigned long) T0_Match_ISR;
	VICVectCntl0 = (1 << 5) | 4; 										// Slot aktivieren und Kanal 4 (Timer)
	VICIntEnable = (1 << 4);												// Interrupts für Kanal 4 aktivieren (Peripherie)
	
	led_init();
	bcd_init();
	seg7_init();
	switch_init();
	timer_init();
	
	timer_start();
	
 	/* Endlosschleife */	
 	while (1)  
	{
		;
	}
}




// ISR

void T0_Match_ISR(void) __irq {
	volatile unsigned int running = (IOPIN0 & S1_MASK) >> 16;
	volatile unsigned int led_reverse = (IOPIN0 & S2_MASK) >> 17;
	volatile unsigned int seg7_reverse = (IOPIN1 & S3_MASK) >> 25;

	if(!running) {
			led_clear();
			seg7_clear();
	} else {
			// Intervall nur bei Bedarf ändern
        unsigned long current_period = bcd_period_table[bcd_read()];
        if (T0MR0 != current_period) {
            T0MR0 = current_period;
						T0TC  = 0;
        }

        // LED Logik
        led_walk(led_count);
        if (led_reverse) led_count = (led_count + 7) % 8;
        else             led_count = (led_count + 1) % 8;
        
        // 7-Segment Logik
        seg7_display(seg7_count);
        if (seg7_reverse) seg7_count = (seg7_count + 9) % 10;
        else              seg7_count = (seg7_count + 1) % 10;
    }

	// Interrupt quittieren 
	 T0IR |= 0x01;
	
	VICVectAddr = 0x00;
}



// LED functions

void led_init(void) {
	IODIR1 |= LED_MASK;		// setzt alle Bits der Maske in IODIR0 = 1 -> Ausgabe-Bits
	IOCLR1 = LED_MASK;
}

void led_display(unsigned long bcd_wert) {
	IOCLR1 = LED_MASK;
	IOSET1 = bcd_wert<<16;
}

void led_clear(void){
	IOCLR1 = LED_MASK;
}

void led_walk(unsigned long wert) {
    if(wert > 7) {
        return;
    }

    IOCLR1 = LED_MASK;
    IOSET1 |= (1 << (16 + wert));
}



// BCD functions

void bcd_init(void) {
	IODIR0 &= ~BCD_MASK;  // setzt alle Bits der Maske in IODIR1 = 0 -> Eingabe-Bits, ohne die Ausgabe-Bits zu verändern
}

unsigned long bcd_read(void) {
	return (IOPIN0 & BCD_MASK)>>10;
}





// SEG7 display functions

void seg7_init(void) {
	IODIR0 |= SEG7_MASK;	// setzt alle Bits der Maske in IODIR1 = 1 -> Ausgabe-Bits
	IOCLR0 = SEG7_MASK;		//Pins 0.18 bis 0.24 auf LOW setzen als Initialzustand
}

void seg7_display(unsigned long wert) {
	IOCLR0 = SEG7_MASK;
	if (wert <= 9 && wert >= 0) {
		IOSET0 = seg7_table[wert];
	}
}

void seg7_clear(void) {
	IOCLR0 = SEG7_MASK;
}





// Switch functions

void switch_init(void) {
	IODIR0 &= ~(S1_MASK | S2_MASK);
	IODIR1 &= ~S3_MASK;
}





// Timer functions

void timer_init(void) {
	timer_reset();
	
	// Prescaler
	T0PR = 12500;
	
	// Match Register
	T0MR0 = bcd_period_table[bcd_read()];
	
	// Match Control Register
	T0MCR = 0x03;						// Interrupt & Timer-Reset bei MR0
	// T0MCR = 0x07; 				// Alternativ + Timer-Stop bei MR0
}

void timer_start(void) {
	if(T0TCR != 0x01) {
		T0TCR = 0x01;
	}
}

void timer_stop(void) {
	T0TCR = 0x00;
}
void timer_reset(void) {
	T0TCR = 0x02;
}
void timer_set_period(unsigned long period) {
	T0MR0 = period;
}
void timer_update_period(unsigned long period) {
	timer_stop();
	timer_set_period(period);
	timer_reset();
	timer_start();
}
