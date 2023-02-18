writepsg        macro
                ld b,&f4            ;} setup PSG register number on PPI port A
                out (c),c               ;}

                ld bc,&f6c0            ;} Tell PSG to select register from data on PPI port A
                out (c),c               ;}

                ld bc,&f600            ;} Put PSG into inactive state.
                out (c),c               ;}

                ld b,&f4            ;} setup register data on PPI port A
                out (c),a               ;}

                ld bc,&f680            ;} Tell PSG to write data on PPI port A into selected register
                out (c),c               ;}

                ld bc,&f600            ;} Put PSG into inactive state
                out (c),c               ;}
                endm


                org 0

                di

                ;Una pequeña pausa para que todos los circuitos se estabilicen
                ld hl,0
PausaInicial:   nop
                nop
                nop
                ld a,h
                or l
                jr nz,PausaInicial

                ;Ponemos todos los puertos del 8255 de salida.
                ld b,&f7            ;8255 PPI control
                ld c,%10000010
                out (c),c               ;Port A output, Port B input, Port C output

                ;Preparamos al PSG para un tono de 1000Hz por los tres canales.
                ld c,7
                ld a,&ff
                writepsg
                ld c,1
                ld a,0
                writepsg
                ld c,3
                ld a,0
                writepsg
                ld c,5
                ld a,0
                writepsg
                ld c,0
                ld a,62
                writepsg
                ld c,2
                ld a,62
                writepsg
                ld c,4
                ld a,62
                writepsg
                ld c,10
                ld a,15
                writepsg
                ld c,11
                ld a,15
                writepsg
                ld c,12
                ld a,15
                writepsg

                ;inicializamos el CRTC para mostrar el modo 2
                ld bc,&bc00
                ld hl,TablaCRTC
SetupCRTC       out (c),c
                ld d,b
                ld e,c
                ld b,&bd
                ld c,(hl)
                out (c),c
                ld b,d
                ld c,e
                inc c
                inc hl
                ld a,c
                cp 16
                jr nz,SetupCRTC

                ;Mode 2, rom baja ON, rom alta OFF
                ld bc,&7f00+%10001010
                out (c),c

                ;Pluma 0 a negro, pluma 1 a blanco
                ld bc,&7f00
                out (c),c
                ld bc,&7f00+%01000000+20
                out (c),c
                ld bc,&7f01
                out (c),c
                ld bc,&7f00+%01000000+&0b
                out (c),c

                ;Borde cambiante
                ex af,af'
                exx
                ld d,18   ;colores del 18 al 25
                ld a,1
                exx
                ex af,af'

BucleTest:      ld bc,&7f10
                out (c),c
                ld bc,&7f00+%01000000
                ld a,c
                exx
                or d
                inc d
                exx
                out (c),a

                ld hl,&c000
                ex af,af'
                ld (hl),a
                rlca
                ex af,af'
                ld de,&c001
                ld bc,16383
                ldir

                exx
                ld a,d
                cp 26    ;si ya hemos llegado al 26, de vuelta al 18
                jr nz,NoResetBorde
                ld d,18
                ex af,af'
                cpl
                ex af,af'
NoResetBorde:
                exx

                ld c,7
                ld a,%11111000
                writepsg

                ld hl,0
EsperaCorta:    nop
                nop
                dec hl
                ld a,h
                or l
                jr nz,EsperaCorta

                ld c,7
                ld a,&ff
                writepsg

                ld hl,0
EsperaLarga:    nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                dec hl
                ld a,h
                or l
                jr nz,EsperaLarga

                jp BucleTest

TablaCRTC:      db &3f,&28,&2e,&8e,&26,&00,&19,&1e,&00,&07,&00,&00,&30,&00,&00,&00
