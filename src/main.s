.include "globals.inc"

.import bankswitch_y
.import ppu_set_palette
.import read_gamepad
.import prepare_sprites
.import ppu_set_sprites

.export main, nmi_handler, irq_handler

.segment "RODATA"
.align 256
chr1:
    .incbin "../pat1.bin"
.align 256
chr2:
    .incbin "../pat2.bin"

.align 256
pt_ptr_lo:
.repeat 256, i
    .byt .lobyte(i*16)
.endrepeat
pt_ptr_hi:
.repeat 256, i
    .byt .hibyte(i*16)
.endrepeat

.align 256
nt:
    .incbin "../nt.bin"

.align 256
nbor_r:
    .incbin "../nbor_r.bin"
.align 256
nbor_g:
    .incbin "../nbor_g.bin"
.align 256
nbor_b:
    .incbin "../nbor_b.bin"

pixel_masks:
    .byt %10000000
    .byt %01000000
    .byt %00100000
    .byt %00010000
    .byt %00001000
    .byt %00000100
    .byt %00000010
    .byt %00000001

.segment "CODE"

.proc set_chr
src = 0
    bit PPUSTATUS
    stx PPUADDR
    sty PPUADDR

    ldx #0
loop:
    ldy #0
:
    lda (src), y
    sta chr_buf, y
    iny
    cpy #16
    bne :-
    .repeat 2
        ldy #0
    :
        lda chr_buf, y
        ora chr_buf+8, y
        sta PPUDATA
        iny
        cpy #8
        bne :-
    .endrepeat

    lda src+0
    clc
    adc #16
    sta src+0
    bcc :+
    inc src+1
:

    inx
    bne loop

    rts
.endproc

.proc set_nt
    bit PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #$00
    sta PPUADDR

.repeat 4, i
    ldy #0
:
    lda nt + i*256, y
    sta PPUDATA
    iny
    bne :-
.endrepeat

    lda #$23
    sta PPUADDR
    lda #$C0
    sta PPUADDR

    lda #0
    ldx #64
:
    sta PPUDATA
    dex
    bne :-

    rts
.endproc

.proc flood_fill
nt_row_ptr = 0
ppu_dest_ptr = 2
chr_ptr = 4
chr_ptr_alt = 6
r = 8
g = 9
b = 10
color = 11
nbor_ptr = 12
neighbor_bits = 14
nbor_row_ptr = 15
check_value = 17
mask = 18
color_row_ptr = 19
empty_stack = 21
color_temp = 22
pixel_mask = 23

    lda cursor_y
    .repeat 3
        lsr
    .endrepeat
    sta tile_y
    lda cursor_x
    .repeat 3
        lsr
    .endrepeat
    sta tile_x

    ; set ptrs
    lda tile_y
    .repeat 5
        asl
    .endrepeat
    sta color_row_ptr+0
    sta nt_row_ptr+0
    lda tile_y
    .repeat 3
        lsr
    .endrepeat
    tay
    clc
    adc #.hibyte(colors)
    sta color_row_ptr+1
    tya
    clc
    adc #.hibyte(nt)
    sta nt_row_ptr+1

    ldy tile_x
    lax (nt_row_ptr), y
    lda pt_ptr_lo, x
    sta chr_ptr+0
    ora #$08
    sta chr_ptr_alt+0
    lda pt_ptr_hi, x
    ldy tile_y
    cpy #15
    bcc :+
    ora #$10
    sta ppu_dest_ptr+1
    and #%00001111
    clc
    adc #.hibyte(chr2)
    jmp @storeChrPtr
:
    adc #.hibyte(chr1)  ; Carry guaranteed to be clear.
@storeChrPtr:
    sta chr_ptr+1
    sta chr_ptr_alt+1

    lda cursor_x
    and #%00000111
    tax
    lda pixel_masks, x
    sta pixel_mask

    lda cursor_y
    and #%00000111
    tay
    lda (chr_ptr), y
    and pixel_mask
    bne pixel1Set
    ; pixel1 not set
    lda (chr_ptr_alt), y
    and pixel_mask
    bne :+
    rts ; on black
:
    ; is green
    lda #.lobyte(nbor_g)
    sta nbor_ptr+0
    lda #.hibyte(nbor_g)
    sta nbor_ptr+1
    lda #%00001100
    sta mask
    lda cursor_color
    asl
    asl
    sta check_value
    jmp doneGetPixel
pixel1Set:
    lda (chr_ptr_alt), y
    and pixel_mask
    bne :+
    ; is red
    lda #.lobyte(nbor_r)
    sta nbor_ptr+0
    lda #.hibyte(nbor_r)
    sta nbor_ptr+1
    lda #%00000011
    sta mask
    lda cursor_color
    sta check_value
    jmp doneGetPixel
