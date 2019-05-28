;STEPPERBI.ASM   MOTOR DE PASSO BIDIRECIONAL NO SIMULADOR
;                Código modificado do stepper.asm
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
upper    EQU 0x0040          ;Converter Acc para caixa alta
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
dir  EQU 7Ch               ;guarda a direção do acionamento

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
 
;cin: 
; jnb ri,cin
; clr ri
; mov a,sbuf
; ret  
 cinn:          ;nao usaremos cinn pois queremos que o motor se movimente e pare
 jnb ri,ret_cinn
 mov a,sbuf
 ret_cinn:
  ret
begin:
;prepara a porta de programação do 8255
  mov   dptr,#port_abc_pgm   ;registro de programação do 8255
  mov   a,#128               ;PA=out,PB=out,PC=out (128)    =128
  movx  @dptr,a              ;programa 8255   :   movx - memória externa
  acall pstri DB "Programa Stepper1 aciona um motor de passo com direcao",13,10,10,0
  acall pstri DB "Escolha a direcao do acionamento (D/E): ",13,10,10,0
  mov dir,#0

inicio0:
  lcall cinn                  ;aguarda o input do usuario 
  cjne  a,#'E',not_E         ;salta se não é E
  mov   dptr,#esquerda           ;dptr->tabela esquerda
  cjne  a,dir,gez
  sjmp  fora
not_E:
  cjne  a,#'D',not_D         ;salta se não é D
  mov   dptr,#direita           ;dptr->tabela direita
  cjne  a,dir,gez
  sjmp  fora
not_D:
  cjne  a,#27,inicio0      ;se não for válido retorna
  mov   a,#00000000b        ;configuração que desliga as bobinas
  mov   dptr,#port_b        ;aponta para as bobinas
  movx  @dptr,a             ;desliga as bobinas
  cpl   a                   ;inverte a configuração 
  mov   dptr,#port_c        ;dptr -> porta c
  movx  @dptr,a             ;desliga as bobinas
  acall pstri DB "Fim da Execucao",0
  ret                       ;retorna ao PAULMON2
gez:
  lcall cout              ;valida o input do usuário
  mov dir,a
  sjmp fora
fora:
  mov   b,#4              ;conta linhas tabela  lcall cout              
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
  mov    r4,#255           ;o loop externo sera executado 9 vezes
delay2:
  mov    r5,#255          ;o loop interno ser executado 100 vezes
delay3:
  nop                     ;ciclo de máquina sem uso
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  nop nop nop
  djnz   r5,delay3        ;conta o loop interno
  djnz   r4,delay2        ;conta o loop externo
  inc    dptr             ;proxima linha da tabela
  djnz   b,loop           ;percorre proxima linha da tabela
  ljmp   inicio0          ;volta a aguardar novo comando do usuário


direita:                    ;tabela do sentiro horário
    DB 00001000b
    DB 00000100b
    DB 00000010b
    DB 00000001b
esquerda:                      ;tabela do sentido anti-horário
    DB 00000001b
    DB 00000010b
    DB 00000100b
    DB 00001000b 

    END                          ;Fim