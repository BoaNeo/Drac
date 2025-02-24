_coins: .byte 0
_animDelay: .byte 0
_shouldDrawMap: .byte 0
_textHUD:
.byte $8,1,20
.fill 7, 'Z'+11+i
.byte 'Z'+11+8
.fill 3,'A'
.byte 'Z'+11+9
.fill 7, 'Z'+11+i
.byte 0

.byte BLACK,16,20
.text "DRAC"
.byte 0

.byte 8+RED,5,23
.byte 'Z'+21
.byte 'Z'+21
.byte 'Z'+21
.byte 0

.byte YELLOW,15,22
.text "coins: 0/5"
.byte 0

.byte RED,16,23
.text "00:00:21"
.byte 0

.byte 8+RED,29,23
.byte 'Z'+22
.byte 'Z'+22
.byte 'Z'+22
.byte 0

.byte $ff

.const SPR_Player = 0
.const SPR_BloodOrCoin = 1
.const SPR_Door = 2
.const SPR_Switch = 3

GameInit:
{
	SetBorderColor(BLACK)
	SetScreenColor(BROWN)
	SetSprColor1(BLACK)
	SetSprColor2(RED)

	SwapToBuffer2()
	lda #<_textHUD
	sta $fa
	lda #>_textHUD
	sta $fb
	jsr DrawScreen
	jsr ApplyColorBuffer1
	SwapToBuffer1()

        SprManagerInit($c0,$ff,OnSprCollision)

        SprSetHandler(SPR_Player, PlySpawn)
        SprSetHandler(SPR_BloodOrCoin, SpawnBloodOrCoin)
        SprSetHandler(SPR_Door, SpawnDoor)
        SprSetHandler(SPR_Switch, SpawnSwitch)

        ExSprSetFlags(SPR_BloodOrCoin, SPRBIT_IsCollider)
        ExSprSetFlags(SPR_Switch, SPRBIT_IsCollider)
        ExSprSetFlags(SPR_Door, SPRBIT_IsCollider | SPRBIT_ExtendY)

	IRQ_SetNext($d1, GameIRQ1)

wait:	lda _shouldDrawMap
	beq wait
	jsr SprUpdate
        jsr DrawMap
        SetBorderColor(RED)
        jsr AnimateFlames
	SetBorderColor(BLACK)
        lda #$0
	sta _shouldDrawMap
        jmp wait
}

AnimateFlames:
{
	ldx _animDelay
	ldy #2
loop:
	cpx #14
	bcc ok
	ldx #0
	ok:
	lda _screen1+40*20+1,x
	adc #1
	and #$0f
	ora #$70
	sta _screen1+40*20+1,x
	lda _screen1+40*20+25,x
	adc #1
	and #$0f
	ora #$70
	sta _screen1+40*20+25,x

	lda _screen1+40*21+1,x
	adc #1
	and #$0f
	ora #$80
	sta _screen1+40*21+1,x
	lda _screen1+40*21+25,x
	adc #1
	and #$0f
	ora #$80
	sta _screen1+40*21+25,x
	inx
	stx _animDelay
	dey
	bpl loop
	rts
}



//----------------------------------------------------------
GameIRQ1:
{
	wait:
	lda $d012
	cmp #$d2
	bcc wait

	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop
	nop
	nop
	nop
//	nop
//	nop
//	nop

	SetScreenColor(RED)
	lda #$10  // no scroll here, but keep multicolor mode on (bit 4)
	sta $d016

	lda $d018
	and #$80
	ora #SCREEN1_BITS
	ora #FONT_BITS
	sta $d018

	SetMultiColor1(ORANGE)
	SetMultiColor2(YELLOW)

        lda #$01
	sta _shouldDrawMap

//        SetBorderColor(CYAN)
//        SetBorderColor(BLACK)

	IRQ_SetNext($e0, GameIRQ2)
	rts
}

GameIRQ2:
{

        nop
        nop
        nop
        nop
	SetScreenColor(BLACK)
	IRQ_SetNext($f9, GameIRQ3)
	rts
}

GameIRQ3:
{
        lda $d011
        and #%11110111 // Switch to 24 rows
        sta $d011

	IRQ_SetNext($102, GameIRQ4)
	rts
}

GameIRQ4:
{

        lda _scrollX
	sta $d016

	lda $d018
	and #$80
	ora _screenBits
	ora _fontBits
	sta $d018

	IRQ_SetNext($32, GameIRQ5)
	rts
}

GameIRQ5:
{
	nop // Make sure raster is off the right edge before changing the color
	nop
	nop
	nop
	SetScreenColor(BROWN)
	SetMultiColor1(DARK_GREY)
	SetMultiColor2(GREY)

	lda $27 // Turn sprites on again ($27 holds active sprite mask from SprUpdate)
	sta $d015

        lda $d011
        ora #%00001000 // Switch to 25 rows
        sta $d011

	IRQ_SetNext($d1, GameIRQ1)
	rts
}

#import "Player.asm"
#import "Coin.asm"

// When the sprite collision handler is called:
// $fb is current sprite index
// ($fc) points to current sprite properties
// $f2 is other sprite index
// ($22) points to other sprite properties
OnSprCollision:
{
	lda $fb
	cmp #SPR_Player
	beq check_ply_collision
	rts

check_ply_collision:
	lda $f2
	cmp #SPR_BloodOrCoin
	bne !next+

	SprSetHandler(SPR_BloodOrCoin, PickBloodOrCoin)
	inc _coins
	rts

!next:	cmp #SPR_Switch
	bne !next+

	lda #1
	sta _openDoor
	SprSetHandler(SPR_Switch, FlipSwitch)
	rts

!next:	cmp #SPR_Door
	bne !next+

	lda #1
	sta _playerDie

	rts
!next:

	rts

}
