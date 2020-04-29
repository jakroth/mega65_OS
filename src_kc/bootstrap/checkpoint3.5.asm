// Xmega65 Kernam Development Template
// Each function of the kernal is a no-args function
// The functions are placed in the SYSCALLS table surrounded by JMP and NOP
  .file [name="checkpoint3.5.bin", type="bin", segments="XMega65Bin"]
.segmentdef XMega65Bin [segments="Syscall, Code, Data, Stack, Zeropage"]
.segmentdef Syscall [start=$8000, max=$81ff]
.segmentdef Code [start=$8200, min=$8200, max=$bdff]
.segmentdef Data [startAfter="Code", min=$8200, max=$bdff]
.segmentdef Stack [min=$be00, max=$beff, fill]
.segmentdef Zeropage [min=$bf00, max=$bfff, fill]
  .const OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_LAST_ADDRESS = 2
  .const OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_DEVICE_NAME = 4
  .label VIC_MEMORY = $d018
  .label SCREEN = $400
  .label COLS = $d800
  .const WHITE = 1
  // To save writing 0x4C and 0xEA all the time, we define them as constants
  .const JMP = $4c
  .const NOP = $ea
  .label current_screen_x = 6
  .label current_screen_line = 2
  .label device_allocation_count = $a
  .label device_allocation_count_33 = $f
  .label current_screen_line_51 = 4
  .label current_screen_line_66 = 4
  .label current_screen_line_90 = 4
  .label current_screen_line_91 = 4
  .label current_screen_line_92 = 4
  .label current_screen_line_93 = 4
  .label current_screen_line_94 = 4
  .label current_screen_line_95 = 4
  .label current_screen_line_97 = 4
  .label current_screen_line_103 = 4
  .label current_screen_line_104 = 4
  .label current_screen_line_105 = 4
  .label device_allocation_count_94 = $f
  .label device_allocation_count_95 = $f
