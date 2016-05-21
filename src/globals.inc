.ifndef GLOBAL_INC
.define GLOBAL_INC

.include "nes.inc"
.include "macros.inc"

.globalzp nmi_counter

.globalzp ticker

; Controller
.globalzp buttons_pressed
.globalzp buttons_held

.globalzp tile_x
.globalzp tile_y
.globalzp chr_addr
.globalzp chr_addr_alt
.globalzp chr_buf

.globalzp cursor_x
.globalzp cursor_y
.globalzp cursor_color

.globalzp return_addr

.globalzp fill_counter

.globalzp is_flooding

.globalzp ppu_dest_ptr_hi
.globalzp ppu_dest_ptr_lo
.globalzp dest_ptr_x

.globalzp new_tile_count

.global colors

.endif
