.pc = $801 "Basic"
:BasicUpstart(main)
.pc = $80d "Program"
  .const OFFSET_STRUCT_IPC_MESSAGE_TO = 1
  .const OFFSET_STRUCT_IPC_MESSAGE_MESSAGE = 4
main: {
    .label msg = ipc_buffer+OFFSET_STRUCT_IPC_MESSAGE_MESSAGE
    .label scr = 2
  b1:
    lda #<$400
    sta.z scr
    lda #>$400
    sta.z scr+1
  __b2:
    jsr ipc_read
    lda #$ff
    cmp ipc_buffer+OFFSET_STRUCT_IPC_MESSAGE_TO
    bne b2
  __b3:
    jmp __b3
  // Print message contents to screen
  b2:
    ldy #0
  __b4:
    cpy #$c
    bcc __b5
    lda #$28
    clc
    adc.z scr
    sta.z scr
    bcc !+
    inc.z scr+1
  !:
    lda.z scr+1
    cmp #>$700
    bne !+
    lda.z scr
    cmp #<$700
  !:
    bcc __b2
    beq __b2
    jmp b1
  __b5:
    lda msg,y
    sta (scr),y
    iny
    jmp __b4
}
// FUNCTION: returns a pointer to the ipc_message buffer, which contains the IPC message that was stored at $0300
ipc_read: {
    .label b = $300
    .label a = ipc_buffer
    jsr enable_syscalls
    lda #0
    sta $d649
    // this runs the code in syscall09
    nop
    jsr enable_syscalls
    lda #0
    sta $d649
    // this runs the code in syscall09
    nop
    tax
  __b1:
    cpx #$10
    bcc __b2
    rts
  __b2:
    lda b,x
    sta a,x
    inx
    jmp __b1
}
enable_syscalls: {
    lda #$47
    sta $d02f
    lda #$53
    sta $d02f
    rts
}
  // VARIABLE: Initialise a struct to temporarily hold (buffer) ipc_messages as they are passed back and forth
  ipc_buffer: .fill $10*1, 0
