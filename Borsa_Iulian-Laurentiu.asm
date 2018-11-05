
.386
.model flat, stdcall

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc

;declaram simbolul start ca public - de acolo incepe executia
public start

;sectiunile programului, date, respectiv cod
.data
;aici declaram date

window_title DB "Tic-Tac-Toe",0
area_width EQU 640 
area_height EQU 480
area DD 0
par DB 0 ;hotaraste ordinea X, O, X si asa mai departe

counter DD 0 ;numara evenimentele de tip timer

arg1 EQU 8 ;simbolul de afisat
arg2 EQU 12 ;pointer la vectorul de pixeli
arg3 EQU 16 ;pozitie x
arg4 EQU 20 ;pozitie y 

;atunci cand cadranN este 0 inseamna ca se poate completa cu X sau O
cadran1 DB 0
cadran2 DB 0
cadran3 DB 0
cadran4 DB 0
cadran5 DB 0
cadran6 DB 0
cadran7 DB 0
cadran8 DB 0
cadran9 DB 0

;atunci cand x_N este 1 inseamna ca X ocupa cadranN
x_1 DD 0
x_2 DD 0
x_3 DD 0
x_4 DD 0
x_5 DD 0
x_6 DD 0
x_7 DD 0
x_8 DD 0
x_9 DD 0

;atunci cand o_N este 1 inseamna ca O ocupa cadranN
o_1 DD 0
o_2 DD 0
o_3 DD 0
o_4 DD 0
o_5 DD 0
o_6 DD 0
o_7 DD 0
o_8 DD 0
o_9 DD 0

;urmatoarele constante stabilesc ce dimensiune au simbolurile, mai exact 40x40
symbol_width EQU 40
symbol_height EQU 40
include x.inc
include letters.inc

.code

make_text proc
	push ebp
	mov ebp, esp
	pusha
	mov eax, [ebp+arg1] ;citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ;de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ;pointer la matricea de pixeli
	mov eax, [ebp+arg4] ;pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ;pointer la coord x
	shl eax, 2 ;inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi],0
	je simbol_pixel_alb
	mov eax,[ebp+24]
	mov dword ptr [edi], eax ;culoare caractere 
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

;un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y, culoare
	push culoare
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 20
endm

draw proc
	push ebp
	mov ebp, esp
	pusha
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
	

evt_click:

	mov eax, [EBP + arg3]
	mov ebx, [EBP + arg2]
;se verifica daca s-a dat click in afara cadranului negru cu sageata de replay
	cmp eax, 200 
	jg nu_restart
	cmp eax, 150
	jle nu_restart
	cmp ebx, 500
	jg nu_restart
	cmp ebx, 400
	jle nu_restart
	jmp restart ;s-a dat click in interiorul cadranului negru cu sageata de replay
	
nu_restart:
;se verifica daca s-a dat click in afara suprafetei de joc cu cele 9 cadrane pentru X si O
	cmp eax, 100
	jle evt_timer
	cmp eax, 400
	jge evt_timer
	cmp ebx, 100
	jle evt_timer
	cmp ebx, 400
	jge evt_timer
	
;se verifica al cui e randul pentru click: X - par si O - impar
	cmp par,1
	je e_impar
	jmp e_par
	
e_par:
;daca par = 0, atunci inseamna ca este randul lui X

	cmp ebx, 200 ;verifica daca s-a facut click in stanga sau in dreapta liniei dintre cadran1 si cadran2
	jl x_cadran_147 ;s-a dat click in stanga
	jmp x_cadran_n147 ;s-a dat click in dreapta
x_cadran_147: ;s-a dat click in cadran1, cadran4 sau cadran7
	cmp eax, 200 ;verifica daca s-a facut click mai sus sau mai jos fata de linia dintre cadran1 si cadran4
	jl x_cadran_1 ;s-a dat click mai sus
	jmp x_cadran_47 ;s-a dat click mai jos
