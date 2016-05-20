.import nmi_handler, reset_handler, irq_handler

.segment "INESHDR"
    .byt "NES", $1A
    .byt 8         ;UNROM has eight 16k banks.
    .byt 0         ;No CHR ROM.
    .byt $20, $08  ;Mapper 2, horizontal mirroring, NES 2.0
    .byt $00       ;No submapper.
    .byt $00       ;PRG ROM not 4 MiB or larger.
    .byt $00       ;No PRG RAM.
    .byt $07       ;8192 (64 * 2^7) bytes CHR RAM, no battery.
    .byt $00       ;NTSC; use $01 for PAL.
    .byt $00       ;No special PPU.

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

