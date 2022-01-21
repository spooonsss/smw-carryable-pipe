
        ; carryable pipe, by WhiteYoshiEgg
        ; based on RussianMan's key disassembly (very heavily edited)

        ; these pipes only work when there are exactly two of them in a level,
        ; and both are spawned (=the player has encountered both).
        ; you can have multiple independent pairs,
        ; determined by the extra byte (00-03).

        ; please read README.txt for more info and limitations!


        ; Stuff you can change

        !Tile = $4B
        !TeleportingSpeed = $60
        !FreezeTimeWhenTeleporting = 1          ; 0 = no, 1 = yes


        ; The below defines are used if !FreezeTimeWhenTeleporting is 1.
        ;  Due to an issue in timing, sprites may not properly freeze while using a pipe.
        ;  Setting !FixFreeze to 1 will fix this issue, in exchange for using one byte of free RAM.
        
        !FixFreeze  =   1               ; 0 = no, 1 = yes
        !FreezeRAM  =   $1FFF|!Base2    ; 1 byte of free RAM.


        ; stuff you shouldn't need to change

        !State = !1504,x
        !OtherPipeIndex = !1510,x
        !ControllerBackup = !151C,x
        !Timer = !1528,x



if !FreezeTimeWhenTeleporting && !FixFreeze
    pushpc
    org $00A2E2 : JSL RestoreFreeze
    pullpc
        
    RestoreFreeze:
        LDA !FreezeRAM
        BEQ +
        STA $9D
        LDA #$00
        STA !FreezeRAM
      + JML $01808C|!BankB
else
    pushpc
    org $00A2E2 : JSL $01808C|!BankB
    pullpc
endif


print "INIT ",pc

        LDA #$09
        STA !14C8,x

        LDA #$FF
        STA !OtherPipeIndex

        RTL





print "MAIN ",pc

        PHB : PHK : PLB : JSR SpriteCode : PLB : RTL : SpriteCode:
        
        LDA !Timer
        BEQ +
        DEC !Timer
      +
        LDA $9D
        BNE .noCarry
        JSR HandleCarryableSpriteStuff
    .noCarry
        JSR HandleState
    .return
        JSR Graphics

        RTS





; state handling

HandleState:

        LDA !State
        JSL $0086DF|!BankB
        dw .idle, .enteringPipe, .teleporting, .exitingPipe



        ; state 00: idle (carryable and solid, waiting for player to enter)

.idle

        LDA !OtherPipeIndex                     ; \
        CMP #$FF                                ;  |
        BNE ..dontLookForOtherPipe              ;  | if the other pipe hasn't been found yet,
        JSR GetOtherPipeIndex                   ;  | look for it
        TYA : STA !OtherPipeIndex               ;  |
..dontLookForOtherPipe                          ; /

        JSR HandleInteraction                   ; \
        BCC ..notOnTop                          ;  |
                                                ;  | initiate teleporting if you're standing on top of it
        LDA $15                                 ;  | and pressing DOWN
        AND #$04                                ;  |
        BNE ..beginTeleporting                  ; /
..notOnTop:
        RTS

..beginTeleporting

        JSR GetOtherPipeIndex                   ; \  check other pipe again before actually teleporting, just in case
        TYA : STA !OtherPipeIndex               ; /  (for example, yoshi may have swallowed the other end)

        ; LDA !OtherPipeIndex                   ; \
        CMP #$FF                                ;  | don't allow teleporting if the other pipe hasn't been found
        BEQ ..dontTeleport                      ; /

        LDA $1470|!Base2                        ; \
        ORA $148F|!Base2                        ;  | don't allow teleporting if you're carrying something
        BNE ..dontTeleport                      ; /

        LDA $1426|!Base2                        ; \  don't allow teleporting if a message box is active
        BNE ..dontTeleport                      ; /

        LDA $5D                                 ; \
        DEC                                     ;  |
        XBA                                     ;  | don't allow teleporting if the other pipe
        LDA #$F0                                ;  | is beyond the edges of the level
        REP #$20                                ;  |
        STA $00                                 ;  |
        SEP #$20                                ;  |
        LDA !14E0,y                             ;  |
        CMP #$FF                                ;  |
        BEQ ..dontTeleport                      ;  |
        XBA                                     ;  |
        LDA.w !E4,y                             ;  |
        REP #$20                                ;  |
        CMP $00                                 ;  |
        BCS ..dontTeleport                      ;  |
        SEP #$20                                ; /

        LDA $13F9|!Base2                        ; \  don't allow teleporting (and don't even play "wrong" sound)
        BNE .return                             ; /  if you're already teleporting (this can happen when you're standing on two at once)

