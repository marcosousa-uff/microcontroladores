; BRAÇO.ASM     : ACIONAMENTO DE UM BRAÇO ROBÓTICO CONSTRUIDO COM 2 MOTORES DE PASSO
;                Input do usuário uma de 8 teclas para o acionamento
;                Código modificado do stepper1.asm
;                modificado para fazer simulaçao nos leds do reads51 TTY
#include <SFR51.inc>   ; definições de todos os SFRs
CSEG at 0000h
org 0000h
ljmp 2040h
ORG  2000h             ;localização deste programa
;B2C55 localizações de memória p0-> PA,PB,PC expansão de portas
port_b       EQU 0x4001  ;82c55B  : porta B
port_c       EQU 0x4002  ;82c55C  : porta C
port_abc_pgm EQU 0x4003  ;82c55pgm  : registro de programação
esc          EQU 0x003E  ;Checagem da tecla ESC do paulmon2
;Upper    EQU 0x0040          ;Converter Acc para caixa alta
;cout     EQU 0x0030          ;Imprime o acumulador na porta serial
;Cin      EQU 0x0032          ;AGUARDA (prende a CPU) um byte da porta serial e coloca no acumulador
;pint8u   EQU 0x004D          ;Imprime Acc em um inteiro de 0 ate 255
; cabeçalho: todo programa deve ter um, para o PAULMON2 poder gerenciar
DB  0xA5, 0xE5, 0xE0, 0xA5 ;bytes de assinatura
DB  35,255,0,0             ;id (35=prog)
DB  0,0,0,0                ;prompt code vector
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;definido pelo usuário
DB  255,255,255,255        ;tamanho e checksum (255=não usado)
DB  "BRACO", 0             ;máximo de 31 caracteres mais o zero
ORG 2040h                  ;executável do código começa aqui
sjmp begin
;NOSSAS VARIAVEIS 
dphc EQU 7Fh               ;guarda copia do dptr para a pstri
dplc EQU 7Eh               ;
port_1       EQU 0x90

;NOSSAS SUBROTINAS -----------------------------------------------------------------------------

; ----------
pstri:               ;esta subrotina supoe que o dptr esta apontando para uma string0
  mov   dphc,dph    ;guarda dptr original
  mov   dplc,dpl    
  pop   dph         ;pega o endereço da string a ser impressa
  pop   dpl
  push  acc         ;salva o acumulador
pstr1:
  clr   a           ;limpa o acumulador
  movc  a,@a+dptr   ;pega um caracter a ser impresso
  inc   dptr        ;avança o dptr para o proximo caracter
  jz    pstr2       ;se ja for o '0' saia
; mov   c,acc.7     ;senão copia para o carry o bit 7 do acc
; anl   a,#7fh      ;apaga o bit 7
  lcall cout        ;imprime o caracter
  jc    pstr2       ;se o carry estiver ligado saia
  sjmp  pstr1       ;senão vai tratar o proximo caracter
pstr2:
  pop   acc         ;recupera o acumulador
  push  dpl         ;repoe endereço de retorno
  push  dph
  mov   dph,dphc    ;recupera o dptr original
  mov   dpl,dplc
  ret
;-----------------------------------------------------------------------------------------------
cout:
 setb ti       ;so para simulacao
 jnb ti,cout
 clr ti 
 mov sbuf,a 
 ret
 
cin: 
 jnb ri,cin
 clr ri
 mov a,sbuf
 ret  
; cinn:          ;nao usaremos cinn pois queremos que o motor se movimente e pare
; jnb r1,ret_cinn
; mov a,sbuf
begin:
;prepara a porta de programação do 8255
  mov   dptr,#port_abc_pgm   ;registro de programação do 8255
  mov   a,#128               ;PA=out,PB=out,PC=out (128)    =128
  movx  @dptr,a              ;programa 8255   :   movx - memória externa
  acall pstri DB "Programa BRACO: aciona um braco robotico com 2 motores de passo",13,10,10,0
  acall pstri DB "Digite o numero do acionamento usando o teclado numerico (NUMLOCK): ",13,10,0
  acall pstri DB "7 8 9",13,10,0
  acall pstri DB "4   6",13,10,0
  acall pstri DB "1 2 3",13,10,0

