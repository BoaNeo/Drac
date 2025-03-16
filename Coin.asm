_tokenPos: .lohifill 20, 38+40*i 
_tokenType: .byte 0
_tokenRow: .byte 0

_openDoor: .byte 0
_spawnedToken: .byte 0

_coinY: .fill 20, VIS_TOP + i*8-7
_bloodY: .fill 20, VIS_TOP + i*8+2
_doorY: .fill 20, VIS_TOP + i*8-3
_switchY: .fill 20, VIS_TOP + i*8-12
_exLifeY: .fill 20, VIS_TOP + i*8-12

.const TOKEN_BLOOD = $79
.const TOKEN_COIN = $49
.const TOKEN_DOOR = $3D
.const TOKEN_SWITCH = $29
.const TOKEN_EXLIFE = $6D

TokenScan:
{
		ldx #$00
	not_found:
		lda _tokenPos.lo,x
		sta pt
		lda _tokenPos.hi,x
		clc
		adc _sprScreenHi
		sta pt+1
		lda pt:$ffff
		cmp #TOKEN_COIN
		beq found
		cmp #TOKEN_BLOOD
		beq found
		cmp #TOKEN_EXLIFE
		beq found
		cmp #TOKEN_DOOR
		beq found
		cmp #TOKEN_SWITCH
		beq found
		inx
		cpx #20
		bne not_found
		lda #0 // no token found
	found:
		sta _tokenType
		stx _tokenRow
		rts
}

InitToken:
{
		SprSetAnimation(_sprAnimEmpty, 0)
		SprSetHandler(SPR_SpawnedToken, SpawnToken)
		rts
}

SpawnToken:
{
	ldx _tokenType
	cpx #0
	bne !next+
	rts
	!next:
	cpx #TOKEN_SWITCH
	bne !next+
	rts
	!next:
	cpx #TOKEN_DOOR
	bne !next+
	rts
	!next:
		stx _spawnedToken
		lda #0 // Clear token
		sta _tokenType
		lda #VIS_RIGHT
		SprSTA(SPR_X)
		SprSetHandler(SPR_SpawnedToken, MoveSpawnedToken)

		cpx #TOKEN_BLOOD
		bne !next+

		SprSetAnimation(_sprAnimBloodSpin, 0)
		ldx _tokenRow
		lda _bloodY,x
		SprSTA(SPR_Y)
		rts
	!next:
		cpx #TOKEN_COIN
		bne !next+

		SprSetAnimation(_sprAnimCoinSpin, 0)
		ldx _tokenRow
		lda _coinY,x
		SprSTA(SPR_Y)
		rts
	!next:
		cpx #TOKEN_EXLIFE
		bne !next+

		SprSetAnimation(_sprAnimExLife, 0)
		ldx _tokenRow
		lda _exLifeY,x
		SprSTA(SPR_Y)
	!next:
		rts
}

MoveSpawnedToken:
{
		lda _mapScrollEnabled
		beq on_screen

			SprSBC(SPR_X, 1)
			cmp #$f0
			bcc on_screen

		no_move:

		SprSetAnimation(_sprAnimEmpty, 0)
		SprSetHandler(SPR_SpawnedToken, SpawnToken)
	on_screen:
		rts
}

PickSpawnedToken:
{
		SprSetAnimation(_sprAnimEmpty, 0)
		SprSetHandler(SPR_SpawnedToken, SpawnToken)
		rts
}

InitSwitch:
{
		SprSetAnimation(_sprAnimEmpty, 0)
		SprSetHandler(SPR_Switch, SpawnSwitch)
		rts
}

SpawnSwitch:
{
		ldx _tokenType
		cpx #TOKEN_SWITCH
		bne no_spawn
		ldx #0 // Clear token
		stx _tokenType
		ldx _tokenRow
		lda _switchY,x
		SprSTA(SPR_Y)
		lda #VIS_RIGHT
		SprSTA(SPR_X)
		SprSetAnimation(_sprAnimSwitchOff, 0)
		SprSetHandler(SPR_Switch, MoveSwitch)
	no_spawn:
		rts
}

MoveSwitch:
{
		lda _mapScrollEnabled
		beq on_screen
			SprSBC(SPR_X, 1)
			cmp #$f0
			bcc on_screen
		no_move:

		SprSetAnimation(_sprAnimEmpty, 0)
		SprSetHandler(SPR_Switch, SpawnSwitch)
	on_screen:
		rts
}

FlipSwitch:
{
		SprSBC(SPR_X, 1)
		SprSetAnimation(_sprAnimSwitchOn, 0)
		SprSetHandler(SPR_Switch, MoveSwitch)
		rts
}


InitDoor:
{
		SprSetAnimation(_sprAnimEmpty, 0)
		SprSetHandler(SPR_Door, SpawnDoor)
		rts
}

SpawnDoor:
{
		ldx _tokenType
		cpx #TOKEN_DOOR
		beq spawn
		rts
	spawn:
		ldx #0 // Clear token
		stx _tokenType
		ldx _tokenRow
		lda _doorY,x
		SprSTA(SPR_Y)
		lda #VIS_RIGHT+2
		SprSTA(SPR_X)

		SprSetFlags(SPRBIT_IsCollider)
		SprSetAnimation(_sprAnimDoorClosed, 0)
		SprSetHandler(SPR_Door, MoveClosedDoor)
		rts
}

MoveClosedDoor:
{
		lda _mapScrollEnabled
		beq on_screen
			SprSBC(SPR_X, 1)
			cmp #$f0
			bcc on_screen
		no_move:

		SprSetAnimation(_sprAnimEmpty, 0)
		SprSetHandler(SPR_Door, SpawnDoor)
	on_screen:

		lda _openDoor
		beq keep_closed

		lda #0
		sta _openDoor

		SprADC(SPR_X,4)
		SprSetAnimation(_sprAnimDoorOpen, 0)
		SprClearFlags(SPRBIT_IsCollider)
		SprSetHandler(SPR_Door, MoveOpenDoor)

	keep_closed:
		rts
}

MoveOpenDoor:
{
		lda _mapScrollEnabled
		beq on_screen
			SprSBC(SPR_X, 1)
			cmp #$f0
			bcc on_screen
		no_move:

		SprSetAnimation(_sprAnimEmpty, 0)
		SprSetHandler(SPR_Door, SpawnDoor)
	on_screen:
		rts
}
