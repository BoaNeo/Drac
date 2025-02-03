.const CHAR_COLLISION_MASK = $f0

PlySpawn:
{
	    lda #80
	    SprSTA(SPR_X)
	    lda #80
	    SprSTA(SPR_Y)

	    SprSetFlags(SPRBIT_Ghost)

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

alive:	SprLDA(SPR_CharBelow)
		and #CHAR_COLLISION_MASK // First 16 characters are "ground"
		beq gnd

		SprSetAnimation(_sprAnimDracFalling, 0)
		SprSetHandler(SPR_Player,PlyFalling)
		rts

	gnd:
		lda $dc00
		ror
		bcs no_up
	    SprSetFlags(SPRBIT_Ghost)
		SprSetAnimation(_sprAnimDracVanish, PlyEOA_ReappearUp)
		SprSetHandler(SPR_Player,PlyTeleportUp)
		rts
	no_up:
		ror
		bcs no_down
	    SprSetFlags(SPRBIT_Ghost)
		SprSetAnimation(_sprAnimDracVanish, PlyEOA_ReappearDown)
		SprSetHandler(SPR_Player,PlyTeleportDown)
		rts
	no_down:
		ror
		bcs no_left
		SprMoveLeft(2)
		rts
	no_left:
		ror
		bcs no_right
		SprMoveRight(1)
		rts
	no_right:
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

alive:	SprLDA(SPR_CharBelow)
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
		bcs no_left
		SprMoveLeft(1)
	exit:
		rts
	no_left:
		ror
		bcs no_right
		SprMoveRight(1)
	no_right:
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
		lda $dc00
		ror
		bcs no_up
		SprMoveUp(1)
		rts
	no_up:
		ror
		bcs no_down
		SprMoveDown(1)
		rts
	no_down:
		ror
		bcs no_left
		SprMoveLeft(2)
		rts
	no_left:
		ror
		bcs no_right
		SprMoveRight(1)
		rts
	no_right:
		ror
		bcs no_fire
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
	    SprClearFlags(SPRBIT_Ghost)
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
		SprClearFlags(SPRBIT_Ghost)
		SprSetAnimation(_sprAnimDracAppear, PlyEOA_StartRun)
		SprSetHandler(SPR_Player,PlyAppear)
		rts
}

PlyEOA_ReappearDown:
{
		SprMoveDown($38)
		SprClearFlags(SPRBIT_Ghost)
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
