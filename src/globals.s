.include "globals.inc"

.export bankswitch_y

.segment "ZEROPAGE"

nmi_counter:            .res 1

ticker: .res 1

; Mapper and bankswitching
current_bank:           .res 1

; Controller
buttons_pressed:        .res 1
buttons_held:           .res 1

tile_x:                 .res 1
tile_y:                 .res 1
chr_addr:               .res 2
chr_buf:                .res 16

cursor_x:               .res 1
cursor_y:               .res 1
cursor_color:           .res 1

.segment "BSS" ; RAM
.align 256
colors: .res 1024

.segment "RODATA"
banktable:
.byte $00, $01, $02, $03, $04, $05, $06

.segment "CODE"
.proc bankswitch_y
    ; Store the current bank so the NMI handler can restore it.
    sty current_bank    
nosave:
    lda banktable, y      ; Read a byte from the banktable
    sta banktable, y      ; and write it back, switching banks.
    rts
.endproc
