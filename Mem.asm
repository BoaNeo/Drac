
//------------------------------------------------------------

.macro MemFill(address, count, value)
{
	.if(count>0)
	{
		lda #<address
		sta $fe
		lda #>address
		sta $ff
		lda #value
		.if(count>255)
		{
			ldy #>count
			sty $fb
			fill2:
			ldy #$00
			fill3:
			sta ($fe),y
			iny
			bne fill3
			inc $ff
			dec $fb
			bne fill2
		}
		ldy #<count
		beq exit
		fillshort:
		dey
		sta ($fe),y
		cpy #0
		bne fillshort
		exit:
	}
}

//------------------------------------------------------------

.macro MemCpy(source, dest, count)
{
	lda #<source
	sta $fc
	lda #>source
	sta $fd
	lda #<dest
	sta $fe
	lda #>dest
	sta $ff

	.if(count>255)
	{
		ldy #>count
		sty $fb
		copy2:
		ldy #$00
		copy3:
		lda ($fc),y
		sta ($fe),y
		iny
		bne copy3
		inc $ff
		inc $fd
		dec $fb
		bne copy2
	}
	ldy #<count
	beq exit
	copyshort:
	dey
	lda ($fc),y
	sta ($fe),y
	cpy #0
	bne copyshort
	exit:
}
