.include "globals.inc"


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
chr_addr_alt:           .res 2
chr_buf:                .res 16*4

cursor_x:               .res 1
cursor_y:               .res 1
cursor_color:           .res 1

return_addr:            .res 2

is_flooding: .res 1

fill_counter: .res 1

ppu_dest_ptr_hi: .res 4
ppu_dest_ptr_lo: .res 4
dest_ptr_x: .res 1

new_tile_count: .res 1


.segment "BSS" ; RAM
.align 256
colors: .res 1024
