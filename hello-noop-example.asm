;----------------------------------------------------------------
; Class Metadata
;----------------------------------------------------------------
  Hello.class = 0
  PPU.class = 1
  PPUControl.class = 2
  PPUMask.class = 3
  
  ;Hello field offset
  Hello.ppuctrl = 1
  Hello.ppumask = 2

  ; PPUControl field offset
  PPUControl.nameTableAddress = 1
  PPUControl.vramIncrement = 2
  PPUControl.sprite8x8PatternTable = 3
  PPUControl.backgroundPatternTable = 4
  PPUControl.spriteSize = 5
  PPUControl.mode = 6
  PPUControl.enableNMI = 7
  
  ; PPUMask field offset
  PPUMask.greyscale = 1
  PPUMask.showBackgroundPixelsOnLeftSide = 2
  PPUMask.showSpritesPixelsOnLeftSide = 3
  PPUMask.showBackground = 4
  PPUMask.showSprites = 5
  PPUMask.emphasizeRed = 6
  PPUMask.emphasizeGreen = 7
  PPUMask.emphasizeBlue = 8

;----------------------------------------------------------------
; Constants
;----------------------------------------------------------------
  Hello._header.mapper = 0
  Hello._header.mirroring = %0001
  Hello._header.prgRomPages = 2
  Hello._header.chrRomPages = 1
  Hello._midScreenH = 14
  Hello._midScreenV = 14
  PPUControl._nameTableDefault = %00000000
  PPUControl._nameTableTopRight = %00000001
  PPUControl._nameTableBottomLeft = %00000010
  PPUControl._nameTableBottomRight = %00000011
  PPU._screenWidthTiles = 32
  PPU._screenHeightTiles = 30

;----------------------------------------------------------------
; Singletons
;----------------------------------------------------------------
  _hello = $0400 ; sizeof = 3
  _ppu = $0403

;----------------------------------------------------------------
; Variables
;----------------------------------------------------------------
  PPUControl.PPUControl.receiver = $0000
  PPUMask.PPUMask.receiver = $0000
  PPUControl.toByte.receiver = $0000
  PPUMask.toByte.receiver = $0000
  PPU.loadBgPalettes.palletes = $0000
  PPU.loadSpritesPalettes.palletes = $0000
  PPU.setBgNameTable.nameTable = $0000

  Hello.main.tmpPPUControl0 = $0404
  Hello.main.tmpPPUMask0 = $0404
  Hello.main.tmpByte0 = $0404 ; 11 bytes
  Hello.clearScreen.for0.row = $0404
  Hello.clearScreen.for1.col = $0405
  
  PPU.setPPUControl.ppuctrl = $0404
  PPU.setPPUMask.ppumask = $0404
  PPU.setScrolling.x = $0404
  PPU.setScrolling.y = $0405

  PPU.setBgNameTable.index = $040F ; comes with Hello.main.tmpByte0
  PPU.setBgNameTable.row = $0410
  PPU.setBgNameTable.col = $0411
  PPU.setBgNameTable.nameTable.len0 = $0412
  PPU.setBgNameTable.nameTable.len1 = $0413
  PPU.setBgNameTable.addr = $0414 ; 2 bytes
  PPU.setBgNameTable.i = $0416
  PPU.setBgNameTable.j = $0417
  
  PPU.setBgNameTableTile.index = $0406 ; comes with Hello.clearScreen.for1.col
  PPU.setBgNameTableTile.row = $0407
  PPU.setBgNameTableTile.col = $0408
  PPU.setBgNameTableTile.tile = $0409
  PPU.setBgNameTableTile.i = $040A ; 2 bytes

  PPUControl.toByte.tmpByte0 = $040C ; comes with Hello.main.tmpPPUControl0
  PPUControl.toByte.return = $040D

  PPUMask.toByte.tmpByte0 = $040D ; ; comes with Hello.main.tmpPPUMask0
  PPUMask.toByte.return = $040E

;----------------------------------------------------------------
; iNES Header
;----------------------------------------------------------------
  .db "NES", $1A ;identification of the iNES header
  .db Hello._header.prgRomPages ;number of 16KB PRG-ROM pages
  .db Hello._header.chrRomPages ;number of 8KB CHR-ROM pages
  .db Hello._header.mapper | Hello._header.mirroring ;mapper 0 and mirroring
  .dsb 9, $00 ;clear the remaining bytes

