;********************************************************************
;* htw saar - Fakultaet fuer Ingenieurwissenschaften				*
;* Labor fuer Eingebettete Systeme									*
;* Mikroprozessortechnik											*
;********************************************************************
;* Assembler_Startup.S: 											*
;* Programmrumpf fuer Assembler-Programme mit dem Keil				*
;* Entwicklungsprogramm uVision fuer ARM-Mikrocontroller			*
;********************************************************************
;* Aufgabe-Nr.: 2 Laborversuch 1               						*
;*              			*						    			*
;********************************************************************
;* Gruppen-Nr.: 			*										*
;*              			*										*
;********************************************************************
;* Name / Matrikel-Nr.:  	*										*
;* 							*										*
;*							*										*
;********************************************************************
;* Abgabedatum: 			*              							*
;* 18.12.2025				*										*
;********************************************************************
DIV_9			EQU			0x38E38E39 	; mit n=1
DIV_10			EQU			0xCCCCCCCD	; mit n=3
;********************************************************************
;* Daten-Bereich bzw. Daten-Speicher				            	*
;********************************************************************
				AREA		Daten, DATA, READWRITE
Datenanfang
X				EQU			Datenanfang
Top_Stack		EQU			Datenanfang + 0x800
Datenende		EQU 		Top_Stack
;********************************************************************
;* Programm-Bereich bzw. Programm-Speicher							*
;********************************************************************
				AREA		Programm, CODE, READONLY
				ARM
Reset_Handler	MSR			CPSR_c, #0x10	; User Mode aktivieren, Reset Handler bereitet Programmstart vor und ist die erste Zeile Code die ausgeführt wird, initialisiert u. a. SP
;********************************************************************
;* Hier das eigene (Haupt-)Programm einfuegen   					*
;********************************************************************
				LDR		SP, =Top_Stack
				LDR     R0, =X     ; R0 = &STRING			!!! '=' liest entweder Adresse von String ein, oder bei Konstanten den Wert, s. DIV_9
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
				STMFD	SP!, {LR}
                MOV     R2, #0   		; Zwischenspeicher für Ergebnis / Akku
				MOV		R5, #0			; Status-Flag
				
                ; erstes Zeichen holen
                LDRB    R1, [R0]        ; R1 = *R0, erstes Byte/ 2 HexZahlen
				CMP		R1, #CHAR_MINUS ; '-'
				MOVEQ	R5, R1			; Setze Flag in R5 bei Minus
				
				CMPNE	R1, #CHAR_PLUS	; '+'
				ADDEQ	R0, R0, #1		; Gehe im Register um ein Wort weiter			

AtoI_Loop
                LDRB    R1, [R0], #1        ; aktuelles Zeichen
                CMP     R1, #0          ; Stringende
                BEQ     AtoI_End  		; ja -> fertig
          
                SUB     R1, R1, #CHAR_0 	; ASCII-Zeichen in Ziffer 0..9 umwandeln: Zahl = Char - 0x30

                MOV     R4, R2, LSL #3      ; R4 = result*8			LSL #3 = Logical Shift Left mit 2^3 = 8, Befehl wird von Rechts nach links ausgeführt, zuerst LSL auf R2, dann Move, auch bei Add o. Änhlichen
                ADD     R4, R4, R2, LSL #1  ; R4 = result*8 + result*2 = result*10
                ADD     R2, R4, R1          ; result = result*10 + digit

                ;ADD     R0, R0, #1 		; nächstes Zeichen, alternativ, da LDRB #1 inkrementiert
                B       AtoI_Loop
				
AtoI_End
				CMP		R5, #0			; negative Flag prüfen
				RSBNE	R2, R2, #0		; Reverse Substract Not Equals, 0 - R2, falls negative Flag gesetzt ist, um Zahl zu negieren
				
				MOV 	R0, R2			; Ergebnis in R0 abspeichern
				LDMFD	SP!, {LR}
				BX		LR
				

