IRQ_Init:
		sei
        lda #<IRQ_Handler
        sta $0314
        lda #>IRQ_Handler
        sta $0315
        lda #$7f  // Kill all timer interrupts (bit 8 value is copied to all other bits that are not zero)
        sta $dc0d // CIA #1
        sta $dd0d // CIA #2

        lda #$81  // Enable raster interrupt (What does setting bit 8 do?)
        sta $d01a
        lda #$1b  // Set raster line interrupt (8 lower bits in d012, high bit is Bit 8 of d011, rest are default)
        sta $d011
        lda #$00
        sta $d012
        lda #$01 // Ack IRQ
        sta $d019 

        lda $dc0d // Why are both these read into A?
        lda $dd0d  
        cli
        rts

IRQ_Handler:
		lda $27 // Turn sprites on again ($27 holds active sprite mask from SprUpdate)
		sta $d015

		lda $d018
		and #$80
		ora _screenBits
		ora _fontBits
		sta $d018

		jsr _IRQ_Func:IRQ_Default

		lda $d011
		and #$80
        ora _IRQ_LineHi:#$00 // #($1b | ( (raster>>1)&$80 ) )  // Set raster line interrupt (8 lower bits in d012, high bit is Bit 8 of d011, rest are default)
        sta $d011
        lda _IRQ_LineLo:#$00 // #(raster&$ff)
        sta $d012
		lda #$01 // Acknowledge raster interrupt
		sta $d019
        jmp $ea81

IRQ_Default:
		rts

.macro IRQ_SetNext(raster, address)
{
        lda #($1b | ( (raster>>1)&$80 ) )  // Set raster line interrupt (8 lower bits in d012, high bit is Bit 8 of d011, rest are default)
        sta _IRQ_LineHi
        lda #(raster&$ff)
        sta _IRQ_LineLo
        lda #<address
        sta _IRQ_Func
        lda #>address
        sta _IRQ_Func+1
}
