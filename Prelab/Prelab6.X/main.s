; Archivo: main.s
; Autor: David Antonio Tobar López
    
; Programa: Contador con botones que se despliega en dos display usando solo
; un puerto
; Compilador: pic-as(v2.32)
; Hardware: PIC16F887, 8 LEDS, 8 R220 Ohms, 4 R470 Ohms, 2 Display 7-seg
; 2 push-button
    
; Fecha de creación: 24 de agosto 2021
; Última fecha de modificación: 24 de agosto de 2021

; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

PROCESSOR   16F887
#include <xc.inc>

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  
  res_TMR1 macro
    banksel PORTA
    movlw   00001011B
    movwf   TMR1H
    movlw   11011100B
    movwf   TMR1L
    bcf	    TMR1IF
  endm
  
  PSECT udata_bank0
    cont:   DS 1
    
  PSECT udata_shr
    W_TEMP:	    DS 1
    STATUS_TEMP:    DS 1
  
  PSECT resVet, class=CODE, delta=2, abs
    ORG 00h
    resetVec:
	PAGESEL main
	goto	main
  
  PSECT intVect, class=CODE, delta=2, abs
    ORG 04h
    PUSH:
	movwf	W_TEMP
	swapf	STATUS,w
	movwf	STATUS_TEMP
    ISR:
	btfsc	TMR1IF
	call	int_tmr1
    POP:
	swapf	STATUS_TEMP,w
	movwf	STATUS
	swapf	W_TEMP,f
	swapf	W_TEMP,w
    retfie
    
    int_tmr1:
	incf	cont
	res_TMR1
    return
    
  PSECT CODE, delta=2,abs
    ORG 100h
    ;------------Configuración---------------
    main:
	call config_io
	call config_osc
	call config_int
	call config_tmr1
	BANKSEL PORTA
    ;--------------Loop----------------------
    loop:
	movf	cont,w
	movwf	PORTA
	goto loop
    
    ;------------Sub-rutinas-----------------
    config_io:
	BANKSEL ANSEL
	clrf	ANSEL
	clrf	ANSELH
	
	BANKSEL TRISA
	clrf	TRISA
	
	BANKSEL	PORTA
	clrf	PORTA
    return
    
    config_osc:
	BANKSEL OSCCON
	bsf	IRCF2
	bcf	IRCF1
	bcf	IRCF0;	Se configura el reloj a 1MHz
	bsf	SCS;	Se usa el reloj interno
    return
    
    config_int:
	BANKSEL PORTA
	bsf GIE
	bsf PEIE
	
	BANKSEL	PIE1
	bsf PIE1,0
	
	BANKSEL PORTA
	bcf PIR1,0
    return
    
    config_tmr1:
	BANKSEL PORTA
	bsf	T1CKPS1
	bcf	T1CKPS0
	bcf	T1OSCEN
	bcf	TMR1CS
	bsf	TMR1ON
    return