;----------------------------------------------------------------
; PRG-ROM Bank(s)
;----------------------------------------------------------------
  .base $10000 - (Hello._header.prgRomPages * $4000) 

Hello._palettes:
  .db $1D, $30, $30, $30, $1D, $30, $30, $30, $1D, $30, $30, $30, $1D, $30, $30, $30

chars: ; debugging purpose
  .db '0','1','2','3','4','5','6','7','8','9' ;00-09
  .db 'A','1','2','3','4','5','6','7','8','9' ;10-19
  .db 'A','1','2','3','4','5','6','7','8','9' ;20-29
  .db 'A','1','2','3','4','5','6','7','8','9'
  .db 'A','1','2','3','4','5','6','7','8','9'
  .db 'A','1','2','3','4','5','6','7','8','9'
  .db 'A','1','2','3','4','5','6','7','8','9'
  .db 'A','1','2','3','4','5','6','7','8','9'
  .db 'A','1','2','3','4','5','6','7','8','9'
  .db 'A','1','2','3','4','5','6','7','8','9'
  .db 'A','1','2','3','4','5','6','7','8','9'
  .db 'A','1','2','3','4','5','6','7','8','9'
  .db 'A','1','2','3','4','5','6','7','8','9'
  .db 'A','1','2','3','4','5','6','7','8','9'
  .db 'A','1','2','3','4','5','6','7','8','9' ;140-149

;;;;;;;;;; Methods

PPU.waitVBlank:
  BIT $2002
  BPL PPU.waitVBlank
  RTS

PPUControl.toByte:
  LDY #PPUControl.nameTableAddress
  LDA (PPUControl.toByte.receiver), Y
  STA PPUControl.toByte.return

  LDY #PPUControl.vramIncrement
  LDA (PPUControl.toByte.receiver), Y
  STA PPUControl.toByte.tmpByte0
  LDA PPUControl.toByte.return
  ORA PPUControl.toByte.tmpByte0
  STA PPUControl.toByte.return

  LDY #PPUControl.sprite8x8PatternTable
  LDA (PPUControl.toByte.receiver), Y
  STA PPUControl.toByte.tmpByte0
  LDA PPUControl.toByte.return
  ORA PPUControl.toByte.tmpByte0
  STA PPUControl.toByte.return

  LDY #PPUControl.backgroundPatternTable
  LDA (PPUControl.toByte.receiver), Y
  STA PPUControl.toByte.tmpByte0
  LDA PPUControl.toByte.return
  ORA PPUControl.toByte.tmpByte0
  STA PPUControl.toByte.return

  LDY #PPUControl.spriteSize
  LDA (PPUControl.toByte.receiver), Y
  STA PPUControl.toByte.tmpByte0
  LDA PPUControl.toByte.return
  ORA PPUControl.toByte.tmpByte0
  STA PPUControl.toByte.return

  LDY #PPUControl.mode
  LDA (PPUControl.toByte.receiver), Y
  STA PPUControl.toByte.tmpByte0
  LDA PPUControl.toByte.return
  ORA PPUControl.toByte.tmpByte0
  STA PPUControl.toByte.return

  LDY #PPUControl.enableNMI
  LDA (PPUControl.toByte.receiver), Y
  STA PPUControl.toByte.tmpByte0
  LDA PPUControl.toByte.return
  ORA PPUControl.toByte.tmpByte0
  STA PPUControl.toByte.return
  RTS

