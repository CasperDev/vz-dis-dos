

VRAM        equ     $7000   ; Video RAM start

;************************************************************
;RAM COMMUNICATION ADRESSSES
; by David Mitchel 1987, R. Quinn 1988

; 7800-7814 : RST jump Vectors
RAMCommArea    equ RCA.AssertChar
    ;-----------------|-addr----|-call from---|-initial value--|

RCA.AssertChar   equ     $7800   ; RTS08         jp $1c96
RCA.NextChar     equ     $7803   ; RTS10         jp $1d78    (DOS: 4293)
RCA.uiCmpHLDE    equ     $7806   ; RTS18         jp MAT.iCmp_HL_DE
RCA.TestNTF      equ     $7809   ; RST20         jp MAT.TestNTF

; In non-disk systems 780c contains a RET instruction. 
; In a disk system this vector is used for DOS overlay requests 
; (Bit 7 of the A register is set on entry if DOS overlay).
RCA.BreakKeyTest   equ     $780c   ; RST28   BreakVector      set to: RET

; In non-disk systems 780f contains a RET instruction. 
; DEBUG entry point under DOS.
RCA.Debug   equ     $780f   ; RST30         set to: RET

; In non-disk system 7812 contains an EI (Enable Interrupts) 
; instruction, followed by a RET instruction at 7813.
RCA.DOSINTHandler   equ     $7812   ; RST38         set to: EI,RET

    
    
; 7815-781c : Keyboard
;---------------------------------------------------------------
KEYBOARD_DCB           equ $7815   ; (structure)
DevSysKeysCaps           equ $7815   ; (byte) Capabilities Flags ( 1 - read only)
DevSysKeysDrvPtr     equ $7816   ; (word) DriveRAddress - 2ef4
; TRS 0 (in Model III but NOT Model 4, location used by shift-lock routine)
KEYS_INVERSE_SCREEN     equ $7818   ; (byte) 
; TRS 0 (in Model III, 0="Upper & Lower Case", else "Caps only")
KEYS_INVERSE_TYPING     equ $7819   ; (byte)
; TRS 0 (in Model III, time counting byte for blinking cursor)
KEYS_UNKNOWN            equ $781a   ; byte
; 781b TRS "K" (in Model III, status of blinking cursor-on or off)
; 781c TRS "I" (in Model III, Cursor Blink Switch - 0="Blink") 
; ( "Ki"=Keyboard Input - Model I only)
KEYS_BUFFER_ADDRESS     equ $781b   ; word
    
KEYS_MATRIX             equ $6800   ; all keys matrix address
; /---------------------------------------------------------------------\
; |                         ADRES   |   D5  D4      D3  D2      D1  D0  |
; |---------|-----------------------------------------------------------|
KEYS_ROW_0:         equ     68FEh   ;   R   Q       E           W   T   |
KEYS_ROW_1:         equ     68FDh   ;   F   A       D   CTRL    S   G   |
KEYS_ROW_2:         equ     68FBh   ;   V   Z       C   SHIFT   X   B   |
KEYS_ROW_3:         equ     68F7h   ;   4   1       3           2   5   |
KEYS_ROW_4:         equ     68EFh   ;   M   SPACE   ,           .   N   |
KEYS_ROW_5:         equ     68DFh   ;   7   0       8   -       9   6   |
KEYS_ROW_6:         equ     68BFh   ;   U   P       I   RETURN  O   Y   |
KEYS_ROW_7:         equ     687Fh   ;   J   ;       K   :       L   H   |
; |---------|-----------------------------------------------------------|    
KROW_CTRL       equ KEYS_ROW_1   ; Keyboard Row with Control Key at bit 2
KEYS_ROW_SHIFT      equ KEYS_ROW_2   ; Keyboard Row with Shift Key at bit 2
KROW_SPACE      equ KEYS_ROW_4   ; Keyboard Row with Shift Key at bit 2
KROW_BREAK      equ KEYS_ROW_5   ; Keyboard Row with Inverse Key at bit 2
KEYS_ROW_RETURN     equ KEYS_ROW_6   ; Keyboard Row with RETURN Key at bit 2
KEYS_ROW_INVERSE    equ KEYS_ROW_7   ; Keyboard Row with Inverse Key at bit 2
KEYS_ROWS_NMI       equ KEYS_ROW_0 & KEYS_ROW_1 & KEYS_ROW_4   ; Keyboard Row with Inverse Key at bit 2

