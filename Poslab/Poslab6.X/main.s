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
  
  res_TMR0 macro
    BANKSEL PORTA
    movlw   131
    movwf   TMR0
    bcf	    T0IF
  endm
  
  res_TMR1 macro
    BANKSEL PORTA
    movlw   00001011B
    movwf   TMR1H
    movlw   11011100B
    movwf   TMR1L
    bcf	    TMR1IF
  endm
  
  res_TMR2 macro
    BANKSEL PORTA
    bcf	    TMR2IF
  endm
  
  div	macro	divisor,cociente,residuo
	movwf	conteo
	clrf	conteo+1
	
	incf	conteo+1
	movlw	divisor
	subwf	conteo,f
	btfsc	STATUS,0
	goto	$-4
	
	decf	conteo+1,w
	movwf	cociente
	
	movlw	divisor
	addwf	conteo,w
	movwf	residuo
  endm
  
  PSECT udata_bank0
    cont:	DS 1
    disp1:	DS 1
    disp2:	DS 1
    divisorV:	DS 1
    decenas:	DS 1
    unidades:	DS 1
    conteo:	DS 1
  
  PSECT udata_shr
    W_TEMP:	    DS 1
    STATUS_TEMP:    DS 1
  
  PSECT resVet, class=CODE, delta=2, abs
    ORG 00h
    resetVec:
	PAGESEL main
	goto	main
  
  PSECT intVect, class=CODE, delta=2,abs
    ORG 04h
    PUSH:
	movwf	W_TEMP
	swapf	STATUS,w
	movwf	STATUS_TEMP
    ISR:
	btfsc	TMR1IF
	call	int_tmr1
	btfsc	T0IF
	call	int_tmr0
	btfsc	TMR2IF
	call	int_tmr2
    POP:
	swapf	STATUS_TEMP,w
	movwf	STATUS
	swapf	W_TEMP,f
	swapf	W_TEMP,w
    retfie
    
    int_tmr0:
	res_TMR0
	movlw	110B
	xorwf	PORTE,f
	btfsc	PORTE,1
	goto	mostrar_disp1
	btfsc	PORTE,2
	goto	mostrar_disp2
    return
    
    mostrar_disp1:
	movf	disp1,w
	movwf	PORTC
    return
    
    mostrar_disp2:
	movf	disp2,w
	movwf	PORTC
    return
    
    int_tmr1:
	incf	cont
	res_TMR1
    return
    
    int_tmr2:
	movlw	001B
	xorwf	PORTE
	res_TMR2
    return
    
  PSECT CODE, delta=2,abs
    ORG 100h
    tabla:
	clrf	PCLATH
	bsf	PCLATH, 0
	andlw	0x0F;
	addwf	PCL;
	retlw	00111111B; cero
	retlw	00000110B; uno
	retlw	01011011B; dos
	retlw	01001111B; tres
	retlw	01100110B; cuatro
	retlw	01101101B; cinco
	retlw	01111101B; seis
	retlw	00000111B; siete
	retlw	01111111B; ocho
	retlw	01100111B; nueve
	retlw	01110111B; A
	retlw	01111100B; b
	retlw	00111001B; C
	retlw	01011110B; D
	retlw	01111001B; E
	retlw	01110001B; F
    ;----------Config-----------
    main:
	call	config_io
	call	config_osc
	call	config_int
	call	config_tmr0
	call	config_tmr1
	call	config_tmr2
	BANKSEL PORTA
    ;-----------Loop------------
    loop:
	movf	cont,w
	movwf	PORTA
	call	ver_limite
	call	preparar_displays
	goto	loop
    ;----Sub-rutinas config-----
    config_io:
	BANKSEL ANSEL
	clrf	ANSEL
	clrf	ANSELH
	
	BANKSEL TRISA
	clrf	TRISA
	clrf	TRISC
	clrf	TRISE
	
	BANKSEL PORTA
	clrf	PORTC
	clrf	PORTA
	movlw	011B
	movwf	PORTE
    return
    
    config_osc:
	BANKSEL OSCCON
	bcf	IRCF2
	bsf	IRCF1
	bsf	IRCF0
	bsf	SCS
    return
    
    config_int:
	BANKSEL PORTA
	bsf	GIE
	bsf	PEIE
	bsf	T0IE
	
	BANKSEL TRISA
	bsf	TMR1IE
	bsf	TMR2IE
	
	BANKSEL PORTA
	bcf	T0IF
	bcf	TMR1IF
	bcf	TMR2IF
    return
    
    config_tmr0:
	BANKSEL	TRISA
	bcf	T0CS
	bcf	PSA
	bsf	PS2
	bsf	PS1
	bcf	PS0
	res_TMR0
    return
    
    config_tmr1:
	BANKSEL PORTA
	bsf	TMR1ON
	bcf	TMR1CS
	bcf	T1CKPS1
	bsf	T1CKPS0
	res_TMR1
    return
    
    config_tmr2:
	BANKSEL PORTA
	bsf	TMR2ON
	bsf	T2CKPS1
	bsf	TOUTPS3
	bsf	TOUTPS2
	bsf	TOUTPS1
	bsf	TOUTPS0
	
	BANKSEL TRISA
	movlw	244
	movwf	PR2
	
	res_TMR2
    return
    ;-------Sub-rutinas---------
    ver_limite:
	movlw	100
	subwf	cont,w
	btfsc	STATUS,2
	clrf	cont
    return
    
    preparar_displays:
	movf	cont,w
	
	div	10, decenas, unidades
	
	movf	decenas,w
	call	tabla
	movwf	disp1
	movf	unidades,w
	call	tabla
	movwf	disp2
    return