Formel			
				STMFD	SP!, {LR}
				LDR		R1, =DIV_9		; MagicNumber für DIV mit 9 wird in R1 geladen
				
				MUL		R2, R0, R0		; X^2 in R2 abgespeichert
				UMULL	R3, R4, R2, R1	; x^2 wird mit MagicNumber multipliziert, UMULL anstelle von SMULL, da R2 immer positiv ist, da R2 = R0^2 
				MOV		R3, R4, LSR #1	; Rechts-Shift um n = 1, s. Skript S. 96 Tabelle 18, damit Ergebnis nicht mehr als LONG vorliegt, herunterskalieren durch Rechts-Shift nach mul mit MagicNumber -> LSR #1 == * 2^-n, ASR nicht notwendig, da niemals - vorliegt
				MOV		R0, R3, LSL #2	; Term wird mit 2^2 = 4 multipliziert und in R0 gespeichert , R3 low, R4 high
										;Mitunter Rundungfehler, da zuerst geteilt wird und dann multipliziert, Kommazahlen werden immer abgeschnitten Bsp: 8/9 = 0
				LDMFD	SP!, {LR}
				BX		LR
				

uItoBCD		
				STMFD	SP!, {LR}
				LDR		R5, =DIV_10		; MagicNumber für DIV mit 10 wird in R1 geladen
				
				MOV		R1, #0			; Zwischenergebnis
				MOV 	R2, #0			; Shift-Parameter		
				
uItoBCD_Loop
				CMP 	R0, #0			; Prüft ob R0 fertig ist
				BEQ		uItoBCD_Done
				
				UMULL	R3, R6, R0, R5	; R5 == Konstante
				MOV		R3, R6, LSR #3 	; q = R0 / 10 mit MagicNumber von R5 und Shift um 3
				
				MOV		R4, R3, LSL #3
				ADD		R4, R4, R3, LSL #1 	; R4 = q * 10 -> Modulo Rechnung Bsp.: 12/10 = 1 -> 1*10 = 10 -> 12-10 = 2 == Rest
				
				SUB 	R4,	R0, R4		; rest = R0 - q * 10 == R0 - R4
				
				;MOV		R7, R4, LSL R2	; Ergebnis wird um R2 nach Links geshifted und in R7 gespeichert um BCD zu bauen
				ADD		R1, R1, R4, LSL R2		; Ergebnis += R7 Egal ob ADD, EOR order ORR, da die Anzahl an Nullstellen
				
				MOV 	R0, R3		; Zwischenergebnis für Modulorechnung in R0 schreiben
				ADD		R2, R2, #4	; R2 - Shiftamount um 4 erhöhen -> eine Hex-Stelle weiter shiften
				
				B		uItoBCD_Loop
				
uItoBCD_Done			
				MOV 	R0, R1
				LDMFD	SP!, {LR}
				BX		LR
				
				
Berechnungen	
				STMFD	SP!, {LR}		; Store Multiple Full Descending, PUSH, Full Descending - Stack Pointer SP zeigt immer auf letztes belegtes Element, Stack wächst von hohen zu niedrigen Speicheradressen
				
                BL      AtoI            ; Branch with Link, merkt sich den Ursprung des branches in LR, im gegensatz zu 'B'
				
				BL		Formel			; Aufruf von Unterprogramm Formel
				
				BL 		uItoBCD			; Aufruf von Unterprogramm uItoBCD
				
				LDMFD	SP!, {LR}		; Load Multiple Full Descending, POP
				
				BX		LR				; BX = Branch and Exchange, Exchange um u.a. in Thumb Modus wechseln zu können, B kann nur Label wie 'uItoBCD' lesen und offset berechnen, aber keine register wie 'LR', deshalb BX LR um aus Unterprogramm zu verlassen

                
;********************************************************************
;* Konstanten im CODE-Bereich                                       *
;********************************************************************
;********************************************************************
;* Ende der Programm-Quelle                                         *
;********************************************************************
				END