x_cadran_1: ;s-a facut click in cadran1
	cmp cadran1, 1 ;verifica daca exista X sau O in cadran1
	jge evt_timer  ;sare pentru urmatorul click daca acest cadran a fost ocupat deja
	inc par ;s-a putut pune X in acest cadran, par devine 1, adica o sa fie randul lui O sa faca click
	make_text_macro '0', area, 130, 130, 0h	;deseneaza X in centrul cadran1
	inc x_1 ;s-a putut pune X in acest cadran, x_1 devine 1 si va ajuta la verificare pentru castigator 
	inc cadran1 ;s-a ocupat cadran1
	jmp evt_timer ;sare pentru urmatorul click
x_cadran_47:
	cmp eax, 300
	jl x_cadran_4
	jmp x_cadran_7
x_cadran_4:
	cmp cadran4, 1
	jge evt_timer 
	make_text_macro '0', area, 130, 230, 0h	
	inc x_4
	inc par
	inc cadran4
	jmp evt_timer
x_cadran_7:
	cmp cadran7, 1
	jge evt_timer 
	make_text_macro '0', area, 130, 330, 0h
	inc par
	inc x_7
	inc cadran7
	jmp evt_timer
x_cadran_n147:
	cmp ebx, 300
	jl x_cadran_258
	jmp x_cadran_369
x_cadran_258:
	cmp eax, 200
	jl x_cadran_2
	jmp x_cadran_58
x_cadran_2:
	cmp cadran2, 1
	jge evt_timer 
	make_text_macro '0', area, 230, 130, 0h
	inc par
	inc x_2
	inc cadran2
	jmp evt_timer
x_cadran_58:
	cmp eax, 300
	jl x_cadran_5
	jmp x_cadran_8
x_cadran_5:
	cmp cadran5, 1
	jge evt_timer 
	make_text_macro '0', area, 230, 230, 0h
	inc par
	inc x_5
	inc cadran5
	jmp evt_timer
x_cadran_8:
	cmp cadran8, 1
	jge evt_timer 
	make_text_macro '0', area, 230, 330, 0h
	inc par
	inc x_8
	inc cadran8
	jmp evt_timer
x_cadran_369:
	cmp eax, 200
	jl x_cadran_3
	jmp x_cadran_69
x_cadran_3:
	cmp cadran3, 1
	jge evt_timer 
	make_text_macro '0', area, 330, 130, 0h
	inc par
	inc x_3
	inc cadran3
	jmp evt_timer
x_cadran_69:
	cmp eax, 300
	jl x_cadran_6
	jmp x_cadran_9
x_cadran_6:
	cmp cadran6, 1
	jge evt_timer 
	make_text_macro '0', area, 330, 230, 0h
	inc par
	inc x_6
	inc cadran6
	jmp evt_timer
x_cadran_9:
	cmp cadran9, 1
	jge evt_timer 
	make_text_macro '0', area, 330, 330, 0h
	inc par
	inc x_9
	inc cadran9
	jmp evt_timer
	
e_impar:
	cmp ebx, 200
	jl o_cadran_147
	jmp o_cadran_n147
o_cadran_147:
	cmp eax, 200
	jl o_cadran_1
	jmp o_cadran_47
o_cadran_1:
	cmp cadran1, 1
	jge evt_timer 
	make_text_macro '1', area, 130, 130, 0FF0000h	
	dec par
	inc o_1
	inc cadran1
	jmp evt_timer
o_cadran_47:
	cmp eax, 300
	jl o_cadran_4
	jmp o_cadran_7
o_cadran_4:
	cmp cadran4, 1
	jge evt_timer 
	make_text_macro '1', area, 130, 230, 0FF0000h	
	inc o_4
	dec par
	inc cadran4
	jmp evt_timer
o_cadran_7:
	cmp cadran7, 1
	jge evt_timer 
	make_text_macro '1', area, 130, 330, 0FF0000h	
	dec par
	inc o_7
	inc cadran7
	jmp evt_timer
