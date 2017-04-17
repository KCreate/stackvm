.def calc r4q
.def s1 r0q
.def s2 r1q
.def s3 r2q
.def s4 r3q

loadi s1, 5
loadi s2, -5
loadi s3, 5.5
loadi s4, -5.5


mov calc, s1
inttofp calc, calc

mov calc, s2
inttofp calc, calc

mov calc, s1
sinttofp calc, calc

mov calc, s2
sinttofp calc, calc

mov calc, s3
fptoint calc, calc

mov calc, s4
fptoint calc, calc