:
    ; is blue
    lda #.lobyte(nbor_b)
    sta nbor_ptr+0
    lda #.hibyte(nbor_b)
    sta nbor_ptr+1
    lda #%00110000
    sta mask
    lda cursor_color
    .repeat 4
        asl
    .endrepeat
    sta check_value
doneGetPixel:

    ; update color_row
    ldy tile_x
    lda mask
    eor #$FF
    and (color_row_ptr), y
    ora check_value
    sta (color_row_ptr), y

    tsx
    stx empty_stack
    lda tile_y
    pha
    lda tile_x
    pha

pullLoop:
    tsx
    cpx empty_stack
    bne :+
    rts
:

    ; Pull the tile to update on and prepare pointers.

    pla
    sta tile_x
    pla
    sta tile_y
    .repeat 5
        asl
    .endrepeat
    sta nbor_row_ptr+0
    sta color_row_ptr+0
    sta nt_row_ptr+0
    lda tile_y
    .repeat 3
        lsr
    .endrepeat
    tax
    clc
    adc nbor_ptr+1
    sta nbor_row_ptr+1
    txa
    clc
    adc #.hibyte(colors)
    sta color_row_ptr+1
    txa
    clc
    adc #.hibyte(nt)
    sta nt_row_ptr+1

    ldy tile_x
    lda (nbor_row_ptr), y
    sta neighbor_bits

    lda (color_row_ptr), y
    sta color

    lax (nt_row_ptr), y
    lda pt_ptr_lo, x
    sta ppu_dest_ptr+0
    sta chr_ptr+0
    ora #$08
    sta chr_ptr_alt+0
    lda pt_ptr_hi, x
    sta ppu_dest_ptr+1
    ldy tile_y
    cpy #15
    bcc :+
    ora #$10
    sta ppu_dest_ptr+1
    and #%00001111
    clc
    adc #.hibyte(chr2)
    jmp @storeChrPtr
:
    adc #.hibyte(chr1)  ; Carry guaranteed to be clear.
@storeChrPtr:
    sta chr_ptr+1
    sta chr_ptr_alt+1

    ; Prepare updates to the pattern tables.

    lda #0
    ldx #0
:
    sta chr_buf, x
    inx
    cpx #16
    bne :-

    ldy #0
ptLoop:
    lda color
    sta color_temp

    lda (chr_ptr), y
    and (chr_ptr_alt), y
    sta b
    lda (chr_ptr), y ; TODO: remove
    eor #$FF
    and (chr_ptr_alt), y
    sta g
    lda (chr_ptr_alt), y
    eor #$FF
    and (chr_ptr), y
    sta r

    lsr color_temp
    bcc :+
    lda r
    ora chr_buf, y
    sta chr_buf, y
:
    lsr color_temp
    bcc :+
    lda r
    ora chr_buf+8, y
    sta chr_buf+8, y
:

    lsr color_temp
    bcc :+
    lda g
    ora chr_buf, y
    sta chr_buf, y
:
    lsr color_temp
    bcc :+
    lda g
    ora chr_buf+8, y
    sta chr_buf+8, y
:

    lsr color_temp
    bcc :+
    lda b
    ora chr_buf, y
    sta chr_buf, y
:
    lsr color_temp
    bcc :+
    lda b
    ora chr_buf+8, y
    sta chr_buf+8, y
:
    iny
    cpy #8
    bne ptLoop

    ; Write to PPU.

    bit PPUSTATUS
    bit PPUCTRL
    lda ppu_dest_ptr+1
    sta PPUADDR
    lda ppu_dest_ptr+0
    sta PPUADDR
    ldx #0
:
    lda chr_buf, x
    sta PPUDATA
    inx
    cpx #16
    bne :-

    ; Push neighbors.

    lsr neighbor_bits
    bcc noRightNeighbor
    ldy tile_x
    iny
    lda (color_row_ptr), y
    and mask
    cmp check_value
    beq noRightNeighbor
    eor (color_row_ptr), y
    ora check_value
    sta (color_row_ptr), y
    lda tile_y
    pha
    tya
    pha
noRightNeighbor:

    lsr neighbor_bits
    bcc noLeftNeighbor
    ldy tile_x
    dey
    lda (color_row_ptr), y
    and mask
    cmp check_value
    beq noLeftNeighbor
    eor (color_row_ptr), y
    ora check_value
    sta (color_row_ptr), y
    lda tile_y
    pha
    tya
    pha
noLeftNeighbor:

    lda color_row_ptr+0
    clc
    adc #32
    sta color_row_ptr+0
    bcc :+
    inc color_row_ptr+1