..doTeleport

        LDA !E4,x                               ; \
        STA $94                                 ;  | center the player horizontally
        LDA !14E0,x                             ;  |
        STA $95                                 ; /

        LDA $0DA0|!Base2                        ; \
        STA !ControllerBackup                   ;  | disable the controller
        LDA #$01                                ;  |
        STA $0DA0|!Base2                        ; /

        JSR EraseFireballs

        ; STZ $17C0|!Base2                      ; \
        ; STZ $17C1|!Base2                      ;  | erase all smoke sprites?
        ; STZ $17C2|!Base2                      ;  | (this doesn't seem to work)
        ; STZ $17C3|!Base2                      ; /

        LDA #$04                                ; \  play pipe sound
        STA $1DF9|!Base2                        ; /

        STZ $73                                 ; \
        LDA #$02                                ;  | all kinds of teleportation settings
        STA $13F9|!Base2                        ; /

        LDY $18DF|!Base2 
        BEQ ..noYoshi
        DEY
        LDA #$00
        STA !151C,y
        STA !1594,y
        STZ $18AE|!Base2
        STZ $14A3|!Base2
        LDA !160E,y
        BEQ ..noYoshi
        TAY
        LDA #$00
        STA !15D0,y
..noYoshi

        LDA #$08
        STA !Timer
        INC !State
        RTS

..dontTeleport
        SEP #$20
        LDA $16                                 ; \
        AND #$04                                ;  | if you're not allowed to teleport,
        BEQ .return                             ;  | play "wrong" sound once
        LDA #$2A                                ;  |
        STA $1DFC|!Base2                        ; /

.return
        RTS



        ; state 01: "entering pipe" animation

.enteringPipe

        LDA !Timer
        BEQ ..nextState

        LDA $18DF|!Base2                        ; \
        BEQ ..notOnYoshi                        ;  |
..onYoshi                                       ;  | set pipe entering pose
        LDA #$02                                ;  |
        STA $1419|!Base2                        ;  |
        LDA #$21                                ;  |
        BRA +                                   ;  |
..notOnYoshi                                    ;  |
        LDA #$0F                                ;  |
+       STA $13E0|!Base2                        ; /

        LDA #$38                                ; \  move the player down the pipe
        STA $7D                                 ; /

        STZ $73                                 ; \
        STZ $7B                                 ;  |
        LDA #$01                                ;  | all kinds of teleportation settings
        STA $185C|!Base2                        ;  | (hiding the player, disabling interaction etc.)
        LDA #$02                                ;  |
        STA $13F9|!Base2                        ;  |
        if !FreezeTimeWhenTeleporting           ;  |
          LDA #$FF                              ;  |
          STA $9D                               ;  |
          if !FixFreeze                         ;  |
            STA !FreezeRAM                      ;  |
          endif                                 ;  |
        endif                                   ; /
        RTS

..nextState

        JSR EraseFireballs

        JSR SetTeleportingXSpeed
        JSR SetTeleportingYSpeed

        INC !State
        RTS



        ; state 02: teleporting (player is invisible and moving between pipes)

.teleporting

        LDA #$01                                ; \
        STA $1404|!Base2                        ;  |
        STA $1406|!Base2                        ;  | all kinds of teleportation settings
        STZ $73                                 ;  |
        LDA #$01                                ;  |
        STA $185C|!Base2                        ;  |
        LDA #$02                                ;  |
        STA $13F9|!Base2                        ;  |
        LDA #$FF                                ;  |
        STA $78                                 ;  |
        if !FreezeTimeWhenTeleporting           ;  |
          STA $9D                               ;  |
          if !FixFreeze                         ;  |
            STA !FreezeRAM                      ;  |
          endif                                 ;  |
        endif                                   ; /

        JSR SetTeleportingXSpeed                ; \  move the player to the other pipe
        JSR SetTeleportingYSpeed                ; /

        LDA $7B                                 ; \
        ORA $7D                                 ;  | if the player doesn't need to move anymore
        ORA $17BC|!Base2                        ;  | and the screen has caught up with them too,
        ORA $17BD|!Base2                        ;  | we're done teleporting
        BNE ..keepTeleporting                   ; /

..doneTeleporting

        LDA.w !E4,y                             ; \
        STA $94                                 ;  |
        LDA !14E0,y                             ;  | fix the player's position to
        STA $95                                 ;  | right beneath the other pipe
        LDA.w !D8,y                             ;  |
        STA $96                                 ;  |
        LDA !14D4,y                             ;  |
        STA $97                                 ; /

        LDA #$04                                ; \  play pipe sound
        STA $1DF9|!Base2                        ; /

        LDA #$01
        STA !Timer
        INC !State

..keepTeleporting
        RTS





        ; state 03: "exiting pipe" animation

.exitingPipe

        LDA !Timer
        BEQ ..nextState

        LDA $187A|!Base2                        ; \
        BEQ ..notOnYoshi                        ;  |
..onYoshi                                       ;  | set pipe exiting pose
        LDA #$02                                ;  |
        STA $1419|!Base2                        ;  |
        LDA #$21                                ;  |
        BRA +                                   ;  |
..notOnYoshi                                    ;  |
        LDA #$0F                                ;  |
+       STA $13E0|!Base2                        ; /

        LDA #-$38                               ; \
        STA $7D                                 ;  | move the player up the pipe
        STZ $7B                                 ; /

        STZ $73                                 ; \
        LDA #$01                                ;  |
        STA $185C|!Base2                        ;  | all kinds of teleportation settings
        LDA #$02                                ;  |
        STA $13F9|!Base2                        ;  |
        if !FreezeTimeWhenTeleporting           ;  |
          LDA #$FF                              ;  |
          STA $9D                               ;  |
          if !FixFreeze                         ;  |
            STA !FreezeRAM                      ;  |
          endif                                 ;  |
        endif                                   ;  |
        RTS                                     ; /

..nextState

        LDY !OtherPipeIndex                     ; \
        LDA.w !E4,y                             ;  |
        STA $94                                 ;  | fix the player's position to
        LDA !14E0,y                             ;  | right on top of the other pipe
        STA $95                                 ;  |
        LDA.w !D8,y                             ;  |
        SEC : SBC #$20                          ;  |
        STA $96                                 ;  |
        LDA !14D4,y                             ;  |
        SBC #$00                                ;  |
        STA $97                                 ; /

        LDA #-$18
        STA $7D
                                                ; \
        STZ $185C|!Base2                        ;  |
        STZ $13F9|!Base2                        ;  | all kinds of teleportation settings
        STZ $1419|!Base2                        ;  |
        STZ $78                                 ;  |
        ;STZ $9D                                 ; /
        STZ !State

        LDA !ControllerBackup                   ; \  re-enable the controller
        STA $0DA0|!Base2                        ; /

        RTS





; finds the other pipe
; (returns the index in Y, or #$FF if there's not exactly one other pipe active)

GetOtherPipeIndex:

        LDA !7FAB9E,x
        STA $00
        LDA !extra_byte_1,x
        STA $01
        STZ $02

        PHX                                     ; \  loop through all sprites
        LDX #!SprSize-1                         ; /
.loop
        CPX $15E9|!Base2                        ; \
        BEQ .continue                           ;  |
        LDA !14C8,x                             ;  | if it's active, it's a custom sprite,
        CMP #$08                                ;  | it's the same sprite number and of the same pair,
        BCC .continue                           ;  | and not the current sprite,
        LDA !7FAB10,x                           ;  | then that's the other pipe
        AND #$08                                ;  |
        BEQ .continue                           ;  |
        LDA !7FAB9E,x                           ;  |
        CMP $00                                 ;  |
        BNE .continue                           ;  |
        LDA !extra_byte_1,x                     ;  |
        CMP $01                                 ;  |
        BNE .continue                           ; /
.foundOtherPipeTop
        TXY
        INC $02
.continue
        DEX
        BPL .loop
.break
        PLX                                     ; \
        LDA $02                                 ;  |
        CMP #$01                                ;  | return invalid value
        BEQ .valid                              ;  | if not exactly one other pipe was found
.invalid                                        ;  |
        LDY #$FF                                ;  |
.valid                                          ;  |
        RTS                                     ; /





; determines where to move the player horizontally when teleporting

SetTeleportingXSpeed:

        LDY !OtherPipeIndex                     ; \
        LDA !14E0,y                             ;  |
        XBA                                     ;  | calculate the distance
        LDA.w !E4,y                             ;  | between the player and the other pipe
        REP #$20                                ;  |
        SEC : SBC $D1                           ;  |
        STA $00                                 ; /

        BPL + : EOR #$FFFF : INC : +            ; \
        CMP #$0010                              ;  |
        SEP #$20                                ;  | if the distance is less than a tile,
        BCS .notCloseEnough                     ;  | stop moving
.closeEnough                                    ;  | (it doesn't need to be an exact match,
        STZ $7B                                 ;  | the player's position will be set to the exact value later on)
        RTS                                     ;  |
.notCloseEnough                                 ; /

        REP #$20                                ; \
        LDA $00                                 ;  |
        SEP #$20                                ;  | otherwise, move the player left or right
        BMI .negativeSpeed                      ;  | depending on whether the distance is negative or positive
.positiveSpeed                                  ;  |
        LDA #!TeleportingSpeed                  ;  |
        BRA +                                   ;  |
.negativeSpeed                                  ;  |
        LDA #-!TeleportingSpeed                 ;  |
+       STA $7B                                 ;  |
.return                                         ;  |
        RTS                                     ; /





; determines where to move the player vertically when teleporting

SetTeleportingYSpeed:

        LDY !OtherPipeIndex                     ; see above
        LDA !14D4,y
        XBA
        LDA.w !D8,y
        REP #$20
        SEC : SBC $D3
        STA $00

        BPL + : EOR #$FFFF : INC : +
        CMP #$0010
        SEP #$20
        BCS .notCloseEnough
.closeEnough
        STZ $7D
        RTS
.notCloseEnough

        REP #$20
        LDA $00
        SEP #$20
        BMI .negativeSpeed
.positiveSpeed
        LDA #!TeleportingSpeed
        BRA +
.negativeSpeed
        LDA #-!TeleportingSpeed
+       STA $7D
.return
        RTS





; erases (player's) fireballs on screen

EraseFireballs:

        LDY #$09
.loop
        LDA !extended_num,y
        CMP #$05
        BNE .continue
        LDA #$00
        STA !extended_num,y
.continue
        DEY
        BPL .loop

        RTS




; the code below is copied from RussianMan's Key disassembly (thanks!)

HandleCarryableSpriteStuff:

        LDA !14C8,x
        CMP #$0B
        BEQ .carried
.notCarried
        JSL $019138|!BankB
.carried

        LDA !1588,x
        AND #$04
        BEQ .notOnGround

        JSR HandleLandingBounce

        LDA !1588,x
        AND #$08
        BEQ .notAgainstCeiling

.againstCeiling
        LDA #$10
        STA !AA,x
        LDA !1588,x
        AND #$03
        BEQ .notAgainstWall
        LDA !E4,x
        CLC : ADC #$08
        STA $9A
        LDA !14E0,x
        ADC #$00
        STA $9B
        LDA !D8,x
        AND #$F0
        STA $98
        LDA !14D4,x
        STA $99
        LDA !1588,x
        AND #$20
        ASL #3
        ROL
        AND #$01
        STA $1933|!Base2
        LDY #$00
        LDA $1868|!Base2
        JSL $00F160|!BankB
        LDA #$08
        STA !1FE2,x

.notAgainstCeiling
        LDA !1588,x
        AND #$03
        BEQ .notAgainstWall
        JSR HandleBlockHit
        LDA !B6,x
        ASL
        PHP
        ROR !B6,x
        ASL
        ROR !B6,x
        PLP
        ROR !B6,x

.notOnGround
.notAgainstWall

        RTS





HandleBlockHit:

        LDA #$01
        STA $1DF9|!Base2

        LDA !15A0,x
        BNE .return

        LDA !E4,x
        SEC : SBC $1A
        CLC : ADC #$14
        CMP #$1C
        BCC .return

        LDA !1588,x
        AND #$40
        ASL #2
        ROR
        AND #$01
        STA $1933|!Base2

        LDY #$00
        LDA $18A7|!Base2
        JSL $00F160|!BankB

        LDA #$05
        STA !1FE2,x

.return
        RTS





HandleLandingBounce:

        LDA !B6,x
        PHP
        BPL +
        EOR #$FF : INC
+       LSR
        PLP
        BPL +
        EOR #$FF : INC
+       STA !B6,x
        LDA !AA,x
        PHA

        LDA !1588,x
        BMI .speed2
        LDA #$00
        LDY !15B8,x
        BEQ .store
.speed2
        LDA #$18
.store
        STA !AA,x

        PLA
        LSR #2
        TAY
        LDA .bounceSpeeds,y
        LDY !1588,x
        BMI .return
        STA !AA,x

.return
        RTS

.bounceSpeeds
        db $00,$00,$00,$F8,$F8,$F8,$F8,$F8
        db $F8,$F7,$F6,$F5,$F4,$F3,$F2,$E8
        db $E8,$E8,$E8,$00,$00,$00,$00,$FE
        db $FC,$F8,$EC,$EC,$EC,$E8,$E4,$E0
        db $DC,$D8,$D4,$D0,$CC,$C8





HandleInteraction:

        LDA !154C,x
        BNE .return
        JSL $01803A|!BankB
        BCC .return

        LDA $15
        AND #$40
        BEQ .checkSprite

        LDA $1470|!Base2
        ORA $148F|!Base2
        ORA $187A|!Base2
        BNE .checkSprite

        LDA #$0B
        STA !14C8,x

.keepCarried
        INC $1470|!Base2
        LDA #$08
        STA $1498|!Base2
        CLC
        RTS

.checkSprite
        LDA !14C8,x
        CMP #$09
        BNE .return

        STZ !154C,x

        LDA !D8,x
        SEC : SBC $D3
        CLC : ADC #$08
        CMP #$20
        BCC .solidSides
        BPL .onTop

        LDA #$10
        STA $7D

        CLC
        RTS

.onTop
        LDA $7D
        BMI .return

        STZ $7D
        STZ $72
        INC $1471|!Base2

        LDA #$1F
        LDY $187A|!Base2
        BEQ .notOnYoshi
        LDA #$2F
.notOnYoshi
        STA $00

        LDA !D8,x
        SEC : SBC $00
        STA $96
        LDA !14D4,x
        SBC #$00
        STA $97

        SEC
        RTS

.return
        CLC
        RTS

.solidSides
        STZ $7B
        %SubHorzPos()
        TYA : ASL : TAY
        REP #$21
        LDA $94
        ADC .DATA_01AB2D,y
        STA $94
        SEP #$20
        CLC
        RTS

.DATA_01AB2D
        db $01,$00,$FF,$FF





; graphics routine

Graphics:

        %GetDrawInfo()

        LDA $13F9|!Base2                        ; \  if the player is inside the pipe,
        BNE .priority                           ; /  use a different graphics routine to draw the tile on top of them

.normal

        LDA $00                                 ;    otherwise, it's about the most basic graphics routine you can get
        STA $0300|!Base2,y
        LDA $01
        STA $0301|!Base2,y
        LDA #!Tile
        STA $0302|!Base2,y
        LDA !extra_byte_1,x
        PHX : TAX
        LDA .properties,x
        PLX
        STA $0303|!Base2,y

        LDY #$02
        LDA #$00
        JSL $01B7B3|!BankB

        RTS



.priority
        LDA #$F0                                ; \  carryable custom sprites draw their own tile in this slot for some reason,
        STA $0301|!Base2,y                      ; /  so we need to explicitly remove that

        LDY #$00                                ; \
..loop                                          ;  |
        LDA $0201|!Base2,y                      ;  | find a new free slot, this time in the $0200 area
        CMP #$F0                                ;  | so it has priority over the player sprite
        BEQ ..break                             ;  |
        INY #4                                  ;  |
        CPY #$FC                                ;  |
        BNE ..loop                              ;  |
        RTS                                     ;  |
..break                                         ; /

        LDA $00                                 ; \
        STA $0200|!Base2,y                      ;  |
        LDA $01                                 ;  | draw the tile there
        STA $0201|!Base2,y                      ;  |
        LDA #!Tile                              ;  |
        STA $0202|!Base2,y                      ;  |
        LDA !extra_byte_1,x                     ;  |
        PHX : TAX                               ;  |
        LDA .properties,x                       ;  |
        PLX                                     ;  |
        STA $0203|!Base2,y                      ; /

        TYA : STA !15EA,x                       ; \
        LDY #$02                                ;  | finish the OAM write with a custom routine
        LDA #$00                                ;  | that handles the $0200 area
        JSR FinishOAMWriteRt                    ; /

        RTS





.properties

        db $3B,$39,$37,$35





; a version of $01B7B3 that uses slots in the $0200 area
; (changes marked with <--)

FinishOAMWriteRt:

        STY $0B
        STA $08
        LDY !15EA,x
        LDA !D8,x
        STA $00
        SEC : SBC $1C
        STA $06
        LDA !14D4,x
        STA $01
        LDA !E4,x
        STA $02
        SEC : SBC $1A
        STA $07
        LDA !14E0,x
        STA $03

.loop
        TYA
        LSR
        LSR
        TAX
        LDA $0B
        BPL +
        LDA $0420|!Base2,x ; <---
        AND #$02
        STA $0420|!Base2,x ; <---
        BRA ++
+       STA $0420|!Base2,x ; <---
++      LDX.B #$00
        LDA $0200|!Base2,y ; <---
        SEC : SBC $07
        BPL +
        DEX
+       CLC : ADC $02
        STA $04
        TXA
        ADC $03
        STA $05

        REP #$20
        LDA $04
        SEC : SBC $1A
        CMP #$0100
        SEP #$20

        BCC +
        TYA
        LSR
        LSR
        TAX
        LDA $0420|!Base2,x ; <---
        ORA #$01
        STA $0420|!Base2,x ; <---
+       LDX.B #$00
        LDA $0201|!Base2,y ; <---
        SEC : SBC $06
        BPL +
        DEX
+       CLC : ADC $00
        STA $09
        TXA
        ADC $01
        STA $0A

        REP #$20
        LDA $09
        PHA
        CLC : ADC #$0010
        STA $09
        SEC : SBC $1C
        CMP #$0100
        PLA
        STA $09
        SEP #$20

        BCC +
        LDA #$F0
        STA $0201|!Base2,y ; <---
+       INY #4
        DEC $08
        BPL .loop

        LDX $15E9|!Base2
        RTS