.segment Code
main: {
    rts
}
cpukil: {
    jsr exit_hypervisor
    rts
}
// FUNCTION to trigger exit from Hypervisor mode
exit_hypervisor: {
    lda #1
    sta $d67f
    rts
}
// Can define specific functions for all the reserved traps later
reserved: {
    jsr exit_hypervisor
    rts
}
vF011wr: {
    jsr exit_hypervisor
    rts
}
vF011rd: {
    jsr exit_hypervisor
    rts
}
alttabkey: {
    jsr exit_hypervisor
    rts
}
restorkey: {
    jsr exit_hypervisor
    rts
}
// end reset function
pagfault: {
    jsr exit_hypervisor
    rts
}
// TRAP FUNCTIONS
reset: {
    // Initialise screen memory, and selects correct font
    lda #$14
    sta VIC_MEMORY
    ldx #' '
    lda #<SCREEN
    sta.z memset.str
    lda #>SCREEN
    sta.z memset.str+1
    lda #<$28*$19
    sta.z memset.num
    lda #>$28*$19
    sta.z memset.num+1
    jsr memset
    ldx #WHITE
    lda #<COLS
    sta.z memset.str
    lda #>COLS
    sta.z memset.str+1
    lda #<$28*$19
    sta.z memset.num
    lda #>$28*$19
    sta.z memset.num+1
    jsr memset
    lda #<0
    sta.z current_screen_x
    sta.z current_screen_x+1
    lda #<$400
    sta.z current_screen_line_51
    lda #>$400
    sta.z current_screen_line_51+1
    lda #<message
    sta.z print_to_screen.message
    lda #>message
    sta.z print_to_screen.message+1
    jsr print_to_screen
    lda #<$400
    sta.z current_screen_line
    lda #>$400
    sta.z current_screen_line+1
    jsr print_newline
    lda.z current_screen_line
    sta.z current_screen_line_97
    lda.z current_screen_line+1
    sta.z current_screen_line_97+1
    lda #<0
    sta.z current_screen_x
    sta.z current_screen_x+1
    lda #<message1
    sta.z print_to_screen.message
    lda #>message1
    sta.z print_to_screen.message+1
    jsr print_to_screen
    jsr print_newline
    jsr detect_devices
    jsr print_device_array
  b1:
  // loop to stop the rest of the code executing (for now)
    jmp b1
  .segment Data
    message: .text "pill0032 operating system starting..."
    .byte 0
    message1: .text "testing hardware"
    .byte 0
}
.segment Code
// FUNCTION to print the device memory register array
print_device_array: {
    .label i = $1f
    lda #0
    sta.z i
  b1:
    lda.z i
    cmp.z device_allocation_count
    bcc b2
    rts
  b2:
    lda.z i
    asl
    clc
    adc.z i
    asl
    tay
    lda device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_DEVICE_NAME,y
    sta.z print_to_screen.message
    lda device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_DEVICE_NAME+1,y
    sta.z print_to_screen.message+1
    lda.z current_screen_line
    sta.z current_screen_line_93
    lda.z current_screen_line+1
    sta.z current_screen_line_93+1
    lda #<0
    sta.z current_screen_x
    sta.z current_screen_x+1
    jsr print_to_screen
    lda.z current_screen_line
    sta.z current_screen_line_94
    lda.z current_screen_line+1
    sta.z current_screen_line_94+1
    lda #<message
    sta.z print_to_screen.message
    lda #>message
    sta.z print_to_screen.message+1
    jsr print_to_screen
    lda.z i
    asl
    clc
    adc.z i
    asl
    tay
    lda device_memory_allocations,y
    sta.z print_hex.value
    lda device_memory_allocations+1,y
    sta.z print_hex.value+1
    lda.z current_screen_line
    sta.z current_screen_line_105
    lda.z current_screen_line+1
    sta.z current_screen_line_105+1
    jsr print_hex
    lda.z current_screen_line
    sta.z current_screen_line_95
    lda.z current_screen_line+1
    sta.z current_screen_line_95+1
    lda #<message1
    sta.z print_to_screen.message
    lda #>message1
    sta.z print_to_screen.message+1
    jsr print_to_screen
    lda.z i
    asl
    clc
    adc.z i
    asl
    tay
    lda device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_LAST_ADDRESS,y
    sta.z print_hex.value
    lda device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_LAST_ADDRESS+1,y
    sta.z print_hex.value+1
    lda.z current_screen_line
    sta.z current_screen_line_104
    lda.z current_screen_line+1
    sta.z current_screen_line_104+1
    jsr print_hex
    jsr print_newline
    inc.z i
    jmp b1
  .segment Data
    message: .text " at $"
    .byte 0
    message1: .text " to $"
    .byte 0
}
.segment Code
// FUNCTION to move the current message line down one position
print_newline: {
    lda #$28
    clc
    adc.z current_screen_line
    sta.z current_screen_line
    bcc !+
    inc.z current_screen_line+1
  !:
    rts
}
// FUNCTION to print a hexidecimal value
// print_hex(word zeropage(8) value)
print_hex: {
    .label value = 8
    jsr make_hex
    lda #<make_hex.hex
    sta.z print_to_screen.message
    lda #>make_hex.hex
    sta.z print_to_screen.message+1
    jsr print_to_screen
    rts
}
// FUNCTION to print a message on the screen
// print_to_screen(byte* zeropage(8) message)
print_to_screen: {
    .label _0 = $17
    .label message = 8
  b1:
  // Copy the message from the array memory to the screen location memory
    ldy #0
    lda (message),y
    cmp #0
    bne b2
    rts
  b2:
    lda.z current_screen_line_51
    clc
    adc.z current_screen_x
    sta.z _0
    lda.z current_screen_line_51+1
    adc.z current_screen_x+1
    sta.z _0+1
    ldy #0
    lda (message),y
    sta (_0),y
    inc.z message
    bne !+
    inc.z message+1
  !:
    inc.z current_screen_x
    bne !+
    inc.z current_screen_x+1
  !:
    jmp b1
}
// FUNCTION to make an array of hex values out of a binary number
// make_hex(word zeropage(8) value)
make_hex: {
    .label _2 = $15
    .label _5 = $17
    .label value = 8
    ldx #0
  b1:
    cpx #4
    bcc b2
    lda #0
    sta hex+4
    rts
  b2:
    lda.z value+1
    cmp #>$a000
    bcc b4
    bne !+
    lda.z value
    cmp #<$a000
    bcc b4
  !:
    ldy #$c
    lda.z value
    sta.z _2
    lda.z value+1
    sta.z _2+1
    cpy #0
    beq !e+
  !:
    lsr.z _2+1
    ror.z _2
    dey
    bne !-
  !e:
    lda.z _2
    sec
    sbc #9
    sta hex,x
  b5:
    asl.z value
    rol.z value+1
    asl.z value
    rol.z value+1
    asl.z value
    rol.z value+1
    asl.z value
    rol.z value+1
    inx
    jmp b1
  b4:
    ldy #$c
    lda.z value
    sta.z _5
    lda.z value+1
    sta.z _5+1
    cpy #0
    beq !e+
  !:
    lsr.z _5+1
    ror.z _5
    dey
    bne !-
  !e:
    lda.z _5
    clc
    adc #'0'
    sta hex,x
    jmp b5
  .segment Data
    hex: .fill 5, 0
}
.segment Code
// FUNCTION to detect all hardware devices
detect_devices: {
    .label _7 = $15
    .label _12 = $17
    .label advance = $13
    .label i = $b
    .label i1 = $11
    lda #<0
    sta.z advance
    sta.z advance+1
    lda #1
    sta.z i
    lda #0
    sta.z i+1
    sta.z i+2
    sta.z i+3
  b1:
    lda.z i+3
    cmp #>$1e8480>>$10
    bcs !b2+
    jmp b2
  !b2:
    bne !+
    lda.z i+2
    cmp #<$1e8480>>$10
    bcs !b2+
    jmp b2
  !b2:
    bne !+
    lda.z i+1
    cmp #>$1e8480
    bcs !b2+
    jmp b2
  !b2:
    bne !+
    lda.z i
    cmp #<$1e8480
    bcs !b2+
    jmp b2
  !b2:
  !:
    lda #0
    sta.z device_allocation_count
    lda #<$d000
    sta.z i1
    lda #>$d000
    sta.z i1+1
  // wait at least 1 second
  b3:
    lda.z i1+1
    cmp #>$dfff
    bne !+
    lda.z i1
    cmp #<$dfff
  !:
    bcc b4
    beq b4
    lda.z current_screen_line
    sta.z current_screen_line_90
    lda.z current_screen_line+1
    sta.z current_screen_line_90+1
    lda #<0
    sta.z current_screen_x
    sta.z current_screen_x+1
    lda #<message
    sta.z print_to_screen.message
    lda #>message
    sta.z print_to_screen.message+1
    jsr print_to_screen
    jsr print_newline
    rts
  b4:
    lda.z i1
    sta.z print_hex.value
    lda.z i1+1
    sta.z print_hex.value+1
    lda.z current_screen_line
    sta.z current_screen_line_103
    lda.z current_screen_line+1
    sta.z current_screen_line_103+1
    lda #<0
    sta.z current_screen_x
    sta.z current_screen_x+1
    jsr print_hex
    lda.z device_allocation_count
    sta.z device_allocation_count_95
    jsr check_mem
    lda.z check_mem.return
    cmp #0
    bne b8
  b6:
    lda.z device_allocation_count
    sta.z device_allocation_count_94
    jsr check_mem
    lda.z check_mem.return
    cmp #0
    bne b10
  b7:
    inc.z i1
    bne !+
    inc.z i1+1
  !:
    jmp b3
  b10:
    lda #<0
    sta.z advance
    sta.z advance+1
    jsr detect_mos6526
    lda.z _12
    sta.z advance
    lda.z _12+1
    sta.z advance+1
    lda.z advance
    bne !+
    lda.z advance+1
    beq b7
  !:
    lda.z i1
    clc
    adc.z advance
    sta.z i1
    lda.z i1+1
    adc.z advance+1
    sta.z i1+1
    jmp b7
  b8:
    lda #<0
    sta.z advance
    sta.z advance+1
    jsr detect_vicii
    lda.z _7
    sta.z advance
    lda.z _7+1
    sta.z advance+1
    lda.z advance
    bne !+
    lda.z advance+1
    beq b6
  !:
    lda.z i1
    clc
    adc.z advance
    sta.z i1
    lda.z i1+1
    adc.z advance+1
    sta.z i1+1
    jmp b6
  b2:
    inc.z i
    bne !+
    inc.z i+1
    bne !+
    inc.z i+2
    bne !+
    inc.z i+3
  !:
    jmp b1
  .segment Data
    message: .text "finished probing for devices"
    .byte 0
}
.segment Code
// FUNCTION to detect VIC-II devices
// detect_vicii(word zeropage($11) address)
detect_vicii: {
    .label v2 = $1f
    .label i = 8
    .label return = $15
    .label address = $11
    ldy #$12
    lda (address),y
    tax
    lda #<1
    sta.z i
    lda #>1
    sta.z i+1
  // read start address + $12;
  b1:
    lda.z i+1
    cmp #>$3e8
    bcc b3
    bne !+
    lda.z i
    cmp #<$3e8
    bcc b3
  !:
    // wait at least 64 microseconds
    ldy #$12
    lda (address),y
    sta.z v2
    cpx.z v2
    bcs b2
    lda.z current_screen_line
    sta.z current_screen_line_92
    lda.z current_screen_line+1
    sta.z current_screen_line_92+1
    lda #<0
    sta.z current_screen_x
    sta.z current_screen_x+1
    lda #<message
    sta.z print_to_screen.message
    lda #>message
    sta.z print_to_screen.message+1
    jsr print_to_screen
    jsr print_newline
    lda.z address
    sta.z populate_array.address
    lda.z address+1
    sta.z populate_array.address+1
    lda #0
    sta.z populate_array.type
    jsr populate_array
    lda #<$7f
    sta.z return
    lda #>$7f
    sta.z return+1
    rts
  b2:
    lda #<0
    sta.z return
    sta.z return+1
    rts
  b3:
    inc.z i
    bne !+
    inc.z i+1
  !:
    jmp b1
  .segment Data
    message: .text "found vic-ii"
    .byte 0
}
.segment Code
// FUNCTION to populate arrays with devices memory registers
// populate_array(byte zeropage($1f) type, word zeropage(8) address)
populate_array: {
    .label _4 = $15
    .label _5 = $17
    .label _6 = $19
    .label _7 = $1b
    .label _8 = $1d
    .label _9 = 8
    .label type = $1f
    .label address = 8
    lda.z type
    cmp #0
    beq !b1+
    jmp b1
  !b1:
    lda.z device_allocation_count
    asl
    clc
    adc.z device_allocation_count
    asl
    tax
    lda.z address
    sta device_memory_allocations,x
    lda.z address+1
    sta device_memory_allocations+1,x
    lda #$7f
    clc
    adc.z address
    sta.z _4
    lda #0
    adc.z address+1
    sta.z _4+1
    lda.z _4
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_LAST_ADDRESS,x
    lda.z _4+1
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_LAST_ADDRESS+1,x
    lda #<_36
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_DEVICE_NAME,x
    lda #>_36
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_DEVICE_NAME+1,x
    ldx.z device_allocation_count
    inx
    lda #<$100
    clc
    adc.z address
    sta.z _5
    lda #>$100
    adc.z address+1
    sta.z _5+1
    txa
    asl
    stx.z $ff
    clc
    adc.z $ff
    asl
    tay
    lda.z _5
    sta device_memory_allocations,y
    lda.z _5+1
    sta device_memory_allocations+1,y
    lda #<$3ff
    clc
    adc.z address
    sta.z _6
    lda #>$3ff
    adc.z address+1
    sta.z _6+1
    lda.z _6
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_LAST_ADDRESS,y
    lda.z _6+1
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_LAST_ADDRESS+1,y
    lda #<_36
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_DEVICE_NAME,y
    lda #>_36
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_DEVICE_NAME+1,y
    inx
    lda #<$800
    clc
    adc.z address
    sta.z _7
    lda #>$800
    adc.z address+1
    sta.z _7+1
    txa
    asl
    stx.z $ff
    clc
    adc.z $ff
    asl
    tay
    lda.z _7
    sta device_memory_allocations,y
    lda.z _7+1
    sta device_memory_allocations+1,y
    lda #<$bff
    clc
    adc.z address
    sta.z _8
    lda #>$bff
    adc.z address+1
    sta.z _8+1
    lda.z _8
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_LAST_ADDRESS,y
    lda.z _8+1
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_LAST_ADDRESS+1,y
    lda #<_36
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_DEVICE_NAME,y
    lda #>_36
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_DEVICE_NAME+1,y
    inx
    stx.z device_allocation_count
  b1:
    lda #1
    cmp.z type
    bne breturn
    lda.z device_allocation_count
    asl
    clc
    adc.z device_allocation_count
    asl
    tax
    lda.z address
    sta device_memory_allocations,x
    lda.z address+1
    sta device_memory_allocations+1,x
    lda #$ff
    clc
    adc.z _9
    sta.z _9
    bcc !+
    inc.z _9+1
  !:
    lda.z _9
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_LAST_ADDRESS,x
    lda.z _9+1
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_LAST_ADDRESS+1,x
    lda #<_37
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_DEVICE_NAME,x
    lda #>_37
    sta device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_DEVICE_NAME+1,x
    inc.z device_allocation_count
  breturn:
    rts
  .segment Data
    _36: .text "vic-ii"
    .byte 0
    _37: .text "mos6526"
    .byte 0
}
.segment Code
// FUNCTION to detect MOS6526 devices
// detect_mos6526(word zeropage($11) address)
detect_mos6526: {
    .label t4 = $1f
    .label i = $b
    .label return = $17
    .label address = $11
    ldy #$19
    lda (address),y
    tax
    // read start address + $0A (minutes or something like it)
    ldy #$1b
    lda (address),y
    cmp #0
    beq b2
    cmp #$18
    bcc b4
  b2:
    lda #<0
    sta.z return
    sta.z return+1
    rts
  b4:
    lda #1
    sta.z i
    lda #0
    sta.z i+1
    sta.z i+2
    sta.z i+3
  b1:
    lda.z i+3
    cmp #>$2dc6c0>>$10
    bcc b3
    bne !+
    lda.z i+2
    cmp #<$2dc6c0>>$10
    bcc b3
    bne !+
    lda.z i+1
    cmp #>$2dc6c0
    bcc b3
    bne !+
    lda.z i
    cmp #<$2dc6c0
    bcc b3
  !:
    // wait at least 1 second
    ldy #$19
    lda (address),y
    sta.z t4
    cpx.z t4
    bcs b2
    lda.z current_screen_line
    sta.z current_screen_line_91
    lda.z current_screen_line+1
    sta.z current_screen_line_91+1
    lda #<0
    sta.z current_screen_x
    sta.z current_screen_x+1
    lda #<message
    sta.z print_to_screen.message
    lda #>message
    sta.z print_to_screen.message+1
    jsr print_to_screen
    jsr print_newline
    lda.z address
    sta.z populate_array.address
    lda.z address+1
    sta.z populate_array.address+1
    lda #1
    sta.z populate_array.type
    jsr populate_array
    lda #<$ff
    sta.z return
    lda #>$ff
    sta.z return+1
    rts
  b3:
    inc.z i
    bne !+
    inc.z i+1
    bne !+
    inc.z i+2
    bne !+
    inc.z i+3
  !:
    jmp b1
  .segment Data
    message: .text "found mos6526"
    .byte 0
}
.segment Code
// FUNCTION to check if a memory address is free to use
// check_mem(word zeropage($11) address)
check_mem: {
    .label address = $11
    .label return = $10
    .label check = $10
    lda #1
    sta.z check
    ldy #0
  b1:
    cpy.z device_allocation_count_33
    bcc b2
    rts
  b2:
    tya
    asl
    sty.z $ff
    clc
    adc.z $ff
    asl
    tax
    lda.z address+1
    cmp device_memory_allocations+1,x
    bcc b3
    bne !+
    lda.z address
    cmp device_memory_allocations,x
    bcc b3
  !:
    lda device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_LAST_ADDRESS+1,x
    cmp.z address+1
    bcc b3
    bne !+
    lda device_memory_allocations+OFFSET_STRUCT_DEVICE_MEMORY_ALLOCATION_LAST_ADDRESS,x
    cmp.z address
    bcc b3
  !:
    lda #0
    sta.z check
  b3:
    iny
    jmp b1
}
// Copies the character c (an unsigned char) to the first num characters of the object pointed to by the argument str.
// memset(void* zeropage($15) str, byte register(X) c, word zeropage($11) num)
memset: {
    .label end = $11
    .label dst = $15
    .label num = $11
    .label str = $15
    lda.z num
    bne !+
    lda.z num+1
    beq breturn
  !:
    lda.z end
    clc
    adc.z str
    sta.z end
    lda.z end+1
    adc.z str+1
    sta.z end+1
  b2:
    lda.z dst+1
    cmp.z end+1
    bne b3
    lda.z dst
    cmp.z end
    bne b3
  breturn:
    rts
  b3:
    txa
    ldy #0
    sta (dst),y
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    jmp b2
}
syscall3F: {
    jsr exit_hypervisor
    rts
}
syscall3E: {
    jsr exit_hypervisor
    rts
}
syscall3D: {
    jsr exit_hypervisor
    rts
}
syscall3C: {
    jsr exit_hypervisor
    rts
}
syscall3B: {
    jsr exit_hypervisor
    rts
}
syscall3A: {
    jsr exit_hypervisor
    rts
}
syscall39: {
    jsr exit_hypervisor
    rts
}
syscall38: {
    jsr exit_hypervisor
    rts
}
syscall37: {
    jsr exit_hypervisor
    rts
}
syscall36: {
    jsr exit_hypervisor
    rts
}
syscall35: {
    jsr exit_hypervisor
    rts
}
syscall34: {
    jsr exit_hypervisor
    rts
}
syscall33: {
    jsr exit_hypervisor
    rts
}
syscall32: {
    jsr exit_hypervisor
    rts
}
syscall31: {
    jsr exit_hypervisor
    rts
}
syscall30: {
    jsr exit_hypervisor
    rts
}
syscall2F: {
    jsr exit_hypervisor
    rts
}
syscall2E: {
    jsr exit_hypervisor
    rts
}
syscall2D: {
    jsr exit_hypervisor
    rts
}
syscall2C: {
    jsr exit_hypervisor
    rts
}
syscall2B: {
    jsr exit_hypervisor
    rts
}
syscall2A: {
    jsr exit_hypervisor
    rts
}
syscall29: {
    jsr exit_hypervisor
    rts
}
syscall28: {
    jsr exit_hypervisor
    rts
}
syscall27: {
    jsr exit_hypervisor
    rts
}
syscall26: {
    jsr exit_hypervisor
    rts
}
syscall25: {
    jsr exit_hypervisor
    rts
}
syscall24: {
    jsr exit_hypervisor
    rts
}
syscall23: {
    jsr exit_hypervisor
    rts
}
syscall22: {
    jsr exit_hypervisor
    rts
}
syscall21: {
    jsr exit_hypervisor
    rts
}
syscall20: {
    jsr exit_hypervisor
    rts
}
syscall1F: {
    jsr exit_hypervisor
    rts
}
syscall1E: {
    jsr exit_hypervisor
    rts
}
syscall1D: {
    jsr exit_hypervisor
    rts
}
syscall1C: {
    jsr exit_hypervisor
    rts
}
syscall1B: {
    jsr exit_hypervisor
    rts
}
syscall1A: {
    jsr exit_hypervisor
    rts
}
syscall19: {
    jsr exit_hypervisor
    rts
}
syscall18: {
    jsr exit_hypervisor
    rts
}
syscall17: {
    jsr exit_hypervisor
    rts
}
syscall16: {
    jsr exit_hypervisor
    rts
}
syscall15: {
    jsr exit_hypervisor
    rts
}
syscall14: {
    jsr exit_hypervisor
    rts
}
syscall13: {
    jsr exit_hypervisor
    rts
}
securexit: {
    jsr exit_hypervisor
    rts
}
securentr: {
    jsr exit_hypervisor
    rts
}
syscall10: {
    jsr exit_hypervisor
    rts
}
syscall0F: {
    jsr exit_hypervisor
    rts
}
syscall0E: {
    jsr exit_hypervisor
    rts
}
syscall0D: {
    jsr exit_hypervisor
    rts
}
syscall0C: {
    jsr exit_hypervisor
    rts
}
syscall0B: {
    jsr exit_hypervisor
    rts
}
syscall0A: {
    jsr exit_hypervisor
    rts
}
syscall09: {
    jsr exit_hypervisor
    rts
}
syscall08: {
    jsr exit_hypervisor
    rts
}
syscall07: {
    jsr exit_hypervisor
    rts
}
syscall06: {
    jsr exit_hypervisor
    rts
}
syscall05: {
    jsr exit_hypervisor
    rts
}
syscall04: {
    jsr exit_hypervisor
    rts
}
syscall03: {
    jsr exit_hypervisor
    rts
}
syscall02: {
    jsr exit_hypervisor
    rts
}
syscall01: {
    jsr exit_hypervisor
    rts
}
// Defining the functions/behvaiours of syscalls and traps
// SYSCALL FUNCTIONS
syscall00: {
    jsr exit_hypervisor
    rts
}
.segment Data
  // Create an array to hold device memory register structs
  device_memory_allocations: .fill 6*$10, 0
