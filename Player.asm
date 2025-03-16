.const CHAR_COLLISION_MASK = $f0
.const BAT_TIME = $20
.const NEXT_LEVEL_CHAR = $5D

_batTimer: .byte 0 
_playerDie: .byte 0

_coins: .byte 0
_blood: .byte 0
_lifes: .byte 0

PlySpawn:
{
	    lda #80
	    SprSTA(SPR_X)
	    lda #80
	    SprSTA(SPR_Y)
	    lda #20
	    SprSTA(SPR_CharAt)

	    SprClearFlags(SPRBIT_CheckCollision)

		SprSetAnimation(_sprAnimDracAppear, PlyEOA_Spawn)
		SprSetHandler(SPR_Player,PlySpawning)
		rts
}

PlySpawning:
{
		lda #0
		sta _playerDie
		rts
}

PlyRun:
{
		lda _playerDie
		bne dead

		SprLDA(SPR_CharAt)
		cmp #NEXT_LEVEL_CHAR
		bne no_new_level

		inc _mapIndex
		jsr InitMap

		no_new_level:		

		SprLDA(SPR_CharAt)
		and #CHAR_COLLISION_MASK
		bne alive

	dead:
		SprSetAnimation(_sprAnimDracDie, PlyEOA_Death)
		SprSetHandler(SPR_Player,PlyDead)
		rts

	alive:
		SprLDA(SPR_CharBelow)
		and #CHAR_COLLISION_MASK // First 16 characters are "ground"
		beq up

		SprSetAnimation(_sprAnimDracFalling, 0)
		SprSetHandler(SPR_Player,PlyFalling)
		rts

	up:
		lda _mapScrollEnabled
		bne should_animate
		lda $dc00
		eor #%01100
		and #%01100
		bne should_animate
		SprSetAnimation(_sprAnimDracRun, 0)
	should_animate:
		lda $dc00
		ror
		bcs down
		lda _blood
		bne !use_blood+
		rts
	!use_blood:
		dec _blood
	    SprClearFlags(SPRBIT_CheckCollision)
		SprSetAnimation(_sprAnimDracVanish, PlyEOA_ReappearUp)
		SprSetHandler(SPR_Player,PlyTeleportUp)
		rts
	down:
		ror
		bcs left
		lda _blood
		bne !use_blood+
		rts
	!use_blood:
		dec _blood
	    SprClearFlags(SPRBIT_CheckCollision)
		SprSetAnimation(_sprAnimDracVanish, PlyEOA_ReappearDown)
		SprSetHandler(SPR_Player,PlyTeleportDown)
		rts
	left:
		ror
		bcs right
		PlyMoveLeft(2)
		rts
	right:
		ror
		bcs fire
		PlyMoveRight(1)
		rts
	fire:
		ror
		bcs no_fire
		SprSetAnimation(_sprAnimDracToBat, PlyEOA_ToBat)
		SprSetHandler(SPR_Player,PlyToBat)
	no_fire:
		rts
}


PlyFalling:
{
		lda _playerDie
		bne dead

		SprLDA(SPR_CharAt)
		and #CHAR_COLLISION_MASK
		bne alive

	dead:

		SprSetAnimation(_sprAnimDracDie, PlyEOA_Death)
		SprSetHandler(SPR_Player,PlyDead)
		rts

	alive:
		SprLDA(SPR_CharBelow)
		and #CHAR_COLLISION_MASK // First 16 characters are "ground"
		bne falling

		SnapToFloor()

		SprSetAnimation(_sprAnimDracRun, 0)
		SprSetHandler(SPR_Player,PlyRun)
		rts

	falling:
		PlyMoveDown(1)

		lda $dc00
		ror
		ror
		ror
		bcs right
		PlyMoveLeft(1)
		jmp fire
	right:
		ror
		bcs fire
		PlyMoveRight(1)
	fire:
		lda $dc00
		and #$10
		bne no_fire
		SprSetAnimation(_sprAnimDracToBat, PlyEOA_ToBat)
		SprSetHandler(SPR_Player,PlyToBat)
	no_fire:
		rts
}

PlyToBat:
{
		lda _playerDie
		bne dead

		SprLDA(SPR_CharAt)
		and #$f0
		bne alive

	dead:

		SprSetAnimation(_sprAnimDracDie, PlyEOA_Death)
		SprSetHandler(SPR_Player,PlyDead)
		rts

alive:	PlyMoveUp(1)
		rts
}

