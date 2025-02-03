IntroInit:
  		lda #$00
        sta $d020
        sta $d021
		lda #%11011000 // Turn on multicolor mode
		sta $d016

		lda #FONT_BITS
		sta _fontBits

		jsr DrawIntro

		SwapToBuffer1()

		IRQ_SetNext($30, IntroIRQ1)

wait:	lda $dc00
		and #%10000
		bne wait

		rts


//----------------------------------------------------------
IntroIRQ1:
{
		lda $d018
		and #$80
		ora _screenBits
		ora #FONT_BITS
		sta $d018

	/*
		ldx _timer
		beq fade
		dex
		stx _timer
		rts
fade:	ldy _startRow
		cpy #33
		beq reset
		ldx #7
rows:	cpy #25
		bcs skip
		lda _rampUp,x
		lda _screenPtr,y
		sta $fe
		sta $fc
		lda _screenPtr+25,y
		sta $ff
		sty $22
		lda ($fe),y

		ldy $22
skip:
		dey
		bmi exit
		dex
		bmi exit

		inx
		cpx #25
		beq exit
		dey
		bne rows
exit:	
		rts
reset:	ldx #50
		stx _timer
		ldx #0
		stx _startRow
		*/
		rts

_startRow: .byte 0
_timer: .byte 10
_rowColors: .fill 25,1
_rampDown: .byte 1,7,5,4,2,6,0
_rampUp: .byte 0,6,2,4,5,7,1
}

DrawIntro:
{
	DrawScreen(_textIntro)
	rts
}

_textIntro:
.byte $02,14,1
.text "BOANEO"
.byte 0
.byte $03,12,4
.text "PRESENTS"
.byte 0
.byte $02,16,8
.text "DRAC"
.byte 0
.byte $07,11,23
.text "PRESS"
.byte 0
.byte $07,22,23
.text "FI"
.byte 0
.byte $07,25,23
.text "RE"
.byte 0
.byte $ff