PPUMask.toByte:
  LDY #PPUMask.greyscale
  LDA (PPUMask.toByte.receiver), Y
  STA PPUMask.toByte.return

  LDY #PPUMask.showBackgroundPixelsOnLeftSide
  LDA (PPUMask.toByte.receiver), Y
  STA PPUMask.toByte.tmpByte0
  LDA PPUMask.toByte.return
  ORA PPUMask.toByte.tmpByte0
  STA PPUMask.toByte.return

  LDY #PPUMask.showSpritesPixelsOnLeftSide
  LDA (PPUMask.toByte.receiver), Y
  STA PPUMask.toByte.tmpByte0
  LDA PPUMask.toByte.return
  ORA PPUMask.toByte.tmpByte0
  STA PPUMask.toByte.return

  LDY #PPUMask.showBackground
  LDA (PPUMask.toByte.receiver), Y
  STA PPUMask.toByte.tmpByte0
  LDA PPUMask.toByte.return
  ORA PPUMask.toByte.tmpByte0
  STA PPUMask.toByte.return

  LDY #PPUMask.showSprites
  LDA (PPUMask.toByte.receiver), Y
  STA PPUMask.toByte.tmpByte0
  LDA PPUMask.toByte.return
  ORA PPUMask.toByte.tmpByte0
  STA PPUMask.toByte.return

  LDY #PPUMask.emphasizeRed
  LDA (PPUMask.toByte.receiver), Y
  STA PPUMask.toByte.tmpByte0
  LDA PPUMask.toByte.return
  ORA PPUMask.toByte.tmpByte0
  STA PPUMask.toByte.return

  LDY #PPUMask.emphasizeGreen
  LDA (PPUMask.toByte.receiver), Y
  STA PPUMask.toByte.tmpByte0
  LDA PPUMask.toByte.return
  ORA PPUMask.toByte.tmpByte0
  STA PPUMask.toByte.return

  LDY #PPUMask.emphasizeBlue
  LDA (PPUMask.toByte.receiver), Y
  STA PPUMask.toByte.tmpByte0
  LDA PPUMask.toByte.return
  ORA PPUMask.toByte.tmpByte0
  STA PPUMask.toByte.return
  RTS

Hello.loadPalettes:
  LDA #<Hello._palettes
  STA PPU.loadBgPalettes.palletes+0
  LDA #>Hello._palettes
  STA PPU.loadBgPalettes.palletes+1
  JSR PPU.loadBgPalettes

  LDA #<Hello._palettes
  STA PPU.loadSpritesPalettes.palletes+0
  LDA #>Hello._palettes
  STA PPU.loadSpritesPalettes.palletes+1
  JMP PPU.loadSpritesPalettes

PPU.loadBgPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address

  LDY #$00              ; byte count starts at 0
-loop:
  LDA (PPU.loadBgPalettes.palletes), Y 
  STA $2007             ; write to PPU
  INY
  CPY #$10    
  BNE -loop:
  RTS

PPU.loadSpritesPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$10
  STA $2006             ; write the low byte of $3F00 address

  LDY #$00              ; byte count starts at 0
-loop:
  LDA (PPU.loadSpritesPalettes.palletes), Y 
  STA $2007             ; write to PPU
  INY
  CPY #$10    
  BNE -loop:
  RTS

Hello.clearScreen:
+for0assign:
  LDX #$00
  STX Hello.clearScreen.for0.row
-for0compare:
  CPX #PPU._screenHeightTiles
  BEQ +for0end:
+for0block:

+for1assign:
  LDX #$00
  STX Hello.clearScreen.for1.col
-for1compare:
  CPX #PPU._screenWidthTiles
  BEQ +for1end:
+for1block:
  LDA #PPUControl._nameTableDefault
  STA PPU.setBgNameTableTile.index
  LDA Hello.clearScreen.for0.row
  STA PPU.setBgNameTableTile.row
  LDA Hello.clearScreen.for1.col
  STA PPU.setBgNameTableTile.col
  LDA #$00
  STA PPU.setBgNameTableTile.tile
  JSR PPU.setBgNameTableTile
+for1increment:
  INC Hello.clearScreen.for1.col
  LDX Hello.clearScreen.for1.col
  JMP -for1compare:
+for1end:
  
+for0increment:
  INC Hello.clearScreen.for0.row
  LDX Hello.clearScreen.for0.row
  JMP -for0compare:
+for0end:
  RTS

PPU.setBgNameTableTile:
  ; i = row * 32
  LDA PPU.setBgNameTableTile.row
  STA PPU.setBgNameTableTile.i+0
  LDA #$00
  STA PPU.setBgNameTableTile.i+1
  CLC
  ASL PPU.setBgNameTableTile.i+0
  ROL PPU.setBgNameTableTile.i+1
  ASL PPU.setBgNameTableTile.i+0
  ROL PPU.setBgNameTableTile.i+1
  ASL PPU.setBgNameTableTile.i+0
  ROL PPU.setBgNameTableTile.i+1
  ASL PPU.setBgNameTableTile.i+0
  ROL PPU.setBgNameTableTile.i+1
  ASL PPU.setBgNameTableTile.i+0
  ROL PPU.setBgNameTableTile.i+1
  ; i += col
  CLC
  LDA PPU.setBgNameTableTile.i+0
  ADC PPU.setBgNameTableTile.col
  STA PPU.setBgNameTableTile.i+0
  BCC +end:
  LDA PPU.setBgNameTableTile.i+1
  ADC #$00
  STA PPU.setBgNameTableTile.i+1