o_cadran_n147:
	cmp ebx, 300
	jl o_cadran_258
	jmp o_cadran_369
o_cadran_258:
	cmp eax, 200
	jl o_cadran_2
	jmp o_cadran_58
o_cadran_2:
	cmp cadran2, 1
	jge evt_timer 
	make_text_macro '1', area, 230, 130, 0FF0000h	
	dec par
	inc o_2
	inc cadran2
	jmp evt_timer
o_cadran_58:
	cmp eax, 300
	jl o_cadran_5
	jmp o_cadran_8
o_cadran_5:
	cmp cadran5, 1
	jge evt_timer 
	make_text_macro '1', area, 230, 230, 0FF0000h	
	dec par
	inc o_5
	inc cadran5
	jmp evt_timer
o_cadran_8:
	cmp cadran8, 1
	jge evt_timer 
	make_text_macro '1', area, 230, 330, 0FF0000h	
	dec par
	inc o_8
	inc cadran8
	jmp evt_timer
o_cadran_369:
	cmp eax, 200
	jl o_cadran_3
	jmp o_cadran_69
o_cadran_3:
	cmp cadran3, 1
	jge evt_timer 
	make_text_macro '1', area, 330, 130, 0FF0000h
	dec par
	inc o_3
	inc cadran3
	jmp evt_timer
o_cadran_69:
	cmp eax, 300
	jl o_cadran_6
	jmp o_cadran_9
o_cadran_6:
	cmp cadran6, 1
	jge evt_timer 
	make_text_macro '1', area, 330, 230, 0FF0000h	
	dec par
	inc o_6
	inc cadran6
	jmp evt_timer
o_cadran_9:
	cmp cadran9, 1
	jge evt_timer 
	make_text_macro '1', area, 330, 330, 0FF0000h	
	dec par
	inc o_9
	inc cadran9
	jmp evt_timer
	
evt_timer:
	
	xor ecx, ecx ;goleste ecx
	add ecx, x_1 
	add ecx, x_2
	add ecx, x_3
	cmp ecx, 3
	je victorie_x ;cadran1, cadran2 si cadran3 au fost ocupate de X
	xor ecx, ecx
	add ecx, x_4
	add ecx, x_5
	add ecx, x_6
	cmp ecx, 3
	je victorie_x
	xor ecx, ecx
	add ecx, x_7
	add ecx, x_8
	add ecx, x_9
	cmp ecx, 3
	je victorie_x
	xor ecx, ecx
	add ecx, x_1
	add ecx, x_4
	add ecx, x_7
	cmp ecx, 3
	je victorie_x
	xor ecx, ecx
	add ecx, x_2
	add ecx, x_5
	add ecx, x_8
	cmp ecx, 3
	je victorie_x
	xor ecx, ecx
	add ecx, x_3
	add ecx, x_6
	add ecx, x_9
	cmp ecx, 3
	je victorie_x
	xor ecx, ecx
	add ecx, x_1
	add ecx, x_5
	add ecx, x_9
	cmp ecx, 3
	je victorie_x
	xor ecx, ecx
	add ecx, x_3
	add ecx, x_5
	add ecx, x_7
	cmp ecx, 3
	je victorie_x
	xor ecx, ecx
	add ecx, o_1
	add ecx, o_2
	add ecx, o_3
	cmp ecx, 3
	je victorie_o
	xor ecx, ecx
	add ecx, o_4
	add ecx, o_5
	add ecx, o_6
	cmp ecx, 3
	je victorie_o
	xor ecx, ecx
	add ecx, o_7
	add ecx, o_8
	add ecx, o_9
	cmp ecx, 3
	je victorie_o
	xor ecx, ecx
	add ecx, o_1
	add ecx, o_4
	add ecx, o_7
	cmp ecx, 3
	je victorie_o
	xor ecx, ecx
	add ecx, o_2
	add ecx, o_5
	add ecx, o_8
	cmp ecx, 3
	je victorie_o
	xor ecx, ecx
	add ecx, o_3
	add ecx, o_6
	add ecx, o_9
	cmp ecx, 3
	je victorie_o
	xor ecx, ecx
	add ecx, o_1
	add ecx, o_5
	add ecx, o_9
	cmp ecx, 3
	je victorie_o
	xor ecx, ecx
	add ecx, o_3
	add ecx, o_5
	add ecx, o_7
	cmp ecx, 3
	je victorie_o

