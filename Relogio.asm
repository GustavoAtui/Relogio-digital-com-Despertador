; --- Mapeamento de Hardware (8051) ---
    RS      equ     P1.3         ; Registro Select do LCD ligado em P1.3
    EN      equ     P1.2         ; Enable do LCD ligado em P1.2
    LED     equ     P1.0         ; LED de alarme ligado em P1.0

    LCALL sendCharacter		 ; Chama a sub-rotina para enviar um caractere ao LCD
    MOV A, #' '			 ; Move um caractere espaço para o acumulador

    HORA_ALARME   equ     00  	 ; Define a hora 
    MINUTO_ALARME equ     51  	 ; Define o minuto	

org 0000h
    LJMP START			 ; Salta para a rotina START ao iniciar

org 0030h
START:
    MOV R5, #00          	 ; Inicializa Horas
    MOV R3, #50          	 ; Inicializa minutos
    LCALL lcd_init       	 ; Inicializa o LCD

    MOV TMOD, #01h		 ; Configura Timer 0 em modo 1
    MOV TH0, #3Ch		 ; Carrega TH0 para gerar um atraso
    MOV TL0, #0B0h		 ; Carrega TL0 para gerar um atraso
    SETB TR0			 ; Inicia Timer 0

    ; Configurações de interrupções para o botão de parada do alarme
    SETB EA              ; Habilita interrupções globais
    SETB EX0             ; Habilita interrupção externa 0 (INT0)
    CLR IT0              ; Configura interrupção para nível baixo (acionada enquanto o botão é pressionado)

LOOP:
    ; Verifica se é o horário do alarme
    MOV A, R5
    CJNE A, #HORA_ALARME, CHECA_MINUTO	  ; Verifica se a hora coincide com a do alarme
    MOV A, R3
    CJNE A, #MINUTO_ALARME, EXIBIR_HORA   ; Verifica se o minuto coincide com o do alarme
    
    ; Ativa o alarme se o horário coincidir
    LCALL alarme_ativado         ; Chama a rotina do alarme

CHECA_MINUTO:
    ; Exibir valor de horas (R5) e minutos (R3) no LCD
EXIBIR_HORA:
    MOV A, #06h			   ; Configura posição do cursor no LCD para horas
    LCALL posicionaCursor
    MOV A, R5
    MOV B, #10
    DIV AB			   ; Converte a hora em formato de dígito
    ADD A, #30h
    LCALL sendCharacter
    MOV A, B
    ADD A, #30h
    LCALL sendCharacter

    MOV A, #08h			   ; Configura posição do cursor no LCD para minutos
    LCALL posicionaCursor
    MOV A, R3
    MOV B, #10
    DIV AB			   ; Converte o minuto em formato de dígito
    ADD A, #30h
    LCALL sendCharacter
    MOV A, B
    ADD A, #30h
    LCALL sendCharacter

    JNB TF0, LOOP		   ; Se Timer não estourou, volta ao LOOP
    CLR TF0			   ; Limpa flag de Timer
    MOV TH0, #3Ch
    MOV TL0, #0B0h
    INC R3                         ; Incrementa minutos

    CJNE R3, #60, LOOP		   ; Se minutos não chegaram a 60, continua no LOOP
    MOV R3, #00              	   ; Zera os minutos
    INC R5                   	   ; Soma +1 nas horas
    CJNE R5, #24, LOOP 		   ; Se horas não chegaram a 24, continua no LOOP
    MOV R5, #00              	   ; Zera as horas

    JMP LOOP			   ; Continua no LOOP principal

alarme_ativado:
    LCALL clearDisplay             ; Limpa o display antes de exibir o alarme

    ; Configura a posição inicial do cursor (mensagem alarme)
    MOV A, #06h                    ; Posição inicial 
    LCALL posicionaCursor

    MOV R2, #10                    ; Define 10 espaços em branco para limpar a linha
EXIBE_ESPACO:
    MOV A, #' '                    ; Caractere de espaço
    LCALL sendCharacter
    DJNZ R2, EXIBE_ESPACO          ; Repete até que R2 chegue a zero

    ; Exibe a mensagem "TOCANDO" no display
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

    ; Ativa o LED do alarme
    SETB LED

    ; Aguarda o botão * para desativar o alarme
AGUARDA_BOTAO:
    CALL SCAN_TECLADO             ; Chama a sub-rotina para escanear o teclado
    JNB P0.6, DESATIVA_ALARME     ; Se * foi pressionado, desativa alarme (no caso "Key 2" do teclado)
    SJMP AGUARDA_BOTAO            ; Continua aguardando o botão * ser pressionado

DESATIVA_ALARME:
    CLR LED                       ; Desativa o LED do alarme
    LCALL clearDisplay            ; Limpa o display para remover "TOCANDO"
    RET                           ; Retorna ao loop principal

; --- Scan do teclado do Edsim51 tecla asterisco  ---
SCAN_TECLADO:
    CLR P0.0                     ; Define Row0 para escanear linha da tecla *
    NOP                          ; Delay
    RET                          ; Retorno                     


; --- Funções de Controle do LCD ---

    
lcd_init:
	CLR RS		          	; Configura RS para indicar instruções
	CLR P1.7			; Define bits de dados	            
	CLR P1.6		            
	SETB P1.5		            
	CLR P1.4		            

	SETB EN		  		; Pulsa Enable para enviar instrução              
	CLR EN		                
	LCALL delay			; Chama delay para completar a operação            

	SETB EN		                
	CLR EN		                

	SETB P1.7			; Define modo 4 bits	            

	SETB EN		                
	CLR EN		                
	LCALL delay			; Delay para estabilização	            

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
	SETB RS  			; Configura RS para indicar dados		            
	MOV C, ACC.7			; Configura bits de dados com ACC	        
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
