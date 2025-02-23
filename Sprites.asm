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
.const SPR_CharAt = 12
.const SPR_CharBelow = 13
.const SPR_SIZE = 14

.const SPR_COUNT = 4

//.const SPRBIT_Enabled = $01 (Not used - sprites are enabled if they have an active handler)
.const SPRBIT_ExtendY = $01
.const SPRBIT_ExtendX = $02
.const SPRBIT_Multicolor = $04
.const SPRBIT_BehindBackground = $08
.const SPRBIT_IsCollider = $40		 // Other sprites may collide with this
.const SPRBIT_CheckCollision = $80   // This sprite checks collision against other sprites

.const VIS_TOP = 50
.const VIS_BOTTOM = VIS_TOP + 8*25 - 21
.const VIS_LEFT = 24 / 2
.const VIS_RIGHT = (24 + 40*8 - 24) / 2

_sprites:
.align $100
* = * "Sprite Properties"
.fill SPR_SIZE*SPR_COUNT, 0
_sprOffset: .lohifill SPR_COUNT, _sprites+SPR_SIZE*i
_sprBaseIndex: .byte 0
_sprScreenHi: .byte $04
_sprOffscreenChar: .byte $ff

.align $100
* = * "Sprite Row to Character Map"
_screenRowOffsetLo:
.for(var i=0;i<256;i++)
{
	.var row = (i-(VIS_TOP-9)) >> 3
	.if(row<0) { .byte 0 }
	else .if(row>24) { .byte <(24*40) }
	else .byte <(row*40)
}
_screenRowOffsetHi:
.for(var i=0;i<256;i++)
{
	.var row = (i-(VIS_TOP-9)) >> 3
	.if(row<0) { .byte 0 }
	else .if(row>24) { .byte >(24*40) }
	else .byte >(row*40)
}

* = * "Sprite Code"

// When the sprite collision handler is called:
// $fb is current sprite index
// ($fc) points to current sprite properties
// $f2 is other sprite index
// ($22) points to other sprite properties
.macro SprManagerInit(base_index, off_screen_char, collision_handler)
{
	lda $d01e // Clear sprite collision (first read)
	lda #$ff // Sprites in multicolor
	sta $d01c
	lda #base_index
	sta _sprBaseIndex
	lda #off_screen_char
	sta _sprOffscreenChar
	lda #<collision_handler
	sta @_collisionHandler
	lda #>collision_handler
	sta @_collisionHandler+1
}

