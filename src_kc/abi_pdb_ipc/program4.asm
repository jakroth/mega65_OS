.pc = $801 "Basic"
:BasicUpstart(main)
.pc = $80d "Program"
main: {
    ldx #$ff
    lda #<message
    sta.z ipc_send.message
    lda #>message
    sta.z ipc_send.message+1
    jsr ipc_send
    ldx #$c8
    lda #<message1
    sta.z ipc_send.message
    lda #>message1
    sta.z ipc_send.message+1
    jsr ipc_send
    ldx #$c7
    lda #<message2
    sta.z ipc_send.message
    lda #>message2
    sta.z ipc_send.message+1
    jsr ipc_send
    ldx #$c6
    lda #<message3
    sta.z ipc_send.message
    lda #>message3
    sta.z ipc_send.message+1
    jsr ipc_send
    ldx #1
    lda #<message2
    sta.z ipc_send.message
    lda #>message2
    sta.z ipc_send.message+1
    jsr ipc_send
    ldx #$64
    lda #<message5
    sta.z ipc_send.message
    lda #>message5
    sta.z ipc_send.message+1
    jsr ipc_send
    ldx #$f0
    lda #<message6
    sta.z ipc_send.message
    lda #>message6
    sta.z ipc_send.message+1
    jsr ipc_send
  __b1:
    jsr yield
    jmp __b1
    message: .text "checkpoint  "
    .byte 0
    message1: .text "4           "
    .byte 0
    message2: .text "------------"
    .byte 0
    message3: .text "moremessages"
    .byte 0
    message5: .text "3           "
    .byte 0
    message6: .text "6.          "
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
// ipc_send(byte register(X) priority, byte* zeropage(2) message)
ipc_send: {
    .label a = 4
    .label m = 2
    .label message = 2
    lda #$ff
    sta $300
    lda #1
    sta $300+1
    stx $300+1+1
    sta $300+1+1+1
    lda #<$300+1+1+1+1
    sta.z a
    lda #>$300+1+1+1+1
    sta.z a+1
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
