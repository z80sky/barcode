;Z80 barcodes by Arcadiy Gobuzov
; made EAN-8, EAN-13
        org    30000
startpoint:
 
	ld	hl, end-routine ; just to know size
	ei
	ld      a,7
        out     (254),a
        ld      a,56
        ld      hl,23295
        ld      (hl),a
        dec     hl
        bit     2,h
        jr      z,$-4
	ld	hl,16384+6143
;
	xor	a
fill:	ld	(hl),a
	dec	hl
	bit	6,h
	jr	nz,fill
;       
	
	ld	c,50
	ld	hl,16384+34
	ld	ix,ean8code
        call    doean8
	ld	hl,16384+50
	ld	ix,ean13code
        call    doean13

        ret
ean8code: 	db	8,9,0,0,0,5,5,7
ean13code:	db	9, 7, 8, 1, 5, 2, 7, 2, 5, 4, 9, 6, 1
;
routine:
doean13:
; print first number
	push	hl
	push	bc
	ld	b,c
	call	next_line	; hl will low adress for first number
	djnz	$-3
	call	get_char
	dec	ix
	exx
	push	hl
	exx
	pop	de	;	de = fnt
	ld	b,8
bloop4:	ld	a,(de)
	inc	de
	ld	(hl),a
	call	next_line
	djnz	bloop4
;
	pop	bc
	pop	hl
	inc	hl

	ld	e,7
	call	guard_pattern
	ld	a,(ix+0); first digit as link to line
	inc	ix
	call	get13
	ld	b,d
	exx	
	inc	b
	exx

loop3:	sla	b
	jr	z,d13_
	call	get_char
	call	nc,getg
	call	c,getl
	call	dodigit
	jr	loop3
;
d13_	ld	b,6
	jr	ean_common
doean8:
loop:	ld	e,7
	call	guard_pattern
	exx	
	inc	b
	exx
	ld	b,4
loop1:	call	get_char
	call	getl
	call	dodigit
	djnz	loop1
	ld	b,4	
ean_common:
	xor	a
	exx
	ld	b,a	; b=0 no digit
	exx

	call	doline1
	call	guard_pattern
	xor	a
	call	doline1
	exx	
	ld	b,128
	exx
;
loop2:	call	get_char
	call	getr
	call	dodigit
	djnz	loop2
;
guard_pattern:
	xor	a
	exx
	ld	b,a
	exx
	ccf
	call	doline1
	xor	a
	call	doline1
	xor	a
	ccf

doline1:push	bc
	db	8	; just to save CY
	ld	a,c
	add	a,5	; low part of guard patterns
	ld	b,a
	db	8
	jr	doline3
doline:	;	nc - res; c - set
	push	bc
	ld	b,c
doline3:push	hl
	push	af
        ld	a,e	; for automodification code res N,(hl); set N,(hl)
	add	a,a     ; calculate N
	add	a,a
	add	a,a
	add	a,$86	; res
	ld	(bloop6+1),a
	ld	(bloop+1),a
	add	a,$40	; $86 -> $c6 
	ld	(bloop7+1),a
	ld	c,a
	pop	af
	jr	nc,bloop
	ld	a,c
	ld	(bloop+1),a

bloop:	db	$cb, $cb
	call	next_line
bloop1:	djnz	bloop
;
	exx
	inc	b
	dec	b
	exx
	jr	z,bloop8
;
	exx	
	ld	d,h
	ld	e,l
	rrc	c
	exx
	ld	b,8
bloop5:	exx
	ld	a,(de)
	inc	de
	and	c
	exx
bloop6:	res	0,(hl)
	jr	z,$+4
bloop7:	set	0,(hl)
	call	next_line
	djnz	bloop5

bloop8:	pop	hl
	pop	bc
	dec	e
	ret	p	; ret if >= 0
	inc	hl
	ld	e,7
	ret
;
dodigit:sla	d
	ret	z
	call	doline
	jr	dodigit
;	
get13:	push	hl
	ld	hl,code13
	jr	getg1
getl:	push	hl
        ld	hl,codesl
	jr	getg1
getr:	push	hl
        ld	hl,codesr
	jr	getg1
getg:	push	hl	; in: a-digit[0..9], out:a-barcode (first 7 bits)
	ld	hl,codesg
getg1:	add	a,l
	jr	nc,$+3
	inc	h
	ld	l,a
	ld	d,(hl)
	pop	hl
	or	a
	ret
next_line:
	inc	h
	ld	a,h
	and	7
	ret	nz
	ld	a,l
	add	a,32
	ld	l,a
	ret	c
	ld	a,h
	sub	8
	ld	h,a
	ret
get_char:
	ld	a,(ix+0)
	inc	ix
	push	af
	exx
	add	a,a
	ld	l,a
	ld	h,0
	ld	de,15616 + 16*8
	add	hl,hl
	add	hl,hl
	add	hl,de
	ld	c,b ; //rrc	c	; move mask
	exx
	pop	af
	ret
	
	;  0          1          2          3          4          5          6          7          8          9
codesl: db %00011011, %00110011, %00100111, %01111011, %01000111, %01100011, %01011111, %01110111, %01101111, %00010111
codesr:	db %11100101, %11001101, %11011001, %10000101, %10111001, %10011101, %10100001, %10001001, %10010001, %11101001
codesg:	db %01001111, %01100111, %00110111, %01000011, %00111011, %01110011, %00001011, %00100011, %00010011, %00101111
;
code13:	db %11111110, %11010010, %11001010, %11000110, %10110010, %10011010, %10001010, %10101010, %10100110, %10010110

end;
	DEVICE ZXSPECTRUM48                
        savesna "barcode.sna",startpoint
;    SAVETAP "t.tap",CODE,"code",30000, 304