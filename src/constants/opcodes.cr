module Constants
  enum Opcode : UInt8
    RPUSH
    RPOP
    MOV
    LOADI
    RST

    ADD
    SUB
    MUL
    DIV
    IDIV
    REM
    IREM

    FADD
    FSUB
    FMUL
    FDIV
    FREM
    FEXP

    FLT
    FGT

    CMP
    LT
    GT
    ULT
    UGT

    SHR
    SHL
    AND
    XOR
    OR
    NOT

    INTTOFP
    SINTTOFP
    FPTOINT

    LOAD
    LOADR
    LOADS
    LOADSR
    STORE
    PUSH

    READ
    READC
    READS
    READCS
    WRITE
    WRITEC
    WRITES
    WRITECS
    COPY
    COPYC

    JZ
    JZR
    JMP
    JMPR
    CALL
    CALLR
    RET

    NOP
    SYSCALL
  end

  # Lookup table for instruction lengths
  INSTRUCTION_LENGTH = [
    2, # rpush
    2, # rpop
    3, # mov
    0, # loadi (this is calculated in the vm itself)
    2, # rst

    3, # add
    3, # sub
    3, # mul
    3, # div
    3, # idiv
    3, # rem
    3, # irem

    3, # fadd
    3, #  fsub
    3, # fmul
    3, # fdiv
    3, #  frem
    3, # fexp

    3, # flt
    3, #  fgt

    3, # cmp
    3, #  lt
    3, # gt
    3, # ult
    3, #  ugt

    3, # shr
    3, #  shl
    3, # and
    3, #  xor
    3, #  or
    2, #  not

    2, # inttofp
    2, # sinttofp
    2, # fptoint

    6, # load
    3, #  loadr
    9, # loads
    6, #  loadsr
    6, #  store
    0, # push (this is calculated in the vm itself)

    3,  #  read
    6,  #  readc
    6,  #  reads
    9,  # readcs
    3,  # write
    6,  #  writec
    6,  # writes
    9,  # writecs
    7,  #  copy
    13, # copyc

    5, # jz
    2, #  jzr
    5, #  jmp
    2, # jmpr
    5, #  call
    2, #  callr
    1, # ret

    1, #  nop
    1, #  syscall
  ] of Int32
end
