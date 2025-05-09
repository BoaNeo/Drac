.const REQUIRED_COINS = 2

_tick: .byte 0
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
/*
.byte 8+RED,5,23
.byte 'Z'+21
.byte 'Z'+21
.byte 'Z'+21
.byte 0

.byte YELLOW,15,22
.text "coins: "
.text "0/"
.byte ('0'+REQUIRED_COINS)
.byte 0

.byte RED,14,23
.text "sunset 00:00"
.byte 0

.byte 8+RED,29,23
.byte 'Z'+22
.byte 'Z'+22
.byte 'Z'+22
.byte 0
*/
.byte $ff

_bloodBar:
.byte $93,$94,$93,$94,$93,$94
.byte $a3,$a4,$a3,$a4,$a3,$a4
_lifeBar:
.byte $95,$96,$95,$96,$95,$96
.byte $a5,$a6,$a5,$a6,$a5,$a6
_textLevelComplete:
.text "level complete"
.byte 0
_textGoToTheExit:
.text "go to the exit"
.byte 0
_textExitRight:
.text "  exit right  "
.byte 0
_textToContinue:
.text " to continue! "
.byte 0
_textGame:
.text "  game  over  "
.byte 0
_textOver:
.text "  press fire  "
.byte 0
_textCoins:
.text "  coins: 0/"
.byte ('0'+REQUIRED_COINS)
.text "  "
.byte 0
_textSunset:
.text " sunset 00:00 "
.byte 0



.const SPR_Player = 0
.const SPR_SpawnedToken = 1
.const SPR_Door = 2
.const SPR_Switch = 3

GameInit:
{
	SetBorderColor(BLACK)
	SetScreenColor(BLACK)
	SetSprColor1(BLACK)
	SetSprColor2(RED)

	jsr ClearScreen1
	jsr ClearScreen2
	jsr ClearColor1
	jsr ClearColor2

	lda #<_textHUD
	sta $fa
	lda #>_textHUD
	sta $fb
	jsr DrawScreen
	jsr ApplyColorBuffer1

	lda #3
	sta _lifes
	lda #3
	sta _blood

	SwapToBuffer1()

	lda #0
	sta _mapIndex

	jsr GameStartRun

    SprManagerInit($c0,$ff,OnSprCollision)

    SprSetHandler(SPR_Player, PlySpawn)
    SprSetHandler(SPR_SpawnedToken, InitToken)
    SprSetHandler(SPR_Door, InitDoor)
    SprSetHandler(SPR_Switch, InitSwitch)

    ExSprSetFlags(SPR_SpawnedToken, SPRBIT_IsCollider)
    ExSprSetFlags(SPR_Switch, SPRBIT_IsCollider)
    ExSprSetFlags(SPR_Door, SPRBIT_IsCollider | SPRBIT_ExtendY)


	IRQ_SetNext($d1, GameIRQ1)

	wait:
		lda _shouldDrawMap
		beq wait
		jsr SprUpdate
	    jsr DrawMap
	//        SetBorderColor(RED)
	    jsr AnimateFlames
	    jsr UpdateHUD
	//	SetBorderColor(BLACK)
	    lda #$0
		sta _shouldDrawMap
		lda _lifes
		bne wait
		lda $dc00
		and #%10000
		bne wait
	release:
		lda $dc00
		and #%10000
		beq release
		rts
}

GameStartRun:
{
	lda #0
	sta _coins
	lda #1
	sta _tick
	lda #'2'
	sta _textSunset+9
	lda #'3'
	sta _textSunset+11
	lda #'0'
	sta _textSunset+12
	lda #1
	sta _mapScrollEnabled
	sta _mapScrollLooped
	jsr InitMap
	rts
}