; 781d-7824 : Video
;----------------------------------------------------------------
; TRS DeviceType (normally 7 = read and write)
SCREEN_DCB               equ $781d   ; byte Device type 0 
VIDEO_DEVICE_TYPE       equ $781d   ; byte Device type 0 
VIDEO_DRIVER_ADDRESS    equ $781e   ; word TRS DriverAddress
CURSORADDR        equ $7820   ; word CursorPosition (range 7000 to 71ff) also TRS 
; TRS Character "covered" on video by Cursor character
VIDEO_UNKNOWN           equ $7822   ; byte
; TRS 7823 "D" (in Model III, ASCII code for Cursor character)
; TRS 7824 "O" (Model III j 0=Space Compression , l="Special" Characters) 
; ( ™DO"=Display Output - Model I only)
TAPE_CRC      equ $7823   ; word 


; 7825-782c : Printer
;----------------------------------------------------------------
PRINTER_DCB     equ $7825   ; (structure)
PRINTER_DEVICE_TYPE     equ $7825   ; byte Capabilities (normally 6 = write only)
PRINTER_DRIVER_ADDRESS  equ $7826   ; word DriverAddress 058d
; TRS 67 - Number of lines per page (+1 in Model III only)
PRINTER_LINES_PER_PAGE  equ $7828   ; byte
; TRS Current Line Number (Model III: Number of lines printed +1)
PRINTER_LINES_PRINTED   equ $7829   ; byte
; TRS 0 (Model III Number of characters printed on current line)
PRINTER_UNKNOWN         equ $782a   ; byte
; TRS 782B "P" (in Model III, max. line length -2, 255="No maximum")
; TRS 782C "R" (in Model 4 only, zero byte)
; ( "PR"=printer - Model I only)
PRINTER_BUFFER_ADDRESS  equ $782b   ; word

;------------------------------------------
SYS.DosReEntry      equ     $782d   ; 
SYS.DosErrEntry      equ     $7830   ; 
SYS.DosDevExec      equ     $7833   ; 
; ...
PRINTER_ERROR_VECTOR    equ $7833   ; (code) ld a,0; ret 

;---------------------------------------------
; Keyboard work area
KEY1         equ     $7836   ; byte

; bit 0 - Shift is pressed
; bit 2 - Function is Active
; bit 5 - ??? is pressed
; bit 7 - Inverse is Active
KEYS_MODIFIERS      equ     $7838   ; Key Modifiers
; $7839  disable up, down keys: low res speed up
KEYS_DEBOUNCER      equ    $783a    ; Key Debounce Counter
IOLATCH_COPY        equ     $783b  ; copy of Hardware IO latch
CURSORCHAR      equ     $783c  ;(byte) character at cursor position

; $783d  video control word
; TRS NOTE: Uses flag byte to determine if Video Display is in 32 or 64 chars/line mode.
; TRS Model 1 - flag contains CURRENT PORT 0FFh OUTPUT BITS:
; - bit 3	Select video 32 character mode if set
; - bit 2 	Turns on cassette tape relay if set
; - bit 0,1	Are set for positive and negative audio pulses to the cassette "AUK" plug

; $783e-$787c  ?


KEYS_SCAN_COORDS equ $7842   ; MSB-bit (6..1), LSB-row (8..1)
KEYS_SCAN_ROWADR equ $7844   ; np: $68fe
; $787d  interrupt (jump? - 3 bytes)

RCA.BASIC_AREA      equ     $7880
; $7880-$788d  division support routine
BAS.UsrVector       equ     $788e  ; BASIC USR routine pointer (word)
; $7890  rnd number seed (3 bytes)
; $7893  INP (XX) (3 bytes)
; $7896  OUT (XX) (3 bytes)
KEYS_LASTKEY        equ     $7899       ; Last Key Pressed
BAS.LastError       equ     $789a   ; error code
PRN.PosInLine         equ     $789b       ; printer position

; 00 - Screen Display Device
; 01 - Printer Device
; 80-ff - Tape Cassette Device
SysCurOutDev          equ     $789c  ; Current Output Device for System/Errors
SCR_LINEMAXLEN          equ     $789d  ; size of video line

; Specifies maximum number of 16-character print zones on line
; (used when items in PRINT statement are separated by commas).
; Value decodes as follows:
;  0 - one print zone
; 16 - two print zones
; 32 - three print zones
; 48 - four print zones
; When comma separator is found in PRINT statement, BASIC
; checks the current cursor position and if is greater or
; equal to this value, a CR char is send to screen. 
SCR_PRINTZONES      equ     $789e   ; 
; $789f  ?

; 78A0-78xx : Basic
BAS.MaxStackPtr     equ     $78a0       ; (word)
BAS.CurLineNo       equ     $78a2       ; (word)
BAS.PrgStartPtr     equ     $78a4       ; (word)
BAS.CursorPos    equ     $78a6       ; (byte) Cursor in Line Position

BAS.LineBufPtr   equ     $78a7       ; thru 7a28 (65 bytes)
CASS_INPUT_FLAG         equ     $78a9       ;(byte) 0 if cassete input else non zero

; Funkcja BASIC RANDOM zapisuje tu aktualna wartość rejestru odświeżania 
; pamięci RAM (R) - wartość przypadkowa zależna od czasu jaki upłynął od
; właczenia komputera.
BAS.RANDOMSEED       equ     $78ab       ;(byte)
; 78aa-d    random number seed


; Flag is used by BASIC locate or Create Variable routine.
;  0 - variable will be created or located (if already exists)
; nonzero - variable will be Created or error will be raised 
;           if variable already exists (when DIM is used)
BAS.CreateVarFlag   equ     $78ae       ; variable flag


;   2 - integer
;   4 - single-precision number
;   8 - double-precision number
;   3 - the number of bytes required for the string vector
MATH_NTF             equ     $78af       ; Number Type Flag


; Used to flag DATA statements while encoding BASIC lines, and
; to store operator number during expression evaluation.
; 78b0      expression evaluator


MEMORY_TOP                 equ     $78b1       ; 30897 (word) Top of memory pointer.

; Pointer to the next available location for storage of a three-byte
; string variable VARPTR in the string VARPTR storage area (78B5).
BAS.StrNextVar        equ     $78b3       ; (word) next location in literal string pool


; String variable VARPTR storage area. Holds three-byte string vectors
; (1 byte length, 2 bytes address of string) for strings currently
; being used in BASIC string operations.
BAS.StrVars       equ     $78b5       ; start of literal string pool
; 78b7 ... 78e1   ?

; VARPTR storage area for string currently being created by BASIC
; (1 byte length, 2 bytes address of string)
BAS.CurStrVec         equ     $78d3       ; length of last defined string

; Pointer to next free byte in string storage area.
; Strings build downward from the top of memory, therefore at power-up
; (or when a CLEAR command is executed) this pointer will contain the
; same address as the top of memory pointer { 40B1H-40B2B) . If a ten
; byte long string is then created, this pointer will point to the top
; of memory minus ten, and so on. When there is not enough room left to
; insert a new string (the difference between this pointer and the one
; at 40A0B-40A1B is less than the length of a string to be stored), a
; "garbage collection" is performed, and if that does not free enough
; string space an Out of String Space error occurs. 
BAS.StrFreePtr          equ     $78d6       ; (word)  Pointer to next free byte in string storage area.


; This pair of locations is used a temporary storage location by more 
; than one routine. 
;   - program pointer during expression evaluation, 
;   - pointer to data while processing DIM statement, 
;   - pointer to end of array while packing strings, 
;   - PRINT USING format flag bits temporarily store
BAS.TempPtr             equ     $78d8       ; temporary pointer
BAS.TempFlags           equ     $78d8       ; temporary byte

; Line number of last DATA item read. 
; Line number is saved so that in the event of a syntax error in a DATA 
; statement, the proper error line number will be displayed and the EDIT 
; mode will function on the correct line.
BAS.CurDataLineNo       equ     $78da       ; Line number of last DATA item read.

; If this byte contains 64 a FOR-NEXT loop is being processed,
; otherwise byte will contain zero. Used to prevent an array variable
; from being used as the index counter in a FOR-NEXT loop (for example,
; the statement FOR X(O) = 1 TO 10 will cause a syntax error, because
; X(0) is an array variable and cannot be used as the counter variable).
BAS.ForNextFlag         equ     $78dc       ; inside For-Next loop

; Flag indicates whether inputing text. Used by RETURN and RESUME NEXT commands.
BAS.InputFlag           equ     $78dd       ; 

; Used for two different purposes: 
;   - Flags whether READ (non-zero) or INPUT (zero) statement is processing 
;   - delimiter character during processing of PRINT USING statement
BAS.ReadInSrc           equ     $78de     ; READ (non-zero) or INPUT (zero) 
BAS.PrintUsingDelim     equ     $78de     ; delimiter for PRINT USING

; Used by several routines, 
;   - pointer to variable for new value during evaluation of LET expression
;   - execution address of BASIC program
;   - after a SYSTEM tape is loaded contain the entry point address 
;     of the program (which is used if only a "/" is typed in response 
;     to the next SYSTEM command prompt)
BAS.PrgStart            equ     $78df       ;(word) pointer to start of program when run
BAS.NewVarPtr           equ     $78df       ;(word) pointer to LET variable

; AUTO input flag. Zero byte here means AUTO is not on.
BAS.AutoFlag         equ     $78e1       ; 0=no auto

; Current input line number used by AUTO input function.
BAS.AutoLineNo          equ     $78e2       ; (word) current line number

; Line increment used by AUTO input function
BAS.AutoLineInc         equ     $78e4       ; (word) auto increment


; Used by several routines for temporary pointers to the BASIC program 
;   - saved position in program text (last byte executed in current line?)
;   - buffer position during text encoding
;   - etc.
BAS.TmpCharPtr          equ     $78e6       ; last byte executed in current line
; TRS -> 78a7 - 78a8 - editor line buffer address (buffer 255 bytes)
BAS.StackPtr       equ     $78e8   ; (word) backspaced stack address
BAS.ErrorLineNo       equ     $78ea   ; (word) error line number

; Current or error line number.
; Used when a period is used to replace a BASIC line number, 
; and when syntax error occurs in program.
BAS.EditLineNo      equ     $78ec       ;(word)

; Pointer to last byte executed when error occured.
; Used by RESUME command.
BAS.ErrBytePtr       equ     $78ee   ; byte executed with error

; Address of error trap line 
; Points to first statement of line specified in ON ERROR GOTO 
; statement, or zero if no error trap set.
BAS.OnErrorPtr      equ     $78f0   ; address of statement to resume at

; Flag to indicate whether an error has occured. 
; Set to -1 (FF) on error, otherwise set to zero 
; Setting the appropriate values into this location will allow 
; you to do many things that BASIC normally does not permit,
; such as exiting an error trap without using a RESUME statement, 
; or redefining the error trap (by using an ON ERROR GOTO statement)
; from within a previously defined error trap.
BAS.ErrorFlag       equ     $78f2     ; error message override

; Used to store position of expressions being evaluated,
; as a decimal point location pointer, etc.
BAS.ExprTmpPtr      equ     $78f3   ; ?


; Last line number executed prior to execution of STOP or END 
; statement or termination using the BREAK key.
BAS.LastLineNo  equ     $78f5       ;(word)  line number ended on

; Pointer to end of last statement executed;
; (points to the colon or zero byte terminator). Used by CONT command.
BAS.StopedPtr   equ     $78f7       ; last statement byte executed

; Pointer to start of simple variables, or one memory location 
; higher than the last of the three zero bytes marking the end
; of the BASIC program. Used to determine end of BASIC program 
; when saving the program.
BAS.PrgEnd       equ     $78f9       ; (word) end of program

; Pointer to start of array variables
BAS.ArrStartPtr  equ     $78fb       ; (word) start of DIM variables table
BAS.ArrEndPtr        equ     $78fd       ; (word) start of free memory

; Pointer to end of last DATA item read. 
; Points to comma or other terminator at end of last item read.
; Search for next DATA item to be read will begin here. 
; RESTORE changes this pointer to one byte prior to beginning of BASIC program.
BAS.DataReadPtr  equ  $78ff       ; (word) data pointer (READ statement)

// *******************************************************************
; BASIC Variable Declaration Table
; This table is organized so that location 7901 contains variable type 
; flag (NTF) that begins with "A", 7902 for one begins with "B" and so on.
; This type flag is same as NTF: Int=2, Str=3, Sng=4, Dbl=8.
; All table locations are set to 4 (Single) on cmd RUN or CLEAR.
BAS.VarTypesTab  equ  $7901       ; thru $791A - variable declaration table

; Trace flag. 
; Zero - trace is off, AF (non-zero) - trace is on
BAS.TraceFlag      equ     $791b       ; byte
; 792f  ???

; Conversion Buffer for numbers converted to displayable ASCII
; When positive integers (BASIC line numbers , etc.) are converted,
; the area from 7930 to 7936 is used, and the string is stored 
; right justified with leading spaces in locations 7930 to 7935
; (7930 always contains a space character), while 7936 always 
; contains a zero byte to terminate the string.
; Other routines (such as PRINT USING) may use more of this area.
SysConvBuffer      equ     $7930       ; thru 7949 (32 bytes)

SysDosVectors       equ     $7952
; 7952-79a5  DOS Vectors
SysDosCVI           equ     $7952
SysDosFN           equ     $7955
SysDosCVS           equ     $7958
SysDosDEF           equ     $795b
SysDosCVD           equ     $795e
SysDosEOF           equ     $7961
SysDosLOC           equ     $7964
SysDosLOF           equ     $7967
SysDosMKIS           equ     $796a
SysDosMKSS           equ     $796d
SysDosMKDS           equ     $7970
SysDosCMD           equ     $7973
SysDosTIMES           equ     $7976
SysDosOPEN           equ     $7979
SysDosFIELD           equ     $797c
SysDosGET           equ     $797f
SysDosPUT           equ     $7982
SysDosCLOSE           equ     $7985
SysDosLOAD           equ     $7988
SysDosMERGE           equ     $798b
SysDosNAME           equ     $798e
SysDosKILL           equ     $7991
SysDosAND           equ     $7994
SysDosLSET           equ     $7997
SysDosRSET           equ     $799a
SysDosINSTR           equ     $799d
SysDosSAVE           equ     $79a0
SysDosLINE           equ     $79a3


; 79A6 - 79E4 contain three-byte Disk BASIC links used to extend 
; the capabilities of BASIC routines when a Disk BASIC is present.
; Under non-disk systems, the first byte of each of these vectors 
; is a machine language RET instruction. 
SysExtVectors      equ     $79a6   ; Extension links - initialized to RET

; Called at 19ECH, from error-handling routine.
; Used to provide long error messages.
SysExtErrMsg       equ     $79a6

; Called at 27FEH, from entrance to USR function routine. 
; Used to expand function to provide up to ten USR calls. 
; If a program running under Disk BASIC contained the statement 
; POKE 16809,201 (placing a RET instruction at 79A9),
; the expanded USR function would be defeated and the single USR 
; call of non-disk BASIC would be restored. 
; Such a program could run correctly under either non-disk or
; Disk BASIC, provided that the normal Level II/Model III BASIC
; requirement for POKEing the USR routine starting address into 
; memory locations 788E-788F is adhered to (rather than use of 
; the DEFUSE command that Disk BASIC normally requires).
SysExtUsr          equ     $79a9

; Called at 1A1CH, from BASIC re-entry ("READY").
OnBasicREADY        equ     $79ac

; Called at 0368H, from near start of routine to input a line
; from the keyboard into the I/O buffer (zeroes INKEY$ buffer 
; and video tab position indicator prior to call)
SysExtInkey        equ     $79af

; Called at 1AA1, after BASIC line has been tokenized 
; (HL points to start of tokenized line)
SysExtTokenize     equ     $79b2

; Called at 1AEC, after insertion or replacement of BASIC line
OnLineChanged  equ     $79b5

; Called at 1AF2, after above call followed by call to 1B5D
; (CLEAR command, leaves HL pointing to start of BASIC program -1)
OnResetBasPrg        equ     $79b8

; Called at 1B8C (NEW command) and at 1DB0 (END command). 
; Used to CLOSE any files remaining open.
SysExtNew          equ     $79bb

; Called at 2174H, at termination of PRINT statement.
; Used to terminate output to disk using PRINT # statement)
SysExtPrintEnd      equ     $79be   ; TODO ???

; Called at 032CH, from byte output routine.
SysExtByteOut        equ     $79c1   ; TODO ???

; Called at 0358H, from start of routine to scan keyboard 
; and input keystroke (if any).
SysExtKeyRead     equ     $79c4   ; TODO ???

; Called at 1EA6H, when RUN command has an argument (filename).
SysExtRunFile     equ     $79c7   ; TODO ???

; Called at 206FH, from start of PRINT command 
; (check for output to disk using PRINT #).
SysExtPrint     equ     $79ca   ; TODO ???

; Called at 20C6H, from PRINT routine after a numeric item has
; been converted to an ASCII string in preparation for printing.
SysExtPrintNum     equ     $79cd   ; TODO ???

; Called at 2103H, from PRINT routine after code which outputs 
; a carriage return (to prevent numeric items being printed 
; from overflowing the end of a line).
SysExtPrintCR      equ     $79d0   ; TODO ???

; Called at 2108H (from PRINT command when a comma is used to
; separate items to be printed) and at 2141H (from PRINT command 
; routine when the TAB function is used, after the TAB argument 
; has been evaluated and placed in the E register.
SysExtPrintTab      equ     $79d3   ; TODO ???

; Called at 219EH, from start of INPUT command 
; (check for input from disk using INPUT #).
SysExtInput      equ     $79d6   ; TODO ???

; Jump to this location at 2AECH, to Disk BASIC routine that
; permits MID$ on left side of " = " (assignment statement).
SysExtAssign       equ     $79d9

; Called at 222DH, Part of READ/INPUT command routine, 
; called just prior to assigning data that has been READ or INPUT 
; to variable.
SysExtReadData       equ     $79dc

; Called at 2278H (after data from INPUT command has been assigned
; to variable, just prior to test for "extra™ data that would
; cause an "?EXTRA IGNORED" message to be printed) and at 2B44H 
; (from LIST command after start and end addresses of program 
; have been found and a check for end of program has been made).
SysExtExtraTest       equ     $79df

; Called at 02B2H. This call is located at the entrance to the
; SYSTEM command and is executed each time the "*?" prompt 
; is about to be displayed. 
; If a SYSTEM tape is being loaded and it places a jump to its 
; entry point address in this vector, the program will start
; automatically. The same thing can be achieved by placing 
; a JP (HL) instruction (an E9H byte) at 79E2, provided that 
; the entry point address on the tape is correct. 
; Note, however, that the SYSTEM command will be unusable 
; afterwards unless the program reloads a RET instruction 
; (a C9H byte) to 79E2 after execution begins.
SysExtPrompt       equ     $79e2

; Addresses are initialized by ROM code at 0G8OH-OO89B to contain 
; the bytes 3A, 0, and 2C (a colon, zero byte, and comma).
BAS.SEPARATORS      equ     $79e5   ; BASIC separators ':' \0 ','  used by input
BAS.sepCOMMA      equ     $79e7   ; BASIC separator '','  used by input

; TRS 79e5 - 79ec DCB RS-232-C INPUT DEVICE CONTROL BLOCK (Model III only)
; 79E5 Device Type (normally 1 read only)
; 79E6 (word) Driver Address
; 79E9 Bit 1 = Wait/No Wait Flag, Bit 2 = Driver On/Off Flag
; 79EB "F1" key definition in Model 4 only (used by Keyboard Driver)
; 79EC "F2" key definition in Model 4 only (used by Keyboard Driver)

; TRS 79ED - 79F4 DCB RS-232-C OUTPUT DEVICE CONTROL BLOCK (Model III only)
; 79ED Device Type (normally 2 write only)
; 79EE (word) Driver Address
; 79F0 Character to Transmit
; 79F1 Bit 1 = Wait/No Wait Flag, Bit 2 = Driver On/Off Flag
; 79F3 "F3" key definition in Model 4 only (used by Keyboard Driver)
; 79F4 "Keyboard row storage for 3880H' in Model 4 only (used by Keyboard Driver)

BAS.LineBuf   equ     $79e8       ; thru 7a28 (65 bytes)

; TRS 79F5 - 79FA RS-232-C INITIALIZATION DEVICE CONTROL BLOCK (Model III only)
; 79F5 Device Type (normally 2 = write only)
; 79F6 (word) Driver Address
; 79F8 Baud Rate Codes (Bits 0-3 = Receive, Bits 4-7 = Send)
; 79F9 RS-232-C Characteristics Switch
; 79FA Wait/Don't Wait Switch CO = Don't Wait)

; TRS 7a10 Model III - flag contains CURRENT PORT OECH OUTPUT BITS:
; - bit 6	Enables fast clock speed if set on Model 4 only
; - bit 5	Disables video wait states if set (not used on Model 4)
; - bit 4	Enables I/O bos if set
; - bit 3	Japanese Kana character set used as "special" characters if set
; - bit 2	Select video 32 character mode if set
; - bit 1	Turns on cassette tape relay if set
; - bit 0	Enables clock display on video if set

; TRS 7a1d - 7a25 I/O ROUTER DEVICE CONTROL BLOCK (Model III only, NOT initialized in Model 4)
; 7A1D Device Type (normally 2 write only)
; 7A1E Driver Address
; 7A20 First character of Destination Device Code
; 7A21 Second character of Destination Device Code
; 7A22 First character of Source Device Code
; 7A23 Second character of Source Device Code
; 7A24 Control Key Flag (used by Keyboard Driver - Models II and 4)
; (Source & Destination Codes may be any of KI, DO, RI, RO, PR)

; 7a29-7a9c   ?
; 7a9d-7aac   tape name
; 7aad-7ad6   ?
; 7ad7-7ae6   tape load routine
; 7ae7-8       zero


BAS.PrgMemory      equ     $7ae9
SysMinMemory       equ     $7b4c
MEMORY_TESTSTART       equ     $7b4d
MEMORY_MIN         equ     $7c14