+end:

  LDA $2002

+if0:
  LDX PPU.setBgNameTableTile.index
  CPX #PPUControl._nameTableDefault
  BNE +elseif0:
  LDA #$20
  JMP +endif0:
+elseif0:
  CPX #PPUControl._nameTableTopRight
  BNE +elseif1:
  LDA #$24
  JMP +endif0:
+elseif1:
  CPX #PPUControl._nameTableBottomLeft
  BNE +else0:
  LDA #$28
  JMP +endif0:
+else0:
  LDA #$2C
+endif0:

  CLC
  ADC PPU.setBgNameTableTile.i+1
  STA $2006
  LDA PPU.setBgNameTableTile.i+0
  STA $2006
  LDA PPU.setBgNameTableTile.tile
  STA $2007
  RTS

PPU.setBgNameTable:
  ; addr = row * 32
  LDA PPU.setBgNameTable.row
  STA PPU.setBgNameTable.addr+0
  LDA #$00
  STA PPU.setBgNameTable.addr+1
  CLC
  ASL PPU.setBgNameTable.addr+0
  ROL PPU.setBgNameTable.addr+1
  ASL PPU.setBgNameTable.addr+0
  ROL PPU.setBgNameTable.addr+1
  ASL PPU.setBgNameTable.addr+0
  ROL PPU.setBgNameTable.addr+1
  ASL PPU.setBgNameTable.addr+0
  ROL PPU.setBgNameTable.addr+1
  ASL PPU.setBgNameTable.addr+0
  ROL PPU.setBgNameTable.addr+1
  ; addr += col
  CLC
  LDA PPU.setBgNameTable.addr+0
  ADC PPU.setBgNameTable.col
  STA PPU.setBgNameTable.addr+0
  LDA PPU.setBgNameTable.addr+1
  ADC #$00
  STA PPU.setBgNameTable.addr+1

+if0:
  LDX PPU.setBgNameTable.index
  CPX #PPUControl._nameTableDefault
  BNE +elseif0:
  CLC
  ADC #$20
  JMP +endif0:
+elseif0:
  CPX #PPUControl._nameTableTopRight
  BNE +elseif1:
  CLC
  ADC #$24
  JMP +endif0:
+elseif1:
  CPX #PPUControl._nameTableBottomLeft
  BNE +else0:
  CLC
  ADC #$28
  JMP +endif0:
+else0:
  CLC
  ADC #$2C
+endif0:

  STA PPU.setBgNameTable.addr+1
  LDA $2002

+for0assign:
  LDX #$00
  STX PPU.setBgNameTable.i
-for0compare:
  CPX PPU.setBgNameTable.nameTable.len0
  BEQ +for0end:
+for0block:
  LDA PPU.setBgNameTable.addr+1
  STA $2006
  LDA PPU.setBgNameTable.addr+0
  STA $2006
+for1assign:
  LDX #$00
  STX PPU.setBgNameTable.j
-for1compare:
  CPX PPU.setBgNameTable.nameTable.len1
  BEQ +for1end:
+for1block:
  LDY PPU.setBgNameTable.j
  LDA (PPU.setBgNameTable.nameTable), Y
  STA $2007
+for1increment:
  INC PPU.setBgNameTable.j
  LDX PPU.setBgNameTable.j
  JMP -for1compare:
+for1end:

+for0increment:
  CLC
  LDA PPU.setBgNameTable.nameTable+0
  ADC PPU.setBgNameTable.nameTable.len1
  STA PPU.setBgNameTable.nameTable+0
  BCC ++for0increment:
  LDA PPU.setBgNameTable.nameTable+1
  ADC #$00
  STA PPU.setBgNameTable.nameTable+1
++for0increment:
  CLC
  LDA PPU.setBgNameTable.addr+0
  ADC #PPU._screenWidthTiles
  STA PPU.setBgNameTable.addr+0
  BCC +++for0increment:
  LDA PPU.setBgNameTable.addr+1
  ADC #$00
  STA PPU.setBgNameTable.addr+1