remiza:
	make_text_macro 'J', area, 455, 105, 0FFC100h
	jmp afisare_litere
	
victorie_x:
	make_text_macro '0', area, 455, 105, 0h
	jmp joc_terminat

victorie_o:
	make_text_macro '1', area, 455, 105, 0FF0000h
	jmp joc_terminat
	
afisare_litere:
	make_text_macro 'A', area, 160, 30, 0h ;P
	make_text_macro 'B', area, 200, 30, 0h ;L
	make_text_macro 'C', area, 240, 30, 0h ;A
	make_text_macro 'D', area, 280, 30, 0h ;Y
	make_text_macro 'E', area, 320, 30, 0h ;E
	make_text_macro 'F', area, 360, 30, 0h ;R
	make_text_macro 'I', area, 405, 105, 0FFC100h ;TROFEU
	cmp par, 0 ;afiseaza dupa PLAYER randul carui jucator este
	jne deseneaza_1
	make_text_macro 'G', area, 400, 30, 0h 
	jmp final_draw
	deseneaza_1:
	make_text_macro 'H', area, 400, 30, 0FF0000h
final_draw:

push ecx
mov ecx,150
verticala_00:
	mov eax, ecx
	mov ebx, area_width
	mul ebx ; eax = y * area_width
	add eax, [450]
	shl eax, 2
	mov ebx, area
	mov dword ptr [ebx+eax], 0h
	cmp ecx, 100
	je iesi_verticala_00
loop verticala_00
	iesi_verticala_00:
	pop ecx
	
push ecx
mov ecx,150
verticala_0:
	mov eax, ecx
	mov ebx, area_width
	mul ebx ; eax = y * area_width
	add eax, [500]
	shl eax, 2
	mov ebx, area
	mov dword ptr [ebx+eax], 0h
	cmp ecx, 100
	je iesi_verticala_0
loop verticala_0
	iesi_verticala_0:
	pop ecx
	
push ecx
mov ecx,400
verticala_1:
	mov eax, ecx
	mov ebx, area_width
	mul ebx ; eax = y * area_width
	add eax, [100]
	shl eax, 2
	mov ebx, area
	mov dword ptr [ebx+eax], 0h
	cmp ecx, 100
	je iesi_verticala_1
loop verticala_1
	iesi_verticala_1:
	pop ecx
	
	push ecx
mov ecx,400
verticala_2:
	mov eax, ecx
	mov ebx, area_width
	mul ebx ; eax = y * area_width
	add eax, [200]
	shl eax, 2
	mov ebx, area
	mov dword ptr [ebx+eax], 0h
	cmp ecx, 100
	je iesi_verticala_2
loop verticala_2
	iesi_verticala_2:
	pop ecx
	
	push ecx
mov ecx,400
verticala_3:
	mov eax, ecx
	mov ebx, area_width
	mul ebx ; eax = y * area_width
	add eax, [300]
	shl eax, 2
	mov ebx, area
	mov dword ptr [ebx+eax], 0h
	cmp ecx, 100
	je iesi_verticala_3
loop verticala_3
	iesi_verticala_3:
	
	pop ecx
	push ecx
mov ecx,400
verticala_4:
	mov eax, ecx
	mov ebx, area_width
	mul ebx ; eax = y * area_width
	add eax, [400]
	shl eax, 2
	mov ebx, area
	mov dword ptr [ebx+eax], 0h
	cmp ecx, 100
	je iesi_verticala_4
