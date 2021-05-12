astack			segment		stack
		dw		200	dup(?)
astack			ends

data				segment
		ovl1					db		'ovl1.ovl',0
		ovl2					db		'ovl2.ovl',0
		
		keep_psp		dw		0

		memErr7		db		'The control block destroyed', 13,10, '$'
		memErr8		db		'Not enough memory to perform the function', 13,10, '$'
		memErr9		db		'Invalid address of the memory block', 13,10, '$'
		memSucces	db		'Succesful free', 13, 10, '$'
		
		sizeErr2			db		'Size error. File not found', 13,10,'$'
		sizeErr3			db		'Size error. Route not found', 13,10,'$'
		sizeSucces		db		'Succesful allocation', 13,10,'$'
		
		loadErr1			db		'Load error. Non-existent function number', 13,10,'$'
		loadErr2			db		'Load error. File not found', 13,10,'$'
		loadErr3			db		'Load error. Route not found', 13,10,'$'
		loadErr4			db		'Load error. Too many open files', 13,10,'$'
		loadErr5			db		'Load error. No access', 13,10,'$'
		loadErr8			db		'Load error. Not enough memory', 13,10,'$'
		loadErr10		db		'Load error. Wrong enviroment', 13,10,'$'
		loadSuccess	db		'Succesful load', 13,10,'$'
		
		fullPath 			db		128 dup(0)
		dtaMem		db		43	dup(?)
		ovlSegAdr		dd		0
		
		dataEnd			db		0
data				ends

code			segment
		assume cs:code, ds:data, es:nothing, ss:astack
;-----------------------------------------------------
		PRINT			proc		near
				push	ax
				mov	ah, 09h
				int 		21h
				pop		ax
				ret
		PRINT 		endp
;-----------------------------------------------------
		freeExtraMem	proc		near
				push	bx
				push	dx
				push	cx
				
				mov	bx, offset progEnd
				mov	ax, offset dataEnd
				add		bx, ax
				
				mov	cl, 4
				shr		bx, cl
				add		bx, 100h
				mov	ah, 4ah
				int		21h
				
				jnc		freeMemSucces
				
				cmp	ax, 7
				je			mem_Err7
				cmp	ax, 8
				je			mem_Err8
				cmp	ax, 9
				je			mem_Err9
				
			mem_Err7:
				mov	dx, offset memErr7
				call		print
				mov	ax, 0
				jmp		freeMemEnd
			mem_Err8:
				mov	dx, offset memErr8
				call		print
				mov	ax, 0
				jmp		freeMemEnd
			mem_Err9:
				mov	dx, offset memErr9
				call		print
				mov	ax, 0
				jmp		freeMemEnd
			freeMemSucces:
				mov	dx, offset memSucces
				call		print
				mov	ax, 1
				
			freeMemEnd:
				pop		cx
				pop		dx
				pop		bx
				
				ret		
		freeExtraMem	endp
;-----------------------------------------------------		
		createPath	proc
				push	ax
				push	cx
				push	bx
				push	di
				push	si
				push	es
				
				mov	si, dx
				
				mov	ax, keep_psp
				mov	es, ax
				mov	es, es:[2ch]
				
				sub		bx, bx
				printEnvVar:
						cmp	byte ptr es:[bx], 0
						je			varEnd
						inc		bx
						jmp		printEnvVar
						
				varEnd:
						inc		bx
						cmp	byte ptr es:[bx+1], 0
						jne		printEnvVar
						
				add		bx, 2
				mov	di, 0
				pathLoop:
						mov	dl, es:[bx]
						mov	byte ptr [fullPath+di], dl
						inc		bx
						inc		di
						cmp	dl, 0
						je			pathLoopEnd
						cmp	dl, '\'
						jne		pathLoop
						mov	cx, di
						jmp		pathLoop
				pathLoopEnd:
						mov	di, cx
						
				filenameLoop:
						mov	dl, byte ptr [si]
						mov	byte ptr [fullPath+di], dl
						inc		di
						inc		si
						cmp	dl, 0
						jne		filenameLoop
						
				pop		es
				pop		si
				pop		di
				pop		bx
				pop		cx
				pop		ax
				
				ret
		createPath	endp
