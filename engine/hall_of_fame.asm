AnimateHallOfFame:
	call HoFFadeOutScreenAndMusic
	call ClearScreen
	ld c, 100
	call DelayFrames
	call LoadFontTilePatterns
	call LoadTextBoxTilePatterns
	call DisableLCD
	ld hl, vBGMap0
	ld bc, $800
	ld a, " "
	call FillMemory
	call EnableLCD
	ld hl, rLCDC
	set 3, [hl]
	xor a
	ld hl, wHallOfFame
	ld bc, HOF_TEAM
	call FillMemory
	xor a
	ld [wUpdateSpritesEnabled], a
	ld [hTilesetType], a
	ld [wSpriteFlipped], a
	ld [wLetterPrintingDelayFlags], a ; no delay
	ld [wHoFMonOrPlayer], a ; mon
	inc a
	ld [H_AUTOBGTRANSFERENABLED], a
	ld hl, wNumHoFTeams
	ld a, [hl]
	inc a
	jr z, .skipInc ; don't wrap around to 0
	inc [hl]
.skipInc
	ld a, $90
	ld [hWY], a
	ld c, BANK(Music_HallOfFame)
	ld a, MUSIC_HALL_OF_FAME
	call PlayMusic
	ld hl, wPartySpecies
	ld c, $ff
.partyMonLoop
	ld a, [hli]
	cp $ff
	jr z, .doneShowingParty
	inc c
	push hl
	push bc
	ld [wHoFMonSpecies], a
	ld a, c
	ld [wHoFPartyMonIndex], a
	ld hl, wPartyMon1Level
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a, [hl]
	ld [wHoFMonLevel], a
	call HoFShowMonOrPlayer
	call HoFDisplayAndRecordMonInfo
	ld c, 80
	call DelayFrames
	coord hl, 2, 13
	ld b, 3
	ld c, 14
	call TextBoxBorder
	coord hl, 14, 15
	ld de, HallOfFameText
	call PlaceString
	ld c, 180
	call DelayFrames
	call GBFadeOutToWhite
	pop bc
	pop hl
	jr .partyMonLoop
.doneShowingParty
	ld a, c
	inc a
	ld hl, wHallOfFame
	ld bc, HOF_MON
	call AddNTimes
	ld [hl], $ff
	call SaveHallOfFameTeams
	xor a
	ld [wHoFMonSpecies], a
	inc a
	ld [wHoFMonOrPlayer], a ; player
	call HoFShowMonOrPlayer
	call HoFDisplayPlayerStats
	call HoFFadeOutScreenAndMusic
	xor a
	ld [hWY], a
	ld hl, rLCDC
	res 3, [hl]
	ret

HallOfFameText:
	db "היכל התהילה@"

HoFShowMonOrPlayer:
	call ClearScreen
	ld a, $d0
	ld [hSCY], a
	ld a, $c0
	ld [hSCX], a
	ld a, [wHoFMonSpecies]
	ld [wcf91], a
	ld [wd0b5], a
	ld [wBattleMonSpecies2], a
	ld [wWholeScreenPaletteMonSpecies], a
	ld a, [wHoFMonOrPlayer]
	and a
	jr z, .showMon
; show player
	call HoFLoadPlayerPics
	jr .next1
.showMon
	coord hl, 12, 5
	call GetMonHeader
	call LoadFrontSpriteByMonIndex
	predef LoadMonBackPic
.next1
	ld b, SET_PAL_POKEMON_WHOLE_SCREEN
	ld c, 0
	call RunPaletteCommand
	ld a, %11100100
	ld [rBGP], a
	ld c, $31 ; back pic
	call HoFLoadMonPlayerPicTileIDs
	ld d, $a0
	ld e, 4
	ld a, [wOnSGB]
	and a
	jr z, .next2
	sla e ; scroll more slowly on SGB
.next2
	call .ScrollPic ; scroll back pic left
	xor a
	ld [hSCY], a
	ld c, a ; front pic
	call HoFLoadMonPlayerPicTileIDs
	ld d, 0
	ld e, -4
; scroll front pic right