PlyBat:
{
		lda _playerDie
		bne dead

		SprLDA(SPR_CharAt)
		and #CHAR_COLLISION_MASK
		bne alive

	dead:

		SprSetAnimation(_sprAnimDracDie, PlyEOA_Death)
		SprSetHandler(SPR_Player,PlyDead)
		rts
		
alive:
		dec _batTimer
		bne control

		SprSetAnimation(_sprAnimDracFromBat, PlyEOA_FromBat)
	control:
		lda $dc00
		ror
		bcs down
		PlyMoveUp(1)
		jmp leftright
	down:
		ror
		bcs leftright
		PlyMoveDown(1)
	leftright:
		lda $dc00
		ror
		ror
		ror
		bcs right
		PlyMoveLeft(2)
		jmp fire
	right:
		ror
		bcs fire
		PlyMoveRight(1)
	fire:
		lda $dc00
		and #$10
		bne no_fire
		SprSetAnimation(_sprAnimDracFromBat, PlyEOA_FromBat)
	no_fire:
		rts
}

PlyTeleportUp:
{
		lda #0
		sta _playerDie
		rts
}

PlyTeleportDown:
{
		lda #0
		sta _playerDie
		rts
}

PlyAppear:
{
		lda #0
		sta _playerDie
		rts
}

PlyDead:
{
		lda #0
		sta _playerDie

		PlyMoveLeft(1)
		SprLDA(SPR_Frame)
		bne no_blow
		PlyMoveLeft(1)

	no_blow:
		SprLDA(SPR_CharBelow)
		and #CHAR_COLLISION_MASK
		bne falling

		SnapToFloor()
		rts

	falling:
		PlyMoveDown(1)
		rts
}

PlyEOA_ToBat:
{
		lda #BAT_TIME
		sta _batTimer
		SprSetAnimation(_sprAnimDracBat, 0)
		SprSetHandler(SPR_Player,PlyBat)
		rts
}

PlyEOA_FromBat:
{
		SprSetAnimation(_sprAnimDracFalling, 0)
		SprSetHandler(SPR_Player,PlyFalling)
		rts
}

PlyEOA_Spawn:
{
	    SprSetFlags(SPRBIT_CheckCollision)
		SprSetAnimation(_sprAnimDracFalling, 0)
		SprSetHandler(SPR_Player,PlyFalling)
		rts
}

PlyEOA_Death:
{
		dec _lifes
		lda _lifes
		beq game_over
		SprSetAnimation(_sprAnimDracAppear, 0)
		SprSetHandler(SPR_Player,PlySpawn)
		rts
game_over:		
		SprSetAnimation(_sprAnimEmpty, 0)
		SprSetHandler(SPR_Player, 0)
		rts
}

PlyEOA_ReappearUp:
{
		PlyMoveUp($48)
	    SprSetFlags(SPRBIT_CheckCollision)
		SprSetAnimation(_sprAnimDracAppear, PlyEOA_StartRun)
		SprSetHandler(SPR_Player,PlyAppear)
		rts
}

PlyEOA_ReappearDown:
{
		PlyMoveDown($38)
	    SprSetFlags(SPRBIT_CheckCollision)
		SprSetAnimation(_sprAnimDracAppear, PlyEOA_StartRun)
		SprSetHandler(SPR_Player,PlyAppear)
		rts
}

PlyEOA_StartRun:
{
		SprSetAnimation(_sprAnimDracRun, 0)
		SprSetHandler(SPR_Player,PlyRun)
		rts
}

.macro SnapToFloor()
{
		SprLDA(SPR_Y)
		and #$f8
		clc
		adc #2
		SprSTA(SPR_Y)
}

.macro PlyMoveUp(dy)
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

.macro PlyMoveDown(dy)
{
		SprLDA(SPR_Y)
		clc
		adc #dy
		cmp #VIS_BOTTOM-5*8
		bcc ok
		lda #1
		sta _playerDie
		lda #VIS_BOTTOM-5*8
ok:		SprSTA(SPR_Y)
}

.macro PlyMoveLeft(dx)
{
		SprLDA(SPR_X)
		sec
		sbc #dx
		bcc not_ok
		cmp #VIS_LEFT+8
		bcs ok
not_ok:	lda #VIS_LEFT+8
ok:		SprSTA(SPR_X)
}

.macro PlyMoveRight(dx)
{
		SprLDA(SPR_X)
		clc
		adc #dx
		cmp #VIS_RIGHT-8
		bcc ok
		lda #VIS_RIGHT-8
ok:		SprSTA(SPR_X)
}

