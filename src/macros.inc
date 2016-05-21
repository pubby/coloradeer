.ifndef MACROS_INC
.define MACROS_INC

.macro repeatbind name, p0, p1, p2, p3 , p4, p5, p6, p7
    .repeat (.paramcount - 1), i
        .scope 
        .if i = 0
            name = p0
        .elseif i = 1
            name = p1
        .elseif i = 2
            name = p2
        .elseif i = 3
            name = p3
        .elseif i = 4
            name = p4
        .elseif i = 5
            name = p5
        .elseif i = 6
            name = p6
        .elseif i = 7
            name = p7
        .else
            .error "too many resetbind params"
        .endif
.endmacro

; into = a + b + carry bit
; Sets A to new value of address+1.
; Sets carry bit on overflow.
; Both values should be 16-bit. Address should be little-endian.
.macro add16into value1, value2, into
    .if (.match (.mid (0, 1, {value2}), #))
        ; += immediate
        lda value1+0
        adc #.lobyte(.right (.tcount ({value2})-1, {value2}))
        sta into+0
        lda value1+1
        adc #.hibyte(.right (.tcount ({value2})-1, {value2}))
        sta into+1
    .else
        ; += absolute or zeropage
        lda value1+0
        adc value2+0
        sta into+0
        lda value1+1
        adc value2+1
        sta into+1
    .endif
.endmacro

; a += (b + carry_bit)
.macro add16 value1, value2
    add16into value1, value2, value1
.endmacro

.macro sub16into value1, value2, into
    .if (.match (.mid (0, 1, {value2}), #))
        ; -= immediate
        lda value1+0
        sbc #.lobyte(.right (.tcount ({value2})-1, {value2}))
        sta into+0
        lda value1+1
        sbc #.hibyte(.right (.tcount ({value2})-1, {value2}))
        sta into+1
    .else
        ; -= absolute or zeropage
        lda value1+0
        sbc value2+0
        sta into+0
        lda value1+1
        sbc value2+1
        sta into+1
    .endif
.endmacro

.macro sub16 value1, value2
    sub16into value1, value2, value1
.endmacro

.macro store16into value, into
    .if (.match (.mid (0, 1, {value}), #))
        ; -= immediate
        lda #.lobyte(.right (.tcount ({value})-1, {value}))
        sta into+0
        lda #.hibyte(.right (.tcount ({value})-1, {value}))
        sta into+1
    .else
        ; -= absolute or zeropage
        lda value+0
        sta into+0
        lda value+1
        sta into+1
    .endif
.endmacro