.ScrollPic
	call DelayFrame
	ld a, [hSCX]
	add e
	ld [hSCX], a
	cp d
	jr nz, .ScrollPic
	ret

HoFDisplayAndRecordMonInfo:
	ld a, [wHoFPartyMonIndex]
	ld hl, wPartyMonNicks
	call GetPartyMonName
	call HoFDisplayMonInfo
	jp HoFRecordMonInfo

HoFDisplayMonInfo:
	coord hl, 0, 2
	ld b, 9
	ld c, 10
	call TextBoxBorder
	coord hl, 9, 6
	ld de, HoFMonInfoText
	call PlaceString
	coord hl, 10, 4
	ld de, wcd6d
	call PlaceString
	ld a, [wHoFMonLevel]
	coord hl, 4, 7
	call PrintLevelCommon
	ld a, [wHoFMonSpecies]
	ld [wd0b5], a
	coord hl, 8, 9
	predef PrintMonType
	ld a, [wHoFMonSpecies]
	jp PlayCry

HoFMonInfoText:
	db   "רמה/"
	next "סוג1/"
	next "סוג2/@"

HoFLoadPlayerPics:
	ld de, RedPicFront
	ld a, BANK(RedPicFront)
	call UncompressSpriteFromDE
	ld hl, sSpriteBuffer1
	ld de, sSpriteBuffer0
	ld bc, $310
	call CopyData
	ld de, vFrontPic
	call InterlaceMergeSpriteBuffers
	ld de, RedPicBack
	ld a, BANK(RedPicBack)
	call UncompressSpriteFromDE
	predef ScaleSpriteByTwo
	ld de, vBackPic
	call InterlaceMergeSpriteBuffers
	ld c, $1

HoFLoadMonPlayerPicTileIDs:
; c = base tile ID
	ld b, 0
	coord hl, 12, 5
	predef_jump CopyTileIDsFromList

HoFDisplayPlayerStats:
	SetEvent EVENT_HALL_OF_FAME_DEX_RATING
	predef DisplayDexRating
	coord hl, 0, 4
	ld b, 6
	ld c, 10
	call TextBoxBorder
	coord hl, 5, 0
	ld b, 2
	ld c, 9
	call TextBoxBorder
	coord hl, 12, 2
	ld de, wPlayerName
	call PlaceString
	coord hl, 10, 6
	ld de, HoFPlayTimeText
	call PlaceString
	coord hl, 1, 7
	ld de, wPlayTimeHours
	lb bc, LEFT_ALIGN | 1, 1, 3
	call PrintNumberLTR
	ld [hl], $6d
	inc hl
	ld de, wPlayTimeMinutes
	lb bc, LEADING_ZEROES | 1, 2
	call PrintNumberLTR
	coord hl, 10, 9
	ld de, HoFMoneyText
	call PlaceString
	coord hl, 1, 10
	ld de, wPlayerMoney
	ld c, $a3
	; set 6, c
	call PrintBCDNumberInternal
	ld hl, DexSeenOwnedText
	call HoFPrintTextAndDelay
	ld hl, DexRatingText
	call HoFPrintTextAndDelay
	ld hl, wDexRatingText

HoFPrintTextAndDelay:
	call PrintText
	ld c, 120
	jp DelayFrames

HoFPlayTimeText:
	db "זמן@"

HoFMoneyText:
	db "כסף@"

DexSeenOwnedText:
	TX_FAR _DexSeenOwnedText
	db "@"

DexRatingText:
	TX_FAR _DexRatingText
	db "@"

HoFRecordMonInfo:
	ld hl, wHallOfFame
	ld bc, HOF_MON
	ld a, [wHoFPartyMonIndex]
	call AddNTimes
	ld a, [wHoFMonSpecies]
	ld [hli], a
	ld a, [wHoFMonLevel]
	ld [hli], a
	ld e, l
	ld d, h
	ld hl, wcd6d
	ld bc, NAME_LENGTH
	jp CopyData

HoFFadeOutScreenAndMusic:
	ld a, 10
	ld [wAudioFadeOutCounterReloadValue], a
	ld [wAudioFadeOutCounter], a
	ld a, $ff
	ld [wAudioFadeOutControl], a
	jp GBFadeOutToWhite