;-----------------------------------------------------
		allocateMemForOvl	proc
				push	bx
				push	cx
				push	dx
				
				push	dx
				mov	dx, offset dtaMem
				mov	ah, 1ah
				int		21h
				pop		dx
				
				sub		cx, cx
				mov	ah, 4eh
				int		21h
				
				jnc		size_Succes
				
				cmp	ax, 2
				je			size_Err2
				cmp	ax, 3
				je			size_Err3
				
				size_Err2:
						mov	dx, offset sizeErr2
						jmp		sizeErr
				size_Err3:
						mov	dx, offset sizeErr3
						jmp		sizeErr
				size_Succes:
						push	di
						mov	di, offset	dtaMem
						mov	bx, [di+1ah]
						mov	ax, [di+1ch]
						pop		di
						
						push	cx
						mov	cl, 4
						shr		bx, cl
						mov	cl, 12
						shr		ax, cl
						pop		cx
						add		bx, ax
						inc		bx
						
						mov	ah, 48h
						int		21h
						
						mov	word ptr ovlSegAdr, ax
						mov	dx, offset sizeSucces
						call		print
						
						mov	ax, 1
						jmp		sizeEnd
						
				sizeErr:
						mov	ax, 0
						call		print
						
				sizeEnd:
				pop		dx
				pop		cx
				pop		bx
				
				ret
		allocateMemForOvl	endp
;-----------------------------------------------------
		loadOvl		proc
				push	ax
				push	bx
				push	cx
				push	dx
				push	ds
				push	es
				
				mov	ax, data
				mov	es, ax
				mov	dx, offset	fullPath
				mov	bx, offset	ovlSegAdr
				mov	ax, 4b03h
				int		21h
				
				jnc		load_Success
				
				cmp	ax, 1
				je			load_Err1
				cmp	ax, 2
				je			load_Err2
				cmp	ax, 3
				je			load_Err3
				cmp	ax, 4
				je			load_Err4
				cmp	ax, 5
				je			load_Err5
				cmp	ax, 8
				je			load_Err8
				cmp	ax, 10
				je			load_Err10
				
				load_Err1:
						mov	dx, offset loadErr1
						jmp		print_and_end
				load_Err2:
						mov	dx, offset loadErr2
						jmp		print_and_end
				load_Err3:
						mov	dx, offset loadErr3
						jmp		print_and_end
				load_Err4:
						mov	dx, offset loadErr4
						jmp		print_and_end
				load_Err5:
						mov	dx, offset loadErr5
						jmp		print_and_end
				load_Err8:
						mov	dx, offset loadErr8
						jmp		print_and_end
				load_Err10:
						mov	dx, offset loadErr10
						jmp		print_and_end
					
				print_and_end:
						call		print
						jmp		load_end
						
				load_Success:
						mov	dx, offset	loadSuccess
						call		print
						
						mov	ax, word ptr ovlSegAdr
						mov	es, ax
						mov	word ptr ovlSegAdr, 0
						mov	word ptr ovlSegAdr+2, ax
						
						call		ovlSegAdr
				
						mov	es, ax
						mov	ah, 49h
						int		21h
						
				load_end:
				pop		es
				pop		ds
				pop		dx
				pop		cx
				pop		bx
				pop		ax
				
				ret
		loadOvl		endp
;-----------------------------------------------------
		startOvl		proc
				push	dx
				
				call		createPath
				
				mov	dx, offset fullPath
				call		allocateMemForOvl
				cmp	ax, 1
				;jne		ovl_end
				
				call		loadOvl
				
				ovl_end:
				pop		dx
				
				ret
		startOvl		endp
;-----------------------------------------------------
		main			proc
				push  	DS       ;\  Сохранение адреса начала PSP в стеке
				sub   	AX,AX    ; > для последующего восстановления по
				push  	AX       ;/  команде ret, завершающей процедуру.
				mov   	AX,DATA             ; Загрузка сегментного
				mov   	DS,AX               ; регистра данных.
				mov	keep_psp, es
				
				call		freeExtraMem
				cmp	ax, 0
				je			end_main
								
				lea		dx, ovl1
				call		startOvl
				
				lea		dx, ovl2
				call		startOvl
				
			end_main:
				; Выход в DOS
				xor AL,AL
				mov AH,4Ch
				int 21H
		main			endp
		progEnd:
		
code	ends
end		main
