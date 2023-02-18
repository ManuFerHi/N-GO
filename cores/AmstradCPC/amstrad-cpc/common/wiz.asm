;; A = REGISTER
;; (HL) = VALUE
 org 0
 ld bc,$F782
 out (C),C
 ld bc,$F600
 out (C),C
 ld hl,Sitio
 ld a,1
 LD B,$F4
 OUT [C],A
 LD BC,$F6C0
 OUT [C],C
 DEFB $ED
 DEFB $71
 LD B,$F5
 OUTI
 LD BC,$F680
 OUT [C],C
 DEFB $ED
 DEFB $71
 halt
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
Sitio: db 0aah