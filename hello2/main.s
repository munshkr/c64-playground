; load PRG at $0801 to load "autostart routine"
.byte $01, $08
* = $0801

; BASIC autostart routine (aka "10 SYS 4096")
.byte $0c, $08, $0a, $00, $9e, $20
.byte $34, $39, $31, $35, $32            ; 4096 = $1000
.byte $00, $00, $00

.dsb $c000 - *  ; pad with zeroes from PC to $c000
* = $c000

main:
    sei

    jsr init_screen   ; clear the screen
    jsr init_text     ; write lines of text

    ldy #$7f          ; $7f = %01111111
    sty $dc0d         ; turn off CIAs Timer interrupts ($7f = %01111111)
    sty $dd0d
    lda $dc0d         ; by reading $dc0d and $dd0d we cancel all CIA-IRQs
    lda $dd0d         ; in queue/unprocessed.

    lda #$01          ; set Interrupt Request Mask
    sta $d01a         ; we want IRQ by Rasterbeam (%00000001)

    lda #<irq         ; point IRQ Vector to our custom irq routine
    ldx #>irq
    sta $0314         ; store in $314/$315
    stx $0315

    lda #$00          ; trigger interrupt at row zero
    sta $d012

    lda #%00000011    ; VIC bank #0 ($0000-$3f00)
    sta $dd00

    lda #%00010110    ; Screen RAM #0001 ($0400-$07FF), Char ROM #011 ($1800-$1FFF)
    sta $d018

    cli
    jmp *


init_screen:
    ldx #$00
    stx $d021     ; set background color
    stx $d020     ; set border color

clear:
    lda #$20      ; #$20 is the spacebar Screen Code
    sta $0400, x  ; fill four areas with 256 spacebar characters
    sta $0500, x
    sta $0600, x
    sta $06e8, x

    lda #$01      ; set foreground to black in Color RAM
    sta $d800, x
    sta $d900, x
    sta $da00, x
    sta $dae8, x

    inx
    bne clear
    rts


line1: .asc "             hello there!                "
line2: .asc "     a boring example of text mode       "


init_text:
    ldx #$00
loop_text:
    lda line1, x
    sta $0590, x
    lda line2, x
    sta $05e0, x

    inx
    cpx #40         ; a line of text has 40 chars
    bne loop_text
    rts

irq:
    dec $d019       ; acknowledge IRQ / clear register for next interrupt
    nop
    jmp $ea31       ; return to Kernel routine
