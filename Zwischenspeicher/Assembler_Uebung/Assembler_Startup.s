;********************************************************************
;* htw saar - Fakultaet fuer Ingenieurwissenschaften				*
;* Labor fuer Eingebettete Systeme									*
;* Mikroprozessortechnik											*
;********************************************************************
;* Assembler_Startup.S: 											*
;* Programmrumpf fuer Assembler-Programme mit dem Keil				*
;* Entwicklungsprogramm uVision fuer ARM-Mikrocontroller			*
;********************************************************************
;* Aufgabe-Nr.: 2.1        	*	               						*
;*              			*						    			*
;********************************************************************
;* Gruppen-Nr.: 8			*										*
;*              			*										*
;********************************************************************
;* Name / Matrikel-Nr.:  	*										*
;* Eric Lorenc / 5013021	*	  									*
;*							*										*
;********************************************************************
;* Abgabedatum:         	*              							*
;*							*										*
;********************************************************************
DIV_9			EQU			0x38E38E39 	; mit n=1
DIV_10			EQU			0xCCCCCCCD	; mit n=3
;********************************************************************
;* Daten-Bereich bzw. Daten-Speicher				            	*
;********************************************************************
				AREA		Daten, DATA, READWRITE
Datenanfang
;********************************************************************
;* Programm-Bereich bzw. Programm-Speicher							*
;********************************************************************
				AREA		Programm, CODE, READONLY
				ARM
Reset_Handler	MSR			CPSR_c, #0x10	; User Mode aktivieren

;********************************************************************
;* Hier das eigene (Haupt-)Programm einfuegen   					*
;********************************************************************
				BL		Berechnungen		
;********************************************************************
;* Ende des eigenen (Haupt-)Programms                               *
;********************************************************************
endlos			B			endlos

;********************************************************************
;* ab hier Unterprogramme                                           *
;********************************************************************
CHAR_0      EQU     0x30    ; '0'
CHAR_PLUS   EQU     0x2B    ; '+'
CHAR_MINUS  EQU     0x2D    ; '-'

AtoI
                ; Initialisierung
                MOV     R2, #0         
                MOV     R3, #0          

                ; erstes Zeichen holen
                LDRB    R1, [R0]        ; R1 = *R0, erstes Byte/ 2 HexZahlen
				CMP		R1, #CHAR_MINUS
				MOVEQ	R5, R1			; Setze Flag in R5 bei Minus
				
				CMPNE	R1, #CHAR_PLUS
				ADDEQ	R0, R0, #1		; Gehe im Register um ein Wort weiter

AtoI_Loop
                LDRB    R1, [R0]        ; aktuelles Zeichen
                CMP     R1, #0          ; Stringende
                BEQ     AtoI_End  		; ja -> fertig
          
                SUB     R1, R1, #CHAR_0 	; ASCII-Zeichen in Ziffer 0..9 umwandeln: Zahl = Char - 0x30

                MOV     R4, R2, LSL #3      ; R4 = result*8			LSL #3 = Logical Shift Left mit 2^3 = 8
                ADD     R4, R4, R2, LSL #1  ; R4 = result*8 + result*2 = result*10
                ADD     R2, R4, R1          ; result = result*10 + digit

                ADD     R0, R0, #1 		; nächstes Zeichen
                B       AtoI_Loop
				
AtoI_End
				CMP		R5, #0			; negative Flag prüfen
				RSBNE	R2, R2, #0		; 0 - R2, falls negative Flag gesetzt ist, um Zahl zu negieren
				
				MOV 	R0, R2
				BX		LR
				
				
Formel			
				MUL		R2, R0, R0		; X^2 in R2 abgespeichert
				UMULL	R3, R4, R2, R1	; x^2 wird mit MagicNumber multipliziert, UMULL anstelle von SMULL, da R2 immer positiv ist, da R2 = R0^2 
				MOV		R3, R4, LSR #1	; Rechts-Shift um n = 1, s. Skript S. 96 Tabelle 18, damit Ergebnis nicht mehr als LONG vorliegt, herunterskalieren durch Rechts-Shift nach mul mit MagicNumber -> LSR #1 == * 2^-n
				MOV		R0, R3, LSL #2	; Term wird mit 2^2 = 4 multipliziert und in R0 gespeichert
				
				BX		LR
				

uItoBCD		
				MOV		R1, #0
				MOV 	R2, #0
				MOV 	R6, #10
				
uItoBCD_Loop
				CMP 	R0, #0
				BEQ		uItoBCD_Done
				
				UMULL	R3, R7, R0, R5
				MOV		R3, R7, LSR #3 
				
				MOV		R4, R3, LSL #3
				ADD		R4, R4, R3, LSL#1
				SUB 	R4,	R0, R4
				
				MOV		R8, R4, LSL R2
				ADD		R1, R1, R8
				
				MOV 	R0, R3
				ADD		R2, R2, #4
				
				B		uItoBCD_Loop
				
uItoBCD_Done			
				MOV 	R0, R1
				BX		LR
				
				
Berechnungen	
				STMFD	SP!, {LR}
				
				LDR     R0, =STRING     ; R0 = &STRING
                BL      AtoI            ; R0 = konvertierte Zahl signed int
				
				LDR		R1, =DIV_9		; MagicNumber für DIV mit 9 wird in R1 geladen
				BL		Formel			; Aufruf von Unterprogramm Formel
				
				LDR		R5, =DIV_10		; MagicNumber für DIV mit 10 wird in R1 geladen
				BL 		uItoBCD			; Aufruf von Unterprogramm uItoBCD
				
				LDMFD	SP!, {LR}
				
				BX		LR

                
;********************************************************************
;* Konstanten im CODE-Bereich                                       *
;********************************************************************
STRING          DCB     "-100",0x00      ; '\0'-terminierter String, in hex = 0xffffff92
				ALIGN	
;********************************************************************
;* Ende der Programm-Quelle                                         *
;********************************************************************
				END
