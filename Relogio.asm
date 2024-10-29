; --- Mapeamento de Hardware (8051) ---
    RS      equ     P1.3    ;Reg Select ligado em P1.3
    EN      equ     P1.2    ;Enable ligado em P1.2
    LED     equ     P1.0    ;LED ligado em P1.0 para sinalizar alarme
 LCALL sendCharacter
    MOV A, #' '

    HORA_ALARME   equ     01   
    MINUTO_ALARME equ     12  

org 0000h
    LJMP START

org 0030h
START:
    MOV R5, #00	;Inicia Horas
    MOV R3, #50  ; Inicia minutos
    LCALL lcd_init           ; Inicializa o LCD

   
    MOV TMOD, #01h          
    MOV TH0, #3Ch            
    MOV TL0, #0B0h           
    SETB TR0                

LOOP:
    ; Verifica se é o horário do alarme
    MOV A, R5
    CJNE A, #HORA_ALARME, CHECA_MINUTO
    MOV A, R3
    CJNE A, #MINUTO_ALARME, EXIBIR_HORA
    
    ; Ativa o alarme se o horário coincidir
    LCALL alarme_ativado
   

CHECA_MINUTO:
    ; Exibir valor de horas (R5) e minutos (R3) no LCD
EXIBIR_HORA:
    MOV A, #06h               
    LCALL posicionaCursor      
    MOV A, R5
    MOV B, #10
    DIV AB                    
    ADD A, #30h               
    LCALL sendCharacter       
    MOV A, B
    ADD A, #30h               
    LCALL sendCharacter       
	
    MOV A, #08h               
    LCALL posicionaCursor      
    MOV A, R3
    MOV B, #10
    DIV AB                    
    ADD A, #30h               
    LCALL sendCharacter       
    MOV A, B
    ADD A, #30h               
    LCALL sendCharacter       

    JNB TF0, LOOP             
    CLR TF0                   
    MOV TH0, #3Ch             
    MOV TL0, #0B0h
    INC R3                    ; Adiciona minutos

    CJNE R3, #60, LOOP
    MOV R3, #00               ; Volta minutos para 00
    INC R5                    ; Adiciona 1 hr
    CJNE R5, #24, LOOP
    MOV R5, #00               ; Volta para 00 horas 

    JMP LOOP                  


alarme_ativado:
    
    LCALL clearDisplay
    LCALL sendCharacter
    MOV A, #' '
    LCALL sendCharacter
    MOV A, #' '
	  LCALL sendCharacter
    MOV A, #' '
    LCALL sendCharacter
    MOV A, #' '
    LCALL sendCharacter
    MOV A, #' '
    LCALL sendCharacter
    MOV A, #'T'
    LCALL sendCharacter
    MOV A, #'O'
    LCALL sendCharacter
    MOV A, #'C'
    LCALL sendCharacter
    MOV A, #'A'
    LCALL sendCharacter
    MOV A, #'N'
    LCALL sendCharacter
    MOV A, #'D'
    LCALL sendCharacter
    MOV A, #'O'
    LCALL sendCharacter

    ; Ligar o LED para sinalizar o alarme
    SETB LED                   ; Aciona LED do alarme
    
    ; Espera 1 minuto usando o Timer 0
    MOV TH0, #3Ch
    MOV TL0, #0B0h
    SETB TR0                   ; Inicia o Timer
    WAIT_1MIN:
    JNB TF0, WAIT_1MIN         ; Espera até que o Timer alcance 1 minuto
    CLR TF0                    ; Limpa o flag do Timer
    CLR TR0                    ; Para o Timer

    ; Desativa o LED e limpa a mensagem de alarme
    CLR LED
    LCALL clearDisplay
    RET

; Inicialização do display LCD
lcd_init:
	CLR RS		               ; clear RS - indica que instruções estão sendo enviadas

	; Function set - modo 4 bits
	CLR P1.7		            
	CLR P1.6		            
	SETB P1.5		            
	CLR P1.4		            

	SETB EN		                
	CLR EN		                
	LCALL delay		            

	SETB EN		                
	CLR EN		                

	SETB P1.7		            

	SETB EN		                
	CLR EN		                
	LCALL delay		            

	; Entry mode set - incrementa sem shift
	CLR P1.7		            
	CLR P1.6		            
	CLR P1.5		            
	CLR P1.4		            

	SETB EN		                
	CLR EN		                

	SETB P1.6		            
	SETB P1.5		            

	SETB EN		                
	CLR EN		                
	LCALL delay		            

	; Display on/off control
	CLR P1.7		            
	CLR P1.6		            
	CLR P1.5		            
	CLR P1.4		            

	SETB EN		                
	CLR EN		                

	SETB P1.7		            
	SETB P1.6		            
	SETB P1.5		            
	SETB P1.4		            

	SETB EN		                
	CLR EN		                
	LCALL delay		            
	RET

; Envio de caracteres para o display
sendCharacter:
	SETB RS  		            
	MOV C, ACC.7		        
	MOV P1.7, C		            
	MOV C, ACC.6		        
	MOV P1.6, C		            
	MOV C, ACC.5		        
	MOV P1.5, C		            
	MOV C, ACC.4		        
	MOV P1.4, C		            

	SETB EN			            
	CLR EN			            

	MOV C, ACC.3		        
	MOV P1.7, C		            
	MOV C, ACC.2		        
	MOV P1.6, C		            
	MOV C, ACC.1		        
	MOV P1.5, C		            
	MOV C, ACC.0		        
	MOV P1.4, C		            

	SETB EN			            
	CLR EN			            

	LCALL delay			        
	RET

; Posiciona o cursor no display LCD
posicionaCursor:
	CLR RS		                 
	SETB P1.7		            
	MOV C, ACC.6		        
	MOV P1.6, C		            
	MOV C, ACC.5		        
	MOV P1.5, C		            
	MOV C, ACC.4		        
	MOV P1.4, C		            

	SETB EN			            
	CLR EN			            

	MOV C, ACC.3		        
	MOV P1.7, C		            
	MOV C, ACC.2		        
	MOV P1.6, C		            
	MOV C, ACC.1		        
	MOV P1.5, C		            
	MOV C, ACC.0		        
	MOV P1.4, C		            

	SETB EN			            
	CLR EN			            

	LCALL delay			        
	RET

; Limpa o display
clearDisplay:
	CLR RS		                 
	CLR P1.7		            
	CLR P1.6		            
	CLR P1.5		            
	CLR P1.4		            

	SETB EN		                
	CLR EN		                

	CLR P1.7		            
	CLR P1.6		            
	CLR P1.5		            
	SETB P1.4		            

	SETB EN		                
	CLR EN		                
	LCALL delay		            
	RET

; Função de delay
delay:
	MOV R0, #60
	DJNZ R0, $
	RET
