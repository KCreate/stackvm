.def STACK_SIZE (4096 * -8)
.def myconst 500
.def myconsttimesfive (myconst * 5)

.db myname (byte * 7) "leonard"

jmp (myfunction + 25)

.label myfunction
