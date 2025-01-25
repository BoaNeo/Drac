.const SPR_X = 0
.const SPR_Y = 1
.const SPR_Bits = 2
.const SPR_Color = 3
.const SPR_AnimPtLo = 4
.const SPR_AnimPtHi = 5
.const SPR_Frame = 6
.const SPR_AnimDelay = 7
.const SPR_HandlerLo = 8
.const SPR_HandlerHi = 9
.const SPR_AnimEndLo = 10
.const SPR_AnimEndHi = 11
.const SPR_CharAbove = 12
.const SPR_CharAt = 13
.const SPR_CharBelow = 14
//.const SPR_Color = 10
//.const SPR_Pt = 11
.const SPR_SIZE = 15

.const SPR_COUNT = 1

.const SPRBIT_Enabled = $01
.const SPRBIT_ExtendX = $02
.const SPRBIT_ExtendY = $04
.const SPRBIT_Multicolor = $08
.const SPRBIT_BehindBackground = $10
.const SPRBIT_Ghost = $20

.const VIS_TOP = 50
.const VIS_BOTTOM = VIS_TOP + 8*25 - 21
.const VIS_LEFT = 24 / 2
.const VIS_RIGHT = (24 + 40*8 - 24) / 2

_sprites:
.fill SPR_SIZE*8, 0
_sprBaseIndex: .byte 0
_sprScreenHi: .byte $04
_sprOffscreenChar: .byte $ff

.macro SprManagerInit(color0, color1, base_index, off_screen_char)
{
	lda #color0
	sta $d025 // Spr color M1
	lda #color1
	sta $d026 // Spr color M2
	lda #$ff
	sta $d015
	sta $d01c
	lda #base_index
	sta _sprBaseIndex
	lda #off_screen_char
	sta _sprOffscreenChar
}

.macro SprSetHandler(spr, handler)
{
	lda #<handler
	sta _sprites + spr*SPR_SIZE + SPR_HandlerLo
	lda #>handler
	sta _sprites + spr*SPR_SIZE + SPR_HandlerHi
}

.macro SprLDA(prop)
{
	ldy #prop
	lda ($fc),y
}

.macro SprSTA(prop)
{
	ldy #prop
	sta ($fc),y
}

.macro SprLDAsafe(prop)
{
	sty $d6
	SprLDA(prop)
	ldy $d6
}

.macro SprSTAsafe(prop)
{
	sty $d6
	SprSTA(prop)
	ldy $d6
}

.macro SprSetAnimation(anim, eoa_handler)
{
	lda #0
	SprSTA(SPR_Frame)
	SprSTA(SPR_AnimDelay)
	lda #>anim
	SprSTA(SPR_AnimPtHi)
	lda #<anim
	SprSTA(SPR_AnimPtLo)
	lda #>eoa_handler
	SprSTA(SPR_AnimEndHi)
	lda #<eoa_handler
	SprSTA(SPR_AnimEndLo)
}

.macro SprSetFlags(flag)
{
	SprLDA(SPR_Bits)
	ora #flag
	SprSTA(SPR_Bits)
}

.macro SprClearFlags(flag)
{
	SprLDA(SPR_Bits)
	and #~flag
	SprSTA(SPR_Bits)
}

.macro SprMoveUp(dy)
{
		SprLDA(SPR_Y)
		sec
		sbc #dy
		bcc not_ok
		cmp #30
		bcs ok
not_ok:	lda #30
ok:		SprSTA(SPR_Y)
}

.macro SprMoveDown(dy)
{
		SprLDA(SPR_Y)
		clc
		adc #dy
		bcc ok
		lda #255-21
ok:		SprSTA(SPR_Y)
}

.macro SprMoveLeft(dx)
{
		SprLDA(SPR_X)
		sec
		sbc #dx
		bcc not_ok
		cmp #8
		bcs ok
not_ok:	lda #8
ok:		SprSTA(SPR_X)
}

.macro SprMoveRight(dx)
{
		SprLDA(SPR_X)
		clc
		adc #dx
		bcc ok
		lda #255-24
ok:		SprSTA(SPR_X)
}

.macro SprSetScreenPt(screen1,screen2)
{
		lda #>screen1
		sta _sprScreenHi
		lda #(>screen1)+3
		sta @_sprPointerHi1+1
		lda #(>screen2)+3
		sta @_sprPointerHi2+1
}

SprUpdate:
{
	// Spr index
	lda #0
	sta $fb 
	// Spr data pt
	lda #<_sprites
	sta $fc 
	lda #>_sprites
	sta $fd
	// Iterate all sprites
	.for(var spr=0;spr<SPR_COUNT;spr++)
	{
		jsr _SprHandler
		jsr _SprToBackCollision
		jsr _SprAnimateSingle
		jsr _SprSetPosition
		inc $fb
		lda $fc
		clc
		adc #SPR_SIZE
		sta $fc
	}
/*
	lda #0
	.for(var spr=0;spr<SPR_COUNT;spr++)
	{
		SprLDAsafe(SPR_Bits)
		ror
		BitSetFromCarry($d015) // Enable spr
		ror
		BitSetFromCarry($d017) // Spr double height
		ror
		BitSetFromCarry($d01d) // Spr double width
		ror
		BitSetFromCarry($d01c) // Spr multicolor
		ror
		BitSetFromCarry($d01b) // Spr priority bit (1=behind background)

	}
	*/
	rts
}

