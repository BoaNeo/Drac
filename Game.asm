_coins: .byte 0

.const SPR_Player = 0
.const SPR_BloodOrCoin = 1
.const SPR_Door = 2
.const SPR_Switch = 3

GameInit:
{
	SetBorderColor(BLACK)
	SetScreenColor(BROWN)
	SetMultiColor1(DARK_GREY)
	SetMultiColor2(GREY)
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
        SetBorderColor(RED)
        jsr DrawMap
        lda #$0
	sta _shouldDrawMap
        SetBorderColor(BLACK)
        jmp wait
}

_shouldDrawMap: .byte 0
_textHUD:
.byte BLACK,2,20
.text "bats: ###"
.byte 0
.byte BLACK,16,20
.text "lives: 3"
.byte 0
.byte BLACK,29,20
.text "vanish: 3"
.byte 0
.byte YELLOW,10,23
.text "RUN "
.byte 'Z'+2
.text " OF "
.byte 'Z'+6
.byte 0
.byte $ff

//----------------------------------------------------------
GameIRQ1:
{
	SetScreenColor(RED)

	lda #$00
	sta $d016 // no scroll here

	lda $d018
	and #$80
	ora #SCREEN1_BITS
	ora #FONT_BITS
	sta $d018

//        SetBorderColor(CYAN)
	jsr SprUpdate
//        SetBorderColor(BLACK)

	IRQ_SetNext($f9, GameIRQ2)
	rts
}

GameIRQ2:
{
        lda $d011
        and #%11110111
        sta $d011


	IRQ_SetNext($102, GameIRQ3)
	rts
}

GameIRQ3:
{
        nop
        nop
        nop
        nop
	SetScreenColor(BLACK)

        lda _scrollX
	sta $d016

	lda $d018
	and #$80
	ora _screenBits
	ora _fontBits
	sta $d018

        lda #$01
	sta _shouldDrawMap

	IRQ_SetNext($32, GameIRQ4)
	rts
}

GameIRQ4:
{
	nop // Make sure raster is off the right edge before changing the color
	nop
	nop
	nop
	SetScreenColor(BROWN)

	lda $27 // Turn sprites on again ($27 holds active sprite mask from SprUpdate)
	sta $d015

        lda $d011
        ora #%00001000
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

	SprSetHandler(SPR_Player,PlyDead)

	rts
!next:

	rts

}
