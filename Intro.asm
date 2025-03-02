.const COLOR_RAMP_SIZE = 16

IntroInit:
{
		IRQ_SetNext($30, IntroIRQ1)

		SetBorderColor(BLACK)
		SetScreenColor(BLACK)

		lda #%11001000 // Turn on multicolor mode
		sta $d016
	    lda $d011
	    ora #%00001000 // Switch to 25 rows
	    sta $d011

		lda #FONT_BITS
		sta _fontBits

		lda #1
		sta _timer
		sta _direction
		lda #0
		sta _screenIndex
		lda #25+COLOR_RAMP_SIZE
		sta _startRow

		jsr ClearScreen1
		jsr ClearColorRam

		SwapToBuffer1()

wait:	lda $dc00
		and #%10000
		bne wait

		lda #$01
		sta _timer
		sta _direction
		lda #<_rampDown
		sta ramp
		lda #>_rampDown
		sta ramp+1

wait_for_fade:
		lda _direction
		bne wait_for_fade 

		rts


//----------------------------------------------------------

IntroIRQ1:
		lda $d018
		and #$80
		ora _screenBits
		ora #FONT_BITS
		sta $d018

		ldx _timer
		beq fade
		dex
		stx _timer
		rts
	fade:
		ldy _startRow
		cpy #25+COLOR_RAMP_SIZE // We've faded all 25 rows completely and we can start over
		beq reset
		ldx #COLOR_RAMP_SIZE-1
	rows:
		cpy #COLOR_RAMP_SIZE // The first rows are off screen
		bcc skip 
		cpy #25+COLOR_RAMP_SIZE // The last are also off screen
		bcs exit
		lda _lineOffsets.lo,y // Get color ram offset for row y (lo byte)
		sta $fe
		lda _lineOffsets.hi,y // Get color ram offset for row y (hi byte)
		sta $ff
		sty $22
//
		cpx #(COLOR_RAMP_SIZE-1)
		bne normal_fill
		lda _direction
		bne normal_fill

		lda _srcOffsets.lo,y // Get color ram offset for row y (lo byte)
		sta $fc
		lda _srcOffsets.hi,y // Get color ram offset for row y (hi byte)
		sta $fd
		ldy #39
	final_fill_line:
		lda ($fc),y
		sta ($fe),y
		dey
		bpl final_fill_line
		jmp next
//
	normal_fill:
		ldy #39
		lda ramp: _rampUp,x
	fill_line:
		sta ($fe),y
		dey
		bpl fill_line
	next:
		ldy $22
	skip:
		iny
		dex
		bpl rows
	exit:
		inc _startRow
		rts
	reset:
		ldx #0
		stx _startRow
		lda _direction
		bne up
		ldx #180
		stx _timer
		lda #<_rampDown
		sta ramp
		lda #>_rampDown
		sta ramp+1
		inc _direction
		rts
	up:
		ldx #5
		stx _timer
		lda #<_rampUp
		sta ramp
		lda #>_rampUp
		sta ramp+1
		dec _direction
		ldx _screenIndex
		lda _screensLo,x
		bne set_screen
		ldx #0
		stx _screenIndex
		lda _screensLo,x
	set_screen:
		sta $fa
		lda _screensHi,x
		sta $fb
		inc _screenIndex
		jsr ClearScreen1
		jmp DrawScreen

_srcOffsets:
		.lohifill 25+COLOR_RAMP_SIZE, i<COLOR_RAMP_SIZE ? _color1 : _color1+40*(i-COLOR_RAMP_SIZE)
_lineOffsets:
		.lohifill 25+COLOR_RAMP_SIZE, i<COLOR_RAMP_SIZE ? $d800 : $d800+40*(i-COLOR_RAMP_SIZE)

_screenIndex: .byte 0
_direction: .byte 0
_startRow: .byte 0
_timer: .byte 10
//_rampDown: .byte WHITE,YELLOW,WHITE,YELLOW,YELLOW,CYAN,YELLOW,CYAN,CYAN,GREEN,CYAN,GREEN,GREEN,BLUE,GREEN,BLUE,BLACK
_rampDown: .byte WHITE, LIGHT_GREEN, YELLOW, LIGHT_GRAY, CYAN, LIGHT_RED, GREEN, GRAY, LIGHT_BLUE, ORANGE, PURPLE, DARK_GRAY, RED, BROWN, BLUE, BLACK

_rampUp: .byte BLACK, BLUE, BROWN, RED, DARK_GRAY, PURPLE, ORANGE, LIGHT_BLUE, GRAY, GREEN, LIGHT_RED, CYAN, LIGHT_GRAY, YELLOW, LIGHT_GREEN, WHITE

//_rampUp: .byte BLUE, GREEN, BLUE, GREEN, GREEN, CYAN, GREEN, CYAN, CYAN, YELLOW, CYAN, YELLOW, YELLOW, WHITE, YELLOW, WHITE, RED
_screensLo: .byte <_textIntro, <_textHelp, <_textHighScore, 0
_screensHi: .byte >_textIntro, >_textHelp, >_textHighScore, 0
}

_textIntro:
.byte RED,14,1
.text "BOANEO"
.byte 0
.byte CYAN,16,4
.text "presents"
.byte 0
.byte RED,16,8
.text "DRAC"
.byte 0
.byte YELLOW,8,23
.text "press FIRE to start."
.byte 0
.byte $ff

///////----------++++++++++----------++++++++++

_textHelp:
.byte YELLOW,2,1
.text "Help DRAC collect "
.byte ('Z'+6)
.text " gold coins"
.byte 0
.byte YELLOW,0,2
.text "in tax from every village in the county."
.byte 0

.byte YELLOW,0,5
.text "Tax must be collected before the sunset"
.byte 0
.byte YELLOW,7,6
.text "so speed is of the essence."
.byte 0

.byte YELLOW,2,9
.text "Be aware of closed doors, walls and"
.byte 0
.byte YELLOW,12,10
.text "other obstacles."
.byte 0

.byte YELLOW,7,13
.text "Consume blood to teleport"
.byte 0
.byte YELLOW,4,14
.text "to higher or lower ground using:"
.byte 0
.byte GREEN,1,17
.text "FIRE + UP or FIRE + DOWN"
.byte 0

.byte YELLOW,1,20
.text "To fly across short distances, press:"
.byte 0
.byte GREEN,16,23
.text "FIRE"
.byte 0
.byte $ff

_textHighScore:
.byte GREEN,11,1
.text "HIGH SCORE"
.byte 0
.byte CYAN,11,6
.text "1. TOX"
.byte 0
.byte GREEN,23,6
.text "123456"
.byte 0
.byte CYAN,11,9
.text "2. TOX"
.byte 0
.byte GREEN,23,9
.text "123456"
.byte 0
.byte CYAN,11,12
.text "3. TOX"
.byte 0
.byte GREEN,23,12
.text "123456"
.byte 0
.byte YELLOW,11,23
.text "PRESS FIRE"
.byte 0
.byte $ff
