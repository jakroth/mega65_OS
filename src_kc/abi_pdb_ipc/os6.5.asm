// XMega65 Kernal Development Template
// Each function of the kernal is a no-args function
// The functions are placed in the SYSCALLS table surrounded by JMP and NOP
  .file [name="os6.5.bin", type="bin", segments="XMega65Bin"]
.segmentdef XMega65Bin [segments="Syscall, Code, Data, Stack, Zeropage"]
.segmentdef Syscall [start=$8000, max=$81ff]
.segmentdef Code [start=$8200, min=$8200, max=$bdff]
.segmentdef Data [startAfter="Code", min=$8200, max=$bdff]
.segmentdef Stack [min=$be00, max=$beff, fill]
.segmentdef Zeropage [min=$bf00, max=$bfff, fill]
  .const SIZEOF_WORD = 2
  .const OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_NAME = 2
  .const OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_STATE = 1
  .const OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORAGE_START_ADDRESS = 4
  .const OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORAGE_END_ADDRESS = 8
  .const OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORED_STATE = $c
  .const OFFSET_STRUCT_IPC_MESSAGE_TO = 1
  .const OFFSET_STRUCT_IPC_MESSAGE_PRIORITY = 2
  .const OFFSET_STRUCT_IPC_MESSAGE_SEQUENCE = 3
  .const OFFSET_STRUCT_IPC_MESSAGE_MESSAGE = 4
  .label VIC_MEMORY = $d018
  .label SCREEN = $400
  .label COLS = $d800
  .const WHITE = 1
  // CONSTANTS for the PDB functions below
  .const STATE_NEW = 1
  .const STATE_READY = 2
  .const STATE_READYSUSPENDED = 3
  .const STATE_BLOCKEDSUSPENDED = 4
  .const STATE_BLOCKED = 5
  .const STATE_RUNNING = 6
  .const STATE_EXIT = 7
  // DEFINES the space to save the stored_states for the 8 Process Descriptor Blocks
  // Process Descriptor Block stored states will live at $C000-$C7FF, with 256 bytes for each
  .label stored_pdbs = $c000
  // 8 processes x 16 bytes = 128 bytes for names
  .label process_names = $c800
  // 8 processes x 64 bytes = 512 bytes for context state
  .label process_context_states = $c900
  // We will have 16 slots of 16 bytes at $CB00-$CBFF
  .label ipc_messages = $cb00
  // To save writing 0x4C and 0xEA all the time, we define them as constants
  .const JMP = $4c
  .const NOP = $ea
  .label current_screen_line = $27
  .label current_screen_x = $2b
  .label lpeek_value = $46
  .label running_pdb = $20
  .label pid_counter = $14
  .label ipc_message_count = $1e
  // Additional global variables for functions
  lda #<SCREEN
  sta.z current_screen_line
  lda #>SCREEN
  sta.z current_screen_line+1
  lda #0
  sta.z current_screen_x
  // DEFINES a variable to use in the lpeek function
  lda #$12
  sta.z lpeek_value
  // VARIABLES to use in the PDB functions below
  // Which is the current running process? Set this in the function resume_pbd().
  lda #$ff
  sta.z running_pdb
  // Counter for helping determine the next available process ID.
  lda #0
  sta.z pid_counter
  sta.z ipc_message_count
  jsr main
  rts
