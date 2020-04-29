.pc = $801 "Basic"
:BasicUpstart(main)
.pc = $80d "Program"
main: {
    jsr ipc_send
  __b1:
    jsr yield
    jmp __b1
    message: .text "cpoint 6.2  "
    .byte 0
}
yield: {
    jsr enable_syscalls
    lda #0
    sta $d645
    nop
    rts
}
enable_syscalls: {
    lda #$47
    sta $d02f
    lda #$53
    sta $d02f
    rts
}
// FUNCTION: for processes to send messages to another process
ipc_send: {
    .const to = 1
    .const priority = 1
    .const sequence = 1
    .label a = 4
    .label m = 2
    lda #$ff
    sta $300
    lda #to
    sta $300+1
    lda #priority
    sta $300+1+1
    lda #sequence
    sta $300+1+1+1
    lda #<$300+1+1+1+1
    sta.z a
    lda #>$300+1+1+1+1
    sta.z a+1
    lda #<main.message
    sta.z m
    lda #>main.message
    sta.z m+1
  __b1:
    ldy #0
    lda (m),y
    cmp #0
    bne __b2
    tya
    tay
    sta (a),y
    jsr enable_syscalls
    lda #0
    sta $d64a
    // this runs the code in syscall0A
    nop
    rts
  __b2:
    ldy #0
    lda (m),y
    sta (a),y
    inc.z a
    bne !+
    inc.z a+1
  !:
    inc.z m
    bne !+
    inc.z m+1
  !:
    jmp __b1
}
