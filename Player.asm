.const CHAR_COLLISION_MASK = $f0
.const BAT_TIME = $20

_batTimer:
.byte 0 

PlySpawn:
{
	    lda #80
	    SprSTA(SPR_X)
	    lda #80
	    SprSTA(SPR_Y)

	    SprClearFlags(SPRBIT_CheckCollision)

		SprSetAnimation(_sprAnimDracAppear, PlyEOA_Spawn)
		SprSetHandler(SPR_Player,PlySpawning)
		rts
}

PlySpawning:
{
		rts
}

PlyRun:
{
		SprLDA(SPR_CharAt)
		and #CHAR_COLLISION_MASK
		bne alive

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
		lda $dc00
		ror
		bcs down
	    SprClearFlags(SPRBIT_CheckCollision)
		SprSetAnimation(_sprAnimDracVanish, PlyEOA_ReappearUp)
		SprSetHandler(SPR_Player,PlyTeleportUp)
		rts
	down:
		ror
		bcs left
	    SprClearFlags(SPRBIT_CheckCollision)
		SprSetAnimation(_sprAnimDracVanish, PlyEOA_ReappearDown)
		SprSetHandler(SPR_Player,PlyTeleportDown)
		rts
	left:
		ror
		bcs right
		SprMoveLeft(2)
		rts
	right:
		ror
		bcs fire
		SprMoveRight(1)
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
		SprLDA(SPR_CharAt)
		and #CHAR_COLLISION_MASK
		bne alive

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
		SprMoveDown(1)

		lda $dc00
		ror
		ror
		ror
		bcs right
		SprMoveLeft(1)
		jmp fire
	right:
		ror
		bcs fire
		SprMoveRight(1)
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
		SprLDA(SPR_CharAt)
		and #$f0
		bne alive

		SprSetAnimation(_sprAnimDracDie, PlyEOA_Death)
		SprSetHandler(SPR_Player,PlyDead)
		rts

alive:	SprMoveUp(1)
		rts
}

PlyBat:
{
		SprLDA(SPR_CharAt)
		and #CHAR_COLLISION_MASK
		bne alive

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
		SprMoveUp(1)
		jmp leftright
	down:
		ror
		bcs leftright
		SprMoveDown(1)
	leftright:
		lda $dc00
		ror
		ror
		ror
		bcs right
		SprMoveLeft(2)
		jmp fire
	right:
		ror
		bcs fire
		SprMoveRight(1)
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
		rts
}

PlyTeleportDown:
{
		rts
}

PlyAppear:
{
		rts
}

PlyDead:
{
		SprMoveLeft(1)
		SprLDA(SPR_Frame)
		bne no_blow
		SprMoveLeft(1)

	no_blow:
		SprLDA(SPR_CharBelow)
		and #CHAR_COLLISION_MASK
		bne falling

		SnapToFloor()
		rts

	falling:
		SprMoveDown(1)
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
		SprSetAnimation(_sprAnimDracAppear, 0)
		SprSetHandler(SPR_Player,PlySpawn)
		rts
}

PlyEOA_ReappearUp:
{
		SprMoveUp($48)
	    SprSetFlags(SPRBIT_CheckCollision)
		SprSetAnimation(_sprAnimDracAppear, PlyEOA_StartRun)
		SprSetHandler(SPR_Player,PlyAppear)
		rts
}

PlyEOA_ReappearDown:
{
		SprMoveDown($38)
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
