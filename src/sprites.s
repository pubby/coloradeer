.include "globals.inc"

.export prepare_sprites
.export ppu_set_sprites

; This is the CPU's copy of the PPU's OAM memory.
; Write sprites to this location and copy them over to the PPU using OAMDMA.
; Note that the configuration file passed to CA65 (nrom128.cfg) reserves
; this space for us so we don't have to use .res or anything like that.
CPU_OAM = $0200

SPR_NT = 1

.define PATTERN(i) ((i) * 2 + SPR_NT)

; This clears all of the sprites in CPU_OAM. Does not write to PPU.
; Clobbers A, X. Preserves Y.
.proc prepare_blank_sprites
    ldx #0
    jsr clear_remaining_cpu_oam
    rts
.endproc

; This writes sprite data to CPU_OAM. Does not write to PPU.
; Clobbers A, X, Y.
.proc prepare_sprites
    ldx #4
    jsr prepare_cursor_sprite
    jsr clear_remaining_cpu_oam
    jsr prepare_sprite0
    rts
.endproc

; Clears CPU_OAM (hides sprites) from X to $FF.
; Clobbers A, X. Preserves Y.
.proc clear_remaining_cpu_oam
    lda #$FF
clearOAMLoop:
    sta CPU_OAM,x
    axs #.lobyte(-4)
    bne clearOAMLoop    ; OAM is 256 bytes. Overflow signifies completion.
    rts
.endproc

; Copies CPU_OAM from main RAM to the PPU.
; Clobbers A. Preserves X, Y.
.proc ppu_set_sprites
    lda #0               ; Write a 0 as the offset into the OAM array.
    sta OAMADDR          ; (Meaning sprite 0 is at CPU_OAM+0)
    lda #.hibyte(CPU_OAM); Start the copy by writing the hibyte of CPU_OAM to
    sta OAMDMA           ; OAMDMA. (The lo-byte is implied to be $00.)
    rts
.endproc

; This subroutine is unlike the other prepare sprite subroutines,
; as it does not make use of the X register.
; Clobbers A. Preserves X, Y.
.proc prepare_sprite0
    ; Set sprite0 now to guarantee that it's uploaded.
    lda #118
    sta CPU_OAM         ; y-position
    lda #PATTERN(0)
    sta CPU_OAM+1       ; Pattern
    ;lda #%00100000
    lda #%00000000
    sta CPU_OAM+2       ; Attribute
    lda #234
    sta CPU_OAM+3       ; x-position
    rts
.endproc

.proc prepare_cursor_sprite
    ; Set sprite0 now to guarantee that it's uploaded.
    lda cursor_y
    sta CPU_OAM, x
    lda #PATTERN(0)
    sta CPU_OAM+1, x
    lda #%00000000
    sta CPU_OAM+2, x    ; Attribute
    lda cursor_x
    sta CPU_OAM+3, x
    .repeat 4
        inx
    .endrepeat
    rts
.endproc

