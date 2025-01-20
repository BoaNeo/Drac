BasicUpstart2(start)
//----------------------------------------------------------
//----------------------------------------------------------
//   Simple IRQ
//----------------------------------------------------------
//----------------------------------------------------------

        * = $4000 "Main Program"
start:  lda #$00
        sta $d020
        lda #$09
        sta $d021
        sei
        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315
        lda #$7f  // Kill all timer interrupts (bit 8 value is copied to all other bits that are not zero)
        sta $dc0d // CIA #1
        sta $dd0d // CIA #2
        lda #$81  // Enable raster interrupt (What does setting bit 8 do?)
        sta $d01a
        lda #$1b  // Set raster line interrupt = 128 (8 lower bits in d012, high bit is Bit 8 of d011, rest are default)
        sta $d011
        lda #$00
        sta $d012
        lda $dc0d // Why are both these read into A?
        lda $dd0d  
        asl $d019 // This acknowledges interrupts in a somewhat nasty and not very compatible way
        cli
        jmp *	// Jump to self

//----------------------------------------------------------
irq1:   lda #$01 // Acknowledge raster interrupt
		sta $d019 

		ldy view_y
		ldx view_x
        lda $dc00
        lsr
        bcs not_up
		cpy #$10
		beq not_up

		Sub16(view_scroll_y,view_y,%00100000)
not_up:	lsr
		bcs not_dwn
		cpy #$00
		beq not_dwn
		Add16(view_scroll_y,view_y,%00100000)
not_dwn:lsr
		bcs not_lft
		cpx #$00
		beq not_lft
		Sub16(view_scroll_x,view_x,%00100000)
not_lft:lsr
		bcs not_rgt
		cpx #$ff-40
		beq not_rgt
		Add16(view_scroll_x,view_x,%00100000)
not_rgt:lsr
		bcs not_fire
		lda #$00
		sta view_x
		sta view_y
		sta view_scroll_x
		sta view_scroll_y
not_fire:

        SetBorderColor(2)
        jsr SetScroll
        jsr DrawMap
        SetBorderColor(0)

        jmp $ea81


view_scroll_x: .byte 0
view_x: .byte 0
view_scroll_y: .byte 0 
view_y: .byte 0 


//------------------------------------------------------------

SetScroll:
{
	lda view_scroll_x
	lsr
	lsr
	lsr
	lsr
	lsr
	eor #7
	ora #%11000000 // Turn on multicolor mode and shrink screen to 38 columns
	sta $d016

	lda view_scroll_y
	lsr
	lsr
	lsr
	lsr
	lsr
	eor #7
	ora #%00010000 // Shrink screen to 24 rows
	sta $d011

	rts
}

.macro Add16(lo, hi, amount)
{
	pha
	clc
	lda lo
	adc #amount
	sta lo
	bcc exit
	inc hi
	exit:
	pla
}

.macro Sub16(lo,hi,amount)
{	
	pha
	sec
	lda lo
	sbc #amount
	sta lo
	bcs exit
	dec hi
	exit:
	pla
}


//------------------------------------------------------------

DrawMap:
{
		// Set map pointer for upper left corner in ($fc,$fe)
		lda view_x
		lsr
		sta $fc
		sta $fe

		lda view_y
		lsr
		clc
		adc #>map
		sta $fd
		sta $ff

		// Set starting point for first row - assume last two characters on the right for now
		ldx #$26
		stx $fb

		lda view_y
		and #$01
		beq fill_middle
		{
			// If Y is uneven, start with a half-row
			ldx #$26	// Set counter for the target buffer

			// If X is uneven, include one extra column and end with a half-column
			lda view_x
			and #$01
			beq even_x
			// Uneven rows are offset by one character, we handle the edges separately
			dex
			// Handle the upper left most byte that would otherwise be skipped on uneven x
			ldy #$00
			lda ($fc),y
			adc #$03
			sta $0400

			even_x:

			clc
			ldy #$13	// Set counter for the map

			// Fill the top screen row with the lower half of the tiles that are currently visible
			loop:
			lda ($fc),y
			adc #$02
			sta $0400,x
			adc #$01
			sta $0401,x
			dex
			dex
	        bmi exit // Bail when x is negative
			dey
	        bpl loop // Continue until y is negative

			exit:
	        inc $fd // Make sure the next loop starts one row further down the map
	        ldx #40+38 // and one row further down in screen memory
			stx $fb
		}

		fill_middle:
		{
			// Fill remaining rows
			ldy #$13
			ldx $fb

			// If X is uneven, include one extra column and end with a half-column
			lda view_x
			and #$01
			bne uneven_x 
			jmp even_x
			uneven_x:
			{
				lda $fd // Reset the map pointer because the unrolled loop below will change it
				sta $ff
				// Fill uneven column in right side (x already offsets to last full tile on the right side)
				.for(var row=0;row<12;row++)
				{
					lda ($fe),y
					sta $0400+1+row*80,x
					adc #$02
					sta $0428+1+row*80,x
					inc $ff
				}
				lda $fd // Reset the map pointer because the unrolled loop below will change it
				sta $ff
				// Full uneven column in left side (unfortunately need to reset y to get the correct tile)
				ldy #$00
				.for(var row=0;row<12;row++)
				{
					lda ($fe),y
					adc #$01
					sta $0400-38+row*80,x
					adc #$02
					sta $0428-38+row*80,x
					inc $ff
				}
				// Reset y
				ldy #$13
				dex
			}

			even_x:
			clc

			loop:
			lda $fd // Reset the map pointer because the unrolled loop below will change it
			sta $ff

			.for(var row=0;row<12;row++)
			{
				lda ($fe),y
				sta $0400+row*80,x
				adc #$01
				sta $0401+row*80,x
				adc #$01
				sta $0428+row*80,x
				adc #$01
				sta $0429+row*80,x
				inc $ff
			}
			dex
			dex
	        bmi final_row
			dey
	        bmi final_row
	        jmp loop
		}

		final_row:
		// If Y is even, end with a half-row
		lda view_y
		and #$01
		bne exit
		{
			ldx #$26	// Set counter for the target buffer
			// If X is uneven, include one extra column and end with a half-column
			lda view_x
			and #$01
			beq even_x
			// Uneven rows are offset by one character, we handle the edges separately
			dex
			// Handle the lower left most byte that would otherwise be skipped on uneven x
			ldy #$00
			lda ($fe),y
			adc #$01
			sta $0400+24*40

			even_x:

			ldy #$13	// Set counter for the map
			clc

			// Fill the bottom screen row with the upper half of the tiles that are currently visible
			loop:
			lda ($fe),y
			sta $0400+24*40,x
			adc #$01
			sta $0401+24*40,x
			dex
			dex
	        bmi exit // Bail when x is negative
			dey
	        bpl loop // Continue until y is negative
		}
		exit:
		rts
}


//----------------------------------------------------------
//        *=$1000 "Music"
//       .import binary "ode to 64.bin"

*=$5000 "Map"
map: 
.fill $1000, (4*(mod(i, 4)+4*i/256))&127


//----------------------------------------------------------
// A little macro
.macro SetBorderColor(color) 
{
        lda #color
        sta $d020
}