.segment Code
// FUNCTION for main
main: {
    rts
}
// Can define specific functions for all the reserved traps later
cpukil: {
    jsr exit_hypervisor
    rts
}
// FUNCTION to trigger exit from Hypervisor mode
exit_hypervisor: {
    // Exit hypervisor
    lda #1
    sta $d67f
    rts
}
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
// The rest of the TRAP FUNCTIONS
pagfault: {
    jsr exit_hypervisor
    rts
}
// TRAP FUNCTIONS - the RESET function
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
    // print these messages on the screens
    lda #<SCREEN+$190
    sta.z current_screen_line
    lda #>SCREEN+$190
    sta.z current_screen_line+1
    // Start with empty message queue
    lda #0
    sta.z ipc_message_count
    lda #<name
    sta.z initialise_pdb.name
    lda #>name
    sta.z initialise_pdb.name+1
    lda #0
    sta.z initialise_pdb.pdb_number
    jsr initialise_pdb
    lda #0
    jsr load_program
    lda #<name1
    sta.z initialise_pdb.name
    lda #>name1
    sta.z initialise_pdb.name+1
    lda #1
    sta.z initialise_pdb.pdb_number
    jsr initialise_pdb
    lda #1
    jsr load_program
    lda #0
    sta.z resume_pdb.pdb_number
    jsr resume_pdb
  b1:
  //print_raster_lines();
    jmp b1
  .segment Data
    name: .text "program6.prg"
    .byte 0
    name1: .text "program5.prg"
    .byte 0
}
.segment Code
// FUNCTION to RESUME a READY process, to make it RUNNING
// resume_pdb(byte zeropage(2) pdb_number)
resume_pdb: {
    .label __1 = $47
    .label __2 = $47
    .label __11 = $49
    .label p = $47
    .label ss = $4d
    .label pdb_number = 2
    lda.z pdb_number
    sta.z __1
    lda #0
    sta.z __1+1
    lda.z __2
    sta.z __2+1
    lda #0
    sta.z __2
    clc
    lda.z p
    adc #<stored_pdbs
    sta.z p
    lda.z p+1
    adc #>stored_pdbs
    sta.z p+1
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORAGE_START_ADDRESS
    lda (p),y
    sta.z dma_copy.src
    iny
    lda (p),y
    sta.z dma_copy.src+1
    iny
    lda (p),y
    sta.z dma_copy.src+2
    iny
    lda (p),y
    sta.z dma_copy.src+3
    lda #<0
    sta.z dma_copy.dest
    sta.z dma_copy.dest+1
    lda #<0>>$10
    sta.z dma_copy.dest+2
    lda #>0>>$10
    sta.z dma_copy.dest+3
    lda #<$400
    sta.z dma_copy.length
    lda #>$400
    sta.z dma_copy.length+1
    jsr dma_copy
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORAGE_START_ADDRESS
    lda (p),y
    sta.z __11
    iny
    lda (p),y
    sta.z __11+1
    iny
    lda (p),y
    sta.z __11+2
    iny
    lda (p),y
    sta.z __11+3
    lda.z __11
    clc
    adc #<$800
    sta.z dma_copy.src
    lda.z __11+1
    adc #>$800
    sta.z dma_copy.src+1
    lda.z __11+2
    adc #<$800>>$10
    sta.z dma_copy.src+2
    lda.z __11+3
    adc #>$800>>$10
    sta.z dma_copy.src+3
    lda #<$800
    sta.z dma_copy.dest
    lda #>$800
    sta.z dma_copy.dest+1
    lda #<$800>>$10
    sta.z dma_copy.dest+2
    lda #>$800>>$10
    sta.z dma_copy.dest+3
    lda #<$1800
    sta.z dma_copy.length
    lda #>$1800
    sta.z dma_copy.length+1
    jsr dma_copy
    // Load stored CPU state into Hypervisor saved register area at $FFD3640 (Joel: ??)
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORED_STATE
    lda (p),y
    sta.z ss
    iny
    lda (p),y
    sta.z ss+1
    ldy #0
  // XXX - Use a for() loop to copy 63 bytes from 
  // ss[0]--ss[62] to ((unsigned char *)$D640)[0]--((unsigned char *)$D640)[62] 
  // (dma_copy doesn't work for this for some slightly complex reasons.)
  __b1:
    cpy #$3f
    bcc __b2
    // Set state of process to running
    lda #STATE_RUNNING
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_STATE
    sta (p),y
    // Mark this PDB as the running process
    lda.z pdb_number
    sta.z running_pdb
    jsr exit_hypervisor
    rts
  __b2:
    lda (ss),y
    sta $d640,y
    iny
    jmp __b1
}
// FUNCTION to copy memory ranges
// dma_copy(dword zeropage(9) src, dword zeropage(5) dest, word zeropage(3) length)
dma_copy: {
    .label __0 = $4f
    .label __2 = $53
    .label __4 = $57
    .label __5 = $59
    .label __7 = $5d
    .label __9 = $61
    .label list_request_format0a = $30
    .label list_source_mb_option80 = $31
    .label list_source_mb = $32
    .label list_dest_mb_option81 = $33
    .label list_dest_mb = $34
    .label list_end_of_options00 = $35
    .label list_cmd = $36
    .label list_size = $37
    .label list_source_addr = $39
    .label list_source_bank = $3b
    .label list_dest_addr = $3c
    .label list_dest_bank = $3e
    .label list_modulo00 = $3f
    .label src = 9
    .label dest = 5
    .label length = 3
    lda #0
    sta.z list_request_format0a
    sta.z list_source_mb_option80
    sta.z list_source_mb
    sta.z list_dest_mb_option81
    sta.z list_dest_mb
    sta.z list_end_of_options00
    sta.z list_cmd
    sta.z list_size
    sta.z list_size+1
    sta.z list_source_addr
    sta.z list_source_addr+1
    sta.z list_source_bank
    sta.z list_dest_addr
    sta.z list_dest_addr+1
    sta.z list_dest_bank
    sta.z list_modulo00
    lda #$a
    sta.z list_request_format0a
    lda #$80
    sta.z list_source_mb_option80
    lda #$81
    sta.z list_dest_mb_option81
    lda #0
    sta.z list_end_of_options00
    sta.z list_cmd
    sta.z list_modulo00
    lda.z length
    sta.z list_size
    lda.z length+1
    sta.z list_size+1
    ldx #$14
    lda.z dest
    sta.z __0
    lda.z dest+1
    sta.z __0+1
    lda.z dest+2
    sta.z __0+2
    lda.z dest+3
    sta.z __0+3
    cpx #0
    beq !e+
  !:
    lsr.z __0+3
    ror.z __0+2
    ror.z __0+1
    ror.z __0
    dex
    bne !-
  !e:
    lda.z __0
    sta.z list_dest_mb
    lda #0
    sta.z __2+2
    sta.z __2+3
    lda.z dest+3
    sta.z __2+1
    lda.z dest+2
    sta.z __2
    lda #$7f
    and.z __2
    sta.z list_dest_bank
    lda.z dest
    sta.z __4
    lda.z dest+1
    sta.z __4+1
    lda.z __4
    sta.z list_dest_addr
    lda.z __4+1
    sta.z list_dest_addr+1
    ldx #$14
    lda.z src
    sta.z __5
    lda.z src+1
    sta.z __5+1
    lda.z src+2
    sta.z __5+2
    lda.z src+3
    sta.z __5+3
    cpx #0
    beq !e+
  !:
    lsr.z __5+3
    ror.z __5+2
    ror.z __5+1
    ror.z __5
    dex
    bne !-
  !e:
    lda.z __5
    // Work around missing fragments in KickC
    sta.z list_source_mb
    lda #0
    sta.z __7+2
    sta.z __7+3
    lda.z src+3
    sta.z __7+1
    lda.z src+2
    sta.z __7
    lda #$7f
    and.z __7
    sta.z list_source_bank
    lda.z src
    sta.z __9
    lda.z src+1
    sta.z __9+1
    lda.z __9
    sta.z list_source_addr
    lda.z __9+1
    sta.z list_source_addr+1
    // DMA list lives in hypervisor memory, so use correct list address when triggering
    // (Variables in KickC usually end up in ZP, so we have to provide the base page correction
    lda #0
    cmp #>list_request_format0a
    beq __b1
    lda #>list_request_format0a
    sta $d701
  __b2:
    lda #$7f
    sta $d702
    lda #$ff
    sta $d704
    lda #<list_request_format0a
    sta $d705
    rts
  __b1:
    lda #$bf+(>list_request_format0a)
    sta $d701
    jmp __b2
}
// FUNCTION to load a program into a pdb
// load_program(byte register(A) pdb_number)
load_program: {
    .label __1 = $63
    .label __2 = $63
    .label __30 = $6d
    .label __31 = $6d
    .label __34 = $d
    .label __35 = $d
    .label pdb = $63
    .label n = $71
    .label i = $12
    .label new_address = $69
    .label address = $d
    .label length = $44
    .label dest = $65
    .label match = $11
    sta.z __1
    lda #0
    sta.z __1+1
    lda.z __2
    sta.z __2+1
    lda #0
    sta.z __2
    clc
    lda.z pdb
    adc #<stored_pdbs
    sta.z pdb
    lda.z pdb+1
    adc #>stored_pdbs
    sta.z pdb+1
    lda #0
    sta.z match
    lda #<$20000
    sta.z address
    lda #>$20000
    sta.z address+1
    lda #<$20000>>$10
    sta.z address+2
    lda #>$20000>>$10
    sta.z address+3
  __b1:
    lda.z address
    sta.z lpeek.address
    lda.z address+1
    sta.z lpeek.address+1
    lda.z address+2
    sta.z lpeek.address+2
    lda.z address+3
    sta.z lpeek.address+3
    jsr lpeek
    txa
    cmp #0
    bne b1
    rts
  // Check for name match
  b1:
    lda #0
    sta.z i
  __b2:
    lda.z i
    cmp #$10
    bcs !__b3+
    jmp __b3
  !__b3:
    jmp __b5
  b3:
    lda #1
    sta.z match
  __b5:
    lda #0
    cmp.z match
    bne !__b8+
    jmp __b8
  !__b8:
    // Found program -- now copy it into place
    sta.z length
    sta.z length+1
    lda #$10
    clc
    adc.z address
    sta.z lpeek.address
    lda.z address+1
    adc #0
    sta.z lpeek.address+1
    lda.z address+2
    adc #0
    sta.z lpeek.address+2
    lda.z address+3
    adc #0
    sta.z lpeek.address+3
    jsr lpeek
    txa
    sta.z length
    lda #0
    sta.z length+1
    lda #$11
    clc
    adc.z address
    sta.z lpeek.address
    lda.z address+1
    adc #0
    sta.z lpeek.address+1
    lda.z address+2
    adc #0
    sta.z lpeek.address+2
    lda.z address+3
    adc #0
    sta.z lpeek.address+3
    jsr lpeek
    stx length+1
    // Copy program into place.
    // As the program is formatted as a C64 program with a
    // $0801 header, we copy it to offset $07FF.
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORAGE_START_ADDRESS
    lda (pdb),y
    sta.z dest
    iny
    lda (pdb),y
    sta.z dest+1
    iny
    lda (pdb),y
    sta.z dest+2
    iny
    lda (pdb),y
    sta.z dest+3
    lda.z dest
    clc
    adc #<$7ff
    sta.z dest
    lda.z dest+1
    adc #>$7ff
    sta.z dest+1
    lda.z dest+2
    adc #0
    sta.z dest+2
    lda.z dest+3
    adc #0
    sta.z dest+3
    lda #$20
    clc
    adc.z address
    sta.z dma_copy.src
    lda.z address+1
    adc #0
    sta.z dma_copy.src+1
    lda.z address+2
    adc #0
    sta.z dma_copy.src+2
    lda.z address+3
    adc #0
    sta.z dma_copy.src+3
    lda.z dest
    sta.z dma_copy.dest
    lda.z dest+1
    sta.z dma_copy.dest+1
    lda.z dest+2
    sta.z dma_copy.dest+2
    lda.z dest+3
    sta.z dma_copy.dest+3
    lda.z length
    sta.z dma_copy.length
    txa
    sta.z dma_copy.length+1
    jsr dma_copy
    // Mark process as now runnable
    lda #STATE_READY
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_STATE
    sta (pdb),y
    rts
  __b8:
    lda #$12
    clc
    adc.z address
    sta.z lpeek.address
    lda.z address+1
    adc #0
    sta.z lpeek.address+1
    lda.z address+2
    adc #0
    sta.z lpeek.address+2
    lda.z address+3
    adc #0
    sta.z lpeek.address+3
    jsr lpeek
    txa
    sta.z new_address
    lda #0
    sta.z new_address+1
    sta.z new_address+2
    sta.z new_address+3
    lda #$13
    clc
    adc.z address
    sta.z lpeek.address
    lda.z address+1
    adc #0
    sta.z lpeek.address+1
    lda.z address+2
    adc #0
    sta.z lpeek.address+2
    lda.z address+3
    adc #0
    sta.z lpeek.address+3
    jsr lpeek
    txa
    sta.z __30
    lda #0
    sta.z __30+1
    sta.z __30+2
    sta.z __30+3
    lda.z __31+2
    sta.z __31+3
    lda.z __31+1
    sta.z __31+2
    lda.z __31
    sta.z __31+1
    lda #0
    sta.z __31
    ora.z new_address
    sta.z new_address
    lda.z __31+1
    ora.z new_address+1
    sta.z new_address+1
    lda.z __31+2
    ora.z new_address+2
    sta.z new_address+2
    lda.z __31+3
    ora.z new_address+3
    sta.z new_address+3
    lda #$14
    clc
    adc.z address
    sta.z lpeek.address
    lda.z address+1
    adc #0
    sta.z lpeek.address+1
    lda.z address+2
    adc #0
    sta.z lpeek.address+2
    lda.z address+3
    adc #0
    sta.z lpeek.address+3
    jsr lpeek
    txa
    sta.z __34
    lda #0
    sta.z __34+1
    sta.z __34+2
    sta.z __34+3
    lda.z __35+1
    sta.z __35+3
    lda.z __35
    sta.z __35+2
    lda #0
    sta.z __35
    sta.z __35+1
    lda.z new_address
    ora.z address
    sta.z address
    lda.z new_address+1
    ora.z address+1
    sta.z address+1
    lda.z new_address+2
    ora.z address+2
    sta.z address+2
    lda.z new_address+3
    ora.z address+3
    sta.z address+3
    jmp __b1
  __b3:
    lda.z i
    clc
    adc.z address
    sta.z lpeek.address
    lda.z address+1
    adc #0
    sta.z lpeek.address+1
    lda.z address+2
    adc #0
    sta.z lpeek.address+2
    lda.z address+3
    adc #0
    sta.z lpeek.address+3
    jsr lpeek
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_NAME
    lda (pdb),y
    sta.z n
    iny
    lda (pdb),y
    sta.z n+1
    ldy.z i
    lda (n),y
    cpx #0
    bne __b4
    cmp #0
    bne !b3+
    jmp b3
  !b3:
  __b4:
    tay
    sty.z $ff
    cpx.z $ff
    beq __b6
    jmp __b5
  __b6:
    inc.z i
    jmp __b2
}
// FUNCTION to peek at an address, to avoid KickC issues
// lpeek(dword zeropage($65) address)
lpeek: {
    .label t = $40
    .label address = $65
    // Work around all sorts of fun problems in KickC
    //  dma_copy(address,$BF00+((unsigned short)<&lpeek_value),1);
    lda #<lpeek_value
    sta.z t
    lda #>lpeek_value
    sta.z t+1
    lda #<lpeek_value>>$10
    sta.z t+2
    lda #>lpeek_value>>$10
    sta.z t+3
    lda #0
    cmp #>lpeek_value
    bne __b1
    lda.z t
    clc
    adc #<$fffbf00
    sta.z t
    lda.z t+1
    adc #>$fffbf00
    sta.z t+1
    lda.z t+2
    adc #<$fffbf00>>$10
    sta.z t+2
    lda.z t+3
    adc #>$fffbf00>>$10
    sta.z t+3
  __b2:
    lda.z address
    sta.z dma_copy.src
    lda.z address+1
    sta.z dma_copy.src+1
    lda.z address+2
    sta.z dma_copy.src+2
    lda.z address+3
    sta.z dma_copy.src+3
    lda.z t
    sta.z dma_copy.dest
    lda.z t+1
    sta.z dma_copy.dest+1
    lda.z t+2
    sta.z dma_copy.dest+2
    lda.z t+3
    sta.z dma_copy.dest+3
    lda #<1
    sta.z dma_copy.length
    lda #>1
    sta.z dma_copy.length+1
    jsr dma_copy
    ldx.z lpeek_value
    rts
  __b1:
    lda.z t
    clc
    adc #<$fff0000
    sta.z t
    lda.z t+1
    adc #>$fff0000
    sta.z t+1
    lda.z t+2
    adc #<$fff0000>>$10
    sta.z t+2
    lda.z t+3
    adc #>$fff0000>>$10
    sta.z t+3
    jmp __b2
}
// FUNCTION to setup a new Process Descriptor Block (PBD)
// initialise_pdb(byte zeropage($13) pdb_number, byte* zeropage($15) name)
initialise_pdb: {
    .label __1 = $73
    .label __2 = $73
    .label __6 = $7f
    .label __7 = $7f
    .label __8 = $7f
    .label __9 = $75
    .label __10 = $75
    .label __11 = $75
    .label __12 = $79
    .label __13 = $79
    .label __14 = $79
    .label __15 = $7d
    .label __16 = $7d
    .label __17 = $7d
    .label p = $73
    .label pn = $18
    .label name = $15
    .label ss = $73
    .label pdb_number = $13
    lda.z pdb_number
    sta.z __1
    lda #0
    sta.z __1+1
    lda.z __2
    sta.z __2+1
    lda #0
    sta.z __2
    clc
    lda.z p
    adc #<stored_pdbs
    sta.z p
    lda.z p+1
    adc #>stored_pdbs
    sta.z p+1
    jsr next_free_pid
    lda.z next_free_pid.pid
    // Setup process ID (Joel: remember p->element == (*p).element == struct.element)
    // Joel: Gets a process ID for the process in this PDB, and stores it in p
    ldy #0
    sta (p),y
    lda.z pdb_number
    sta.z __6
    tya
    sta.z __6+1
    asl.z __7
    rol.z __7+1
    asl.z __7
    rol.z __7+1
    asl.z __7
    rol.z __7+1
    asl.z __7
    rol.z __7+1
    asl.z __7
    rol.z __7+1
    clc
    lda.z __8
    adc #<process_names
    sta.z __8
    lda.z __8+1
    adc #>process_names
    sta.z __8+1
    // Setup process name
    // (32 bytes space for each to fit 16 chars + nul)
    // (we could just use 17 bytes, but kickc can't multiply by 17)
    // Joel: This jumps to the beginning of process_names ($C800) + pdb_number * 32 (== left bit shift 5)
    // to prepare for storing a pointer to the name array of characters
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_NAME
    lda.z __8
    sta (p),y
    iny
    lda.z __8+1
    sta (p),y
    // XXX - copy the string in the array 'name' into the array 'p->process_name'
    // XXX - To make your life easier, do something like char *pn=p->process_name
    // Then you can just do something along the lines of pn[...]=name[...] in a loop to copy the name into place.
    // (The arrays are both 17 bytes long)
    // JOEL: loop that copies the passed in name parameter into process_name
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_NAME
    lda (p),y
    sta.z pn
    iny
    lda (p),y
    sta.z pn+1
  __b1:
    ldy #0
    lda (name),y
    cmp #0
    beq !__b2+
    jmp __b2
  !__b2:
    // Set process state as not running.
    //XXX - Put the value STATE_NOTRUNNING into p->process_state
    lda #STATE_NEW
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_STATE
    sta (p),y
    lda.z pdb_number
    sta.z __9
    lda #0
    sta.z __9+1
    sta.z __9+2
    sta.z __9+3
    ldx #$d
    cpx #0
    beq !e+
  !:
    asl.z __10
    rol.z __10+1
    rol.z __10+2
    rol.z __10+3
    dex
    bne !-
  !e:
    lda.z __11
    clc
    adc #<$30000
    sta.z __11
    lda.z __11+1
    adc #>$30000
    sta.z __11+1
    lda.z __11+2
    adc #<$30000>>$10
    sta.z __11+2
    lda.z __11+3
    adc #>$30000>>$10
    sta.z __11+3
    // Set stored memory area
    // For now, we just use fixed 8KB (==$2000) steps from $30000-$3FFFF corresponding to the PDB number.
    // XXX - Set p->storage_start_address to the correct start address for a process that is in this PDB.
    // The correct address is:
    lda.z __11
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORAGE_START_ADDRESS
    sta (p),y
    iny
    lda.z __11+1
    sta (p),y
    iny
    lda.z __11+2
    sta (p),y
    iny
    lda.z __11+3
    sta (p),y
    lda.z pdb_number
    sta.z __12
    lda #0
    sta.z __12+1
    sta.z __12+2
    sta.z __12+3
    ldx #$d
    cpx #0
    beq !e+
  !:
    asl.z __13
    rol.z __13+1
    rol.z __13+2
    rol.z __13+3
    dex
    bne !-
  !e:
    lda.z __14
    clc
    adc #<$31fff
    sta.z __14
    lda.z __14+1
    adc #>$31fff
    sta.z __14+1
    lda.z __14+2
    adc #<$31fff>>$10
    sta.z __14+2
    lda.z __14+3
    adc #>$31fff>>$10
    sta.z __14+3
    // XXX - Then do the same for the end address of the process, but starting $1FFF after the start address
    lda.z __14
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORAGE_END_ADDRESS
    sta (p),y
    iny
    lda.z __14+1
    sta (p),y
    iny
    lda.z __14+2
    sta (p),y
    iny
    lda.z __14+3
    sta (p),y
    lda.z pdb_number
    sta.z __15
    lda #0
    sta.z __15+1
    asl.z __16
    rol.z __16+1
    asl.z __16
    rol.z __16+1
    asl.z __16
    rol.z __16+1
    asl.z __16
    rol.z __16+1
    asl.z __16
    rol.z __16+1
    asl.z __16
    rol.z __16+1
    clc
    lda.z __17
    adc #<process_context_states
    sta.z __17
    lda.z __17+1
    adc #>process_context_states
    sta.z __17+1
    // This assigns 64 bytes for an array to hold the context switching state of each process
    // Joel: stored_state is a pointer (actually it's the start of an array), so this is a pointer to a pointer
    // Joel: the stored state pointer is assigned the start of the range + pdb_number * 64 (== left bit shift 6)
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORED_STATE
    lda.z __17
    sta (p),y
    iny
    lda.z __17+1
    sta (p),y
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORED_STATE
    lda (ss),y
    pha
    iny
    lda (ss),y
    sta.z ss+1
    pla
    sta.z ss
    ldy #0
  // XXX - Set all 64 bytes of the array 'ss' to zero, to clear the context switching state
  __b4:
    cpy #$3f
    bcc __b5
    // Set standard CPU flags (8-bit stack, interrupts disabled)
    // Joel: not entirely sure what setting $24 in this location does
    lda #$24
    ldy #7
    sta (ss),y
    // XXX - Set the stack pointer to $01FF
    // Joel: I think this saves a pointer to the start of the MEMORY STACK (at function invocation) for this process. 
    // So far we've just set up the memory space for saving the process metadata.
    // $D645 might hold address of our storage memory?
    // This requires a bit of fiddly pointer arithmetic, so to save you the trouble working it out,
    // you can use the following as the left side of the expression:
    ldy #5
    lda #<$1ff
    sta (ss),y
    iny
    lda #>$1ff
    sta (ss),y
    // XXX - Set the program counter to $080D
    // Joel: I think this is the pointer to the start of the INSTRUCTIONS for this process.
    // (This requires a bit of fiddly pointer arithmetic, so to save you
    // the trouble working it out, you can use the following as the left side of the expression:
    ldy #8
    lda #<$80d
    sta (ss),y
    iny
    lda #>$80d
    sta (ss),y
    rts
  __b5:
    lda #0
    sta (ss),y
    iny
    jmp __b4
  __b2:
    ldy #0
    lda (name),y
    sta (pn),y
    inc.z pn
    bne !+
    inc.z pn+1
  !:
    inc.z name
    bne !+
    inc.z name+1
  !:
    jmp __b1
}
// FUNCTION to find the next available processor id (I think assumes 8 processors)
next_free_pid: {
    .label __2 = $7f
    .label pid = $17
    .label p = $7f
    .label i = $18
    inc.z pid_counter
    // Start with the next process ID
    lda.z pid_counter
    sta.z pid
    ldx #1
  __b1:
    cpx #0
    bne b1
    rts
  b1:
    ldx #0
    txa
    sta.z i
    sta.z i+1
  __b2:
    lda.z i+1
    cmp #>8
    bcc __b3
    bne !+
    lda.z i
    cmp #<8
    bcc __b3
  !:
    jmp __b1
  __b3:
    lda.z i
    sta.z __2+1
    lda #0
    sta.z __2
    clc
    lda.z p
    adc #<stored_pdbs
    sta.z p
    lda.z p+1
    adc #>stored_pdbs
    sta.z p+1
    ldy #0
    lda (p),y
    cmp.z pid
    bne __b4
    inc.z pid
    ldx #1
  __b4:
    inc.z i
    bne !+
    inc.z i+1
  !:
    jmp __b2
}
// Copies the character c (an unsigned char) to the first num characters of the object pointed to by the argument str.
// memset(void* zeropage($1c) str, byte register(X) c, word zeropage($1a) num)
memset: {
    .label end = $1a
    .label dst = $1c
    .label num = $1a
    .label str = $1c
    lda.z num
    bne !+
    lda.z num+1
    beq __breturn
  !:
    lda.z end
    clc
    adc.z str
    sta.z end
    lda.z end+1
    adc.z str+1
    sta.z end+1
  __b2:
    lda.z dst+1
    cmp.z end+1
    bne __b3
    lda.z dst
    cmp.z end
    bne __b3
  __breturn:
    rts
  __b3:
    txa
    ldy #0
    sta (dst),y
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    jmp __b2
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
    // Saves an IPC message from the current process into the queue for delivery to another process
    // Initialise an IPC Message pointer to point to $0300
    .label m = $300
    .label __1 = $84
    .label __2 = $84
    .label pdb = $84
    lda.z running_pdb
    sta.z __1
    lda #0
    sta.z __1+1
    lda.z __2
    sta.z __2+1
    lda #0
    sta.z __2
    clc
    lda.z pdb
    adc #<stored_pdbs
    sta.z pdb
    lda.z pdb+1
    adc #>stored_pdbs
    sta.z pdb+1
    ldy #0
    lda (pdb),y
    tax
    lda m+OFFSET_STRUCT_IPC_MESSAGE_TO
    sta.z queue_message.to
    lda m+OFFSET_STRUCT_IPC_MESSAGE_PRIORITY
    sta.z queue_message.priority
    lda m+OFFSET_STRUCT_IPC_MESSAGE_SEQUENCE
    sta.z queue_message.sequence
    jsr queue_message
    jsr exit_hypervisor
    rts
}
// FUNCTION: if the queue has space (<16) then this creates a new struct and copies the passed parameters into it
// queue_message(byte register(X) from, byte zeropage($81) to, byte zeropage($82) priority, byte zeropage($83) sequence)
queue_message: {
    // Queue the message
    .label message = syscall0A.m+OFFSET_STRUCT_IPC_MESSAGE_MESSAGE
    .label __8 = $86
    .label __9 = $86
    .label __18 = $88
    .label m = $84
    .label pdb = $86
    .label to = $81
    .label priority = $82
    .label sequence = $83
    lda.z ipc_message_count
    cmp #$f+1
    bcc __b1
    rts
  __b1:
    lda.z ipc_message_count
    asl
    asl
    asl
    asl
    clc
    adc #<ipc_messages
    sta.z m
    lda #>ipc_messages
    adc #0
    sta.z m+1
    txa
    ldy #0
    sta (m),y
    lda.z to
    ldy #OFFSET_STRUCT_IPC_MESSAGE_TO
    sta (m),y
    lda.z priority
    ldy #OFFSET_STRUCT_IPC_MESSAGE_PRIORITY
    sta (m),y
    lda.z sequence
    ldy #OFFSET_STRUCT_IPC_MESSAGE_SEQUENCE
    sta (m),y
    ldy #0
  __b2:
    cpy #$c
    bcc __b3
    ldx #0
  // Change the state of the "to" process. The "to" field is a process id. This code finds the associated process descriptor block. 
  __b4:
    cpx #8
    bcc __b5
    inc.z ipc_message_count
    rts
  __b5:
    txa
    sta.z __8
    lda #0
    sta.z __8+1
    lda.z __9
    sta.z __9+1
    lda #0
    sta.z __9
    clc
    lda.z pdb
    adc #<stored_pdbs
    sta.z pdb
    lda.z pdb+1
    adc #>stored_pdbs
    sta.z pdb+1
    ldy #0
    lda (pdb),y
    cmp.z to
    bne __b7
    lda #STATE_READY
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_STATE
    sta (pdb),y
  __b7:
    inx
    jmp __b4
  __b3:
    lda #OFFSET_STRUCT_IPC_MESSAGE_MESSAGE
    clc
    adc.z m
    sta.z __18
    lda #0
    adc.z m+1
    sta.z __18+1
    lda message,y
    sta (__18),y
    iny
    jmp __b2
}
syscall09: {
    .label __1 = $8c
    .label __2 = $8c
    .label __13 = $8e
    .label pdb = $8c
    .label message_id = $8b
    .label m = $9a
    lda.z running_pdb
    sta.z __1
    lda #0
    sta.z __1+1
    lda.z __2
    sta.z __2+1
    lda #0
    sta.z __2
    clc
    lda.z pdb
    adc #<stored_pdbs
    sta.z pdb
    lda.z pdb+1
    adc #>stored_pdbs
    sta.z pdb+1
    ldy #0
    lda (pdb),y
    sta.z get_next_message_id.receiver
    jsr get_next_message_id
    lda.z get_next_message_id.best_message
    sta.z message_id
    lda #$ff
    cmp.z message_id
    bne __b1
    ldx #0
  __b4:
    cpx #$10
    bcc __b5
    lda #STATE_BLOCKED
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_STATE
    sta (pdb),y
    lda.z running_pdb
    jsr pause_pdb
    jsr syscall05
  __b1:
    lda #$ff
    cmp.z message_id
    beq __b2
    lda.z message_id
    jsr get_pointer_to_message
    lda.z m
    sta.z dma_copy.src
    lda.z m+1
    sta.z dma_copy.src+1
    lda #0
    sta.z dma_copy.src+2
    sta.z dma_copy.src+3
    lda #<$300
    sta.z dma_copy.dest
    lda #>$300
    sta.z dma_copy.dest+1
    lda #<$300>>$10
    sta.z dma_copy.dest+2
    lda #>$300>>$10
    sta.z dma_copy.dest+3
    lda #<$10
    sta.z dma_copy.length
    lda #>$10
    sta.z dma_copy.length+1
    jsr dma_copy
    lda.z message_id
    jsr dequeue_message
    jsr exit_hypervisor
  __b2:
    jsr exit_hypervisor
    rts
  __b5:
    txa
    clc
    adc #<$300
    sta.z __13
    lda #>$300
    adc #0
    sta.z __13+1
    lda #$ff
    ldy #0
    sta (__13),y
    inx
    jmp __b4
}
// FUNCTION: removes an IPC message from the queue (by copying the last message in the queue over it and decrementing the message count)
// dequeue_message(byte register(A) message_num)
dequeue_message: {
    .label dest = $9a
    .label src = $8e
    .label last = $8c
    cmp.z ipc_message_count
    bcc __b1
    rts
  __b1:
    ldx.z ipc_message_count
    dex
    tay
    stx.z $ff
    cpy.z $ff
    bne __b2
    lda.z ipc_message_count
    sec
    sbc #1
    asl
    asl
    asl
    asl
    clc
    adc #<ipc_messages
    sta.z last
    lda #>ipc_messages
    adc #0
    sta.z last+1
    ldy #0
  __b4:
    cpy #$10
    bcc __b5
    dec.z ipc_message_count
    rts
  __b5:
    lda #$ff
    sta (last),y
    iny
    jmp __b4
  __b2:
    asl
    asl
    asl
    asl
    clc
    adc #<ipc_messages
    sta.z dest
    lda #>ipc_messages
    adc #0
    sta.z dest+1
    lda.z ipc_message_count
    sec
    sbc #1
    asl
    asl
    asl
    asl
    clc
    adc #<ipc_messages
    sta.z src
    lda #>ipc_messages
    adc #0
    sta.z src+1
    ldx #0
  __b7:
    cpx #$10
    bcc __b8
    ldy #0
  __b9:
    cpy #$10
    bcc __b10
    dec.z ipc_message_count
    rts
  __b10:
    lda #$ff
    sta (src),y
    iny
    jmp __b9
  __b8:
    stx.z $ff
    txa
    tay
    lda (src),y
    sta (dest),y
    inx
    jmp __b7
}
// FUNCTION: returns the address of the IPC message number passed to it
// get_pointer_to_message(byte register(A) id)
get_pointer_to_message: {
    .label return = $9a
    asl
    asl
    asl
    asl
    clc
    adc #<ipc_messages
    sta.z return
    lda #>ipc_messages
    adc #0
    sta.z return+1
    rts
}
syscall05: {
    .label __9 = $90
    .label __10 = $90
    .label next_pdb = $1f
    .label pdb = $90
    // Yield the running process to another process
    // Restarts the last process if no other ready process is found
    lda.z running_pdb
    sta.z next_pdb
    cmp #8
    bcs __b1
    lda.z running_pdb
    jsr pause_pdb
  __b1:
    ldx #0
  //only pauses a pdb is one is currently running (i.e. if running_pdb is not set to FF)
  __b3:
    cpx #8
    bcc __b4
  __b7:
    lda.z next_pdb
    sta.z resume_pdb.pdb_number
    jsr resume_pdb
    jsr exit_hypervisor
    rts
  __b4:
    cpx.z next_pdb
    bne __b5
  __b6:
    inx
    jmp __b3
  __b5:
    txa
    sta.z __9
    lda #0
    sta.z __9+1
    lda.z __10
    sta.z __10+1
    lda #0
    sta.z __10
    clc
    lda.z pdb
    adc #<stored_pdbs
    sta.z pdb
    lda.z pdb+1
    adc #>stored_pdbs
    sta.z pdb+1
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_STATE
    lda (pdb),y
    cmp #STATE_READY
    bne __b6
    stx.z next_pdb
    jmp __b7
}
// FUNCTION to PAUSE a RUNNING process, to make it READY
// Joel: I think it can also be used to copy a parent process into a child process 
// pause_pdb(byte register(A) pdb_number)
pause_pdb: {
    .label __1 = $92
    .label __2 = $92
    .label __12 = $94
    .label p = $92
    .label ss = $98
    sta.z __1
    lda #0
    sta.z __1+1
    lda.z __2
    sta.z __2+1
    lda #0
    sta.z __2
    clc
    lda.z p
    adc #<stored_pdbs
    sta.z p
    lda.z p+1
    adc #>stored_pdbs
    sta.z p+1
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORAGE_START_ADDRESS
    lda (p),y
    sta.z dma_copy.dest
    iny
    lda (p),y
    sta.z dma_copy.dest+1
    iny
    lda (p),y
    sta.z dma_copy.dest+2
    iny
    lda (p),y
    sta.z dma_copy.dest+3
    lda #<0
    sta.z dma_copy.src
    sta.z dma_copy.src+1
    lda #<0>>$10
    sta.z dma_copy.src+2
    lda #>0>>$10
    sta.z dma_copy.src+3
    lda #<$400
    sta.z dma_copy.length
    lda #>$400
    sta.z dma_copy.length+1
    jsr dma_copy
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORAGE_START_ADDRESS
    lda (p),y
    sta.z __12
    iny
    lda (p),y
    sta.z __12+1
    iny
    lda (p),y
    sta.z __12+2
    iny
    lda (p),y
    sta.z __12+3
    lda.z __12
    clc
    adc #<$800
    sta.z dma_copy.dest
    lda.z __12+1
    adc #>$800
    sta.z dma_copy.dest+1
    lda.z __12+2
    adc #<$800>>$10
    sta.z dma_copy.dest+2
    lda.z __12+3
    adc #>$800>>$10
    sta.z dma_copy.dest+3
    lda #<$800
    sta.z dma_copy.src
    lda #>$800
    sta.z dma_copy.src+1
    lda #<$800>>$10
    sta.z dma_copy.src+2
    lda #>$800>>$10
    sta.z dma_copy.src+3
    lda #<$1800
    sta.z dma_copy.length
    lda #>$1800
    sta.z dma_copy.length+1
    jsr dma_copy
    // Copy Hypervisor saved register area (at $FFD3640??) into stored CPU state 
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORED_STATE
    lda (p),y
    sta.z ss
    iny
    lda (p),y
    sta.z ss+1
    ldy #0
  // XXX - Use a for() loop to copy 63 bytes from 
  // ((unsigned char *)$D640)[0]--((unsigned char *)$D640)[62] to ss[0]--ss[62] 
  __b1:
    cpy #$3f
    bcc __b2
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_STATE
    lda (p),y
    cmp #STATE_RUNNING
    bne __breturn
    // Set state of process to ready
    lda #STATE_READY
    sta (p),y
    // Change the running process to no process
    lda #$ff
    sta.z running_pdb
  __breturn:
    rts
  __b2:
    lda $d640,y
    sta (ss),y
    iny
    jmp __b1
}
// FUNCTION: find the next message addressed to the Process ID passed in (will return a number from 0 to 15)
// get_next_message_id(byte zeropage($8a) receiver)
get_next_message_id: {
    .label m = $9a
    .label highest_priority = $21
    .label receiver = $8a
    .label best_message = $8b
    lda #0
    sta.z highest_priority
    lda #$ff
    sta.z best_message
    ldx #0
  // loops through the IPC messages to find the best match for this receiver (based on highest_priority)
  __b1:
    cpx #$10
    bcc __b2
    rts
  __b2:
    txa
    asl
    asl
    asl
    asl
    clc
    adc #<ipc_messages
    sta.z m
    lda #>ipc_messages
    adc #0
    sta.z m+1
    ldy #OFFSET_STRUCT_IPC_MESSAGE_TO
    lda (m),y
    cmp.z receiver
    bne __b3
    ldy #OFFSET_STRUCT_IPC_MESSAGE_PRIORITY
    lda (m),y
    ldy.z highest_priority
    sta.z $ff
    cpy.z $ff
    bcs __b3
    ldy #OFFSET_STRUCT_IPC_MESSAGE_PRIORITY
    lda (m),y
    sta.z highest_priority
    stx.z best_message
  __b3:
    inx
    jmp __b1
}
syscall08: {
    .label __1 = $9c
    .label __2 = $9c
    .label pdb = $9c
    .label pname = $24
    .label oname = $22
    .label ss = $9c
    lda.z running_pdb
    sta.z __1
    lda #0
    sta.z __1+1
    lda.z __2
    sta.z __2+1
    lda #0
    sta.z __2
    clc
    lda.z pdb
    adc #<stored_pdbs
    sta.z pdb
    lda.z pdb+1
    adc #>stored_pdbs
    sta.z pdb+1
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_NAME
    lda (pdb),y
    sta.z pname
    iny
    lda (pdb),y
    sta.z pname+1
    lda #<$300
    sta.z oname
    lda #>$300
    sta.z oname+1
  __b1:
    ldy #0
    lda (oname),y
    cmp #0
    bne __b2
    tya
    tay
    sta (pname),y
    lda.z running_pdb
    jsr load_program
    // setup new program
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORED_STATE
    lda (ss),y
    pha
    iny
    lda (ss),y
    sta.z ss+1
    pla
    sta.z ss
    ldy #0
  __b4:
    cpy #$3f
    bcc __b5
    lda #$24
    ldy #7
    sta (ss),y
    ldy #5
    lda #<$1ff
    sta (ss),y
    iny
    lda #>$1ff
    sta (ss),y
    ldy #8
    lda #<$80d
    sta (ss),y
    iny
    lda #>$80d
    sta (ss),y
    lda.z running_pdb
    sta.z resume_pdb.pdb_number
    jsr resume_pdb
    jsr exit_hypervisor
    rts
  __b5:
    lda #0
    sta (ss),y
    iny
    jmp __b4
  __b2:
    ldy #0
    lda (oname),y
    sta (pname),y
    inc.z pname
    bne !+
    inc.z pname+1
  !:
    inc.z oname
    bne !+
    inc.z oname+1
  !:
    jmp __b1
}
syscall07: {
    .label __5 = $a1
    .label __6 = $a1
    .label __13 = $9f
    .label __14 = $9f
    .label parent_pdb = $9e
    .label pdb = $9f
    .label i = $26
    .label p = $a1
    .label child_pdb = $26
    // Forks the current process
    lda.z running_pdb
    sta.z parent_pdb
    lda.z running_pdb
    jsr pause_pdb
    lda #0
    sta.z i
  __b1:
    lda.z i
    cmp #8
    bcc __b2
    lda #0
    sta.z child_pdb
    jmp __b4
  __b2:
    lda.z i
    sta.z __13
    lda #0
    sta.z __13+1
    lda.z __14
    sta.z __14+1
    lda #0
    sta.z __14
    clc
    lda.z pdb
    adc #<stored_pdbs
    sta.z pdb
    lda.z pdb+1
    adc #>stored_pdbs
    sta.z pdb+1
    ldy #0
    lda (pdb),y
    cmp #0
    bne __b3
  __b4:
    lda.z child_pdb
    sta.z initialise_pdb.pdb_number
    lda #<name
    sta.z initialise_pdb.name
    lda #>name
    sta.z initialise_pdb.name+1
    jsr initialise_pdb
    lda #0
    sta $300
    lda.z child_pdb
    jsr pause_pdb
    lda.z child_pdb
    sta.z __5
    lda #0
    sta.z __5+1
    lda.z __6
    sta.z __6+1
    lda #0
    sta.z __6
    clc
    lda.z p
    adc #<stored_pdbs
    sta.z p
    lda.z p+1
    adc #>stored_pdbs
    sta.z p+1
    ldy #0
    lda (p),y
    sta $300
    lda.z parent_pdb
    sta.z running_pdb
    jsr exit_hypervisor
    rts
  __b3:
    inc.z i
    jmp __b1
  .segment Data
    name: .text "temp_child_name"
    .byte 0
}
.segment Code
syscall06: {
    .label __1 = $a3
    .label __2 = $a3
    .label pdb = $a3
    lda.z running_pdb
    sta.z __1
    lda #0
    sta.z __1+1
    lda.z __2
    sta.z __2+1
    lda #0
    sta.z __2
    clc
    lda.z pdb
    adc #<stored_pdbs
    sta.z pdb
    lda.z pdb+1
    adc #>stored_pdbs
    sta.z pdb+1
    lda #<message
    sta.z print_to_screen.c
    lda #>message
    sta.z print_to_screen.c+1
    jsr print_to_screen
    ldy #0
    lda (pdb),y
    sta.z print_hex.value
    tya
    sta.z print_hex.value+1
    jsr print_hex
    lda #<message1
    sta.z print_to_screen.c
    lda #>message1
    sta.z print_to_screen.c+1
    jsr print_to_screen
    lda.z running_pdb
    sta.z print_hex.value
    lda #0
    sta.z print_hex.value+1
    jsr print_hex
    jsr print_newline
    jsr exit_hypervisor
    rts
  .segment Data
    message: .text "you are pid "
    .byte 0
    message1: .text " in pdb "
    .byte 0
}
.segment Code
// FUNCTION to move the screen pointer to a new line
print_newline: {
    lda #$28
    clc
    adc.z current_screen_line
    sta.z current_screen_line
    bcc !+
    inc.z current_screen_line+1
  !:
    lda #0
    sta.z current_screen_x
    rts
}
// FUNCTION to print a value in the hex format
// print_hex(word zeropage($29) value)
print_hex: {
    .label __3 = $a5
    .label __6 = $a7
    .label value = $29
    ldx #0
  __b1:
    cpx #8
    bcc __b2
    lda #0
    sta hex+4
    lda #<hex
    sta.z print_to_screen.c
    lda #>hex
    sta.z print_to_screen.c+1
    jsr print_to_screen
    rts
  __b2:
    lda.z value+1
    cmp #>$a000
    bcc __b4
    bne !+
    lda.z value
    cmp #<$a000
    bcc __b4
  !:
    ldy #$c
    lda.z value
    sta.z __3
    lda.z value+1
    sta.z __3+1
    cpy #0
    beq !e+
  !:
    lsr.z __3+1
    ror.z __3
    dey
    bne !-
  !e:
    lda.z __3
    sec
    sbc #9
    sta hex,x
  __b5:
    asl.z value
    rol.z value+1
    asl.z value
    rol.z value+1
    asl.z value
    rol.z value+1
    asl.z value
    rol.z value+1
    inx
    jmp __b1
  __b4:
    ldy #$c
    lda.z value
    sta.z __6
    lda.z value+1
    sta.z __6+1
    cpy #0
    beq !e+
  !:
    lsr.z __6+1
    ror.z __6
    dey
    bne !-
  !e:
    lda.z __6
    clc
    adc #'0'
    sta hex,x
    jmp __b5
  .segment Data
    hex: .fill 5, 0
}
.segment Code
// FUNCTION to print a string message at the current screen pointer
print_to_screen: {
    .label c = $29
  __b1:
    ldy #0
    lda (c),y
    cmp #0
    bne __b2
    rts
  __b2:
    ldy #0
    lda (c),y
    ldy.z current_screen_x
    sta (current_screen_line),y
    inc.z current_screen_x
    inc.z c
    bne !+
    inc.z c+1
  !:
    jmp __b1
}
syscall04: {
    jsr exit_hypervisor
    rts
}
syscall03: {
    ldx.z running_pdb
    jsr describe_pdb
    jsr exit_hypervisor
    rts
}
// FUNCTION to describe/print a Process Control Block
// describe_pdb(byte register(X) pdb_number)
describe_pdb: {
    .label __1 = $a9
    .label __2 = $a9
    .label p = $a9
    .label n = $ab
    .label ss = $a9
    txa
    sta.z __1
    lda #0
    sta.z __1+1
    lda.z __2
    sta.z __2+1
    lda #0
    sta.z __2
    clc
    lda.z p
    adc #<stored_pdbs
    sta.z p
    lda.z p+1
    adc #>stored_pdbs
    sta.z p+1
    lda #<message
    sta.z print_to_screen.c
    lda #>message
    sta.z print_to_screen.c+1
    jsr print_to_screen
    txa
    sta.z print_hex.value
    lda #0
    sta.z print_hex.value+1
    jsr print_hex
    lda #<message1
    sta.z print_to_screen.c
    lda #>message1
    sta.z print_to_screen.c+1
    jsr print_to_screen
    jsr print_newline
    lda #<message2
    sta.z print_to_screen.c
    lda #>message2
    sta.z print_to_screen.c+1
    jsr print_to_screen
    ldy #0
    lda (p),y
    sta.z print_hex.value
    iny
    lda #0
    sta.z print_hex.value+1
    jsr print_hex
    jsr print_newline
    lda #<message3
    sta.z print_to_screen.c
    lda #>message3
    sta.z print_to_screen.c+1
    jsr print_to_screen
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_STATE
    lda (p),y
    cmp #STATE_NEW
    bne !__b7+
    jmp __b7
  !__b7:
    lda (p),y
    cmp #STATE_RUNNING
    bne !__b8+
    jmp __b8
  !__b8:
    lda (p),y
    cmp #STATE_BLOCKED
    bne !__b9+
    jmp __b9
  !__b9:
    lda (p),y
    cmp #STATE_READY
    bne !__b10+
    jmp __b10
  !__b10:
    lda (p),y
    cmp #STATE_BLOCKEDSUSPENDED
    bne !__b11+
    jmp __b11
  !__b11:
    lda (p),y
    cmp #STATE_READYSUSPENDED
    bne !__b12+
    jmp __b12
  !__b12:
    lda (p),y
    cmp #STATE_EXIT
    bne !__b13+
    jmp __b13
  !__b13:
    lda (p),y
    sta.z print_hex.value
    iny
    lda #0
    sta.z print_hex.value+1
    jsr print_hex
  __b15:
    jsr print_newline
    lda #<message11
    sta.z print_to_screen.c
    lda #>message11
    sta.z print_to_screen.c+1
    jsr print_to_screen
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_PROCESS_NAME
    lda (p),y
    sta.z n
    iny
    lda (p),y
    sta.z n+1
    ldx #0
  __b16:
    txa
    tay
    lda (n),y
    cmp #0
    bne __b17
    jsr print_newline
    lda #<message12
    sta.z print_to_screen.c
    lda #>message12
    sta.z print_to_screen.c+1
    jsr print_to_screen
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORAGE_START_ADDRESS
    lda (p),y
    sta.z print_dhex.value
    iny
    lda (p),y
    sta.z print_dhex.value+1
    iny
    lda (p),y
    sta.z print_dhex.value+2
    iny
    lda (p),y
    sta.z print_dhex.value+3
    jsr print_dhex
    jsr print_newline
    lda #<message13
    sta.z print_to_screen.c
    lda #>message13
    sta.z print_to_screen.c+1
    jsr print_to_screen
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORAGE_END_ADDRESS
    lda (p),y
    sta.z print_dhex.value
    iny
    lda (p),y
    sta.z print_dhex.value+1
    iny
    lda (p),y
    sta.z print_dhex.value+2
    iny
    lda (p),y
    sta.z print_dhex.value+3
    jsr print_dhex
    jsr print_newline
    lda #<message14
    sta.z print_to_screen.c
    lda #>message14
    sta.z print_to_screen.c+1
    jsr print_to_screen
    ldy #OFFSET_STRUCT_PROCESS_DESCRIPTOR_BLOCK_STORED_STATE
    lda (ss),y
    pha
    iny
    lda (ss),y
    sta.z ss+1
    pla
    sta.z ss
    ldy #4*SIZEOF_WORD
    lda (ss),y
    sta.z print_hex.value
    iny
    lda (ss),y
    sta.z print_hex.value+1
    jsr print_hex
    jsr print_newline
    rts
  __b17:
    txa
    tay
    lda (n),y
    jsr print_char
    inx
    jmp __b16
  __b13:
    lda #<message10
    sta.z print_to_screen.c
    lda #>message10
    sta.z print_to_screen.c+1
    jsr print_to_screen
    jmp __b15
  __b12:
    lda #<message9
    sta.z print_to_screen.c
    lda #>message9
    sta.z print_to_screen.c+1
    jsr print_to_screen
    jmp __b15
  __b11:
    lda #<message8
    sta.z print_to_screen.c
    lda #>message8
    sta.z print_to_screen.c+1
    jsr print_to_screen
    jmp __b15
  __b10:
    lda #<message7
    sta.z print_to_screen.c
    lda #>message7
    sta.z print_to_screen.c+1
    jsr print_to_screen
    jmp __b15
  __b9:
    lda #<message6
    sta.z print_to_screen.c
    lda #>message6
    sta.z print_to_screen.c+1
    jsr print_to_screen
    jmp __b15
  __b8:
    lda #<message5
    sta.z print_to_screen.c
    lda #>message5
    sta.z print_to_screen.c+1
    jsr print_to_screen
    jmp __b15
  __b7:
    lda #<message4
    sta.z print_to_screen.c
    lda #>message4
    sta.z print_to_screen.c+1
    jsr print_to_screen
    jmp __b15
  .segment Data
    message: .text "pdb#"
    .byte 0
    message1: .text ":"
    .byte 0
    message2: .text "  pid:          "
    .byte 0
    message3: .text "  state:        "
    .byte 0
    message4: .text "new"
    .byte 0
    message5: .text "running"
    .byte 0
    message6: .text "blocked"
    .byte 0
    message7: .text "ready"
    .byte 0
    message8: .text "blockedsuspended"
    .byte 0
    message9: .text "readysuspended"
    .byte 0
    message10: .text "exit"
    .byte 0
    message11: .text "  process name: "
    .byte 0
    message12: .text "  mem start:    $"
    .byte 0
    message13: .text "  mem end:      $"
    .byte 0
    message14: .text "  pc:           $"
    .byte 0
}
.segment Code
// FUNCTION to print a character at the current screen pointer
// print_char(byte register(A) c)
print_char: {
    ldy.z current_screen_x
    sta (current_screen_line),y
    inc.z current_screen_x
    rts
}
// FUNCTION to print a larger value in hex format
// print_dhex(dword zeropage($2c) value)
print_dhex: {
    .label __0 = $ad
    .label value = $2c
    lda #0
    sta.z __0+2
    sta.z __0+3
    lda.z value+3
    sta.z __0+1
    lda.z value+2
    sta.z __0
    sta.z print_hex.value
    lda.z __0+1
    sta.z print_hex.value+1
    jsr print_hex
    lda.z value
    sta.z print_hex.value
    lda.z value+1
    sta.z print_hex.value+1
    jsr print_hex
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
// SYSCALL FUNCTIONS
syscall00: {
    jsr exit_hypervisor
    rts
}
.segment Syscall
  // Now we can have a nice table of up to 64 SYSCALL handlers expressed in a fairly readable and easy format.
  // Each line is an instance of the struct SysCall from above, with the JMP opcode value, the address of the handler
  // routine and the NOP opcode value.
  SYSCALLS: .byte JMP
  .word syscall00
  .byte NOP, JMP
  .word syscall01
  .byte NOP, JMP
  .word syscall02
  .byte NOP, JMP
  .word syscall03
  .byte NOP, JMP
  .word syscall04
  .byte NOP, JMP
  .word syscall05
  .byte NOP, JMP
  .word syscall06
  .byte NOP, JMP
  .word syscall07
  .byte NOP, JMP
  .word syscall08
  .byte NOP, JMP
  .word syscall09
  .byte NOP, JMP
  .word syscall0A
  .byte NOP, JMP
  .word syscall0B
  .byte NOP, JMP
  .word syscall0C
  .byte NOP, JMP
  .word syscall0D
  .byte NOP, JMP
  .word syscall0E
  .byte NOP, JMP
  .word syscall0F
  .byte NOP, JMP
  .word syscall10
  .byte NOP, JMP
  .word securentr
  .byte NOP, JMP
  .word securexit
  .byte NOP, JMP
  .word syscall13
  .byte NOP, JMP
  .word syscall14
  .byte NOP, JMP
  .word syscall15
  .byte NOP, JMP
  .word syscall16
  .byte NOP, JMP
  .word syscall17
  .byte NOP, JMP
  .word syscall18
  .byte NOP, JMP
  .word syscall19
  .byte NOP, JMP
  .word syscall1A
  .byte NOP, JMP
  .word syscall1B
  .byte NOP, JMP
  .word syscall1C
  .byte NOP, JMP
  .word syscall1D
  .byte NOP, JMP
  .word syscall1E
  .byte NOP, JMP
  .word syscall1F
  .byte NOP, JMP
  .word syscall20
  .byte NOP, JMP
  .word syscall21
  .byte NOP, JMP
  .word syscall22
  .byte NOP, JMP
  .word syscall23
  .byte NOP, JMP
  .word syscall24
  .byte NOP, JMP
  .word syscall25
  .byte NOP, JMP
  .word syscall26
  .byte NOP, JMP
  .word syscall27
  .byte NOP, JMP
  .word syscall28
  .byte NOP, JMP
  .word syscall29
  .byte NOP, JMP
  .word syscall2A
  .byte NOP, JMP
  .word syscall2B
  .byte NOP, JMP
  .word syscall2C
  .byte NOP, JMP
  .word syscall2D
  .byte NOP, JMP
  .word syscall2E
  .byte NOP, JMP
  .word syscall2F
  .byte NOP, JMP
  .word syscall30
  .byte NOP, JMP
  .word syscall31
  .byte NOP, JMP
  .word syscall32
  .byte NOP, JMP
  .word syscall33
  .byte NOP, JMP
  .word syscall34
  .byte NOP, JMP
  .word syscall35
  .byte NOP, JMP
  .word syscall36
  .byte NOP, JMP
  .word syscall37
  .byte NOP, JMP
  .word syscall38
  .byte NOP, JMP
  .word syscall39
  .byte NOP, JMP
  .word syscall3A
  .byte NOP, JMP
  .word syscall3B
  .byte NOP, JMP
  .word syscall3C
  .byte NOP, JMP
  .word syscall3D
  .byte NOP, JMP
  .word syscall3E
  .byte NOP, JMP
  .word syscall3F
  .byte NOP
  // Originally we had only two SYSCALLs defined, so "align" tells KickC to
  //  make the TRAP table begin at the next multiple of $100, i.e., at $8100.
  .align $100
  TRAPS: .byte JMP
  .word reset
  .byte NOP, JMP
  .word pagfault
  .byte NOP, JMP
  .word restorkey
  .byte NOP, JMP
  .word alttabkey
  .byte NOP, JMP
  .word vF011rd
  .byte NOP, JMP
  .word vF011wr
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word reserved
  .byte NOP, JMP
  .word cpukil
  .byte NOP