.macro SprHasHandler(spr)
{
	lda _sprites + spr*SPR_SIZE + SPR_HandlerHi
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

.macro SprADC(prop, val)
{
	ldy #prop
	lda ($fc),y
	clc
	adc #val
	sta ($fc),y
}

.macro SprSBC(prop, val)
{
	ldy #prop
	lda ($fc),y
	sec
	sbc #val
	sta ($fc),y
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

.macro ExSprSetFlags(spr, flags)
{
	lda _sprites + spr*SPR_SIZE + SPR_Bits
	ora #flags
	sta _sprites + spr*SPR_SIZE + SPR_Bits
	ldx #spr // Current sprite index
	ror
	_SetBitXIfCarrySet($d017) // SPRBIT_ExtendY -  Spr double height
	ror
	_SetBitXIfCarrySet($d01d) // SPRBIT_ExtendX - Spr double width
//	ror
//	BitSetFromCarry($d01c) // SPRBIT_MultiColor -  Spr multicolor
}

.macro _SetBitXIfCarrySet(target)
{
	bcc !next+
	tay
	lda target
	ora _bits,x
	sta target
	tya
!next:
}

.macro SprClearFlags(flag)
{
	SprLDA(SPR_Bits)
	and #~flag
	SprSTA(SPR_Bits)
	ldx $fb // Current sprite index
	ror
	_ClearBitXIfCarryClear($d017) // SPRBIT_ExtendY -  Spr double height
	ror
	_ClearBitXIfCarryClear($d01d) // SPRBIT_ExtendX - Spr double width
}

.macro ExSprClearFlags(spr, flags)
{
	lda _sprites + spr*SPR_SIZE + SPR_Bits
	and #~flags
	sta _sprites + spr*SPR_SIZE + SPR_Bits
	ldx #spr // Current sprite index
	ror
	_SetBitXIfCarrySet($d017) // SPRBIT_ExtendY -  Spr double height
	ror
	_SetBitXIfCarrySet($d01d) // SPRBIT_ExtendX - Spr double width
//	ror
//	BitSetFromCarry($d01c) // SPRBIT_MultiColor -  Spr multicolor
}

.macro _ClearBitXIfCarryClear(target)
{
	bcs !next+
	tay
	lda target
	and _bitMasks,x
	sta target
	tya
!next:
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
	// Get collision bits for this frame
	lda $d01e
	sta $26
	// Clear active sprites
	lda #$00
	sta $27

	// Iterate all sprites
	.for(var spr=0;spr<SPR_COUNT;spr++)
	{
		// Set spr index
		ldx #spr
		stx $fb
		// Set spr data pt
		lda _sprOffset,x
		sta $fc
		lda _sprOffset+SPR_COUNT,x
		sta $fd

		SprLDA(SPR_HandlerHi)
		beq no_handler
		sta handler+2
		SprLDA(SPR_HandlerLo)
		sta handler+1
	handler:
		jsr $ffff

		SprLDA(SPR_Bits)
		and #SPRBIT_CheckCollision
		beq skip_collision

		jsr _SprToBackCollision
		lda #1<<spr
		jsr _SprToSprCollision
	skip_collision:
		jsr _SprAnimateSingle
		jsr _SprSetPosition
		// Enable sprite
		lda #1<<spr
		ora $27
		sta $27
	no_handler:
	}

	// Clear collision bits for this frame
	lda #0
	sta $d01e
//	lda $27
//	sta $d015
	rts
}

_SprToSprCollision:
{
		sta $d6 // Collision mask of potential collision in $d6 (starting with self)
		and $26
		bne coll
		rts
coll:
		lda $fb // Get index of current sprite
		sta $f2
next:	inc $f2 // Spr index of potential collision
		lda $d6
		asl
		beq exit // No more bits to check
		sta $d6
		and $26
		beq next // No collision here, try next

		ldx $f2
		// Set spr data pt
		lda _sprOffset,x
		sta $22
		lda _sprOffset+SPR_COUNT,x
		sta $23

		// Potential collision between sprite with index $fb (current) and index $f2, check AABB
		// First check if this other sprite is "active" (I.e. has a non-null handler) 
//		ldy #SPR_HandlerHi
//		lda ($22),y
//		beq next
		ldy #SPR_Bits
		lda ($22),y
		and #SPRBIT_IsCollider
		beq next

		// Then check for X overlap		
		SprLDA(SPR_X)
		sta $24
//		ldy #SPR_X
		lda ($22),y
		sta $25
		clc
		adc #12
		cmp $24
		bcc next
		lda $24
		clc
		adc #12
		cmp $25
		bcc next

		// And Y overlap		
		SprLDA(SPR_Y)
		sta $24
//		ldy #SPR_X
		lda ($22),y
		sta $25
		clc
		adc #12
		cmp $24
		bcc next
		lda $24
		clc
		adc #12
		cmp $25
		bcc next

//		lda #13
//		ldx $fb
//		sta $d027,x
//		ldx $f2
//		sta $d027,x

		jsr @_collisionHandler: exit

		jmp next
exit:
		rts

}

_SprToBackCollision:
{
		SprLDA(SPR_Y)
		tax // Store y-coord in x reg (because I need y for zero-page indexing in X direction)

		SprLDA(SPR_X)
		cmp #VIS_LEFT
		bcc exit
		cmp #VIS_RIGHT
		bcs exit
		// Convert x pixels to column by subtracting the min value and dividing by 4
		sbc #VIS_LEFT - 12/2 // Left edge minus half a sprite width (in double-width coords)
		lsr
		lsr
		tay // Store x-coord in y register

		// We're in the relevant screen area between line 21 and 221
		// And row 8 to 168 (x position is double pixels)

		// Calculate screen row
		lda _sprScreenHi
		clc
		adc _screenRowOffsetHi,x
		sta $ff
		lda _screenRowOffsetLo,x
		sta $fe

		// Safe X-COORD
		clc
		sty $d6
		// Get the relevant characters behind and below the sprite
		lda ($fe),y
		SprSTA(SPR_CharAt)
		lda $d6
		adc #80
		tay
		lda ($fe),y
		SprSTA(SPR_CharBelow)
		rts
exit:	lda _sprOffscreenChar
		SprSTA(SPR_CharAt)
		SprSTA(SPR_CharBelow)
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
		ldy #$00 // Index 0 in animation is the framerate (# of frames each image is repeated)
		cmp ($fe),y
		bcc no_anim

		// Reset frame delay
		lda #$00
		SprSTA(SPR_AnimDelay)

		// Then get the frame index
		SprLDA(SPR_Frame)
		ldy #$01 // Index 1 in animation is the anim length
		cmp ($fe),y
		bcc no_reset

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
		clc
		adc #1
		SprSTA(SPR_AnimDelay)
		rts
}

_SprSetPosition:
{
		// We use half-x internally because it is easier than having to deal with the extra hi bit in $d010
		// So we get out internal X and multiply by 2, rolling the high bit into the carry
		SprLDA(SPR_X)
		clc
		rol 
		tay

		// ... Then store the carry in the sprites X-pos high bit in $d010
		ldx $fb // Current sprite index
		BitSetOrClearFromCarry($d010) // spr x hi
		
		txa // Current sprite index
		asl // because sprite X and Y are stored in alternating registers, we have to multiply the index by 2
		tax

		tya // Restore X coord
		sta $d000,x // spr x lo

		SprLDA(SPR_Y)
		sta $d001,x // spr y

		rts

/*
	lda #0
	.for(var spr=0;spr<SPR_COUNT;spr++)
	{
		SprLDAsafe(SPR_Bits)
		ror
		BitSetOrClearFromCarry($d015) // Enable spr
		ror
		BitSetOrClearFromCarry($d017) // Spr double height
		ror
		BitSetOrClearFromCarry($d01d) // Spr double width
		ror
		BitSetOrClearFromCarry($d01c) // Spr multicolor
		ror
		BitSetOrClearFromCarry($d01b) // Spr priority bit (1=behind background)

	}
	*/
}

* = * "Bit"

_bits: .byte $01, $02, $04, $08, $10, $20, $40, $80
_bitMasks: .byte ~$01, ~$02, ~$04, ~$08, ~$10, ~$20, ~$40, ~$80


.macro SetBit(index, target)
{
	lda target
	ldx #index
	ora _bits,x
	sta target
}

.macro ClearBit(index, target)
{
	lda target
	ldx #index
	and _bitMasks,x
	sta target
}

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
.macro BitSetOrClearFromCarry(target)
{
		lda target
		and _bitMasks,x
		bcc no_set
		ora _bits,x
no_set:	sta target
}