+++for0increment:
  INC PPU.setBgNameTable.i
  LDX PPU.setBgNameTable.i
  JMP -for0compare:
+for0end:
  RTS

PPU.setPPUControl:
  LDA PPU.setPPUControl.ppuctrl
  STA $2000
  RTS

PPU.setPPUMask:
  LDA PPU.setPPUMask.ppumask
  STA $2001
  RTS

PPU.setScrolling:
  LDA #$00
  STA $2006
  STA $2006
  LDA PPU.setScrolling.x
  STA $2005
  LDA PPU.setScrolling.y
  STA $2005
  RTS

Hello.refreshPPU:
  LDX #Hello.ppuctrl
  LDA _hello, X
  STA PPU.setPPUControl.ppuctrl
  JSR PPU.setPPUControl

  LDX #Hello.ppumask
  LDA _hello, X
  STA PPU.setPPUMask.ppumask
  JSR PPU.setPPUMask

  LDA #$00
  STA PPU.setScrolling.x
  STA PPU.setScrolling.y
  JMP PPU.setScrolling

PPU.PPU:
  LDA #PPU.class
  STA _ppu
  RTS

PPUControl.PPUControl:
  LDA #PPUControl.class
  STA (PPUControl.PPUControl.receiver)
  LDA #$00
  LDY #PPUControl.nameTableAddress
  STA (PPUControl.PPUControl.receiver), Y
  LDA #$00
  LDY #PPUControl.vramIncrement
  STA (PPUControl.PPUControl.receiver), Y
  LDA #$00
  LDY #PPUControl.sprite8x8PatternTable
  STA (PPUControl.PPUControl.receiver), Y
  LDA #%00010000
  LDY #PPUControl.backgroundPatternTable
  STA (PPUControl.PPUControl.receiver), Y
  LDA #$00
  LDY #PPUControl.spriteSize
  STA (PPUControl.PPUControl.receiver), Y
  LDA #$00
  LDY #PPUControl.mode
  STA (PPUControl.PPUControl.receiver), Y
  LDA #%10000000
  LDY #PPUControl.enableNMI
  STA (PPUControl.PPUControl.receiver), Y
  RTS

PPUMask.PPUMask:
  LDA #PPUMask.class
  STA (PPUMask.PPUMask.receiver)
  LDA #%00000000 ;greyscale = false
  LDY #PPUMask.greyscale
  STA (PPUMask.PPUMask.receiver), Y
  LDA #%00000010 ;showBackgroundPixelsOnLeftSide = true
  LDY #PPUMask.showBackgroundPixelsOnLeftSide
  STA (PPUMask.PPUMask.receiver), Y
  LDA #%00000100 ;showSpritesPixelsOnLeftSide = true
  LDY #PPUMask.showSpritesPixelsOnLeftSide
  STA (PPUMask.PPUMask.receiver), Y
  LDA #%00001000 ;showBackground = true
  LDY #PPUMask.showBackground
  STA (PPUMask.PPUMask.receiver), Y
  LDA #%00010000 ;showSprites = true
  LDY #PPUMask.showSprites
  STA (PPUMask.PPUMask.receiver), Y
  LDA #%00000000 ;emphasizeRed = false
  LDY #PPUMask.emphasizeRed
  STA (PPUMask.PPUMask.receiver), Y
  LDA #%00000000 ;emphasizeGreen = false
  LDY #PPUMask.emphasizeGreen
  STA (PPUMask.PPUMask.receiver), Y
  LDA #%00000000 ;emphasizeBlue = false
  LDY #PPUMask.emphasizeBlue
  STA (PPUMask.PPUMask.receiver), Y
  RTS

