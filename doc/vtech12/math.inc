;
; Single precision numbers are stored in four bytes of memory (or
; sometimes two register pairs f such as BC and DE), while double
; precision numbers take eight bytes of memory. However, the formats
;for single and double precision are exactly the same, except that
;double precision numbers have four more bytes. Therefore , anything
;that is said about single precision numbers also applies equally to
;double precision,, if you change the byte count accordingly.

; If we talk about "the remaining three bytes" of a single precision 
; number, you can usually figure that the same thing will apply 
; to "the remaining seven bytes" of a double precision number.

; A single precision number is stored in memory in the following format:
;   LSB     2SB     MSB     EXP
; A double precision number is stored in this manner;
;   LSB     6SB     5SB     4SB     3SB     2SB     MSB     EXP

; In the above examples, MSB indicates the Most Significant Byte, 
; S2B is the 2nd most Significant Byte, and so on to the Least 
; Significant Byte (LSB), EXB stands for the Exponent byte.

; To decode a number in memory, start with the exponent byte. If this byte contains zero, 
; the number is zero regardless of what the other bytes may contain. 

; if EXP == 0 => Number = 0

; Otherwise, take the number found in the exponent byte and subtract 128 
; to get the actual exponent. Another way to think of this is that the leftmost bit 
; of the exponent byte will be set if the exponent is positive, or will equal zero 
; if the exponent is negative. The rightmost seven bits contain the actual exponent value,
; which can be read "as is" for a positive exponent. If the exponent is negative, 
; the rightmost seven bits must be complemented, and then have a value of one added, 
; to produce the proper negative exponent. It's easier to just subtract 128 decimal (80H) 
; from the value found in the exponent byte. 
; NOTE: if the exponent byte contains 128 decimal, onr exponent will be zero (which does NOT mean 
; that the number is zero - for that the exponent byte itself must be zero).

; Next, look at the Most Significant Byte. If the leftmost bit of that byte is set, the number 
; is negative, but if it's a zero the number is positive (note that we are talking about 
; the number itself here, whereas before we were dealing with the sign of the exponent).
; Now that you know the sign of the number, treat the leftmost bit as if it were set (a binary "1")
; and write down the bits of the MSB.

; Continue to write out the bits of the remaining bytes, until yon have written out the LSB. 
; Place a decimal point to the left of the resulting binary number. 
; At this point, your number should be written out in this format:
;   .1bbbbbbb   bbbbbbbb    bbbbbbbb    (... continue if Double Precision)
;   MSB         S2B         LSB         (S3B,S4B,...)
; Again note that the first digit of the MSB (which contained the sign
; bit) has been changed to a one,
; Next, take the exponent value and move the decimal point that many places,
; If the exponent was positive, move the decimal point that number of places
; to the right, while a negative exponent moves the decimal point to the left 
; (in which case you'll have to add leading zeros as required).

; Suppose we want to decode the binary number 10110,01101, Here's how it's done: 
;   1   0   1   1   0   ,   0   1   1       0       1
;   16  8   4   2   1   ,   1/2 1/4 1/8     1/16    1/32
;                           .5  .25 .125    .0625   .3125 
; = 16 + 4 + 2 + .25 + .125 + .3125 = 22.40626




; STRING VECTORS

;        struct StrVec
;LEN     byte
;ADDR    word
;        ends




; NUMBER TYPES

; The VZ Math uses a single digit as a number type indicator. 
; This digit is the number of bytes required to store a given type of number:
;   2 - integer
;   4 - single-precision number
;   8 - double-precision number
;   3 - the number of bytes required for the string vector
; The number type indicator digit figures in all arithmetic operations
; and number currently being processed is stored in NUMBER TYPE FLAG - NTF
; which is located at 78af. 
; This flag is generally associated with the number currently stored 
; in the primary ACCUMULATOR. 



; SMC Sub - Self Modified Code Subtract routine
; IN: bhl - 24 bit integer to subtract from
;     a - LSB of bhl integer (a == l)
; OUT bhl - 24 bit result 
;     a - 0  
MAT.SubBHLCust   equ $7880   ; routine entry
MAT.SubBHLArgL  equ $7881   ; LSB of value to subtract from BHL
MAT.SubBHLArgH  equ $7885   ; SB2 of value to subtract from BHL
MAT.SubBHLArgB  equ $7889   ; MB2 of value to subtract from BHL
MAT.SubBHLRetA  equ $788c   ; result value returned in A

; ACCUMULATORS

; The two arithmetic accumulators in the memory are located:
;   791d to 7824 (8 bytes) 
;   7927 to 792e (8 bytes)
; Numbers are stored in the accumulators during computations. 
; The method of storage of a given number depends on its number type, 
; and on which accumulator is being used.

; Accumulator 1
MATH_ACC_CY      equ     $791c       ; extension byte for ACC
MATH_ACC_DBL     equ     $791d       ; Double variable (8 bytes): LSB LSB LSB LSB LSB LSB MSB EXP
MATH_ACC         equ     $7921       ; Int,Single,String (2 or 4 bytes):  LSB LSB MSB EXP
MATH_ACC_MSB     equ     $7923       ; shortcut to MSB of Component part 
MATH_ACC_EXP     equ     $7924       ; shortcut to Exponent part (EXP)

; Operation sign/flags beetween Accumulators
MATH_ACC_SIGN    equ     $7925       ; math routines

; Accumulator 2
MATH_ACC2_CY     equ     $7926       ; extension byte for ACC
MATH_ACC2_DBL    equ     $7927       ; Double variable (8 bytes): LSB LSB LSB LSB LSB LSB MSB EXP
MATH_ACC2_MSB    equ     $792d       ; shortcut to MSB of Component part 
MATH_ACC2_EXP    equ     $792e       ; shortcut to Exponent part (EXP)

;794a-7951  double precision math
MATH_ACC3_DBL    equ     $794a       ; Double variable (8 bytes): LSB LSB LSB LSB LSB LSB MSB EXP
MATH_ACC3_MSB    equ     $7950       ; shortcut to MSB of Component part 
MATH_ACC3_EXP    equ     $7951       ; shortcut to Exponent part (EXP)
