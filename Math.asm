//------------------------------------------------------------
// A: Overridden
// C: Overridden
// Z: Overridden

.macro Add_8to16(lo, hi, amount)
{
	clc
	cld
	lda lo
	adc #amount
	sta lo
	bcc exit
	inc hi
	exit:
}

//------------------------------------------------------------
// A: Overridden
// C: Overridden
// Z: Overridden

.macro Sub_8from16(lo,hi,amount)
{	
	sec
	cld
	lda lo
	sbc #amount
	sta lo
	bcs exit
	dec hi
	exit:
}