Hello.Hello:
  LDA #Hello.class
  STA _hello
  ; code for "ppuctrl : PPUControl{}.toByte"
  ; 1) instantiate PPUControl
  LDA #<Hello.main.tmpPPUControl0
  STA PPUControl.PPUControl.receiver+0
  LDA #>Hello.main.tmpPPUControl0
  STA PPUControl.PPUControl.receiver+1 
  JSR PPUControl.PPUControl
  ; 2) call toByte()
  LDA #<Hello.main.tmpPPUControl0
  STA PPUControl.toByte.receiver+0
  LDA #>Hello.main.tmpPPUControl0
  STA PPUControl.toByte.receiver+1
  JSR PPUControl.toByte
  ; 3) assign the return vale to ppuctrl
  LDA PPUControl.toByte.return
  LDX #Hello.ppuctrl
  STA _hello, X

  ; code for "ppumask : PPUMask{}.toByte"
  ; 1) instantiate PPUMask
  LDA #<Hello.main.tmpPPUMask0
  STA PPUMask.PPUMask.receiver+0
  LDA #>Hello.main.tmpPPUMask0
  STA PPUMask.PPUMask.receiver+1
  JSR PPUMask.PPUMask
  ; 2) call toByte()
  LDA #<Hello.main.tmpPPUMask0
  STA PPUMask.toByte.receiver+0
  LDA #>Hello.main.tmpPPUMask0
  STA PPUMask.toByte.receiver+1
  JSR PPUMask.toByte
  ; 3) assign the return vale to ppumask
  LDA PPUMask.toByte.return
  LDX #Hello.ppumask
  STA _hello, X

  ;code for "#ppu : PPU{}"
  JSR PPU.PPU ; no receiver cause its singleton
  RTS

Hello.main:
  ;;;;;;;;;; Initial setup start
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs
 
  JSR PPU.waitVBlank    ; First wait for vblank to make sure PPU is ready

-clrMem:
  LDA #$00
  STA $0000, X
  STA $0100, X
  STA $0300, X
  STA $0400, X
  STA $0500, X
  STA $0600, X
  STA $0700, X
  LDA #$FE
  STA $0200, X
  INX
  BNE -clrMem:

  JSR Hello.Hello

  JSR PPU.waitVBlank      ; Second wait for vblank, PPU is ready after this
  ;;;;;;;;;; Initial setup Finish
  ;;;;;;;;;; Effective code start

  JSR Hello.loadPalettes
  JSR Hello.clearScreen

  LDA #$48 ;H
  STA Hello.main.tmpByte0+0
  LDA #$65 ;e
  STA Hello.main.tmpByte0+1
  LDA #$6C ;l
  STA Hello.main.tmpByte0+2
  LDA #$6C ;l
  STA Hello.main.tmpByte0+3
  LDA #$6F ;o
  STA Hello.main.tmpByte0+4
  
  LDA #$4E ;N
  STA Hello.main.tmpByte0+5
  LDA #$4F ;O
  STA Hello.main.tmpByte0+6
  LDA #$4F ;O
  STA Hello.main.tmpByte0+7
  LDA #$50 ;P
  STA Hello.main.tmpByte0+8
  LDA #$21 ;!
  STA Hello.main.tmpByte0+9

  LDA #PPUControl._nameTableDefault
  STA PPU.setBgNameTable.index
  LDA #Hello._midScreenV
  STA PPU.setBgNameTable.row
  LDA #Hello._midScreenH
  STA PPU.setBgNameTable.col
  LDA #<Hello.main.tmpByte0
  STA PPU.setBgNameTable.nameTable+0
  LDA #>Hello.main.tmpByte0
  STA PPU.setBgNameTable.nameTable+1
  LDA #$02
  STA PPU.setBgNameTable.nameTable.len0
  LDA #$05
  STA PPU.setBgNameTable.nameTable.len1

  JSR PPU.setBgNameTable
  JSR PPU.waitVBlank
  JSR Hello.refreshPPU
  JMP Hello.gameLoop

Hello.gameLoop:
-forever0:
  JMP -forever0:

Hello.nmi:
  ;;;;;;;;;; NMI native process Start
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer
  ;;;;;;;;;; NMI native process End
  ;;;;;;;;;; NMI Effective code Start
  JSR Hello.loadPalettes
  JSR Hello.refreshPPU
  ;;;;;;;;;; NMI Effective code End
  ;;;;;;;;;; NMI native process Start
  PLA
  TAY
  PLA
  TAX
  PLA
  ;;;;;;;;;; NMI native process End
  RTI

Hello.irq:
   RTI

;----------------------------------------------------------------
; Interrupt vectors
;----------------------------------------------------------------
  .org $FFFA     

  .dw Hello.nmi
  .dw Hello.main 
  .dw Hello.irq        

;----------------------------------------------------------------
; CHR-ROM bank(s)
;----------------------------------------------------------------
   .base $0000

Hello._tileSet1:
   .incbin "graphics.nes"
Hello._tileSet2:
   .incbin "graphics.nes"