.include "globals.inc"

.export ppu_set_palette

.segment "RODATA"
palette:
    ;.byt $0F,$0B,$00,$10, $0F,$11,$29,$20, $0F,$16,$27,$38, $0F,$0F,$08,$00
    .byt $0F,$0B,$00,$10, $0F,$11,$29,$20, $0F,$16,$27,$38, $0F,$08,$00,$27
    .byt $0F,$07,$29,$37, $0F,$27,$14,$34, $0F,$01,$2C,$30, $0F,$0F,$12,$22

.segment "CODE"
; Clobbers A, X. Preserves Y.
.proc ppu_set_palette
    ppu_palette_address = $3F00
    lda #.hibyte(ppu_palette_address)
    sta PPUADDR
    lda #.lobyte(ppu_palette_address)
    sta PPUADDR
    ldx #0
copyPaletteLoop:
    lda palette,x
    sta PPUDATA
    inx
    cpx #32
    bne copyPaletteLoop
    rts
.endproc

