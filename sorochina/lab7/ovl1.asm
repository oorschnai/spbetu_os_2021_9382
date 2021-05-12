MY SEGMENT
		ASSUME 	CS:MY, DS:nothing, ES:nothing, SS:nothing
		main			proc		far
				jmp start
				inOverlay	db	'In overlay1', 13,10,'$'
				adress			db	'Segment adress:  $'
				endl				db	13, 10, '$'
			start:
				push	ax
				push 	dx
				push	ds
				
				mov	ax, cs
				mov 	ds, ax
				
				mov 	dx, offset inOverlay
				call 		print
				
				mov	dx, offset adress
				call		print
				
				mov	ax, cs
				call		printWord
				
				mov	dx, offset endl
				call 		print
				
				pop		ds
				pop 	dx
				pop		ax
				retf
		main 			endp
;-----------------------------------------------------
		PRINT			proc		near
				push	ax
				mov	ah, 09h
				int 		21h
				pop		ax
				ret
		PRINT 		endp
;-----------------------------------------------------
		printWord	proc	
				xchg	ah, al
				call		printByte
				xchg	ah, al
				call		printByte
				ret
		printWord	endp
;-----------------------------------------------------
		printByte		proc
				push	ax
				push	bx
				push	dx
				
				call		byte_to_hex
				mov	bh, ah
				
				mov	dl, al
				mov	ah, 02h
				int 21h
				
				mov	dl, bh
				mov	ah, 02h
				int 21h
				
				pop		dx
				pop		bx
				pop		ax
				ret
		printByte		endp
;-----------------------------------------------------
TETR_TO_HEX PROC near
		and AL,0Fh
		cmp AL,09
		jbe next
		add AL,07
next:
		add AL,30h
		ret
TETR_TO_HEX ENDP
;--------------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
		push CX
		mov AH,AL
		call TETR_TO_HEX
		xchg AL,AH
		mov CL,4
		shr AL,CL
		call TETR_TO_HEX ;в AL старшая цифра
		pop CX 			;в AH младшая
		ret
BYTE_TO_HEX ENDP
MY ENDS
		end main