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

#define PINSEL_UART1 			0x50000UL
#define LCR_MASK_DLAB_ON	0x9FUL
#define LCR_MASK_DLAB_OFF	0x1FUL
#define DLL_MASK					41UL
#define DLM_MASK					0x00UL
#define FCR_MASK					0x07UL
#define PCLOCK						12500000UL
#define PUT_MASK					0x20UL //THRE-Maske
#define GET_MASK					0x1UL // RDR-Maske


void init_uart1(unsigned long baudrate, unsigned long data_bits, unsigned long stop_bits, unsigned long parity_type);	
void uart1_putc(char c);	
char uart1_getc(void);
void uart1_puts(char *s);
unsigned long read_hex32(void);
unsigned char read_hex8(void);
void print_hex8(unsigned char val);
int hexCharToInt(char c);


int main (void) {
	char cmd;
	unsigned long addr;
	unsigned char data;
	unsigned char *ptr;
	int i;
	
	
	init_uart1(19200, 8, 2, 2); //1: Baudrate, 2: Datenbits, 3: Stoppbits, 4: Parity 
	
	for(i = 0; i < 10; i++) {
		uart1_putc('0' + i);
	}
	uart1_puts("\r\n");
	
	while(1) {
		cmd = uart1_getc();
		uart1_putc(cmd);
		while(cmd != 'D' && cmd != 'E') { //////////////////////////////////////
			uart1_puts(" Only 'D' and 'E' allowed\r\n");
			cmd = uart1_getc();
			uart1_putc(cmd);
		}; 
		
		uart1_getc(); // Leerzeichen
		uart1_putc(0x20); //echo
		
		if (cmd == 'D') {
			
			addr = read_hex32();
			ptr = (unsigned char *)addr;
			
			uart1_puts("\r\n");
			print_hex8((addr >> 24) & 0xFF);
			print_hex8((addr >> 16) & 0xFF);
			print_hex8((addr >> 8) & 0xFF);
			print_hex8(addr & 0xFF);
			uart1_puts(": ");
			print_hex8(*ptr);
			uart1_puts("\r\n");
		}
			
		if (cmd == 'E') {
			addr = read_hex32();
			uart1_getc(); // Leerzeichen
			uart1_putc(0x20); //echo
			data = read_hex8();

			ptr = (unsigned char *)addr;
			*ptr = data;

			uart1_puts("\r\n");
		}
	}
}

void init_uart1(unsigned long baudrate, unsigned long data_bits, unsigned long stop_bits, unsigned long parity_type) {
	unsigned long bd_low = ((PCLOCK / (16 * baudrate)) % 256);
	unsigned long bd_high = ((PCLOCK / (16 * baudrate)) / 256);
	PINSEL0 |= PINSEL_UART1; 
	U1LCR |= (data_bits - 5); 
	U1LCR |= (stop_bits - 1) << 2; 
	U1LCR |= (1 << 7); // DLAB_ON
	if(parity_type == 0) { // 0 = keine Parität; 1 = ungerade parität ; 2 = gerade Parität
		U1LCR |= (0 << 3);
	} else {
			U1LCR |= (1 << 3);
			U1LCR |= (parity_type - 1) << 4;
	}
	U1DLL = bd_low; // Divisor Latch Least Significant Byte: Divisor für Baudrate von 4800 bei 12,5 MHz = 163 = 0xA3 in Hex
	U1DLM = bd_high; // Divisor Latch Most Significant Byte: leer, da Divisor kleiner als 255 und somit in die ersten 8 Bit passt
	U1LCR &= (0x7F); // DLAB 'Divisor Latch Access Bit' wieder deaktiviert
	U1FCR = FCR_MASK;
}

void uart1_putc(char c) {
    while (!(U1LSR & (PUT_MASK))); // !!!
    U1THR = c;
}

char uart1_getc(void) {
	while (!(U1LSR & GET_MASK)); // !!!
	return U1RBR;
}

void uart1_puts(char *s) {
	while (*s) {
		uart1_putc(*s++);
	}
}

unsigned long read_hex32(void) {
    unsigned long value = 0;
    char c;
    int i;

    for (i = 0; i < 8; i++) {
        c = uart1_getc();
        uart1_putc(c); // Echo
				if (c == 0x0D) {
					return value;
				}
        value = (value << 4) | hexCharToInt(c);
    }

    return value;
}

unsigned char read_hex8(void) {
    char c1, c2;

    c1 = uart1_getc(); uart1_putc(c1);
    c2 = uart1_getc(); uart1_putc(c2);

    return (hexCharToInt(c1) << 4) | hexCharToInt(c2);
}

void print_hex8(unsigned char val) {
    char hex[]="0123456789ABCDEF";

    uart1_putc(hex[val >> 4]);
    uart1_putc(hex[val & 0x0F]);
}

int hexCharToInt(char c) {
	if(c >= '0' && c <= '9') return c - '0';
	if(c >= 'A' && c <= 'F') return c - 'A' + 10;
	if(c >= 'a' && c <= 'f') return c - 'a' + 10;
	return 0;
}