loop verticala_4
	iesi_verticala_4:
	pop ecx
	
	push ecx
	mov ecx, 500
orizontala_0:
	mov eax, 150
	mov ebx, area_width
	mul ebx ; eax = y * area_width
	add eax, ecx
	shl eax, 2
	mov ebx, area
	mov dword ptr [ebx+eax], 0h
	cmp ecx, 400
	je iesi_orizontala_0
	loop orizontala_0
	iesi_orizontala_0:
	pop ecx
	
	push ecx
	mov ecx, 500
orizontala_1:
	mov eax, 100
	mov ebx, area_width
	mul ebx ; eax = y * area_width
	add eax, ecx
	shl eax, 2
	mov ebx, area
	mov dword ptr [ebx+eax], 0h
	cmp ecx, 100
	je iesi_orizontala_1
	loop orizontala_1
	iesi_orizontala_1:
	pop ecx
	
	push ecx
	mov ecx,400
orizontala_2:
	mov eax, [200]
	mov ebx, area_width
	mul ebx ; eax = y * area_width
	add eax, ecx
	shl eax, 2
	mov ebx, area
	mov dword ptr [ebx+eax], 0h
	cmp ecx, 100
	je iesi_orizontala_2
	loop orizontala_2
	iesi_orizontala_2:
	pop ecx
	
	push ecx
	mov ecx,400
orizontala_3:
	mov eax, [300]
	mov ebx, area_width
	mul ebx ; eax = y * area_width
	add eax, ecx
	shl eax, 2
	mov ebx, area
	mov dword ptr [ebx+eax], 0h
	cmp ecx, 100
	je iesi_orizontala_3
	loop orizontala_3
	iesi_orizontala_3:
	pop ecx
	
	push ecx
	mov ecx,400
orizontala_4:
	mov eax, [400]
	mov ebx, area_width
	mul ebx ; eax = y * area_width
	add eax, ecx
	shl eax, 2
	mov ebx, area
	mov dword ptr [ebx+eax], 0h
	cmp ecx, 100
	je iesi_orizontala_4
	loop orizontala_4
	iesi_orizontala_4:
	pop ecx
	
;deseneaza cadranul negru cu sageata de replay
	make_text_macro 'M', area, 400, 150, 0h
	make_text_macro 'M', area, 400, 161, 0h
	make_text_macro 'M', area, 461, 150, 0h
	make_text_macro 'M', area, 461, 161, 0h
	make_text_macro 'L', area, 431, 161, 0h
	make_text_macro 'K', area, 431, 150, 0h	

eticheta:

	popa
	mov esp, ebp
	pop ebp
	ret
	
;se vor ocupa toate cadranN cu 1 pentru a nu se mai putea da click in ele
joc_terminat:
	mov cadran1, 1
	mov cadran2, 1
	mov cadran3, 1
	mov cadran4, 1
	mov cadran5, 1
	mov cadran6, 1
	mov cadran7, 1
	mov cadran8, 1
	mov cadran9, 1
	jmp eticheta
	
restart: 
	mov cadran1, 0
	mov cadran2, 0
	mov cadran3, 0
	mov cadran4, 0
	mov cadran5, 0
	mov cadran6, 0
	mov cadran7, 0
	mov cadran8, 0
	mov cadran9, 0
	
	mov x_1, 0
	mov x_2, 0
	mov x_3, 0
	mov x_4, 0
	mov x_5, 0
	mov x_6, 0
	mov x_7, 0
	mov x_8, 0
	mov x_9, 0
	
	mov o_1, 0
	mov o_2, 0
	mov o_3, 0
	mov o_4, 0
	mov o_5, 0
	mov o_6, 0
	mov o_7, 0
	mov o_8, 0
	mov o_9, 0
	mov par, 0
	
draw endp
	
start:

;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
;apelam functia de desenare a ferestrei
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	
	call BeginDrawing
	add esp, 20

	;terminarea programului
	push 0
	call exit
end start
