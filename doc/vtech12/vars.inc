VRAM        equ     $7000   ; Video RAM start

// *********************************************************************
;RAM COMMUNICATION ADRESSSES
; by David Mitchel 1987, R. Quinn 1988

; 7800-7814 : RST jump Vectors
RAMCommArea    equ AssertTokenVect


AssertTokenVect   equ     $7800   ; RTS08         jp $1c96
NextTokenVect     equ     $7803   ; RTS10         jp $1d78    (DOS: 4293)
CmpHLDEVect      equ     $7806   ; RTS18         jp MAT_iCmp_HL_DE
TestNTFVect      equ     $7809   ; RST20         jp MAT_TestNTF

; In non-disk systems 780c contains a RET instruction. 
; In a disk system this vector is used for DOS overlay requests 
; (Bit 7 of the A register is set on entry if DOS overlay).
TestBreakKeyVect   equ     $780c   ; RST28   BreakVector      set to: RET

; In non-disk systems 780f contains a RET instruction. 
; DEBUG entry point under DOS.
OnDebug   equ     $780f   ; RST30         set to: RET

; In non-disk system 7812 contains an EI (Enable Interrupts) 
; instruction, followed by a RET instruction at 7813.
DOSINTHandlerVect   equ     $7812   ; RST38         set to: EI,RET

    
    
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
TAPESTARTPRG			equ $781e   ; Startup address from Tape
CURSORADDR        equ $7820   ; word Cursor Address in VRAM (range 7000 to 71ff) also TRS 
; TRS Character "covered" on video by Cursor character
VIDEO_UNKNOWN           equ $7822   ; byte
; TRS 7823 "D" (in Model III, ASCII code for Cursor character)
; TRS 7824 "O" (Model III j 0=Space Compression , l="Special" Characters) 
; ( ™DO"=Display Output - Model I only)
TAPE_CRC      	equ $7823   ; word 


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
KEYCODE1         equ     $7836   ; KeyCode of 1st key pressed 
KEYCODE2         equ     $7837   ; KeyCode of 2nd key pressed 


; bit 0 - Shift is pressed
; bit 1 - INVERSE is Active
; bit 2 - ???Function is Active
; bit 3 - KEYCODE1 variable has pressed KeyCode
; bit 4 - KEYCODE2 variable has pressed KeyCode
; bit 5 - ??? is pressed
; bit 7 - Ctrl is pressed
KEYSFLAGS      equ     $7838   ; Keyboard's current State

; bit 0 - RETURN key pressed
; bit 2 - BREAK key pressed 
; bit 3 - tape load for VERIFY Command
; bit 4 - text edited for INPUT Command
; bit 5 - buffered output while reading text from keyboard
; bit 6 - tape load for CRUN Command
SYSFLAGS		equ		$7839	; System flags
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

CURSORTIMER			equ	$7841	; timer for inverse char under cursor
KEYS_SCAN_COORDS equ $7842   ; MSB-bit (6..1), LSB-row (8..1)
KEYS_SCAN_ROWADR equ $7844   ; np: $68fe

FCOLOR				equ	$7846	; Foreground Color

TAPEHIDEINFO		equ	$784c	; Hide Tape operations info texts (0-show, nonzero-hide)
OnCpuINT		equ $787d  ; user interrupt vector interrupt (jump - 3 bytes)

BASIC_VARS_AREA      equ     $7880
; $7880-$788d  division support routine
BAS_UsrVector       equ     $788e  ; BASIC USR routine pointer (word)
; $7890  rnd number seed (3 bytes)
; $7893  INP (XX) (3 bytes)
; $7896  OUT (XX) (3 bytes)
KEYS_LASTKEY        equ     $7899       ; Last Key Pressed
LASTERRORNO       equ     $789a   ; error code
PRN_PosInLine         equ     $789b       ; printer position in line

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
STACKTOPPTR     equ     $78a0       ; (word)
BasicLineNo       equ     $78a2       ; Current Basic Line Number (word)
PrgStartPtr     equ     $78a4       ; (word)
CURSORPOS    equ     $78a6       ; (byte) Cursor in Line Position

LINEBUFPTR   equ     $78a7       ; thru 7a28 (65 bytes)
SysINPUTSrcFlag         equ     $78a9       ;(byte) 0 if cassete input else non zero

; Funkcja BASIC RANDOM zapisuje tu aktualna wartość rejestru odświeżania 
; pamięci RAM (R) - wartość przypadkowa zależna od czasu jaki upłynął od
; właczenia komputera.
RANDOMSEED       equ     $78ab       ;(byte)
; 78aa-d    random number seed


; Flag is used by BASIC locate or Create Variable routine.
;  0 - variable will be created or located (if already exists)
; nonzero - variable will be Created or error will be raised 
;           if variable already exists (when DIM is used)
CreateVarFlag   equ     $78ae       ; variable flag


;   2 - integer
;   4 - single-precision number
;   8 - double-precision number
;   3 - the number of bytes required for the string vector
MATH_NTF             equ     $78af       ; Number Type Flag


; Used to flag DATA statements while encoding BASIC lines, and
; to store operator number during expression evaluation.
; 78b0      expression evaluator


MEMORY_TOP                 equ     $78b1       ; (word) Top of memory pointer.

; Pointer to the next available location for storage of a three-byte
; string variable VARPTR in the string VARPTR storage area (78B5).
BAS_StrNextVar        equ     $78b3       ; (word) next location in literal string pool


; String variable VARPTR storage area. Holds three-byte string vectors
; (1 byte length, 2 bytes address of string) for strings currently
; being used in BASIC string operations.
BAS_StrVars       equ     $78b5       ; start of literal string pool
; 78b7 ... 78e1   ?

; VARPTR storage area for string currently being created by BASIC
; (1 byte length, 2 bytes address of string)
StrVecBuf         equ     $78d3       ; length of last defined string

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
BAS_StrFreePtr          equ     $78d6       ; (word)  Pointer to next free byte in string storage area.


; This pair of locations is used a temporary storage location by more 
; than one routine. 
;   - program pointer during expression evaluation, 
;   - pointer to data while processing DIM statement, 
;   - pointer to end of array while packing strings, 
;   - PRINT USING format flag bits temporarily store
BAS_TempPtr             equ     $78d8       ; temporary pointer
BAS_TempFlags           equ     $78d8       ; temporary byte

; Line number of last DATA item read. 
; Line number is saved so that in the event of a syntax error in a DATA 
; statement, the proper error line number will be displayed and the EDIT 
; mode will function on the correct line.
DATALineNo       equ     $78da       ; Line number of last DATA item read.

; If this byte contains 64 a FOR-NEXT loop is being processed,
; otherwise byte will contain zero. Used to prevent an array variable
; from being used as the index counter in a FOR-NEXT loop (for example,
; the statement FOR X(O) = 1 TO 10 will cause a syntax error, because
; X(0) is an array variable and cannot be used as the counter variable).
ForNextFlag         equ     $78dc       ; inside For-Next loop

; Flag indicates whether inputing text. Used by RETURN and RESUME NEXT commands.
INPUTFLAG           equ     $78dd       ; 

; Used for two different purposes: 
;   - Flags whether READ (non-zero) or INPUT (zero) statement is processing 
;   - delimiter character during processing of PRINT USING statement
BAS_ReadInSrc           equ     $78de     ; READ (non-zero) or INPUT (zero) 
BAS_PrintUsingDelim     equ     $78de     ; delimiter for PRINT USING

; Used by several routines, 
;   - pointer to variable for new value during evaluation of LET expression
;   - execution address of BASIC program
;   - after a SYSTEM tape is loaded contain the entry point address 
;     of the program (which is used if only a "/" is typed in response 
;     to the next SYSTEM command prompt)
PrgStart            equ     $78df       ;(word) pointer to start of program when run
BAS_NewVarPtr           equ     $78df       ;(word) pointer to LET variable

; Basic AUTO input flag [TRS]. 0 - OFF, 1 - ON.
AUTONUM_ON         equ     $78e1       ; 0=no auto

; Current input line number used by AUTO input function.
AUTONUM_LINE          equ     $78e2       ; (word) current line number

; Line increment used by AUTO input function
AUTONUM_INC         equ     $78e4       ; (word) auto increment


; Used by several routines for temporary pointers to the BASIC program 
;   - saved position in program text (last byte executed in current line?)
;   - buffer position during text encoding
;   - etc.
BAS_TmpCharPtr          equ     $78e6       ; last byte executed in current line
; TRS -> 78a7 - 78a8 - editor line buffer address (buffer 255 bytes)
BAS_StackPtr       equ     $78e8   ; (word) backspaced stack address
ErrorLineNo       equ     $78ea   ; (word) error line number

; Current or error line number.
; Used when a period is used to replace a BASIC line number, 
; and when syntax error occurs in program.
EditLineNo      equ     $78ec       ;(word)

; Pointer to last byte executed when error occured.
; Used by RESUME command.
ErrorTokenPtr       equ     $78ee   ; byte executed with error

; Address of error trap line 
; Points to first statement of line specified in ON ERROR GOTO 
; statement, or zero if no error trap set.
BAS_OnErrorPtr      equ     $78f0   ; address of statement to resume at

; Flag to indicate whether an error has occured. 
; Set to -1 (FF) on error, otherwise set to zero 
; Setting the appropriate values into this location will allow 
; you to do many things that BASIC normally does not permit,
; such as exiting an error trap without using a RESUME statement, 
; or redefining the error trap (by using an ON ERROR GOTO statement)
; from within a previously defined error trap.
ERRORFLAG       equ     $78f2     ; error message override

; Used to store position of expressions being evaluated,
; as a decimal point location pointer, etc.
BAS_ExprTmpPtr      equ     $78f3   ; ?


; Last line number executed prior to execution of STOP or END 
; statement or termination using the BREAK key.
BAS_LastLineNo  equ     $78f5       ;(word)  line number ended on

; Pointer to end of last statement executed;
; (points to the colon or zero byte terminator). Used by CONT command.
BAS_StopedPtr   equ     $78f7       ; last statement byte executed

; Pointer to start of simple variables, or one memory location 
; higher than the last of the three zero bytes marking the end
; of the BASIC program. Used to determine end of BASIC program 
; when saving the program.
PrgEndPtr       equ     $78f9       ; (word) end of program

; Pointer to start of array variables
ArrStartPtr  equ     $78fb       ; (word) start of DIM variables table
ArrEndPtr        equ     $78fd       ; (word) start of free memory

; Pointer to end of last DATA item read. 
; Points to comma or other terminator at end of last item read.
; Search for next DATA item to be read will begin here. 
; RESTORE changes this pointer to one byte prior to beginning of BASIC program.
DataReadPtr  equ  $78ff       ; (word) data pointer (READ statement)

// *******************************************************************
; BASIC Variable Declaration Table
; This table is organized so that location 7901 contains variable type 
; flag (NTF) that begins with "A", 7902 for one begins with "B" and so on.
; This type flag is same as NTF: Int=2, Str=3, Sng=4, Dbl=8.
; All table locations are set to 4 (Single) on cmd RUN or CLEAR.
BAS_VarTypesTab  equ  $7901       ; thru $791A - variable declaration table

; Trace flag. 
; Zero - trace is off, AF (non-zero) - trace is on
TRACEFLAG      equ     $791b       ; byte
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
BAS_SEPARATORS      equ     $79e5   ; BASIC separators ':' \0 ','  used by input
BAS_sepCOMMA      equ     $79e7   ; BASIC separator '','  used by input

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

EditLineBuf   equ     $79e8       ; thru 7a28 (65 bytes)

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
FileNameBuf		equ	$7a9d		; tape file name buffer (16 bytes)
; 7aad-7ad5   ?
TAPEFILENAME	equ	$7ab2		; tape buffer for filename (18) bytes
PRINTBUFFER		equ	$7ad2		; 4 byte buffer used by Printer routines (up to 7AD5H)

TAPEFILETYPE	equ	$7ad2		; file type read from Tape
TAPEBYTEBUF		equ	$7ad3		; last byte read from Tape
FILENAMELEN		equ	$7ad6		; length of file name for tape
; 7ad7-7ae6   Editor Flags
; For every screen line there is info about line in editor context:
;   80 - single line 
;   81 - first line of two line statement
;    0 - second line of two line statement
EDITORLINES	equ		$7ad7		; 16 bytes for every screen line
; 7ae7-8       zero


BAS_PrgMemory      equ     $7ae9
SysMinMemory       equ     $7b4c
MEMORY_TESTSTART       equ     $7b4d
MEMORY_MIN         equ     $7c14

/***********************************************************
 * 
 *  Laser 210/VZ210 ROM 1+2
 *  -----------------------
 *  Input/Output Interface
 *
 *  Various Sources
 ***********************************************************/

; Hardware Output Register for Gfx Mode, Speaker and Cassette Out
; bit 5 - Speaker Out (-)
; bit 4 - MC6847 CSS pin - COLOR 0 (Green) or 1 (Orange)
; bit 3 - MC6847 AG pin - MODE 0 or 1
; bit 2 - Cassette Out (-) N/C
; bit 1 - Cassette Out (+)
; bit 0 - Speaker Out (+)
IO_LATCH      equ $6800   ; (byte) write only, used bits 5-0 

CassIn       equ $6800   ; (bit 6) read only [shared with Keyboard Matrix]
INTLineIn    equ $6800   ; (bit 7) read only [shared with Keyboard Matrix]
    

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
MAT_SubBHLCust   equ $7880   ; routine entry
MAT_SubBHLArgL  equ $7881   ; LSB of value to subtract from BHL
MAT_SubBHLArgH  equ $7885   ; SB2 of value to subtract from BHL
MAT_SubBHLArgB  equ $7889   ; MB2 of value to subtract from BHL
MAT_SubBHLRetA  equ $788c   ; result value returned in A

; ACCUMULATORS

; The two arithmetic accumulators in the memory are located:
;   791d to 7824 (8 bytes) 
;   7927 to 792e (8 bytes)
; Numbers are stored in the accumulators during computations. 
; The method of storage of a given number depends on its number type, 
; and on which accumulator is being used.

; Accumulator 1
MATH_ACC_CY      equ     $791c       ; extension byte for ACC
ACC_DBL    		 equ     $791d       ; Double variable (8 bytes): LSB LSB LSB LSB LSB LSB MSB EXP
ACC_SNG        	 equ     $7921       ; Int,Single,String (2 or 4 bytes):  LSB LSB MSB EXP
MATH_ACC_MSB     equ     $7923       ; shortcut to MSB of Component part 
MATH_ACC_EXP     equ     $7924       ; shortcut to Exponent part (EXP)

; Operation sign/flags beetween Accumulators
MATH_ACC_SIGN    equ     $7925       ; math routines

; Accumulator 2
MATH_ACC2_CY     equ     $7926       ; extension byte for ACC
ACC2    equ     $7927       ; Double variable (8 bytes): LSB LSB LSB LSB LSB LSB MSB EXP
MATH_ACC2_MSB    equ     $792d       ; shortcut to MSB of Component part 
MATH_ACC2_EXP    equ     $792e       ; shortcut to Exponent part (EXP)

;794a-7951  double precision math
MATH_ACC3_DBL    equ     $794a       ; Double variable (8 bytes): LSB LSB LSB LSB LSB LSB MSB EXP
MATH_ACC3_MSB    equ     $7950       ; shortcut to MSB of Component part 
MATH_ACC3_EXP    equ     $7951       ; shortcut to Exponent part (EXP)





