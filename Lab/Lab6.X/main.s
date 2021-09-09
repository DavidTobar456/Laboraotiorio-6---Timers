; Archivo: main.s
; Autor: David Antonio Tobar López
    
; Programa: LED intermitente con interrupción de Timer 2
; Compilador: pic-as(v2.32)
; Hardware: PIC16F887, 1 LEDS, 1 R220 Ohms
    
; Fecha de creación: 7 de septiembre 2021
; Última fecha de modificación: 7 des septiembre de 2021

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
  
  res_TMR2  macro
    banksel PORTA
    bcf    TMR2IF
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
	btfsc	TMR2IF
	call	int_tmr2
    POP:
	swapf	STATUS_TEMP,w
	movwf	STATUS
	swapf	W_TEMP,f
	swapf	W_TEMP,w
    retfie
    
    int_tmr2:
	movlw	001B
	xorwf	PORTE,f
	res_TMR2
    return
    
  PSECT CODE, delta=2,abs
    ORG 100h
    ;------------Configuración---------------
    main:
	call config_io
	call config_osc
	call config_int
	call config_tmr2
	BANKSEL PORTA
    ;--------------Loop----------------------
    loop:
	goto loop
    
    ;------------Sub-rutinas-----------------
    config_io:
	BANKSEL ANSEL
	clrf	ANSEL
	clrf	ANSELH
	
	BANKSEL TRISA
	clrf	TRISE
	
	BANKSEL	PORTA
	movlw	001B
	movwf	PORTE
    return
    
    config_osc:
	BANKSEL OSCCON
	bcf	IRCF2
	bsf	IRCF1
	bsf	IRCF0;	Se configura el reloj a 500kHz
	bsf	SCS;	Se usa el reloj interno
    return
    
    config_int:
	BANKSEL PORTA
	bsf GIE
	bsf PEIE
	
	BANKSEL	PIE1
	bsf TMR2IE
	
	BANKSEL PORTA
	bcf TMR2IF
    return
    
    config_tmr2:
	BANKSEL PORTA
	bsf	TOUTPS3
	bsf	TOUTPS2
	bsf	TOUTPS1
	bsf	TOUTPS0
	
	bsf	TMR2ON
	
	bsf	T2CKPS1
    return