:
    lsr neighbor_bits
    bcc noDownNeighbor
    ldy tile_x
    lda (color_row_ptr), y
    and mask
    cmp check_value
    beq noDownNeighbor
    eor (color_row_ptr), y
    ora check_value
    sta (color_row_ptr), y
    ldx tile_y
    inx
    txa
    pha
    tya
    pha
noDownNeighbor:

    lda color_row_ptr+0
    sec
    sbc #64
    sta color_row_ptr+0
    bcs :+
    dec color_row_ptr+1
:
    lsr neighbor_bits
    bcc noUpNeighbor
    ldy tile_x
    lda (color_row_ptr), y
    and mask
    cmp check_value
    beq noUpNeighbor
    eor (color_row_ptr), y
    ora check_value
    sta (color_row_ptr), y
    ldx tile_y
    dex
    txa
    pha
    tya
    pha
noUpNeighbor:

    jmp pullLoop
.endproc

.proc move_cursor
    inc ticker

    lda buttons_held
    and #BUTTON_B
    beq :+
    lda ticker
    and #%00000011
    beq :+
    rts
:

    lda buttons_pressed
    and #BUTTON_SELECT
    beq :++
    lda cursor_color
    clc
    adc #1
    and #%00000011
    bne :+
    lda #1
:
    sta cursor_color
:

    lda buttons_held
    and #BUTTON_LEFT
    beq :+
    dec cursor_x
:

    lda buttons_held
    and #BUTTON_RIGHT
    beq :+
    inc cursor_x
:

    lda buttons_held
    and #BUTTON_UP
    beq :++
    ldx cursor_y
    bne :+
    ldx #240
:
    dex
    stx cursor_y
:

    lda buttons_held
    and #BUTTON_DOWN
    beq :++
    ldx cursor_y
    cpx #239
    bcc :+
    ldx #0
:
    inx
    stx cursor_y
:
    rts
.endproc

.proc nmi_handler
    inc nmi_counter     ; Notify the main loop that NMI occured.
    rti
.endproc

.proc irq_handler
    rti
.endproc

.macro wait_for_nmi frames_to_wait
    .local nmiLoop
    lda nmi_counter
    .if frames_to_wait > 1
        clc
        adc #frames_to_wait-1
    nmiLoop:
        cmp nmi_counter
        bne nmiLoop
    .else
    nmiLoop:
        cmp nmi_counter
        beq nmiLoop
    .endif
.endmacro

.proc main
    jsr ppu_set_palette
    lda #0
    sta PPUCTRL
    sta PPUMASK


    lda #%00111111
    ldx #0
.repeat 4, i
:
    sta colors+i*256, x
    inx
    bne :-
.endrepeat

    ;bankswitch_to bg_chr

    lda #1
    sta cursor_color
    lda #128
    sta cursor_x
    sta cursor_y

    lda #<chr1
    sta 0
    lda #>chr1
    sta 1

    ldx #0
    ldy #0
    jsr set_chr

    lda #<chr2
    sta 0
    lda #>chr2
    sta 1

    ldx #$10
    ldy #0
    jsr set_chr

    lda #9
    sta tile_x
    lda #9
    sta tile_y
    ;jsr set_foo
    lda #9
    sta tile_x
    lda #8
    sta tile_y
    ;jsr set_foo


    jsr set_nt

    jsr prepare_sprites

    lda #0
    sta PPUADDR
    sta PPUADDR

    lda #PPUCTRL_NMI_ON
    sta PPUCTRL

forever:
    jsr read_gamepad
    jsr move_cursor
    jsr prepare_sprites

    lda buttons_pressed
    and #BUTTON_A
    beq :+
    wait_for_nmi
    lda #0 
    sta PPUMASK
    jsr flood_fill
:

    wait_for_nmi

    ; Do sprite DMA.
    jsr ppu_set_sprites

    lda # PPUCTRL_8X16_SPR | PPUCTRL_NMI_ON
    sta PPUCTRL

    lda #PPUMASK_BG_ON | PPUMASK_SPR_ON | PPUMASK_NO_BG_CLIP | PPUMASK_NO_SPR_CLIP
    sta PPUMASK

    lda #0
    sta PPUSCROLL
    sta PPUSCROLL
    sta PPUADDR
    sta PPUADDR

waitForSprite0Clear:
    bit PPUSTATUS
    bvs waitForSprite0Clear

    ldx #0
    ldy #120
    tya
    and #$F8
    asl
    asl

waitForSprite0Hit:
    bit PPUSTATUS
    bvc waitForSprite0Hit

    stx PPUADDR
    sty PPUSCROLL
    stx PPUSCROLL
    sta PPUADDR

    lda # PPUCTRL_8X16_SPR | PPUCTRL_NMI_ON | PPUCTRL_BG_PT_1000
    sta PPUCTRL

    jmp forever
.endproc