_SprHandler:
{
			SprLDA(SPR_HandlerHi)
			beq no_handler
			sta handler+2
			SprLDA(SPR_HandlerLo)
			sta handler+1
handler: 	jmp $ffff
no_handler: rts
}

_SprToBackCollision:
{
		SprLDA(SPR_Bits)
		and #SPRBIT_Ghost
		beq solid
		rts
solid:
		SprLDA(SPR_Y)
		cmp #VIS_TOP-9
		bcc exit
		cmp #VIS_BOTTOM-21
		bcs exit
		tax // Store y-coord in x reg (because I need y for zero-page indexing in X direction)

		// We're in the relevant screen area between line 21 and 221
		SprLDAsafe(SPR_X)
		cmp #VIS_LEFT
		bcc exit
		cmp #VIS_RIGHT
		bcs exit
		// And row 8 to 168 (x position is double pixels)
		// Convert x pixels to column by subtracting the min value and dividing by 4
		sbc #VIS_LEFT - 12/2 // Left edge minus half a sprite width (in double-width coords)
		lsr
		lsr
		tay // Store x-coord in y register
		// Convert y pixels to row by subtracting the min value and dividing by 8
		txa
		sbc #VIS_TOP-9 // Fist "fully visible " position where sprite bottom is aligned with a row is 53, +/- half a character yields [49;57[, i.e. VIS_TOP-1 to VIS_TOP+7 
		lsr
		lsr
		lsr
		tax
		// Calculate screen position
		lda _sprScreenHi
		sta $ff
		lda #0
		cpx #0
		beq noloop
loop:	clc
		adc #40
		bcc !nohi+
		inc $ff
!nohi:	dex
		bne loop
noloop: sta $fe
		// Safe X-COORD
		clc
		sty $d6
		// Get the relevant character
//		lda ($fe),y
//		SprSTA(SPR_CharAbove)
//		lda $d6
//		adc #80
//		tay
		lda ($fe),y
		SprSTA(SPR_CharAt)
		lda $d6
		adc #80
		tay
		lda ($fe),y
		SprSTA(SPR_CharBelow)
		rts
exit:	lda _sprOffscreenChar
		SprSTA(SPR_CharAbove)
		SprSTA(SPR_CharAt)
		SprSTA(SPR_CharBelow)
		//.break
		rts
}

_SprAnimateSingle:
{
		// First we get the pointer to the current animation sequence and store in ($fe)
		SprLDA(SPR_AnimPtLo)
		sta $fe
		SprLDA(SPR_AnimPtHi)
		sta $ff

		// Then we check the frame-repeat count - if it has not reached the limit, just exit
		SprLDA(SPR_AnimDelay)
		clc
		adc #1
		ldy #$00 // Index 0 in animation is the framerate (# of frames each image is repeated)
		cmp ($fe),y
		bne no_anim

		// Reset frame delay
		lda #$00
		SprSTA(SPR_AnimDelay)

		// Then get the frame index
		SprLDA(SPR_Frame)

		ldy #$01 // Index 1 in animation is the anim length
		cmp ($fe),y
		bne no_reset

		// Trigger end-of-frame handler if any
		SprLDA(SPR_AnimEndHi)
		beq no_handler
		sta handler+2
		SprLDA(SPR_AnimEndLo)
		sta handler+1
handler:jmp $ffff
no_handler:
		// Reset frame
		lda #$00
no_reset:
		clc // Bump frame counter for next frame and store it (This also magically gets us past the frame_repeat and frame_count fields)
		adc #1
		SprSTA(SPR_Frame)

		asl // Two bytes per frame: spr index and color
		tay

		lda ($fe),y
		clc
		adc _sprBaseIndex
		tax // Remember the sprite index since we need to use the A register

		iny // Get the color
		lda ($fe),y

		// Now, get the sprite index and set both color and sprite pointer
		ldy $fb
		sta $d027,y
		txa
		sta @_sprPointerHi1:$07f8,y
		sta @_sprPointerHi2:$07f8,y

		rts
no_anim:
		SprSTA(SPR_AnimDelay)
		rts
}

_SprSetPosition:
{
		lda $fb // Current sprite index
		asl
		tax

		SprLDA(SPR_X)
		clc
		rol
		sta $d000,x // spr x lo
		BitSetFromCarry($d010) // spr x hi

		SprLDA(SPR_Y)
		sta $d001,x // spr y

		rts
}

_bits: .byte $01, $02, $04, $08, $10, $20, $40, $80
_bitMasks: .byte ~$01, ~$02, ~$04, ~$08, ~$10, ~$20, ~$40, ~$80


// X->: The index of the bit to set
// ->C: The CARRY will contain the value of the specified bit
.macro BitGetInCarry(source)
{
		lda source
		and _bitMasks,x
		cmp _bits,x
}

// X->: The index of the bit to set
// C->: The value of the bit
.macro BitSetFromCarry(target)
{
		lda target
		and _bitMasks,x
		bcc no_set
		ora _bits,x
no_set:	sta target
}