inicio0:
  lcall cin                  ;aguarda o input do usuario
  cjne  a,#'1',not_1         ;salta se não é 1
  mov   dptr,#baixo_esq           ;dptr->tabela 1
  sjmp  fora
not_1:
  cjne  a,#'2',not_2         ;salta se não é 2
  mov   dptr,#baixo           ;dptr->tabela 2
  sjmp  fora
not_2:

cjne  a,#'3',not_3         ;salta se não é 3
  mov   dptr,#baixo_dir           ;dptr->tabela 3
  sjmp  fora
not_3:
  cjne  a,#'4',not_4         ;salta se não é 4
  mov   dptr,#esq           ;dptr->tabela 4
  sjmp  fora
not_4:
  cjne  a,#'6',not_6         ;salta se não é 6
  mov   dptr,#dir           ;dptr->tabela 6
  sjmp  fora
not_6:
  cjne  a,#'7',not_7         ;salta se não é 7
  mov   dptr,#cima_esq           ;dptr->tabela 7
  sjmp  fora
not_7:
  cjne  a,#'8',not_8         ;salta se não é 8
  mov   dptr,#cima           ;dptr->tabela 8
  sjmp  fora
not_8:
  cjne  a,#'9',not_9         ;salta se não é 9
  mov   dptr,#cima_dir           ;dptr->tabela 9
  sjmp  fora
not_9:
  cjne  a,#27,inicio0       ;se não for válido retorna
  mov   a,#00000000b        ;configuração que desliga as bobinas
  mov   dptr,#port_b        ;aponta para as bobinas
  movx  @dptr,a             ;desliga as bobinas
  cpl   a                   ;inverte a configuração 
  mov   dptr,#port_c        ;dptr -> porta c
  movx  @dptr,a             ;desliga as bobinas
  acall pstri DB "Fim da Execucao",0
  ret                       ;retorna ao PAULMON2
fora:
  lcall cout              ;valida o input do usuário
  mov   b,#4              ;conta linhas tabela
loop:
  clr    a                ;a <- 0
  movc   a,@a+dptr        ;pega uma configuração da tabela
  push   dph              ;salva na pilha os "bits altos" do dptr
  push   dpl              ;salva na pilha os "bits baixos" do dptr
  mov    dptr,#port_b     ;faz o dptr apontar para a porta b
  ;mov    dptr,p1
  movx   @dptr,a          ;energiza a bobina atual
  cpl    a                ;inverte a configuração
  ;mov    dptr,#port_c     ;dptr -> bobinas
  mov    dptr,#port_1
  ;movx   @dptr,a          ;liga as bobinas 
  mov    p1,a
  mov a,#0xFF
  pop    dpl              ;recupera os "bits baixos" do dptr
  pop    dph              ;recupera os "bits altos" do dptr
  mov    r4,#30           ;o loop externo sera executado 9 vezes
delay2:
  mov    r5,#100          ;o loop interno ser executado 100 vezes
delay3:
  nop                     ;ciclo de máquina sem uso
  nop
  djnz   r5,delay3        ;conta o loop interno
  djnz   r4,delay2        ;conta o loop externo
  inc    dptr             ;proxima linha da tabela
  djnz   b,loop           ;percorre proxima linha da tabela
  ljmp   inicio0          ;volta a aguardar novo comando do usuário

baixo_esq:                  ;1 baixo esquerda    
    DB 00010001b
    DB 00100010b
    DB 01000100b
    DB 10001000b
baixo:                  ;2 baixo           
    DB 00010000b
    DB 00100000b
    DB 01000000b
    DB 10000000b 
baixo_dir:                  ;3 baixo direita
    DB 00011000b
    DB 00100100b
    DB 01000010b
    DB 10000001b
esq:                  ;4 esquerda
    DB 00000001b
    DB 00000010b
    DB 00000100b
    DB 00001000b
dir:                  ;6 direita
    DB 00001000b
    DB 00000100b
    DB 00000010b
    DB 00000001b
cima_esq:                  ;7 cima esquerda
    DB 10000001b
    DB 01000010b
    DB 00100100b
    DB 00011000b
cima:                  ;8 cima
    DB 10000000b
    DB 01000000b
    DB 00100000b
    DB 00010000b
cima_dir:                  ;9 cima direita
    DB 10001000b
    DB 01000100b
    DB 00100010b
    DB 00010001b

    END                          ;Fim