.segment Syscall
  // Now we can have a nice table of up to 64 SYSCALL handlers expressed 
  // in a fairly readable and easy format.
  // Each line is an instance of the struct SysCall from above, with the JMP
  // opcode value, the address of the handler routine and the NOP opcode value
SYSCALLS:
  .byte JMP
  .word syscall00
  .byte NOP
  .byte JMP
  .word syscall01
  .byte NOP
  .byte JMP
  .word syscall02
  .byte NOP
  .byte JMP
  .word syscall03
  .byte NOP
  .byte JMP
  .word syscall04
  .byte NOP
  .byte JMP
  .word syscall05
  .byte NOP
  .byte JMP
  .word syscall06
  .byte NOP
  .byte JMP
  .word syscall07
  .byte NOP
  .byte JMP
  .word syscall08
  .byte NOP
  .byte JMP
  .word syscall09
  .byte NOP
  .byte JMP
  .word syscall0A
  .byte NOP
  .byte JMP
  .word syscall0B
  .byte NOP
  .byte JMP
  .word syscall0C
  .byte NOP
  .byte JMP
  .word syscall0D
  .byte NOP
  .byte JMP
  .word syscall0E
  .byte NOP
  .byte JMP
  .word syscall0F
  .byte NOP
  .byte JMP
  .word syscall10
  .byte NOP
  .byte JMP
  .word securentr
  .byte NOP
  .byte JMP
  .word securexit
  .byte NOP
  .byte JMP
  .word syscall13
  .byte NOP
  .byte JMP
  .word syscall14
  .byte NOP
  .byte JMP
  .word syscall15
  .byte NOP
  .byte JMP
  .word syscall16
  .byte NOP
  .byte JMP
  .word syscall17
  .byte NOP
  .byte JMP
  .word syscall18
  .byte NOP
  .byte JMP
  .word syscall19
  .byte NOP
  .byte JMP
  .word syscall1A
  .byte NOP
  .byte JMP
  .word syscall1B
  .byte NOP
  .byte JMP
  .word syscall1C
  .byte NOP
  .byte JMP
  .word syscall1D
  .byte NOP
  .byte JMP
  .word syscall1E
  .byte NOP
  .byte JMP
  .word syscall1F
  .byte NOP
  .byte JMP
  .word syscall20
  .byte NOP
  .byte JMP
  .word syscall21
  .byte NOP
  .byte JMP
  .word syscall22
  .byte NOP
  .byte JMP
  .word syscall23
  .byte NOP
  .byte JMP
  .word syscall24
  .byte NOP
  .byte JMP
  .word syscall25
  .byte NOP
  .byte JMP
  .word syscall26
  .byte NOP
  .byte JMP
  .word syscall27
  .byte NOP
  .byte JMP
  .word syscall28
  .byte NOP
  .byte JMP
  .word syscall29
  .byte NOP
  .byte JMP
  .word syscall2A
  .byte NOP
  .byte JMP
  .word syscall2B
  .byte NOP
  .byte JMP
  .word syscall2C
  .byte NOP
  .byte JMP
  .word syscall2D
  .byte NOP
  .byte JMP
  .word syscall2E
  .byte NOP
  .byte JMP
  .word syscall2F
  .byte NOP
  .byte JMP
  .word syscall30
  .byte NOP
  .byte JMP
  .word syscall31
  .byte NOP
  .byte JMP
  .word syscall32
  .byte NOP
  .byte JMP
  .word syscall33
  .byte NOP
  .byte JMP
  .word syscall34
  .byte NOP
  .byte JMP
  .word syscall35
  .byte NOP
  .byte JMP
  .word syscall36
  .byte NOP
  .byte JMP
  .word syscall37
  .byte NOP
  .byte JMP
  .word syscall38
  .byte NOP
  .byte JMP
  .word syscall39
  .byte NOP
  .byte JMP
  .word syscall3A
  .byte NOP
  .byte JMP
  .word syscall3B
  .byte NOP
  .byte JMP
  .word syscall3C
  .byte NOP
  .byte JMP
  .word syscall3D
  .byte NOP
  .byte JMP
  .word syscall3E
  .byte NOP
  .byte JMP
  .word syscall3F
  .byte NOP
  // Originally we had only two SYSCALLs defined, so "align" tells KickC to
  //  make the TRAP table begin at the next multiple of $100, i.e., at $8100.
  .align $100
TRAPS:
  .byte JMP
  .word reset
  .byte NOP
  .byte JMP
  .word pagfault
  .byte NOP
  .byte JMP
  .word restorkey
  .byte NOP
  .byte JMP
  .word alttabkey
  .byte NOP
  .byte JMP
  .word vF011rd
  .byte NOP
  .byte JMP
  .word vF011wr
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word reserved
  .byte NOP
  .byte JMP
  .word cpukil
  .byte NOP