UpdateHUD:
{
	ldx _lifes
	beq game_over
	lda _screen1+24*40+25
	ora _screen1+24*40+24
	ora _screen1+24*40+22
	ora _screen1+24*40+21
	cmp #'0'
	beq game_over
	lda _coins
	cmp #REQUIRED_COINS 
	bcs level_completed
	jmp show_coins
	game_over:
		DRAW_TEXT(_textGame, 13, 23, _colorBlinkGreen)
		DRAW_TEXT(_textOver, 13, 24, _colorBlinkYellow)
		lda #0
		sta _mapScrollEnabled
		jmp bars	
	level_completed:
		lda _mapScrollEnabled
		beq end_reached
		DRAW_TEXT(_textLevelComplete, 13, 23, _colorBlinkGreen)
		DRAW_TEXT(_textGoToTheExit, 13, 24, _colorBlinkYellow)
		jmp bars
		end_reached:
			DRAW_TEXT(_textExitRight, 13, 23, _colorBlinkGreen)
			DRAW_TEXT(_textToContinue, 13, 24, _colorBlinkYellow)
			jmp bars
	show_coins:
		lda _coins
		clc
		adc #'0'
		sta _textCoins+9

		DRAW_TEXT(_textCoins, 13, 23, _colorBlinkGreen)
		DRAW_TEXT(_textSunset, 13, 24, _colorBlinkYellow)

		jsr ClockTick
	bars:
		FILL_BAR(_blood, _bloodBar, 5, 23)
		FILL_BAR(_lifes, _lifeBar, 29,23)
		rts
}

ClockTick:
{
		dec _tick
		beq tick_now
		rts
	tick_now:
		lda #55
		sta _tick

		DEC_DIGIT(12)
		DEC_DIGIT(11)
		DEC_DIGIT(9)
		DEC_DIGIT(8)
		rts
}
.macro DEC_DIGIT(x)
{
		lda _textSunset+x
		cmp #'0'
		beq wrap
		dec _textSunset+x
		rts
	wrap:
		lda #'9'
		sta _textSunset+x
}

_blink:
.byte 0
_colorBlinkYellow:
.byte RED, YELLOW, WHITE,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW, CYAN, GREEN, PURPLE, RED, BLUE, BLACK
_colorBlinkGreen:
.byte BLUE, GREEN, CYAN,GREEN,GREEN,GREEN,GREEN,GREEN, GREEN,GREEN, GREEN, GREEN, PURPLE, RED, BLUE, BLACK

.macro DRAW_TEXT(text, x, y, color)
{
	lda _blink
	lsr
	lsr
	and #$0f
	tay
	lda color,y
	tay
	inc _blink
	ldx #0
	draw:
		lda text,x
		beq done
		sta _screen1 + x + y*40,x
		tya
		sta $d800 + x + y*40,x
		inx
		bne draw
	done:
}

.macro FILL_BAR(count, bar, x, y)
{
	lda count
	asl
	sta $22
	ldx #0
	!fill:
		cpx $22
		bcs clear
		lda bar,x
		sta _screen1+x+y*40,x
		lda bar+6,x
		sta _screen1+x+(y+1)*40,x
		inx
		cpx #6
		bne !fill-
		beq done
	clear:	
		lda #$20
	!fill:
		sta _screen1+x+y*40,x
		sta _screen1+x+(y+1)*40,x
		inx
		cpx #6
		bne !fill-
	done:
}

AnimateFlames:
{
	ldx _animDelay
	ldy #1
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
		cmp #SPR_SpawnedToken
		bne !next+

			SprSetHandler(SPR_SpawnedToken, PickSpawnedToken)

			lda _spawnedToken
			cmp #TOKEN_BLOOD
			beq !blood+
				cmp #TOKEN_COIN
				beq !coin+
				lda _lifes
				cmp #3
				bcs !full+
				inc _lifes
			!full:
				rts
			!coin:
				lda _coins
				cmp #REQUIRED_COINS
				bcs !done+
					inc _coins
					lda _coins
					cmp #REQUIRED_COINS
					bcc !done+
						// Extend the map so it shows the end-screen
						lda _mapWidth
						clc
						adc #10
						sta _mapWidth
						// And disable map looping
						lda #0
						sta _mapScrollLooped
			!done:
				rts
			!blood:
				lda _blood
				cmp #3
				bcs !full+
					inc _blood
			!full:
				rts

	!next:
		cmp #SPR_Switch
		bne !next+

			lda #1
			sta _openDoor
			SprSetHandler(SPR_Switch, FlipSwitch)
			rts

	!next:	
		cmp #SPR_Door
		bne !next+

			lda #1
			sta _playerDie
			rts
	!next:

	rts
}
