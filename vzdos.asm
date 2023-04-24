	DEVICE NOSLOT64K
	SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
;***************************************************************************************************
;
; The R/W head is positioned to the desired track by applying the control signals to the stepper motor.
; The stepper motor rotates 2 steps per track.
;
; In order to assure proper positioning of the R/W head after powering on, a step-out operation 
; (recalibration) is performed until it is locked at track 00 by the track 00 stopper.
;
; The drive is selected by activating the -BENBL line. After being selected, the drive motor 
; and the LED on the front panel bezel will be on.
;
CR					EQU		$0d			; CR char
UP					EQU		$1b			; Cursor Up			

SpaceKeyRow			equ		$68ef		; Address of Keyboard Row with SPACE key
SpaceKeyCol			equ		4			; Bit Number of Keyboard Column with SPACE key
BreakKeybRow		equ		$68df		; Address of Keyboard Row with BREAK key

BreakKeybMask		equ		%00000100	; Bitmask of Keyboard Column with BREAK key
BreakKeyCol			equ		2			; Bit Number of Keyboard Column with BREAK key


;***************************************************************************************************
;
;   S Y S T E M   V A R I A B L E S
;  
;---------------------------------------------------------------------------------------------------
SysVecParse			equ		$7804	; 
SYS_BASIC_STACK		EQU		$78a0	
SYS_MEMTOP_PTR    	EQU     $78B1   ; Address of highest available RAM 
SYS_STRING_SPACE	EQU		$78d6 	; String space pointer (current location).
SYS_BACKSP_STACK	EQU		$78e8   ; backspaced stack address
SYS_BASIC_PRG		equ		$7ae9	; address of first byte of BASIC program
SYS_BASIC_START_PTR	equ 	$78a4	; 16bit pointer to start of current BASIC Program
SYS_BASIC_END_PTR	equ 	$78f9	; 16bit pointer to end of current BASIC Program
SYS_ARR_START_PTR	equ 	$78fb	; 16bit pointer to start of area for BASIC arrays
SYS_ARR_END_PTR		equ 	$78fd	; 16bit pointer to end of area for BASIC arrays
BasicLineNumber		equ		$78a2	; Current line being processed by BASIC.
ErrorLineNumber		equ		$78ea	; BASIC Line where Error occoured
EditLineNumber		equ		$78ec	; BASIC Line currently edited


;***************************************************************************************************
;
;   S Y S T E M   R O U T I N E S
;  
;---------------------------------------------------------------------------------------------------
SysPrintChar		equ		$032a	; Prints char from register a to screen (also spec char like CR)
SysNewLine			equ		$20f9	; Outputs CR to screen if cursor is not already at the beginning of line
SysMsgOut			EQU		$28a7	; MsgOut(hl)
SysStartBASIC		equ		$1a19	; Start BASIC
SysRaiseSyntaxError	equ		$1997	; Raise BASIC Syntax Error routine
SysBASICStop		equ		$1da0	; BASIC STOP proc with Break Key pressed
SysBASICReset		equ 	$1b9a	; Restart BASIC
PrintMsg_IN_LINE	equ		$0fa7	; Print IN <line number from hl>
SysCheckNextChar	equ 	$1d78	; BASIC Parser Main routine
SysExecRUN			equ		$36e9	; Execute BASIC RUN command
SysParseNextExpr	equ		$1d1e	; Parse next BASIC expression
SysSetPrgReady		equ		$1ae8	; Reset BASIC and set BASIC Program ready to run (start adr pushed on Stack)

SysCheckIllegalDirect equ	$2828	; Throw ILLEGAL DIRECT Error if current BASIC line <> FFFF

SysEvalByteExpr		equ		$2b1c	; Evaluate Integer expression and places it in ACC and register de

SysErrRaiseFuncCode equ		$1e4a	; Raise BASIC FUNCTION CODE	Error
TXT_READY			equ		$1929	; 'READY' text

;***************************************************************************************************

; Bit 0..Bit 3 : Stepper-motor control phases (active HIGH)
; Bit 4        : Drive 1 enable.(active HIGH)
; Bit 5        : Write Data (inverted, active LOW writes 1) => Output pulse when writing to diskette
; Bit 6        : Write Request (active LOW) => Access type (0 = write, 1 = read)
; Bit 7        : Drive 2 enable (active HIGH)
FLCTRL				equ		$10		; (write only) Floppy Disk Control Register

FLDATA				equ		$11		; (read only) Data Byte from FDC

FLPOOL				equ		$12		; (read only) Clock Pulse from FDC (Bit 7)

FLWRPROT			equ		$13		; (read only) Write Protect Status (Bit 7) 1=Write Protected

;--------- Bits
FL_STEPPER_MASK	equ	%00001111		; Bit 0 -.Bit 3 :Stepper-motor control phases (active HIGH)
FL_DRV_1_ENABLE	equ	%00010000		; Bit 4 : Drive 1 enable.(active HIGH)
FL_WRITE_DATA	equ	%00100000		; Bit 5 : Write Data Bit 
FL_WRITE_REQ	equ	%01000000		; Bit 6 : Write Request (active LOW)
FL_DRV_2_ENABLE	equ	%10000000		; Bit 7 : Drive 2 enable (active HIGH)


FCB_OPENFLAG	equ	0
FCB_ACCESS		equ	1
FCB_FNAM		equ	2	
FCB_TRKN0		equ	10
FCB_SCTRNO		equ	11
FCB_PTR			equ	12

FCBLENGTH		equ 13

; File number.
; When processing a data file, this is the number of the FCB block used.
;   0 = FCB1 
;   1 = FCB2
FILNO 				equ		0		; IY+00 FILE# (1 byte)

; Filename 
; Name of the file to process. Must be entered by the user program before 
; each file/program access.
FNAM				equ		1		; IY+0l FILENAME (8 bytes)

; File Type (2 bytes)
;   Byte 1 = target type.
;   Byte 2 = actual type.
; From the user program, the type of file to be processed is in the first byte.
TYPE 				equ		9		; IY+09 FILE TYPE (2 bytes)

; Selected Drive.
;   0x10 = Drive 1
;   0x80 = Drive 2
; Drive 1 (0x10) is set during initialization.
DK 					equ		11		; IY+0b SELECTED DRIVE#  (1 byte)

; Access type.
;   0 = read 
;   1 = write 
; Must be set by the user program. 
; With BASIC, this is done with the OPEN command.
RQST 				equ		12		; IY+0c REQUEST CODE (1 byte)

; Starting drive (source)
;   1 = Drive 1
;   2 = Drive 2
; Used by DCOPY command
SOURCE 				equ		13		; IY+0d SOURCE DRIVE FOR DCOPY (1 byte)

; User Buffer Address
; Address of a user buffer area to or from which data is to be transferred.
; When loading and saving programs, this is the program area.
; When reading data files, it is the BASIC input/output buffer.
UBFR 				equ		14		; IY+0e USER BUFFER ADDRESS (16bit address)

; Target drive (destination)
;   1 = Drive 1
;   2 = Drive 2
; Used by DCOPY command
DESTIN 				equ		16		; IY+10 DEST DRIVE FOR DCOPY (1 byte)

; User Sector Number.
; Number of the Sector to be used in current operation.
SCTR 				equ		17		; IY+11 USER SPEC. SECTOR NUMBER

; User Track Number.
; Number of the Track to be used in current operation.
TRCK 				equ		18		; IY+12 USER SPEC. TRACK NUMBER

; Retry counter for read errors (checksum).
; Set to 10 upon initialization.
RETRY 				equ		19		; IY+13 RETRY COUNT (1 byte)

; Current track number over which the read/write head is located.
DTRCK 				equ		20		; IY+14 CURRENT TRACK NUMBER (1 byte)

; Marker field for the next sector to be addressed.
NSCT 				equ		21		; IY+15 NEXT SCTR NUMBER (1 byte)

; Marker field for the next track to be addressed.
NTRK 				equ		22		; IY+16 NEXT TRK NUMBER (1 byte)

; File Control Block 1. (13 bytes)
;   0  FLAG Indicates the status of the FCB. 
;             0 - FCB not used 
;             1 - FCB used, file currently not active 
;             2 - FCR used, file active.
;            Active means that a current sector of this file is in the data buffer for processing
;   1 ACCESS Access type for this file.
;             0 - read
;             1 - write
;   2 FNAM   Filename (8 bytes)
;  10 TRK#   Track Number 
;  11 SCTR#  Number of currently processed Sector
;  12 PTR    Index to the next byte in this sector to be processed
FCB1 				equ		23		; IY+17 FILE CONTROL BLOCK 1 (13 bytes) 

; File Control Block 2. (13 bytes)
;   0  FLAG Indicates the status of the FCB. 
;             0 - FCB not used 
;             1 - FCB used, file currently not active 
;             2 - FCR used, file active.
;            Active means that a current sector of this file is in the data buffer for processing
;   1 ACCESS Access type for this file.
;             0 - read
;             1 - write
;   2 FNAM   Filename (8 bytes)
;  10 TRK#   Track Number 
;  11 SCTR#  Number of currently processed Sector
;  12 PTR    Index to the next byte in this sector to be processed

FCB2 				equ		36		; IY+24 FILE CONTROL BLOCK 1 (13 bytes) 


; Pointer to the DOS data buffer.
; Used for writing and reading a sector.
; This is located immediately after the DOS vectors in the work area.
DBFR 				equ		49		; IY+31 DATA BUFFER ADDRESS (16bit address)

; Copy of the command byte sent to the Floppy Disk Controller.
LTHCPY 				equ		51		; IY+33 COPY OF LATCH (1 byte)

; Disk Allocation Map buffer.
; Pointer to the DOS buffer in which 
; the sector alloacation map is temporarily stored.
; This is behind the data buffer in the DOS work area.
MAPADR 				equ		52		; IY+34 TRACK/SECTOR MAP ADDRESS (16bit address)

; Track counter for the DCOPY command.
TRKCNT 				equ		54		; IY+36 TRK CNT FOR DCOPY (1 byte)

; Track pointer for the DCOPY command.
TRKPTR 				equ		55		; IY+37 TRK PTR FOR DCOPY (1 byte)


; Step pulse raster for moving drive head (track adjustment).
; Floppy Controller accept 4 bits of Stepping Motor Phase but for simplicity
; of futher calculations this variable holds 8 bits with 4 lower bits mirrored in 4 high bits.
PHASE 				equ		56		; IY+38 STEPPER PHASE (1 byte)

; Flag for DCOPY
DCPYF				equ 	57		; IY+39 DCOPY FLAG (1 byte)

; Reserved for extensions.
RESVE				equ 	58		; IY+3a  Reserved for extensions. (10 bytes)

SectorHeader		equ		67		; IY+43 SECTOR HEADER (10 bytes) (ending sequence: GAP2 + IDAM ending)

SectorBuffer		equ		77		; IY+4d BUFFER DATA (128 bytes + 2 bytes Checksum)

SectorCRCBuf		equ		205		; IY+CD	BUFFER DATA CRC (2 bytes)	

Unknown				equ     207  	; IY+CF ??? (24 bytes)

MapBuffer		equ			231		; IY+e7 DISK ALLOCATION MAP BUFFER (80 bytes)




;***************************************************************************************************
; ROM SEQUENCE & INIT PROC
	org	$4000
	db $aa,$55,$e7,$18																				;4000	aa 55 e7 18 

;***************************************************************************************************
	di								; disable Interrupts											;4004	f3 
	jp DOSInit						; DOS initialize routine 										;4005	c3 47 40
	jp PWRON						; Disk power ON													;4008	c3 41 5f 	. A _ 
	jp PWROFF						; Disk power OFF												;400b	c3 52 5f 	. R _ 
	jp ERROR						; Error handling routine										;400e	c3 41 42 	. A B 
	jp RDMAP						; Read the track map of the disk								;4011	c3 17 47 	. . G 
	jp CLEAR						; Clear a sector of the disk									;4014	c3 49 47 	. I G 
	jp SVMAP						; Save sector allocation map to the disk						;4017	c3 54 47 	. T G 
	jp INIT							; Initialize the disk											;401a	c3 08 4b 	. . K 
	jp CSI							; Command string interpreter									;401d	c3 67 53 	. g S 
	jp HEX							; Convert ASCII to HEX											;4020	c3 b9 53 	. . S 
	jp IDAM							; Read identification address mark								;4023	c3 ea 53 	. . S 
	jp CREATE						; Create an entry in directory									;4026	c3 7b 58 	. { X 
	jp MAP							; Search for empty sector										;4029	c3 bf 58 	. . X 
	jp SEARCH						; Search for file in directory									;402c	c3 13 59 	. . Y 
	jp FIND							; Search empty space in directory								;402f	c3 68 59 	. h Y 
	jp WRITE						; Write a sector to disk										;4032	c3 a1 59 	. . Y 
	jp READ							; Read a sector from disk										;4035	c3 27 5b 	. ' [ 
	jp DLY							; Delay mS in reg C												;4038	c3 be 5e 	. . ^ 
	jp STPIN						; Track step in													;403b	c3 ce 5e 	. . ^ 
	jp STPOUT						; Track step out												;403e	c3 01 5f 	. . _ 
	jp LOAD							; Load a file from disk											;4041	c3 b1 43 	. . C 
	jp SAVE							; Save a file to disk											;4044	c3 6e 44 	. n D 



;***************************************************************************************************
; DOS INIT
; Executes at computer BOOT time when OS detects DOS ROM exists.
; - Resets Floppy Drive Controller hardware do default state.
; - Allocates 311 bytes at top of RAM for DOS Work Area (variables and buffers)
; - install hook to intercept BASIC command parser
;***************************************************************************************************
DOSInit:
; Setup Drive Controller 
; * Step Motor 0001
; * Drive 1 disabled
; * Drive 2 disabled
; * Write Request (inactive)
; * Write Data = 1
	ld a,%01100001					; Write Req + Write Data + Step Motor Phase (0001)				;4047	3e 61 	> a 
	out (FLCTRL),a					; set Flopy Control byte										;4049	d3 10 	. . 

; -- Allocate DOS memory - check top memory
	ld hl,(SYS_MEMTOP_PTR)			; hl - current top memory address								;404b	2a b1 78 	* . x 
	push hl							; save hl - top address											;404e	e5 	. 
; -- reserve 310 bytes
	ld de,-310						; de = -310 bytes to substract									;404f	11 ca fe 	. . . 
	add hl,de						; substract 310 bytes											;4052	19 	. 
; -- set DOS Base address to IY
	push hl							; transfer hl - new top address									;4053	e5 	. 
	pop iy							; ... to IY register - DOS Base									;4054	fd e1 	. . 

; -- check if enough memory
	pop hl							; hl - old top memory											;4056	e1 	. 
	ld de,$8000						; de = -32767													;4057	11 00 80 	. . . 
	or a							; clear Carry Flag												;405a	b7 	. 
	sbc hl,de						; check if top mem less than $8000								;405b	ed 52 	. R 
	jp nc,.continue					; no - continue													;405d	d2 6a 40 	. j @ 

; -- not enough memory - display error and jump to BASIC
	ld hl,ERR_InsufficientMemoryForDOS	; Error message												;4060	21 44 41 	! D A 
	ei								; enable interrupts												;4063	fb 	. 
	call SysMsgOut					; print message on screen										;4064	cd a7 28 	. . ( 
	jp SysStartBASIC				; jump to BASIC													;4067	c3 19 1a 	. . . 



; **************************************************************************************************
; Reserve 311 bytes for DOS
; Reallocate all BASIC pointers
.continue:
; -- set new MEMTOP 311 bytes lower
	add hl,de						; restore hl back to old top memory								;406a	19 	. 
	ld de,311						; reserve 311 bytes of memory									;406b	11 37 01 	. 7 . 
	sbc hl,de						; substract 311 bytes from old top mem							;406e	ed 52 	. R 
	ld (SYS_MEMTOP_PTR),hl			; store as new MEMTOP											;4070	22 b1 78 	" . x 
; -- update BASIC String Space Pointer 
	ld (SYS_STRING_SPACE),hl		; store as new String Space Pointer								;4073	22 d6 78 	" . x 
; -- update BASIC Stack Address
	ld de,50						; 50 bytes of String Space										;4076	11 32 00 	. 2 . 
	or a							; clear Carry Flag												;4079	b7 	. 
	sbc hl,de						; calculate new address											;407a	ed 52 	. R 
	ld (SYS_BASIC_STACK),hl			; store as new BASIC Stack Address								;407c	22 a0 78 	" . x 
; -- update BASIC Backspaced Stack Address
	dec hl																							;407f	2b 	+ 
	dec hl							; decrement by 2												;4080	2b 	+ 
	ld (SYS_BACKSP_STACK),hl		; store as new Backspaced Stack Address							;4081	22 e8 78 	" . x 
; -- set CPU Stack Pointer to new value
	inc hl																							;4084	23 	# 
	inc hl							; increment back by 2											;4085	23 	# 
	ld sp,hl						; set CPU stack Pointer											;4086	f9 	. 



; **************************************************************************************************
; Initialize DOS Block Memory
; Reset all parameters to default values
;
	ld (iy+DTRCK),0					; Current Track Number = 0	(Drive Head position)				;4087	fd 36 14 00 	. 6 . . 
	ld (iy+TRCK),0					; User Track Number	= 0											;408b	fd 36 12 00 	. 6 . . 
	ld (iy+SCTR),0					; User Sector Number = 0										;408f	fd 36 11 00 	. 6 . . 
	ld (iy+RETRY),10				; Read/Write Retry Counter = 10									;4093	fd 36 13 0a 	. 6 . . 
	ld (iy+NTRK),0					; Next Track = 0												;4097	fd 36 16 00 	. 6 . . 
	ld (iy+NSCT),0					; Next Sector = 0												;409b	fd 36 15 00 	. 6 . . 
	ld (iy+FCB1),0					; File Control Block 1 Open Flag = not open 					;409f	fd 36 17 00 	. 6 . . 
	ld (iy+FCB2),0					; File Control Block 2 Open Flag = not open						;40a3	fd 36 24 00 	. 6 $ . 
	ld (iy+DCPYF),0					; Flag for DCOPY command = none									;40a7	fd 36 39 00 	. 6 9 . 
	ld (iy+DK),$10					; Selected Drive 1												;40ab	fd 36 0b 10 	. 6 . . 
	ld (iy+LTHCPY),%01100001		; Update Shadow Register with value written to FDC Control 		;40af	fd 36 33 61 	. 6 3 a 
; -- Stepper Phase contains 4 bits values duplicated in high and low nibble
;    this way futher rotation operations used by StepIn and StepOut don't need any corrections
	ld (iy+PHASE),%00010001			; Stepper Phase 0001-0001										;40b3	fd 36 38 11 	. 6 8 . 

; -- set address of Sector Data as operation Buffer
	push iy							; iy - DOS base address											;40b7	fd e5 	. . 
	pop hl							; copy to hl													;40b9	e1 	. 
	ld de,SectorBuffer				; offset from DOS Base to Sector Buffer							;40ba	11 4d 00 	. M . 
	add hl,de						; hl - absolute address of Sector Data Buffer					;40bd	19 	. 
	ld (iy+DBFR),l					; store as Data Buffer (low byte)								;40be	fd 75 31 	. u 1 
	ld (iy+DBFR+1),h				; store as Data Buffer (high byte)								;40c1	fd 74 32 	. t 2 

; -- fill Sector Header data with default values
; only 10 bytes of Sector Header ending sequence: GAP2 + IDAM ending
	ld de,-10						; de = -10 														;40c4	11 f6 ff 	. . . 
	add hl,de						; hl - 10 bytes before sector buffer							;40c7	19 	. 
	ex de,hl						; de - SectorHeader address 									;40c8	eb 	. 
	ld hl,SectorGAP2Data			; hl - default Sector Header ending sequence (source)			;40c9	21 5d 4d 	! ] M 
	ld bc,10						; 10 bytes to copy												;40cc	01 0a 00 	. . . 
	ldir							; copy template data											;40cf	ed b0 	. . 

; --set address for Disk Allocation Map Buffer
	push iy							; iy - DOS base address											;40d1	fd e5 	. . 
	pop hl							; copy to hl													;40d3	e1 	. 
	ld de,MapBuffer					; offset from DOS base to Alloc Map Buffer area					;40d4	11 e7 00 	. . . 
	add hl,de						; hl - absolute address of Alloc Map Buffer						;40d7	19 	. 
	ld (iy+MAPADR),l				; store low byte												;40d8	fd 75 34 	. u 4 
	ld (iy+MAPADR+1),h				; store high byte												;40db	fd 74 35 	. t 5 

; -- reset Head position in Floppy Drive 1 to Track 00
;    move Head 40 times so it will be on Track 00 no matter where it was when power off
	call PWRON						; Disk power ON													;40de	cd 41 5f 	. A _ 
	ld b,40							; max 40 tracks to STEPOUT										;40e1	06 28 	. ( 
	call STPOUT						; step out 40 times 											;40e3	cd 01 5f 	. . _ 
	call PWROFF						; Disk power OFF												;40e6	cd 52 5f 	. R _ 

; -- Hook Up BASIC parser (RST 10) to allow DOS Commands
	ld hl,DOSCheckNextChar			; NextToken replace routine										;40e9	21 93 42 	! . B 
	ld (SysVecParse),hl				; set new jump address to intercept BASIC Parser				;40ec	22 04 78 	" . x 

; -- print DOS BASIC V1.2
	ld hl,TxtDosBasic12				; text message "DOS BASIC V1.2"									;40ef	21 13 41 	! . A 
	ei								; enable interrupt 												;40f2	fb 	. 
	call SysMsgOut					; print message on screen via System routine					;40f3	cd a7 28 	. . ( 

; -- check if another ROM is present - continue chain initialization
	ld hl,$6000						; ROM address 													;40f6	21 00 60 	! . ` 
; -- test ROM sequence: AA 55 E7 18
	ld a,$aa						; a - 1st sequence byte											;40f9	3e aa 	> . 
	cp (hl)							; test if matches												;40fb	be 	. 
	inc hl							; hl - next ROM address											;40fc	23 	# 
	jr nz,.finish					; no - start BASIC												;40fd	20 10 	  . 
	ld a,$55						; a - 2nd sequence byte											;40ff	3e 55 	> U 
	cp (hl)							; test if matches												;4101	be 	. 
	inc hl							; hl - next ROM address											;4102	23 	# 
	jr nz,.finish					; no - start BASIC												;4103	20 0a 	  . 
	ld a,$e7						; a - 3rd sequence byte											;4105	3e e7 	> . 
	cp (hl)							; test if matches												;4107	be 	. 
	inc hl							; hl - next ROM address											;4108	23 	# 
	jr nz,.finish					; no - start BASIC												;4109	20 04 	  . 
	ld a,$18						; a - 4th sequence byte											;410b	3e 18 	> . 
	cp (hl)							; test if matches												;410d	be 	. 
	inc hl							; hl - next ROM address											;410e	23 	# 
.finish:
	jp nz,SysStartBASIC				; no - start BASIC --------------------------------------------	;410f	c2 19 1a 	. . . 
; -- if match found then start ROM init routine
	jp (hl)							; jump to ROM Init ($6004) ------------------------------------	;4112	e9 	. 



; **************************************************************************************************
; DOS Title Text
TxtDosBasic12:
	db UP,UP,"DOS BASIC V1.2",CR,CR,0	;4113	1b 1b 44 4f 53 20 42 41 53 49 43 20 56 31 2e 32 0d 0d 00 



; **************************************************************************************************
; Table with addresses of Error Texts
; Every entry contain absolute address of Error Text
; Errors 0,1 and 17 are handled by ROM standard routines so there is no Texts in DOS ROM
ErrorsTable:	
									; Error 00   NO ERROR (OK)
									; Error 01   SYNTAX ERROR
	dw ERR_FileAlreadyExists		; Error 02   FILE ALREADY EXISTS								;4126	62 41 
	dw ERR_DirectoryFull			; Error 03   DIRECTORY FULL										;4128	77 41 
	dw ERR_DiskWriteProtected		; Error 04   DISK WRITE PROTECTED								;412a	87 41 
	dw ERR_FileNotOpen				; Error 05   FILE NOT OPEN										;412c	9d 41 
	dw ERR_DiskIOError				; Error 06   DISK I/O ERROR										;412e	ac 41
	dw ERR_DiskFull					; Error 07   DISK FULL											;4130	bc 41 
	dw ERR_FileAlreadyOpen			; Error 08   FILE ALREADY OPEN									;4132	c7 41 
	dw ERR_DiskIOError				; Error 09   SECTOR NOT FOUND									;4134	ac 41
	dw ERR_DiskIOError				; Error 10   CHECKSUM ERROR										;4136	ac 41 
	dw ERR_UnsupportedDevice		; Error 11   UNSUPPORTED DEVICE									;4138	da 41 
	dw ERR_FileTypeMismatch			; Error 12   FILE TYPE MISMATCH									;413c	ee 41
	dw ERR_FileNotFound				; Error 13   FILE NOT FOUND										;413c	02 42
	dw ERR_DiskBufferFull			; Error 14   DISK BUFFER FULL									;413e	12 42
	dw ERR_IllegalRead				; Error 15   ILLEGAL READ										;4140	24 42 
	dw ERR_IllegalWrite				; Error 16   ILLEGAL WRITE										;4142	32 42 
									; Error 17   BREAK


; **************************************************************************************************
; Error Texts
; Every text is terminated with byte 0 (NULL)
ERR_InsufficientMemoryForDOS:
	db "?INSUFFICIENT MEMORY FOR DOS",CR,0	;4144	3f 49 4e 53 55 46 46 49 43 49 45 4e 54 20 4d 45 4d 4f 52 59 20 46 4f 52 20 44 4f 53 0d 00 
ERR_FileAlreadyExists:
	db "?FILE ALREADY EXISTS",0				;4162	3f 46 49 4c 45 20 41 4c 52 45 41 44 59 20 45 58 49 53 54 53 00 	
ERR_DirectoryFull:
	db "?DIRECTORY FULL",0					;4177	3f 44 49 52 45 43 54 4f 52 59 20 46 55 4c 4c 00 
ERR_DiskWriteProtected:
	db "?DISK WRITE PROTECTED",0			;4187	3f 44 49 53 4b 20 57 52 49 54 45 20 50 52 4f 54 45 43 54 45 44 00 
ERR_FileNotOpen:
	db "?FILE NOT OPEN",0					;419d	3f 46 49 4c 45 20 4e 4f 54 20 4f 50 45 4e 00 
ERR_DiskIOError:
	db "?DISK I/O ERROR",0					;41ac	3f 44 49 53 4b 20 49 2f 4f 20 45 52 52 4f 52 00
ERR_DiskFull:
	db "?DISK FULL",0						;41bc	3f 44 49 53 4b 20 46 55 4c 4c 00 
ERR_FileAlreadyOpen:
	db "?FILE ALREADY OPEN",0				;41c7	3f 46 49 4c 45 20 41 4c 52 45 41 44 59 20 4f 50 45 4e 00 
ERR_UnsupportedDevice:	
	db "?UNSUPPORTED DEVICE",0				;41da	3f 55 4e 53 55 50 50 4f 52 54 45 44 20 44 45 56 49 43 45 00 
ERR_FileTypeMismatch:	
	db "?FILE TYPE MISMATCH",0				;41ee	3f 46 49 4c 45 20 54 59 50 45 20 4d 49 53 4d 41 54 43 48 00 
ERR_FileNotFound:
	db "?FILE NOT FOUND",0					;4202	3f 46 49 4c 45 20 4e 4f 54 20 46 4f 55 4e 44 00 
ERR_DiskBufferFull:
	db "?DISK BUFFER FULL",0				;4212	3f 44 49 53 4b 20 42 55 46 46 45 52 20 46 55 4c 4c 00 
ERR_IllegalRead:
	db "?ILLEGAL READ",0					;4224	3f 49 4c 4c 45 47 41 4c 20 52 45 41 44 00 
ERR_IllegalWrite:
	db "?ILLEGAL WRITE",0					;4232	3f 49 4c 4c 45 47 41 4c 20 57 52 49 54 45 00 



;***************************************************************************************************
; Error handling routine
;---------------------------------------------------------------------------------------------------
; Reads the content of register A and prints the .error message before going back to BASIC.
; IN: A - Error Code (0..17)
; OUT: Exit to BASIC
;***************************************************************************************************
ERROR:
; -- cleanup BASIC if  ???
	push af							; save a - Error Code											;4241	f5 	. 
	ld a,(iy+DCPYF)					; a - DCOPY flag 												;4242	fd 7e 39 	. ~ 9 
	or a							; is DCOPY command in progress?									;4245	b7 	. 
	call nz,ClearBASIC				; yes - Clear BASIC program and select drive D1					;4246	c4 44 51 	. D Q 
	pop af							; restore a - Error Code										;4249	f1 	. 

;***************************************************************************************************
; Handle error:
; * 0 - no error 					-> switch to BASIC
; * 1 - Syntax Error 				-> handled by BASIC standard routine
; * 2..16 - custom DOS error 		-> show error text and switch to BASIC
; * 17 - Break Key pressed 			-> hadled by BASIC standard routine

; -- check if No Error (Error Code = 0)
	or a							; check if 0 - No Error											;424a	b7 	
	jr z,.GotoBASICReady			; yes - switch to BASIC											;424b	28 34 

; -- check if Syntax Error (Error Code 1)
	cp 01							; check if Error Code = 1 (Syntax Error)						;424d	fe 01 	
	jp z,SysRaiseSyntaxError		; yes - use BASIC routine to handle Error						;424f	ca 97 19 	. . . 

; -- check if BREAK (Error Code 17)
	cp 17							; check if Error Code = 17 (BREAK)								;4252	fe 11 	. . 
	jp z,.GotoBASICBreak			; yes - switch to BASIC handler									;4254	ca 8a 42 	

; -- Move Screen cursor to begin of next line 
	push af							; save a - Error Code											;4257	f5 	. 
	call SysNewLine					; call system routine to print CR 								;4258	cd f9 20 	. .   
	pop af							; restore a - Error Code										;425b	f1 	. 

; -- calculate address of error text for Code 
;    ErrorsTable has addresses for errors 2..16 so shift begin by 2 entries 2 bytes each 
	ld hl,ErrorsTable-4				; table with addr of error messages (minus 2 entries)			;425c	21 22 41 	! " A 
	sla a							; a = Error Code x 2 bytes per entry							;425f	cb 27 	. ' 
	add a,l							; add to hl														;4261	85 	. 
	ld l,a																							;4262	6f 	o 
	ld a,0																							;4263	3e 00 	> . 
	adc a,h																							;4265	8c 	. 
	ld h,a							; hl - points to entry in ErrorsTable for specyfic Error		;4266	67 	g 
	ld e,(hl)						; e - low byte of oddress of Error text							;4267	5e 	^ 
	inc hl							; next byte of address											;4268	23 	# 
	ld d,(hl)						; de - address of Error text									;4269	56 	V 
	ex de,hl						; hl - address of Error text									;426a	eb 	. 

; -- turn Disk Off and print error on screen
	call PWROFF						; Turn Off Disk power 											;426b	cd 52 5f 	. R _ 
	call SysMsgOut					; print error text												;426e	cd a7 28 	. . ( 

; -- set BASIC line number where Error was found
	ld hl,(BasicLineNumber)			; hl - Current line being processed by BASIC or Command			;4271	2a a2 78 	* . x 
	ld (ErrorLineNumber),hl			; set BASIC Line where Error occoured							;4274	22 ea 78 	" . x 
	ld (EditLineNumber),hl			; BASIC Line currently edited									;4277	22 ec 78 	" . x 

; -- check if error was found in program line or wrote on screen as direct command (-1)
	inc hl							; hl will be 0 if outside of BASIC program						;427a	23 	# 
	ld a,l																							;427b	7d 	} 
	or h							; check if hl not equal 0 (error in line)						;427c	b4 	. 
	dec hl							; hl - Basic line												;427d	2b 	+ 
	call nz,PrintMsg_IN_LINE		; yes - Print IN <line number from hl>							;427e	c4 a7 0f 	. . . 

.GotoBASICReady:
; -- transfer control to BASIC/ROM 
	ld bc,SysStartBASIC				; address of BASICReady entry point routune to execute			;4281	01 19 1a 	. . . 
	ld hl,(SYS_BACKSP_STACK)		; initial address of BASIC stack								;4284	2a e8 78 	* . x 
	jp SysBASICReset				; reset BASIC variables and go to BASIC Ready -----------------	;4287	c3 9a 1b 	. . . 

.GotoBASICBreak:
; -- transfer control to BASIC/ROM simulating BREAK Key Pressed
	call PWROFF						; Disk power OFF												;428a	cd 52 5f 	. R _ 
	ld a,1							; BREAK Key to simulate via BASIC								;428d	3e 01 	> . 
	ei								; enable interrupts												;428f	fb 	. 
	jp SysBASICStop					; jump to BASIC STOP routine ----------------------------------	;4290	c3 a0 1d 	. . . 





;***************************************************************************************************
; Routine called when BASIC parse next char/token 
; IN: hl - address of next char/token to parse
;     [sp] - return address to calling routine
DOSCheckNextChar:
; -- test if this code was called from specific ROM routine
	exx								; save bc,de,hl to alteranate register set						;4293	d9 	. 
	ld hl,$1d5b						; expected return address										;4294	21 5b 1d 	! [ . 
	pop de							; de - return address to calling routine						;4297	d1 	. 
	or a							; clear Carry flag												;4298	b7 	. 
	sbc hl,de						; is return address is eual to expected? 						;4299	ed 52 	. R 
	push de							; push back original return address on stack					;429b	d5 	. 
	exx								; restore bc,de,hl from alternate register set					;429c	d9 	. 
	jp nz,SysCheckNextChar			; not equal - jump to ROM original routine 						;429d	c2 78 1d 	. x . 

; -- this code was called from expected BASIC ROM routine
	push hl							; save hl - address of next char to parse						;42a0	e5 	. 
	call SysCheckNextChar			; call BASIC Parser Main routine first							;42a1	cd 78 1d 	. x . 
	jr nz,.startParse				; if not end of BASIC expression - try to parse					;42a4	20 02 	  . 

; -- end of expression (':') or end of BASIC line ('\0') found
.exit:
	pop de							; restore stack pointer 										;42a6	d1 	. 
	ret								; ---------------------- End of Proc --------------------------	;42a7	c9 	. 

;***************************************************************************************************
; Parse BASIC expression
; IN: hl - address of next char/token to parse
;     a - next char/token to parse
;---------------------------------------------------------------------------------------------------
.startParse:
	or a							; is it BASIC token char (a >= 128)?							;42a8	b7 	. 
	jp p,ParseCmdText				; no - parse expression as text (command)						;42a9	f2 ef 42 	. . B 
; -- command token
	cp $8e							; is it RUN command?											;42ac	fe 8e 	. . 
	jr nz,.exit						; no - return to BASIC ----------------------------------------	;42ae	20 f6 	  . 




;***************************************************************************************************
; DOS Command RUN
;---------------------------------------------------------------------------------------------------
; Syntax: RUN "filaname"
; Load one file specified by filename (which has the file type code "T") from a Floppy Disk 
; and RUN it (execute). Filename may have no more than 8 characters. If user typed just RUN command
; without filename then standard BASIC 'RUN' command will be parsed and executed. 
.parse_RUN:
	inc hl							; hl - next char or token										;42b0	23 	# 
	ld a,(hl)						; a -  next char or token										;42b1	7e 	~ 
	or a							; is it '\0' - end of BASIC line								;42b2	b7 	. 
	jr z,.backToROM					; yes - just 'RUN' command - jump to ROM original routine -----	;42b3	28 10 	( . 

; -- skip trailing spaces
	cp ' '							; is it ' ' char?												;42b5	fe 20 	.   
	jr z,.parse_RUN					; yes - ignore it - parse next char								;42b7	28 f7 	( . 

; -- expected name of file enclosed in double quote chars '"'
	cp '"'							; is it double quote char '"' ?									;42b9	fe 22 	. " 
	jr nz,.backToROM				; no - no filename after 'RUN' - jump to ROM original routine 	;42bb	20 08 	  . 

; -- found '"' char - expecting filename
	pop de							; de - address of command start to parse 						;42bd	d1 	. 
	ld bc,LoadAndRunFile			; bc - routine to load file and execute BASIC RUN command		;42be	01 db 45 	. . E 
	dec hl							; hl - last char of filename									;42c1	2b 	+ 
	ex de,hl						; hl - start of command RUN, de - end of filename				;42c2	eb 	. 
	jr ExecDOSCmd					; execute LoadAndRunFile and return to BASIC ------------------	;42c3	18 61 	. a 

.backToROM:
	pop hl							; restore hl - parse point 										;42c5	e1 	. 
	jp SysCheckNextChar				; jump to ROM original routine --------------------------------	;42c6	c3 78 1d 	. x . 


;***************************************************************************************************
; There is a chance that 2 DOS commands will be tokenized "mixed" way: BRUN and DCOPY.
; Because standard BASCI already have commands RUN and COPY it can tokenize above DOS comands
; as 1 ASCII char and standard command token: 'B'+token of RUN and 'D'+token of COPY.
; This routine covers these two cases.
TryParseMixedSyntax:
	pop hl							; restore hl - parse point 										;42c9	e1 	. 
	push hl							; save hl back - parse point									;42ca	e5 	. 

; -- check if it's stored as "mixed" BRUN (where 'B' is ASCII char and 'RUN' is a token $8e)
	inc hl							; hl - point to next char of expression							;42cb	23 	# 
	ld a,(hl)						; a - parsed char 												;42cc	7e 	~ 
	cp 'B'							; is it 'B'?													;42cd	fe 42 	. B 
	jr nz,.checkDCOPY				; no - check possible DCOPY Command								;42cf	20 0b 	  . 
	inc hl							; point to next char											;42d1	23 	# 
	ld a,(hl)						; a - parsed char/token											;42d2	7e 	~ 
	cp $8e							; is it BASIC 'RUN" token?										;42d3	fe 8e 	. . 
	jr nz,.backToROM				; no - transfer control to BASIC Parser Main routine			;42d5	20 14 	  . 
	ld b,6							; b - index of DOS 'BRUN' Command								;42d7	06 06 	. . 
	push bc							; put bc on stack - DOS 'BRUN' Command							;42d9	c5 	. 
	jr ExecIdxDOSCmd				; execute DOS command determined by index in register b			;42da	18 39 	. 9 

.checkDCOPY:
; -- check if it's stored as "mixed" DCOPY (where 'D' is ASCII char and 'COPY' is a token $96)
	cp 'D'							; is it 'D'?													;42dc	fe 44 	. D 
	jr nz,.backToROM				; no - transfer control to BASIC Parser Main routine			;42de	20 0b 	  . 
	inc hl							; point to next char											;42e0	23 	# 
	ld a,(hl)						; a - parsed char/token											;42e1	7e 	~ 
	cp $96							; is it BASIC 'COPY" token?										;42e2	fe 96 	. . 
	jr nz,.backToROM				; no - transfer control to BASIC Parser Main routine			;42e4	20 05 	  . 
	ld b,14							; b - index of DOS 'DCOPY' Command								;42e6	06 0e 	. . 
	push bc							; put bc on stack - DOS 'DCOPY' Command							;42e8	c5 	. 
	jr ExecIdxDOSCmd				; execute DOS command determined by index in register b			;42e9	18 2a 	. * 
.backToROM:
	pop hl							; restore hl - parse point 										;42eb	e1 	. 
	jp SysCheckNextChar				; jump to ROM original routine --------------------------------	;42ec	c3 78 1d 	. x . 



;***************************************************************************************************
; Parse and execute BASIC text expression as DOS command
; IN: hl - address of text expression
ParseCmdText:
	ld de,DOSCmdNames-1				; de - table with all DOS commands text (will be incremented)	;42ef	11 2d 43 	. - C 
	ld b,-1							; b - Command number 											;42f2	06 ff 	. . 

.compareCmd:
	ld c,(hl)						; c - first char to check										;42f4	4e 	N 
	ex de,hl						; hl - address in Commands Table, de - point to parsed char 	;42f5	eb 	. 

.searchNext:
; -- find start of DOS command text (with bit 7 set)
	inc hl							; point to next char in Commands Table							;42f6	23 	# 
	or (hl)							; is 7th bit set?												;42f7	b6 	. 
	jp p,.searchNext				; no - keep search start of DOS Command							;42f8	f2 f6 42 	. . B 

; -- found start of command
	inc b							; b - number of command (00..0d)								;42fb	04 	. 
	ld a,(hl)						; a - 1st char of DOS Command									;42fc	7e 	~ 
	and %01111111					; clear 7th bit (convert to ascii) - end of table if was $80?	;42fd	e6 7f 	.  
	jr z,TryParseMixedSyntax		; yes - try parse "mixed" format BRUN or DCOPY					;42ff	28 c8 	( . 
; -- compare 1st chars 
	cp c							; is 1st char of DOS command equal to parsed char?				;4301	b9 	. 
	jr nz,.searchNext				; no - keep search start of DOS command							;4302	20 f2 	  . 

; -- first char match
	ex de,hl						; de - address in Commands Table, hl - point to parsed char		;4304	eb 	. 
	push hl							; save hl - point to parsed char								;4305	e5 	. 
.compareNext:
	inc de							; point to next char in Commands Table							;4306	13 	. 
	ld a,(de)						; a - next char of DOS Command									;4307	1a 	. 
	or a							; is bit 7 set? (start of next command name)					;4308	b7 	. 
	jp m,ExecIdxDOSCmd				; yes - execute DOS command determined by index in register b	;4309	fa 15 43 	. . C 

; -- compare next chars
	ld c,a							; c - char of Command from Commands Table						;430c	4f 	O 
	inc hl							; point to next parsed char										;430d	23 	# 
	ld a,(hl)						; a - parsed char												;430e	7e 	~ 
	cp c							; is the same as char from Commands Table?						;430f	b9 	. 
	jr z,.compareNext				; yes - continue to compare next chars							;4310	28 f4 	( . 
; -- chars differs - try next entry from Commands Table
	pop hl							; restore hl - start of parsed text								;4312	e1 	. 
	jr .compareCmd					; compare to next DOS Command ---------------------------------	;4313	18 df 	. . 


;***************************************************************************************************
; Find entry point of DOS Command and Execute it
; IN: b - index of DOS Command to execute 
ExecIdxDOSCmd:
	ld a,b							; a - DOS Command index											;4315	78 	x 
; -- clean up stack
	pop bc							; take out value - move CPU stack pointer						;4316	c1 	. 
	pop bc							; take out value - move CPU stack pointer						;4317	c1 	. 
	pop bc							; take out value - move CPU stack pointer						;4318	c1 	. 

; -- find address of code to execute for this command
	sla a							; a - command index * 2 (every table entry has 16bit address) 	;4319	cb 27 	. ' 
	ld c,a							; c - offset in DOS Command Pointers table						;431b	4f 	O 
	ld b,0							; bc - offset in DOS Command Pointers table						;431c	06 00 	. . 
	ex de,hl						; de - piont to parsed char										;431e	eb 	. 
	ld hl,DOSCmdPointers			; hl - table with pointers for every DOS Command 				;431f	21 71 43 	! q C 
	add hl,bc						; add offset for DOS Command									;4322	09 	. 
	ld c,(hl)						; c - LSB of code address 										;4323	4e 	N 
	inc hl							; point to next byte with MSB									;4324	23 	# 
	ld b,(hl)						; bc - address of code to execute for DOS Command				;4325	46 	F 


; IN: de - point to parsed char
;     bc - address of routine to execute
ExecDOSCmd:
	ld hl,SysParseNextExpr			; hl address of System routine to continue run next expression	;4326	21 1e 1d 	! . . 
	push hl							; push on stack as return after executing DOS command			;4329	e5 	. 
	ex de,hl						; hl - next parsed char											;432a	eb 	. 
	inc hl							; hl - parse point												;432b	23 	# 
	push bc							; push DOS Command routine address on stack						;432c	c5 	. 
	ret								; execute code routine ----------------------------------------	;432d	c9 	. 



; **************************************************************************************************
; DOS Commands Names for Parser
; First byte of Name has bit 7 set to 1. End of table is marked with byte $80 (0 with 7th bit set).
DOSCmdNames:
	defb 	$80|'L','OAD'			; 00 LOAD			; Load program file from Disk				;432e	cc 4f 41 44 	D 
	defb	$80|'S','AVE'			; 01 SAVE			; Save program file to Disk					;4332	d3 41 56 45 	E 
	defb	$80|'O','PEN'			; 02 OPEN			; Open file on Disk to read or write		;4336	cf 50 45 4e 	N 
	defb	$80|'C','LOSE'			; 03 CLOSE			; Close opened file							;433a	c3 4c 4f 53 45 	E 
	defb	$80|'B','SAVE'			; 04 BSAVE			; Save binary file							;433f	c2 53 41 56 45 	E 
	defb	$80|'B','LOAD'			; 05 BLOAD			; Load binary file							;4344	c2 4c 4f 41 44 	D 
	defb	$80|'B','RUN'			; 06 BRUN			; Load and Run binary program				;4349	c2 52 55 4e 	N 
	defb	$80|'D','IR'			; 05 DIR			; Print Directory (list files)				;434d	c4 49 52 	. I R 
	defb	$80|'E','RA'			; 06 ERA			; Erase (delete) file from Disk				;4350	c5 52 41 	A 
	defb	$80|'R','EN'			; 07 REN			; Rename file on Disk						;4353	d2 45 4e 	. E N 
	defb	$80|'I','NIT'			; 08 INIT			; Initialize (format) Disk					;4356	c9 4e 49 54 	T 
	defb	$80|'D','RIVE'			; 09 DRIVE			; Select active Drive						;435a	c4 52 49 56 45 	E 
	defb	$80|'I','N#'			; 0A IN#			; Read data from channel # 					;435f	c9 4e 23 	# 
	defb	$80|'P','R#'			; 0B PR#			; Print data to channel #					;4362	d0 52 23 	# 
	defb	$80|'D','COPY'			; 0C DCOPY			; Disk copy									;4365	c4 43 4f 50 59 	Y 
	defb	$80|'S','TATUS'			; 0D STATUS			; Print status of active Disk				;436a	d3 54 41 54 55 53 	S 
	defb	$80						; -----------------	; End of Table marker ---------------------	;4370	80 	. 

; **************************************************************************************************
; DOS Commands Execute Addresses
; One 16bit address of code to execute per every DOS Command listed in DOSCmdNames Table 
DOSCmdPointers:
	defw	DCmdLOAD				; 00 LOAD			; Load program file from Disk				;4371	91 43 	C 
	defw	DCmdSAVE				; 01 SAVE			; Save program file to Disk					;4373	4e 44 	D 
	defw	DCmdOPEN				; 02 OPEN			; Open file on Disk to read or write		;4375	f5 45 	E 
	defw	DCmdCLOSE				; 03 CLOSE			; Close opened file							;4377	dd 47 	. G 9 
	defw	DCmdBSAVE				; 04 BSAVE			; Save binary file							;4379	39 48 	H 
	defw	DCmdBLOAD				; 05 BLOAD			; Load binary file							;437b	c4 48  	. H . 
	defw	DCmdBRUN				; 06 BRUN			; Load and Run binary program				;437d	ef 48 	H 
	defw	DCmdDIR					; 05 DIR			; Print Directory (list files)				;437f	06 49 	. I 
	defw	DCmdERA					; 06 ERA			; Erase (delete) file from Disk				;4381	94 49 	I 
	defw	DCmdREN					; 07 REN			; Rename file on Disk						;4383	80 4a 	J 
	defw	DCmdINIT				; 08 INIT			; Initialize (format) Disk					;4385	08 4b 	K 
	defw	DCmdDRIVE				; 09 DRIVE			; Select active Drive						;4387	78 4d 	M 
	defw	DCmdIN#					; 0A IN#			; Read data from channel # 					;4389	92 4d 	M 
	defw	DCmdPR#					; 0B PR#			; Print data to channel #					;438b	64 4e 	N 
	defw	DCmdDCOPY				; 0C DCOPY			; Disk copy									;438d	fb 4f 	O 
	defw	DCmdSTATUS				; 0D STATUS			; Print status of active Disk				;438f	d5 52 	R 


;***************************************************************************************************
; DOS Command LOAD
; Syntax: LOAD "filaname"
; -----------------------
; Load file specified by filename (which has the file type code "T") from a Floppy Disk.
; Filename may have no more than 8 characters.
; IN: hl - parse point (just after 'LOAD' text)
DCmdLOAD:
; -- expected required name of file enclosed with double quote chars 
;    and termianted with \0 or ':' char (end of BASIC expression)
	call CSI						; parse filename and copy it to (iy+FNAM)						;4391	cd 67 53 	. g S 
	push hl							; save hl - parse point											;4394	e5 	. 
	or a							; was any Error?												;4395	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;4396	c2 41 42 	. A B 

; -- set type of file as BASIC text ('T') and call DOS routine
	ld (iy+TYPE),'T'				; set type of file as BASIC text ('T')							;4399	fd 36 09 54 	. 6 . T 
	call LOAD						; Load a file from disk											;439d	cd b1 43 	. . C 
	or a							; was any Error?												;43a0	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;43a1	c2 41 42 	. A B 

; -- print 'READY' on screen
	ld hl,TXT_READY					; hl - address of 'READY' text in ROM							;43a4	21 29 19 	! ) . 
	call SysMsgOut					; display text on screen										;43a7	cd a7 28 	. . ( 
; -- push on Stack address of 1st BASIC line and run it
	ld hl,(SYS_BASIC_START_PTR)		; start of current BASIC Program 								;43aa	2a a4 78 	* . x 
	push hl							; push hl on stack as next thing to parse and run				;43ad	e5 	. 
	jp SysSetPrgReady				; Reset BASIC and set BASIC Program ready to run --------------	;43ae	c3 e8 1a 	. . . 




;***************************************************************************************************
; Load the file specified in IY+FNAM to the memory.
;---------------------------------------------------------------------------------------------------
; NOTE: Aside from filename, file type, sector and track, directory entry for that file contains 
; 16-bit addresses of start and end (excluded) of memory area where file will be loaded.
; IN: interrups disabled
;     (iy+FNAM) - name of the file to load 
;     (iy+TYPE) - type of the file to load 
; OUT: a - Error code
;      File loaded in memory
;***************************************************************************************************
LOAD:
	di								; disable interrupts											;43b1	f3 	. 
; -- turn onn drive and wait 50 ms
	call PWRON						; Disk power ON													;43b2	cd 41 5f 	. A _ 
	push bc							; save bc														;43b5	c5 	. 
	ld bc,50						; number of miliseconds to delay								;43b6	01 32 00 	. 2 . 
	call DLY						; delay 50 ms													;43b9	cd be 5e 	. . ^ 
	pop bc							; restore bc													;43bc	c1 	. 

; -- try to find file on disk
	call SEARCH						; Search for file in disk directory								;43bd	cd 13 59 	. . Y 
	cp 2							; was Error 02 - FILE ALREADY EXISTS?							;43c0	fe 02 	. . 
	jp z,.verifyType				; yes - file found - continue and verify file type				;43c2	ca ca 43 	. . C 

; -- could be other Error
	or a							; is any Error?													;43c5	b7 	. 
	ret nz							; yes - ------------- End of Proc (with Error) ----------------	;43c6	c0 	. 

; -- no errors means file not found
	ld a,13							; a - Error 13 - FILE NOT FOUND									;43c7	3e 0d 	> . 
	ret								; ------------------- End of Proc (with Error) ----------------	;43c9	c9 	. 


.verifyType:
; -- verify file types 
	ld a,(iy+TYPE)					; a - requested file type										;43ca	fd 7e 09 	. ~ . 
	cp (iy+TYPE+1)					; is the same as type of file just found?						;43cd	fd be 0a 	. . . 
	ld a,12							; a - Error 12 - FILE TYPE MISMATCH								;43d0	3e 0c 	> . 
	ret nz							; no - ------------------ End of Proc (with Error) ------------	;43d2	c0 	. 

; --------------------------------------------------------------------------------------------------
; When SEARCH returns with Error 02 (FILE ALREADY EXISTS) it means we have found Directory Entry
; with that file. In this case registers are set as:
; de - address of file track number (next byte after filename in loaded Directory Entry)


;***************************************************************************************************
; Load program bytes from disk into memory.
; File must be type 'T' (BASIC) or 'B' (binary) and directory entry of file must be loaded into buffer.
; Directory entry contains: Track Number, Sector Number, Program Start address and Program End Address
; IN: de - address in directory entry just after filename (pointing to Track Number)
LoadProgramData:
; -- set track number of Sector to read
	ld a,(de)						; a - Track Number of file										;43d3	1a 	. 
	inc de							; de - address of Sector Number in Directory Entry 				;43d4	13 	. 
	ld (iy+TRCK),a					; set as requested Track Number									;43d5	fd 77 12 	. w . 

; -- set Sector Number of Sector to read
	ld a,(de)						; a - Sector Number of file										;43d8	1a 	. 
	inc de							; de - address of file Start/Load address						;43d9	13 	. 
	ld (iy+SCTR),a					; set as requested Sector Number								;43da	fd 77 11 	. w . 

; -- set boundary of memory where file must be loaded
	ex de,hl						; hl - address of file Start/Load address						;43dd	eb 	. 
	ld e,(hl)						; e - LSB of destination address								;43de	5e 	^ 
	inc hl							; point to MSB of dectination address							;43df	23 	# 
	ld d,(hl)						; de - address of memory where load file						;43e0	56 	V 
	inc hl							; point to LSB of end of memory area							;43e1	23 	# 

; -- set destination address as BASIC program Start and DOS Buffer
	ld (SYS_BASIC_START_PTR),de		; store destination program start as BASIC Program Start 		;43e2	ed 53 a4 78 	. S . x 
	ld (iy+UBFR),e					; store destination program start as buffer address				;43e6	fd 73 0e 	. s . 
	ld (iy+UBFR+1),d																				;43e9	fd 72 0f 	. r . 

; -- set end of destination address as BASIC program End
	ld e,(hl)						; e - LSB of memory address where loaded file ends 				;43ec	5e 	^ 
	inc hl							; point to MSB of memory address								;43ed	23 	# 
	ld d,(hl)						; de - memory address where loaded file ends (excluded)			;43ee	56 	V 
	ld (SYS_BASIC_END_PTR),de		; set address as BASIC Program End								;43ef	ed 53 f9 78 	. S . x 

;***************************************************************************************************
; File will be loaded chunk by chunk. Every chunk will be 126 bytes from Sector Data.
; Two last bytes contains Track and Sector Number of next chunk - next sector to read.

; -- load data chunk 

.loadFileChunk:
	call READ						; Read a sector from disk										;43f3	cd 27 5b 	. ' [ 
	or a							; was it any Error?												;43f6	b7 	. 
	jp nz,.exitError				; yes - cleanup BASIC addresses and exit with Error				;43f7	c2 41 44 	. A D 

; -- no error 
	ld l,(iy+DBFR)					; 																;43fa	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)				; hl - address of buffer with Sector data						;43fd	fd 66 32 	. f 2 

; -- setup track and sector number to read next
	push hl							; save hl - address of Sector data								;4400	e5 	. 
	ld de,126						; only 126 bytes from Sector are File Data chunk				;4401	11 7e 00 	. ~ . 
	add hl,de						; hl - points to Track Number of Sector with next data chunk	;4404	19 	. 
	ld a,(hl)						; a - Track Number of Sector with next data chunk				;4405	7e 	~ 
	inc hl							; hl - points to Number of Sector with next data chunk			;4406	23 	# 
	ld (iy+TRCK),a					; set Track Number to read next									;4407	fd 77 12 	. w . 
	ld a,(hl)						; a - Number of Sector with next data chunk						;440a	7e 	~ 
	ld (iy+SCTR),a					; set Sector Number to read next								;440b	fd 77 11 	. w . 
	pop hl							; restore hl - address with Sector data							;440e	e1 	. 

; -- copy program chunk from Sector Buffer to destination memory
	ld e,(iy+UBFR)																					;440f	fd 5e 0e 	. ^ . 
	ld d,(iy+UBFR+1)				; de - destination address to copy program chunk				;4412	fd 56 0f 	. V . 
	ld bc,126						; 126 bytes to copy	(full sector w/o linking to next data)		;4415	01 7e 00 	. ~ . 

; -- if next track and sector equals 0 than this is last sector
; -- size of data in last sector can be smaller than 126 bytes 
	ld a,(iy+TRCK)					; a - next Track Number											;4418	fd 7e 12 	. ~ . 
	or (iy+SCTR)					; is track and sector numbers = 0?								;441b	fd b6 11 	. . . 
	jr z,.loadLastChunk				; yes - need calculate how many bytes to copy					;441e	28 10 	( . 

; -- not last sector - copy data
	ldir							; copy 126 bytes to memory										;4420	ed b0 	. . 
; -- update destination address for next program chunk
	ld (iy+UBFR),e					; store LSB of destination address								;4422	fd 73 0e 	. s . 
	ld (iy+UBFR+1),d				; store MSB of destination address								;4425	fd 72 0f 	. r . 

; -- check if it was last sector (Z=1) 
	ld a,(iy+TRCK)					; a - next Track number											;4428	fd 7e 12 	. ~ . 
	or (iy+SCTR)					; is track and sector numbers both are 0?						;442b	fd b6 11 	. . . 
	jr .loadFileChunk				; red next file chunk from next sector ------------------------	;442e	18 c3 	. . 


.loadLastChunk:
; -- calculate how many bytes left in last sector
	push hl							; save hl - address of loaded sector data						;4430	e5 	. 
	ld hl,(SYS_BASIC_END_PTR)		; hl - address of program end 									;4431	2a f9 78 	* . x 
	or a							; clear Carry flag												;4434	b7 	. 
	sbc hl,de						; subtract address of program chunk start, hl - data size 		;4435	ed 52 	. R 
	ld c,l							; copy hl to bc													;4437	4d 	M 
	ld b,h							; bc - number of chunk bytes to copy							;4438	44 	D 
	pop hl							; restore hl - address of loaded sector data					;4439	e1 	. 
; -- copy bc bytes from memory pointed by hl to memory pointed by de
	ldir							; copy chunk of file											;443a	ed b0 	. . 
; -- file loaded - turn off Drive and return with No Error
	call PWROFF						; Disk power OFF												;443c	cd 52 5f 	. R _ 
	xor a							; a - Error 0 - NO ERROR										;443f	af 	. 
	ret								; -------------------- End of Proc ----------------------------	;4440	c9 	. 


; -- Clear BASIC Program addresses and Exit with error in a register
.exitError:
	ld hl,(SYS_BASIC_START_PTR)		; hl - start of BASIC Program									;4441	2a a4 78 	* . x 
; -- put 0000 as End of BASIC mark
	ld (hl),0						; store LSB of 0000												;4444	36 00 	6 . 
	inc hl							; point to next byte											;4446	23 	# 
	ld (hl),0						; store MSB of 0000												;4447	36 00 	6 . 
	inc hl							; hl - next address after End of BASIC							;4449	23 	# 
	ld (SYS_BASIC_END_PTR),hl		; store as End of current BASIC Program address					;444a	22 f9 78 	" . x 
	ret								; --------------- End of Proc (with Error) --------------------	;444d	c9 	. 





;***************************************************************************************************
; DOS Command SAVE
; Syntax: SAVE "filaname"
; -----------------------
; Save BASIC program from memory to one file specified by filename (which will have file type code "T")
; on Disk. Filename may have no more than 8 characters.
; IN: hl - parse point (just after 'SAVE' text)
DCmdSAVE:
; -- expected required name of file enclosed with double quote chars and terminated with \0 or ':'
	call CSI						; parse filename and copy it to (iy+FNAM)						;444e	cd 67 53 	. g S 
	push hl							; save hl - parse point											;4451	e5 	. 
	or a							; was any Error?												;4452	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;4453	c2 41 42 	. A B 

; -- turn on Disk Drive and wait 2 ms
	call PWRON						; Disk power ON													;4456	cd 41 5f 	. A _ 
	push bc							; save bc 														;4459	c5 	. 
	ld bc,2							; bc - 2 miliseconds to delay									;445a	01 02 00 	. . . 
	call DLY						; delay 2 ms 													;445d	cd be 5e 	. . ^ 
	pop bc							; restore bc													;4460	c1 	. 

; -- check if Disk is not Write-Protected
	in a,(FLWRPROT)					; a - read Write Protected flag from FDC						;4461	db 13 	. . 
	or a							; is bit 7 set? (write protected)								;4463	b7 	. 
	ld a,04							; a - Error 04 - DISK WRITE PROTECTED							;4464	3e 04 	> . 
	jp m,ERROR						; yes - go to Error handling routine --------------------------	;4466	fa 41 42 	. A B 

; -- set type of file as BASIC text ('T') and continue as DOS routine
	ld (iy+TYPE),'T'				; set type of file as BASIC text ('T')							;4469	fd 36 09 54 	. 6 . T 
	pop hl							; restore hl - parse point										;446d	e1 	. 



;***************************************************************************************************
; Save program or memory to disk.
;---------------------------------------------------------------------------------------------------
; Program or menory block is sepcified by start address in (SYS_BASIC_START_PTR) 
; end end address in (SYS_BASIC_END_PTR). 
; It will be saved fo file specified by name in (iy+FNAM) and type in (iy+TYPE).
; IN: (iy+FNAM) - filename to save
;     (iy+TYPE) - type of file 
;     (SYS_BASIC_START_PTR) - memory address where program starts
;     (SYS_BASIC_END_PTR) - memory address where program ends (excluded)
; OUT: a - Error code
;***************************************************************************************************
SAVE:
; -- save start and end of Program for future restore
	ld de,(SYS_BASIC_END_PTR)		; end of current BASIC Program 									;446e	ed 5b f9 78 	. [ . x 
	push de							; save de - end of Program										;4472	d5 	. 
	ld de,(SYS_BASIC_START_PTR)		; start of current BASIC Program 								;4473	ed 5b a4 78 	. [ . x 
	push de							; save de - start of Program									;4477	d5 	. 
	push hl							; save hl - 													;4478	e5 	. 

DoSaveFile:
	di								; disable interrupts											;4479	f3 	. 
; -- delay 50 ms
	push bc							; save bc 														;447a	c5 	. 
	ld bc,50						; bc - number of miliseconds to delay							;447b	01 32 00 	. 2 . 
	call DLY						; delay 50 ms													;447e	cd be 5e 	. . ^ 
	pop bc							; restore bc													;4481	c1 	. 

; -- setup address of Program as data source
	ld de,(SYS_BASIC_START_PTR)		; de - start of current BASIC Program 							;4482	ed 5b a4 78 	. [ . x 
	ld (iy+UBFR),e					; store LSB of address											;4486	fd 73 0e 	. s . 
	ld (iy+UBFR+1),d				; set Program address as Copy Buffer (source)					;4489	fd 72 0f 	. r . 

; -- read Disk Allocation Map
	ld (iy+TRCK),0					; Track 0 contains Sector with Disk Map							;448c	fd 36 12 00 	. 6 . . 
	ld (iy+SCTR),15					; Sector 15 (on track 0) contains Disk Map						;4490	fd 36 11 0f 	. 6 . . 
	call READ						; Read Disk Map into Sector Buffer from disk					;4494	cd 27 5b 	. ' [ 
	or a							; was any Error?												;4497	b7 	. 
	jp nz,SAVE_ExitError			; yes -  exit with Error --------------------------------------	;4498	c2 9a 48 	. . H 

; -- no error - copy Disk Map from Sector Buffer to Map Buffer
	ld e,(iy+MAPADR)																				;449b	fd 5e 34 	. ^ 4 
	ld d,(iy+MAPADR+1)				; de - (dst) buffer for Disk Map								;449e	fd 56 35 	. V 5 
	ld l,(iy+DBFR)																					;44a1	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)				; hl - (src) buffer with sector data							;44a4	fd 66 32 	. f 2 
	ld bc,80						; bc - number of bytes to copy									;44a7	01 50 00 	. P . 
	ldir							; copy Disk Map 												;44aa	ed b0 	. . 
; -- create Directory Entry for file
	call CREATE						; Create an entry in directory									;44ac	cd 7b 58 	. { X 
	or a							; was any Error?												;44af	b7 	. 
	jp nz,SAVE_ExitError			; yes -  exit with Error --------------------------------------	;44b0	c2 9a 48 	. . H 

; -- Directory Entry was created for this file
; NTRK and NSCT contains values for sector alloacated for chunk of file data
; 

.writeNextChunk:
; -- check next Track and Sector - if 0 then last sector has been written
	ld a,(iy+NTRK)					; a - track numer for first free sector							;44b3	fd 7e 16 	. ~ . 
	or (iy+NSCT)					; track and sector numbers are 0? (no free sectors)				;44b6	fd b6 15 	. . . 
	jp z,.finalizeSave				; yes - finalize save (update dir entry, disk map, etc)			;44b9	ca 7c 45 	. | E 

; -- save track and sector numbers allocated for 1st chunk of file
	ld d,(iy+NTRK)					; d - Track Number for chunk of file 							;44bc	fd 56 16 	. V . 
	ld e,(iy+NSCT)					; e - Sector Number for chunk of file 							;44bf	fd 5e 15 	. ^ . 

; -- check if there is free space on Disk for next sector
	call MAP						; search for empty sector in Disk Map							;44c2	cd bf 58 	. . X 
	cp 7							; was Error 07 - DISK FULL?										;44c5	fe 07 	. . 
	jr nz,.checkOtherError			; no - check if other error										;44c7	20 19 	  . 

; -- disk full 
	call SEARCH						; Search for file in directory									;44c9	cd 13 59 	. . Y 
	cp 2							; is Error 02 - FILE ALREADY EXISTS?							;44cc	fe 02 	. . 
	ld a,6							; a - Error 6 - DISK I/O ERROR									;44ce	3e 06 	> . 
	jp nz,SAVE_ExitError			; no - exit with Error 06 -------------------------------------	;44d0	c2 9a 48 	. . H 

; -- disk full but file exists on Disk - mark it as deleted
	ex de,hl						; hl - address in Directory Entry (after filename)				;44d3	eb 	. 
	ld de,-10						; de - 10 bytes to begin of Dir Entry (filetype byte)			;44d4	11 f6 ff 	. . . 
	add hl,de						; hl - address of FileType byte in Dir Entry					;44d7	19 	. 
	ld (hl),1						; set FileType as deleted										;44d8	36 01 	6 . 
	call WRITE						; Write a sector with Directory to disk							;44da	cd a1 59 	. . Y 
	ld a,7							; a - Error 07 - DISK FULL										;44dd	3e 07 	> . 
	jp SAVE_ExitError				; exit with Error 07 ------------------------------------------	;44df	c3 9a 48 	. . H 

.checkOtherError:
	or a							; was any Error (after Find Empty Sector)?						;44e2	b7 	. 
	jp nz,SAVE_ExitError			; yes - exit with Error ---------------------------------------	;44e3	c2 9a 48 	. . H 

; -- setup destination sector to write file chunk
	ld (iy+TRCK),d					; set Track Number												;44e6	fd 72 12 	. r . 
	ld (iy+SCTR),e					; set Sector Number												;44e9	fd 73 11 	. s . 

; -- prepare sector buffer 
	ld l,(iy+DBFR)					; 																;44ec	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)				; hl - address of Sector buffer									;44ef	fd 66 32 	. f 2 
	push hl							; save hl - address of Sector Buffer							;44f2	e5 	. 
; -- fill with 0 bytes 
	ld e,l							; copy hl to de													;44f3	5d 	] 
	ld d,h							; de - address of buffer 										;44f4	54 	T 
	inc de							; start from 2nd byte											;44f5	13 	. 
	ld (hl),0						; store 0 in 1st byte											;44f6	36 00 	6 . 
	ld bc,128						; 128 bytes to clear 											;44f8	01 80 00 	. . . 
	ldir							; fill buffer with 0 values										;44fb	ed b0 	. . 

; -- get address of data chunk 
	ld l,(iy+UBFR)					; hl - address of data chunk to write on Disk					;44fd	fd 6e 0e 	. n . 
	ld h,(iy+UBFR+1)				; 																;4500	fd 66 0f 	. f . 
	push hl							; save hl - address of data chunk								;4503	e5 	. 
; -- determine chunk length
	ld de,(SYS_BASIC_END_PTR)		; de - address of Program end 									;4504	ed 5b f9 78 	. [ . x 
	or a							; clear Carry flag												;4508	b7 	. 
	sbc hl,de						; hl - negative offset from end of data to write				;4509	ed 52 	. R 
	jp nc,.writeLastSector			; if it's positive or 0? (start >= end)							;450b	d2 3a 45 	. : E 

; -- maximum 126 bytes per sector
	ld de,126						; 126 bytes can be write to one sector 							;450e	11 7e 00 	. ~ . 
	add hl,de						; add 126 to negative offset - negative offset for next chunk	;4511	19 	. 
	jp c,.partialSector				; if positive then less than 126 bytes to write					;4512	da 76 45 	. v E 

; -- full sector with 126 bytes of data
; -- store start of next chunk 
	ld de,(SYS_BASIC_END_PTR)		; end of data to write											;4515	ed 5b f9 78 	. [ . x 
	add hl,de						; add negative offset - address of next chunk of data			;4519	19 	. 
	ld (iy+UBFR),l					; store address of next chunk of data							;451a	fd 75 0e 	. u . 
	ld (iy+UBFR+1),h																				;451d	fd 74 0f 	. t . 

; -- copy 126 bytes of program to Sector Buffer 
	pop hl							; hl - address of data block to write							;4520	e1 	. 
	pop de							; de - address of Sector Buffer									;4521	d1 	. 
	ld bc,126						; bc - 126 bytes to copy										;4522	01 7e 00 	. ~ . 
	ldir							; copy program data to sector buffer							;4525	ed b0 	. . 
; -- store link - next Track and Sector Number into last 2 bytes of sector
	ld a,(iy+NTRK)					; a - Track Number of sector for next chunk of file 			;4527	fd 7e 16 	. ~ . 
	ld (de),a						; store Track number as 127th byte of sector					;452a	12 	. 
	inc de							; de - points to 128th byte of sector							;452b	13 	. 
	ld a,(iy+NSCT)					; a - Sector NUmber for next chunk of file						;452c	fd 7e 15 	. ~ . 
	ld (de),a						; store Sector NUmber as 128th byte of sector					;452f	12 	. 

.flushSector:
	call WRITE						; Write a sector to disk										;4530	cd a1 59 	. . Y 
	or a							; was any Error?												;4533	b7 	. 
	jp nz,SAVE_ExitError			; yes - exit with Error ---------------------------------------	;4534	c2 9a 48 	. . H 
	jp .writeNextChunk				; no - write next chunk of data -------------------------------	;4537	c3 b3 44 	. . D 


.writeLastSector:
	push hl							; save hl - number of bytes to write 							;453a	e5 	. 
; -- get Disk Map address 
	ld l,(iy+MAPADR)																				;453b	fd 6e 34 	. n 4 
	ld h,(iy+MAPADR+1)				; hl - address of Disk Map 										;453e	fd 66 35 	. f 5 
; -- calculate byte offset 
	ld a,(iy+NTRK)					; a - Track Number of sector for next chunk of file				;4541	fd 7e 16 	. ~ . 
	dec a							; a = a -1 (Disk Map covers sectors from track 1)				;4544	3d 	= 
	sla a							; track * 2 (2 bytes in Map covers 1 track)						;4545	cb 27 	. ' 
	ld e,a							; e - offset in Disk Map for Track								;4547	5f 	_ 
	ld d,0							; de - offset in Disk Map for Track								;4548	16 00 	. . 
	ld a,(iy+NSCT)					; a - Sector number for next chunk of file						;454a	fd 7e 15 	. ~ . 
	cp 8							; set Carry flag if Sector < 8 									;454d	fe 08 	. . 
	ccf								; invert Carry - will be 1 if Sector >= 8 						;454f	3f 	? 
	adc hl,de						; hl - address in Disk Map of bitmask with this sector			;4550	ed 5a 	. Z 
; -- calculate bit number 
	and %0111						; a - bit number for this sector								;4552	e6 07 	. . 
	inc a							; preincrement for number of rotates 1..8						;4554	3c 	< 
	ld b,a							; b - how many times to rotate bitmask							;4555	47 	G 
; -- reset bit for this sector (not used)
	ld c,(hl)						; c - bitmask with this sector									;4556	4e 	N 
	rlc c							; pre-rotate left (set Carry from 7th bit)						;4557	cb 01 	. . 
.loop1:
	rrc c							; rotate right bitmask											;4559	cb 09 	. . 
	djnz .loop1						; keep rotate until bit is at position 0						;455b	10 fc 	. . 
	res 0,c							; clear bit for this sector										;455d	cb 81 	. . 
	ld b,a							; b - number of rotates to do									;455f	47 	G 
	rrc c							; pre-rotate right (set Carry from 0th bit)						;4560	cb 09 	. . 
.loop2:
	rlc c							; rotate left bitmask											;4562	cb 01 	. . 
	djnz .loop2						; keep rotate until bit returns to its original position		;4564	10 fc 	. . 
	ld (hl),c						; store updated byte to Disk Map								;4566	71 	q 
; -- copy last chunk of data into sector buffer
	pop bc							; bc - number of bytes to copy									;4567	c1 	. 
	pop hl							; hl - address of last chunk of data							;4568	e1 	. 
	pop de							; de - sector buffer address									;4569	d1 	. 
	ldir							; copy last chunk of data to Sector buffer						;456a	ed b0 	. . 
; -- set it was last chunk of file
	ld (iy+NTRK),0					; set next track to 0 (no next sector)							;456c	fd 36 16 00 	. 6 . . 
	ld (iy+NSCT),0					; set next sectro to 0 (no next sector)							;4570	fd 36 15 00 	. 6 . . 
	jr .flushSector					; write sector to Disk and continue ---------------------------	;4574	18 ba 	. . 


.partialSector:
	ex de,hl						; de - bytes above end of data, hl - chunk length (126)			;4576	eb 	. 
	or a							; clear Carry Flag												;4577	b7 	. 
	sbc hl,de						; hl - length of partial chunk (less than 126)					;4578	ed 52 	. R 
	jr .writeLastSector				; write as last sector (126 bytes or less)						;457a	18 be 	. . 


; -- all data stored on Disk
.finalizeSave:
	call SEARCH						; Search for file in directory									;457c	cd 13 59 	. . Y 
	cp 2							; was Error 2 - FILE ALREADY EXISTS								;457f	fe 02 	. . 
	jp nz,SAVE_ExitError			; no - exit with Error ----------------------------------------	;4581	c2 9a 48 	. . H 

; -- file found - update Directory Entry
	inc de							; skip track number	byte 										;4584	13 	. 
	inc de							; skip sector number byte										;4585	13 	. 
; -- update program start address 
	ld hl,(SYS_BASIC_START_PTR)		; hk - start of current BASIC Program							;4586	2a a4 78 	* . x 
	ex de,hl						; de - program start, hl - address in Directory Entry 			;4589	eb 	. 
	ld (hl),e						; store LSB of program start									;458a	73 	s 
	inc hl							; point to MSB													;458b	23 	# 
	ld (hl),d						; store MSB of program start									;458c	72 	r 
	inc hl							; point to program end in Directory Entry						;458d	23 	# 
; -- update program end address
	ex de,hl						; exchange de and hl											;458e	eb 	. 
	ld hl,(SYS_BASIC_END_PTR)		; hl - end of current BASIC Program 							;458f	2a f9 78 	* . x 
	ex de,hl						; de - program end, hl - address in Directory Entry 			;4592	eb 	. 
	ld (hl),e						; store LSB of program end										;4593	73 	s 
	inc hl							; point to MSB													;4594	23 	# 
	ld (hl),d						; store MSB of program end										;4595	72 	r 
; -- write directory entry to Disk
	call WRITE						; Write a sector with Directory to Disk							;4596	cd a1 59 	. . Y 
	or a							; was any Error?												;4599	b7 	. 
	jp nz,SAVE_ExitError			; yes - exit with Error ---------------------------------------	;459a	c2 9a 48 	. . H 

; -- update Disk Map sector

; -- clear data buffer (fill with 0 bytes)
	ld l,(iy+DBFR)					; hl - address of data buffer									;459d	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)																				;45a0	fd 66 32 	. f 2 
	push hl							; save hl - address of data buffer								;45a3	e5 	. 
	ld e,l							; copy hl to de (destination)									;45a4	5d 	] 
	ld d,h																							;45a5	54 	T 
	inc de							; de - points to 2nd byte of buffer								;45a6	13 	. 
	ld (hl),0						; store 0 in 1st byte of buffer									;45a7	36 00 	6 . 
	ld bc,128						; bc - 128 bytes to fill										;45a9	01 80 00 	. . . 
	ldir							; fill data buffer with 0										;45ac	ed b0 	. . 
; -- copy disk Map into data buffer
	pop hl							; restore hl - address of data buffer							;45ae	e1 	. 
	ld e,(iy+MAPADR)				; de - address of Disk Map data									;45af	fd 5e 34 	. ^ 4 
	ld d,(iy+MAPADR+1)																				;45b2	fd 56 35 	. V 5 
	ex de,hl						; de - data buffer (dst), hl - Disk Map data (src)				;45b5	eb 	. 
	ld bc,80						; bc - 80 bytes to copy											;45b6	01 50 00 	. P . 
	ldir							; copy Disk Map into data buffer								;45b9	ed b0 	. . 
; -- write Disk Map into Disk
	ld (iy+TRCK),0					; set Track Number 0											;45bb	fd 36 12 00 	. 6 . . 
	ld (iy+SCTR),15					; set Sector Number 15											;45bf	fd 36 11 0f 	. 6 . . 
	call WRITE						; Write a sector to disk										;45c3	cd a1 59 	. . Y 
; -- turn off disk drive
	push af							; save a - error code after Write Sector						;45c6	f5 	. 
	call PWROFF						; Disk power OFF												;45c7	cd 52 5f 	. R _ 
	pop af							; restore a - error code after Write Sector						;45ca	f1 	. 

; -- restore BASIC variables
	pop hl							; restore hl - 													;45cb	e1 	. 
	pop de							; restore de - BASIC Program Start								;45cc	d1 	. 
	ld (SYS_BASIC_START_PTR),de		; store into start of current BASIC Program variable			;45cd	ed 53 a4 78 	. S . x 
	pop de							; restore de - BASIC Program End								;45d1	d1 	. 
	ld (SYS_BASIC_END_PTR),de		; store into end of current BASIC Program variable				;45d2	ed 53 f9 78 	. S . x 
; -- exit
	or a							; was any Error after Write Disk Map to Disk?					;45d6	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine							;45d7	c2 41 42 	. A B 
	ret								; ----------------- End of Proc -------------------------------	;45da	c9 	. 



LoadAndRunFile:
	call CSI						; Parse filename typed by user									;45db	cd 67 53 	. g S 
	push hl							; save hl - next char after filename (parser pointer)			;45de	e5 	. 
	or a							; was any error?												;45df	b7 	. 
	jp nz,ERROR						; yes - goto Error handling routine	---------------------------	;45e0	c2 41 42 	. A B 
; -- valid filename detected
	ld (iy+TYPE),'T'				; set File Type 'T' - BASIC text program						;45e3	fd 36 09 54 	. 6 . T 
	call LOAD					; Load a file from disk											;45e7	cd b1 43 	. . C 
	or a							; was any Error?												;45ea	b7 	. 
	jp nz,ERROR						; yes - goto Error handling routine	---------------------------	;45eb	c2 41 42 	. A B 
	ld de,(SYS_BASIC_START_PTR)		; de - start of current BASIC Program 							;45ee	ed 5b a4 78 	. [ . x 
	jp SysExecRUN					; Execute BASIC RUN command - start from address in de --------	;45f2	c3 e9 36 	. . 6 
	


;***************************************************************************************************
; DOS Command OPEN
; Syntax: OPEN "filaname",mode
;         mode - 0 read, 1 - write
; ----------------------------
; Open file specified by "filename" (which has the file type code "D") for Read or Write.
; Argument mode must be 0 (for read) or 1 (for write). After open file is ready to read from 
; via DOS command 'IN#' or to write to via DOS command 'PR#'
; NOTE: This command must always be used from inside BASIC program. 
; IN: hl - parse point 
DCmdOPEN:	
; -- throw ILLEGAL DIRECT Error if current BASIC line <> FFFF
	call SysCheckIllegalDirect		; verify command used from BASIC program 						;45f5	cd 28 28 	. ( ( 

; -- parse first argument - filename
	call ParseFilename				; Verify syntax and copy filename to DOS Filename Buffer		;45f8	cd 78 53 	. x S 
	push hl							; save hl - points to next char after filename					;45fb	e5 	. 
	or a							; was any Error?												;45fc	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine							;45fd	c2 41 42 	. A B 
	pop af							; take value from CPU stack - adjust CPU Stack Pointer			;4600	f1 	. 

; -- parse next char - must be ','
	rst 8							; verify this char is ',' (comma) and point hl to next			;4601	cf 	. 
	defb ','						; expected char													;4602	2c 	, 

; -- parse next argument - accrss mode 
	call SysEvalByteExpr			; a - parsed integer value										;4603	cd 1c 2b 	. . + 
	or a							; is it 0? (open file to read)									;4606	b7 	. 
	jr z,.continue					; yes - set Access mode flag and continue						;4607	28 05 	( . 
	cp 2							; is it 2 or greater? (invalid mode)							;4609	fe 02 	. . 
	jp nc,SysErrRaiseFuncCode		; yes - Raise BASIC FUNCTION CODE Error							;460b	d2 4a 1e 	. J . 

; -- open to read
.continue:
	ld (iy+RQST),a					; store access type (read or write) 							;460e	fd 77 0c 	. w . 
	push hl							; save hl -  points to next char after mode 					;4611	e5 	. 
; -- check if file is already opened
	call FindFCBForOpen				; Find FCB Block to use or get one if file already opened		;4612	cd 78 47 	. x G 
	cp 05							; was Error 05   FILE NOT OPEN? (means OK)						;4615	fe 05 	. . 
; -- File is already opened or both FCB are used
	jp nz,ERROR						; no - go to Error handling routine	---------------------------	;4617	c2 41 42 	. A B 

; -- flush sector data if any FCB has file Opened for Write
	push hl							; save hl - address of File Control Block to use				;461a	e5 	. 
	call FlushSectorData			; Flush Sector Data to disk from both FCBs 						;461b	cd a5 4f 	. . O 
	pop hl							; restore hl - FCB to use										;461e	e1 	. 

; -- set FCB is used
	ld (hl),1						; set FCB flag - used but file not active						;461f	36 01 	6 . 
	inc hl							; hl - address of Access type field								;4621	23 	# 
; -- set Access type (read/write)
	ld a,(iy+RQST)					; a - requested access type (read.write)						;4622	fd 7e 0c 	. ~ . 
	ld (hl),a						; set Access type in FCB										;4625	77 	w 
	inc hl							; hl - address of Filename field 								;4626	23 	# 
; -- set Filename (FNAM)
	push iy							; iy - DOS base address											;4627	fd e5 	. . 
	pop de							; copy to de													;4629	d1 	. 
	inc de							; de - address of FNAM in DOS Structure							;462a	13 	. 
	ex de,hl						; de - FNAM field in FCB, hl - FNAM field in DOS structure 		;462b	eb 	. 
	ld bc,8							; bc - 8 chars of filename 										;462c	01 08 00 	. . . 
	ldir							; copy filename to FCB											;462f	ed b0 	. . 
; -- 	
	push de							; save de - address of TRK# field in FCB						;4631	d5 	. 
	di								; disable interrupts											;4632	f3 	. 

; -- turn Disk power ON 
	call PWRON						; Disk power ON													;4633	cd 41 5f 	. A _ 
	push bc							; save bc														;4636	c5 	. 
	ld bc,50						; bc - number of miliseconds to delay							;4637	01 32 00 	. 2 . 
	call DLY						; delay 50 ms													;463a	cd be 5e 	. . ^ 
	pop bc							; restore bc													;463d	c1 	. 

; -- check if file exists
	call SEARCH						; Search for file in directory									;463e	cd 13 59 	. . Y 
	cp 02							; file found? (Error 02 - FILE ALREADY EXISTS?) 				;4641	fe 02 	. . 
	jp nz,.fileNotExists			; no - create if mode=Write, error if mode=read					;4643	c2 6b 46 	. k F 

; -- file exists already - must be 'D' type (data)
	ld a,(iy+TYPE+1)				; a - file type of found file									;4646	fd 7e 0a 	. ~ . 
	cp 'D'							; is it type 'D' (data)?										;4649	fe 44 	. D 
	ld a,12							; a - Error 12   FILE TYPE MISMATCH								;464b	3e 0c 	> . 
	jp nz,ERROR						; no - go to Error handling routine								;464d	c2 41 42 	. A B 

; -- file exists and is type 'D' - fill 1st sector data in FCB
	pop hl							; pop hl - address of TRK# field in FCB							;4650	e1 	. 
; -- set Track from Directory Entry of found file
	ld a,(de)						; a - Track Number from disk Directory Entry 					;4651	1a 	. 
	ld (hl),a						; set as Track Number in FCB									;4652	77 	w 
	ld (iy+TRCK),a					; set as Track Number in DOS Structure							;4653	fd 77 12 	. w . 
	inc de							; de - address of Sector Number in Directory Entry				;4656	13 	. 
	inc hl							; hl - address of Sector Number in FCB							;4657	23 	# 
; -- set Sector from Directory Entry of found file
	ld a,(de)						; a - Sector Number from disk Directory Entry 					;4658	1a 	. 
	ld (hl),a						; set as Sector Number in FCB									;4659	77 	w 
	ld (iy+SCTR),a					; set as Sector Number in DOS Structure							;465a	fd 77 11 	. w . 
; -- set Byte-in-Sector Index (PTR)
	xor a							; a - index of current byte in Sector = 0						;465d	af 	. 
	inc hl							; hl - address of PTR field in FCB								;465e	23 	# 
	ld (hl),a						; set Index (PTR) to 0											;465f	77 	w 

; -- if mode = read we are done, if mode = write we have to read whole file and find end of data
	ld a,(iy+RQST)					; a - requested access type (mode) (read/write)					;4660	fd 7e 0c 	. ~ . 
	or a							; is it 0 (read)?												;4663	b7 	. 
	jr nz,.seekEndOfFile			; no - seek End of file and setup point of write				;4664	20 53 	  S 

; -- file is ready to read from - turn driive power off and exit
	call PWROFF						; Disk power OFF												;4666	cd 52 5f 	. R _ 
	pop hl							; restore hl - address of next char in BASIC					;4669	e1 	. 
	ret								; -------------------- End of Proc ----------------------------	;466a	c9 	. 


.fileNotExists:
; -- file not exists - error if mode=read	
	ld c,a							; save a - previous error code (FILE NOT EXISTS)				;466b	4f 	O 
	ld a,(iy+RQST)					; requested access type (read/write)							;466c	fd 7e 0c 	. ~ . 
	or a							; is it 0 (read)?												;466f	b7 	. 
	ld a,c							; a - restore previous error code								;4670	79 	y 
	jp z,.exitError						; yes - release FCB and exit with Error 						;4671	ca a8 46 	. . F 

; -- mode=write - need to create file - check if Disk is not Write-Protected
	in a,(FLWRPROT)					; a - read Write Protected flag from FDC						;4674	db 13 	. . 
	or a							; is bit 7 set? (write protected)								;4676	b7 	. 
	ld c,04							; c - Error 04 - DISK WRITE PROTECTED							;4677	0e 04 	. . 
	jp m,.exitError						; yes - release FCB and exit with Error 						;4679	fa a8 46 	. . F 

; -- create file type 'D'	
	call RDMAP						; Read the allocation map of the disk							;467c	cd 17 47 	. . G 
	ld (iy+TYPE),'D'				; set file type 'D' (data)										;467f	fd 36 09 44 	. 6 . D 
	call CREATE						; Create an entry in directory									;4683	cd 7b 58 	. { X 
	or a							; was any error?												;4686	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;4687	c2 41 42 	. A B 

; -- file created update - properities of allocated 1st Sector
	pop hl							; restore hl - address of TRK# field in FCB						;468a	e1 	. 
	ld a,(iy+NTRK)					; a - Track number of allocated Sector							;468b	fd 7e 16 	. ~ . 
	ld (iy+TRCK),a					; set as Track Number in DOS structure							;468e	fd 77 12 	. w . 
	ld (hl),a						; set as Track Number in FCB									;4691	77 	w 
	inc hl							; hl - address of SCTR# field in FCB							;4692	23 	# 
	ld a,(iy+NSCT)					; a - Sector Number of allocated Sector							;4693	fd 7e 15 	. ~ . 
	ld (iy+SCTR),a					; set as Sector Number in DOS structure							;4696	fd 77 11 	. w . 
	ld (hl),a						; set as Sector Number in FCB									;4699	77 	w 
	inc hl							; hl - address of PTR field in FCB								;469a	23 	# 
	ld (hl),0						; set Byte-in-Sector Index (PTR) to 0							;469b	36 00 	6 . 
; -- clear Sector buffer and write it to Disk 
	call CLEAR						; Clear a sector of the disk									;469d	cd 49 47 	. I G 
; -- update Disk Allocation Map
	call SVMAP						; Save allocation Map to the disk								;46a0	cd 54 47 	. T G 

; -- file is ready to write to - turn driive power off and exit
	call PWROFF						; Disk power OFF												;46a3	cd 52 5f 	. R _ 
	pop hl							; restore hl - address of next char in BASIC					;46a6	e1 	. 
	ret								; -------------------- End of Proc ----------------------------	;46a7	c9 	. 


.exitError:
; -- release FCB (set flag to "not used"
	pop hl							; restore hl - address of TRK# field in FCB						;46a8	e1 	. 
	ld de,-10						; de - offset to FCB Open flag from TRK# field					;46a9	11 f6 ff 	. . . 
	add hl,de						; hl - address of FCB Open flag									;46ac	19 	. 
	ld (hl),0						; set Flag to 0 - FCB not used									;46ad	36 00 	6 . 
; -- exit with previous error (if was any)
	ld a,c							; a - previous Error code										;46af	79 	y 
	or a							; was any error?												;46b0	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	; Error handling routine	;46b1	c2 41 42 	. A B 

; -- no previous code - exit with Error 13 - FILE NOT FOUND
	ld a,13							; a - Error 13 - FILE NOT FOUND									;46b4	3e 0d 	> . 
	jp ERROR						; go to Error handling routine --------------------------------	;46b6	c3 41 42 	. A B 


.seekEndOfFile:
; -- file exists and requested mode=write - read sector into buffer
	push hl							; save hl - address of PTR field in FCB							;46b9	e5 	. 
.readNextSector:
	call READ						; Read a sector from disk										;46ba	cd 27 5b 	. ' [ 
	or a							; was any error?												;46bd	b7 	. 
	jp nz,ERROR						; yes - goto Error handling routine								;46be	c2 41 42 	. A B 
; -- get next sector params from file
	ld l,(iy+DBFR)					; hl - address of sector data buffer							;46c1	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)																				;46c4	fd 66 32 	. f 2 
	ld de,126						; de - offset in sector to next track/sector data				;46c7	11 7e 00 	. ~ . 
	add hl,de						; hl - address of Next Track Number of file						;46ca	19 	. 
	ld a,(hl)						; a - Next Track Number											;46cb	7e 	~ 
	or a							; is it 0? (it was last sector of this file)?					;46cc	b7 	. 
	jr z,.lastSecFound				; yes - find end of data in this sector 						;46cd	28 0a 	( . 
; -- set next sector params to read
	inc hl							; hl - address of Next Sector Number of file					;46cf	23 	# 
	ld (iy+TRCK),a					; set Track NUmber to read next									;46d0	fd 77 12 	. w . 
	ld a,(hl)						; a - Next Sector Number 										;46d3	7e 	~ 
	ld (iy+SCTR),a					; set Sector Number to read next								;46d4	fd 77 11 	. w . 
	jr .readNextSector				; read next sector --------------------------------------------	;46d7	18 e1 	. . 

.lastSecFound:
; -- check how many bytes are used in this sector
	ld b,126						; b - 126 bytes of data in buffer								;46d9	06 7e 	. ~ 
	ld l,(iy+DBFR)					; hl - address of buffer with sector data						;46db	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)																				;46de	fd 66 32 	. f 2 
.nextByte:
	ld a,(hl)						; a - data byte from last sector								;46e1	7e 	~ 
	inc hl							; hl - address of next byte										;46e2	23 	# 
	or a							; is daba byte = 0? (end of data)?								;46e3	b7 	. 
	jr z,.updateFCBexit				; yes - update FCB with this sector params and exit				;46e4	28 1d 	( . 
	djnz .nextByte					; no - check all 126 bytes ------------------------------------	;46e6	10 f9 	. . 

; -- all 126 bytes are used - need to create 1 more sector
	call RDMAP						; Read disk allocation Map										;46e8	cd 17 47 	. . G 
	call MAP						; Search for empty sector and alloacte it						;46eb	cd bf 58 	. . X 
	or a							; was any error?												;46ee	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;46ef	c2 41 42 	. A B 
; -- no error - set new sector track and Sector Number
	ld a,(iy+NTRK)					; a - Track Number of new sector								;46f2	fd 7e 16 	. ~ . 
	ld (iy+TRCK),a					; set as Track Number in DOS structure							;46f5	fd 77 12 	. w . 
	ld a,(iy+NSCT)					; a - Sector Number of new sector								;46f8	fd 7e 15 	. ~ . 
	ld (iy+SCTR),a					; set as Sector Number in DOS structure							;46fb	fd 77 11 	. w . 
; -- clear buffer and write empty sector to disk
	call CLEAR						; Clear a sector of the disk									;46fe	cd 49 47 	. I G 

	ld b,126						; b - 126 free bytes in this sector								;4701	06 7e 	. ~ 
.updateFCBexit:
	ld a,126						; a - total 126 bytes can be stored in one sector				;4703	3e 7e 	> ~ 
	sub b							; subtract number of free bytes (index of 1st byte to use)		;4705	90 	. 
	pop hl							; restore hl - address of PTR field in FCB						;4706	e1 	. 
	ld (hl),a						; set as Byte-inSector Index (PTR) in FCB						;4707	77 	w 
	dec hl							; hl - address of Sector Number (SCTR#) in FCB					;4708	2b 	+ 
	ld a,(iy+SCTR)					; a - Sector Number from DOS Structure							;4709	fd 7e 11 	. ~ . 
	ld (hl),a						; set as Sector Number in FCB									;470c	77 	w 
	dec hl							; hl - address of Track Number (TRK#) in FCB					;470d	2b 	+ 
	ld a,(iy+TRCK)					; a - Track Number from DOS Structure							;470e	fd 7e 12 	. ~ . 
	ld (hl),a						; set as Track Number in FCB									;4711	77 	w 
; -- file is ready to write to - turn driive power off and exit 
	call PWROFF						; Disk power OFF												;4712	cd 52 5f 	. R _ 
	pop hl							; restore hl - address of next char in BASIC					;4715	e1 	. 
	ret								; -------------------- End of Proc ----------------------------	;4716	c9 	. 



;***************************************************************************************************
; Read Sector Allocation Map.
;---------------------------------------------------------------------------------------------------
; The sectors allocation map is loaded from sector 15 of track 0 from the disk 
; into the memory pointed by adress stored in iy+MAPADR
; IN: Disabled interrupts
; OUT: a - error code or 0 if no error
;***************************************************************************************************
RDMAP:
; -- read sector 15 on track 0
	ld (iy+TRCK),0					; Track number 0												;4717	fd 36 12 00 	. 6 . . 
	ld (iy+SCTR),15					; Sector Number 15												;471b	fd 36 11 0f 	. 6 . . 
	call READ						; Read a sector from disk into Sector Buffer					;471f	cd 27 5b 	. ' [ 
	or a							; check if error (a != 0)										;4722	b7 	. 
	jp nz,ERROR						; yes - jump to Error handling routine							;4723	c2 41 42 	. A B 
; -- copy map data from read buffer into MapData
	ld e,(iy+MAPADR)																				;4726	fd 5e 34 	. ^ 4 
	ld d,(iy+MAPADR+1)				; dst - de - Allocation Map Address 							;4729	fd 56 35 	. V 5 
	ld l,(iy+DBFR)																					;472c	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)				; src - hl - Data Buffer										;472f	fd 66 32 	. f 2 
	ld bc,80						; 80 bytes to copy (1 bit for Sector -> 640 sectors)			;4732	01 50 00 	. P . 
	ldir							; copy bytes													;4735	ed b0 	. . 
	ret								; ------------------------- End of Proc -----------------------	;4737	c9 	. 



;***************************************************************************************************
; Fill Data Buffer with value 0
; IN: none
; OUT: none
;***************************************************************************************************
ClearDataBuffer:
	ld l,(iy+DBFR)																					;4738	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)				; src - hl - Data Buffer address								;473b	fd 66 32 	. f 2 
	ld (hl),0						; set first byte to 0											;473e	36 00 	6 . 
	ld e,l																							;4740	5d 	] 
	ld d,h							; dst - de - Data Buffer address								;4741	54 	T 
	inc de							; dst - de - address of next byte 								;4742	13 	. 
	ld bc,128						; 128 bytes to clear											;4743	01 80 00 	. . . 
	ldir							; fill buffer with 0 											;4746	ed b0 	. . 
	ret								; -------------------------- End of Proc ----------------------	;4748	c9 	. 



;***************************************************************************************************
; Clear a sector of the disk
; IN: Disabled interrupts
;     IY+TRCK - track number 
;     IY+SCTR - sector number
;     IY+DRVS - drive selected  
; OUT: a - error code or 0 if no error
;***************************************************************************************************
CLEAR:
	call ClearDataBuffer			; clear 128 bytes in Data Buffer								;4749	cd 38 47 	. 8 G 
	call WRITE						; Write a sector to disk										;474c	cd a1 59 	. . Y 
	or a							; check if error (a != 0)										;474f	b7 	. 
	jp nz,ERROR						; yes - jump to Error handling routine							;4750	c2 41 42 	. A B 
	ret								; -------------------------- End of Proc ----------------------	;4753	c9 	. 



;***************************************************************************************************
; Save the track map pointed by iy+MAPADR to the disk (track 0, sector 15)
;---------------------------------------------------------------------------------------------------
; IN: Disabled interrupts
;     IY+DRVS - drive selected  
;	  IY+MAPADR - pointer to updated Sector Allocation Map
;	  The corresponding drive must be switched on.
; OUT: a - error code or 0 if no error
;***************************************************************************************************
SVMAP:
; -- clear sector buffer
	call ClearDataBuffer			; clear 128 bytes in Data Buffer								;4754	cd 38 47 	. 8 G 

; -- setup parameters (track=0,sector=15)
	ld (iy+TRCK),0					; Track number 0												;4757	fd 36 12 00 	. 6 . . 
	ld (iy+SCTR),15					; Sector number 15												;475b	fd 36 11 0f 	. 6 . . 

; -- copy Sector Map data into Sector Data Buffer
	ld e,(iy+DBFR)																					;475f	fd 5e 31 	. ^ 1 
	ld d,(iy+DBFR+1)				; dst - de - address of Data Buffer								;4762	fd 56 32 	. V 2 
	ld l,(iy+MAPADR)																				;4765	fd 6e 34 	. n 4 
	ld h,(iy+MAPADR+1)				; src - hl - address of MapData									;4768	fd 66 35 	. f 5 
	ld bc,80						; 80 bytes to copy (rest of sector is already cleared to 0)		;476b	01 50 00 	. P . 
	ldir							; copy bytes do Data Buffer										;476e	ed b0 	. . 
; -- write buffer to Disk Sector
	call WRITE						; Write a sector to disk										;4770	cd a1 59 	. . Y 
	or a							; check if error (a != 0)										;4773	b7 	. 
	jp nz,ERROR						; yes - jump to Error handling routine							;4774	c2 41 42 	. A B 
	ret								; -------------------------- End of Proc ----------------------	;4777	c9 	. 


;***************************************************************************************************
; Find File Control Block for Open file
; If file already open it returns FCB for that file, if not returns free FCB to use.
; If both FCBs are used by another files then returns Error 14 - DISK BUFFER FULL 
; IN: hl - parse point 
;     (iy+FNAM) - filename to close
; OUT: a - error/status codes: 8 - FILE ALREADY OPEN or 5 - FILE NOT OPEN
;      de - address of FCB (if file is Opened)
;      hl - address of FCB to use (if file is not Opened)
FindFCBForOpen:
	push iy							; iy - DOS base address											;4778	fd e5 	. . 
	pop hl							; copy to hl													;477a	e1 	. 

; -- check if file is open and use FCB Block 1
	ld (iy+FILNO),0					; set File # to 0 - current used FCB Block 1					;477b	fd 36 00 00 	. 6 . . 
	ld de,FCB1						; de - offset to 1st FCB Block									;477f	11 17 00 	. . . 
	add hl,de						; hl - address of FCB Block	1									;4782	19 	. 
	ld a,(hl)						; a - Open Flag 												;4783	7e 	~ 
	or a							; is file Opened in FCB 1?												;4784	b7 	. 
	jr z,.checkFCB2					; no - check FCB Block 2 --------------------------------------	;4785	28 09 	( . 

; -- check if FCB Block 1 handles this file
	call FCBHandlesFile				; check if filenames in FCB and (iy+FNAM) match					;4787	cd bf 47 	. . G 
	cp 8							; is Error 8 - FILE ALREADY OPEN ?								;478a	fe 08 	. . 
	ret z							; yes - ------------------ End Of Proc ------------------------	;478c	c8 	. 

; -- set FCB 2 is used 
	inc (iy+FILNO)					; set File # to 1 - current used FCB Block 2					;478d	fd 34 00 	. 4 . 
.checkFCB2:
; -- check if file is open and use FCB Block 2
	ld de,13						; de - size of FCB Block structure								;4790	11 0d 00 	. . . 
	add hl,de						; hl - address of FCB Block	2									;4793	19 	. 
	ld a,(hl)						; a - Open Flag 												;4794	7e 	~ 
	or a							; is file Opened using FCB 2?									;4795	b7 	. 
	jr nz,l47ach					; yes - check if FCB Block 2 handles this file ----------------	;4796	20 14 	  . 

; -- file is not Open - return FILE NOT OPEN
;    de - will contain free FCB to use 
	push iy							; iy - DOS base address											;4798	fd e5 	. . 
	pop hl							; copy to hl													;479a	e1 	. 
	ld de,FCB1						; de - offset to 1st FCB Block									;479b	11 17 00 	. . . 
	add hl,de						; hl - address of FCB Block	1									;479e	19 	. 
	ld a,(iy+FILNO)					; a - FCB block used											;479f	fd 7e 00 	. ~ . 
	or a							; is it FCB block 1?											;47a2	b7 	. 
	jr z,.exitError					; yes - hl has address of FCB 1 - return with error				;47a3	28 04 	( . 
; -- used FCB 2
	ld de,13						; de - offset from FCB1 to FCB2									;47a5	11 0d 00 	. . . 
	add hl,de						; hl has address of FCB 2 - return with error					;47a8	19 	. 
.exitError:
; -- return Error 5 - FILE NOT OPEN
	ld a,5							; set Error 5 - FILE NOT OPEN									;47a9	3e 05 	> . 
	ret								; ---------------------- End of Proc --------------------------	;47ab	c9 	. 

l47ach:
; -- check if FCB Block 2 handles this file
	call FCBHandlesFile				; check if filenames in FCB and (iy+FNAM) match					;47ac	cd bf 47 	. . G 
	cp 8							; is Error 8 - FILE ALREADY OPEN ?								;47af	fe 08 	. . 
	ret z							; yes - ------------------ End Of Proc ------------------------	;47b1	c8 	. 

; -- FCB 2 used by another file - check FCB 1 can be used?
	or a							; clear Carry flag												;47b2	b7 	. 
	sbc hl,de						; hl - address of FCB 1 										;47b3	ed 52 	. R 
	ld a,(iy+FCB1)					; a - FCB1 Open flag											;47b5	fd 7e 17 	. ~ . 
	or a							; can FCB 1 be used? (Open FLAG != 0)							;47b8	b7 	. 
	ld a,14							; set Error 14 - DISK BUFFER FULL								;47b9	3e 0e 	> . 
	ret nz							; no - ------------------- End of Proc (with Error) ----------	;47bb	c0 	. 

; -- return Error 5 - FILE NOT OPEN - FCB1 can be used
	ld a,5							; set Error 5 - FILE NOT OPEN									;47bc	3e 05 	> . 
	ret								; ---------------------- End of Proc --------------------------	;47be	c9 	. 


;***************************************************************************************************
; Check if FCB specified by hl handles filename specified in iy+FNAM  
; IN: hl - address of FCB (File Control Block) 
;     (iy+FNAM) - filename to close
; OUT: a - error/status codes: 8 - FILE ALREADY OPEN or 5 - FILE NOT OPEN
;	   Z flag - 1 - filenames match, 0 - filenames are different	
;      de - (if fileanmes match) address of FCB
;      hl - (if fileanmes match) points to next char after filename (track number in FCB)
FCBHandlesFile:
	push iy							; save iy - DOS base											;47bf	fd e5 	. . 
	push hl							; save hl - FCB structure										;47c1	e5 	. 
	ld b,8							; b - 8 chars of filename										;47c2	06 08 	. . 
	inc hl							; skip Status byte												;47c4	23 	# 
	inc hl							; hl - filename in FCB											;47c5	23 	# 
.nextChar:
	ld a,(iy+FNAM)					; a - char of filename to compare								;47c6	fd 7e 01 	. ~ . 
	cp (hl)							; is it the same in FCB?										;47c9	be 	. 
	inc hl							; hl - next char of filename in FCB								;47ca	23 	# 
	inc iy							; iy - next char of filename in DOS structure					;47cb	fd 23 	. # 
	jr nz,.returnNotOpen			; not match - return with Error FILE NOT OPEN -----------------	;47cd	20 08 	  . 
	djnz .nextChar					; continue to compare all 8 chars -----------------------------	;47cf	10 f5 	. . 
	ld a,8							; a - Error 5 - FILE ALREADY OPEN								;47d1	3e 08 	> . 
	pop de							; restore de - FCB Structure									;47d3	d1 	. 
	pop iy							; restore iy - DOS base											;47d4	fd e1 	. . 
	ret								; ----------------- End of Proc -------------------------------	;47d6	c9 	. 
.returnNotOpen:
	pop hl							; restore hl - FCB Structure									;47d7	e1 	. 
	pop iy							; restore iy - DOS base											;47d8	fd e1 	. . 
	ld a,5							; a - Error 5 - FILE NOT OPEN									;47da	3e 05 	> . 
	ret								; ----------------- End of Proc -------------------------------	;47dc	c9 	. 


;***************************************************************************************************
; DOS Command CLOSE
; Syntax: CLOSE "filaname"
; ------------------------
; Close file specified by "filename" (which has the file type code "D") previously opened by OPEN.
; Filename may have no more than 8 characters.
; IN: hl - parse point (just after 'CLOSE' text)
DCmdCLOSE:
; -- parse required filename (must be terminated with 0 or ':')
	call CSI						; parse filename and copy it to (iy+FNAM)						;47dd	cd 67 53 	. g S 
	or a							; was any Error?												;47e0	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;47e1	c2 41 42 	. A B 
	push hl							; save hl - address of next character in BASIC					;47e4	e5 	. 

; -- test if command is called from BASIC program or direct 
	ld hl,(BasicLineNumber)			; hl - Current line being processed by BASIC					;47e5	2a a2 78 	* . x 
	inc hl							; if was -1 (oxffff) then now will be 0							;47e8	23 	# 
	ld a,h																							;47e9	7c 	| 
	or l							; is hl = 0 (called as direct command)?							;47ea	b5 	. 
	jr nz,.fromBasicProg			; no - continue 												;47eb	20 0a 	  . 

; -- called from direct command 
	call FindFCBForOpen				; Find FCB Block used by this file if file already opened		;47ed	cd 78 47 	. x G 
	pop hl							; restore hl - address of next character in BASIC				;47f0	e1 	. 
	cp 08							; is file Opened? (Error 08   FILE ALREADY OPEN)				;47f1	fe 08 	. . 
	ret nz							; no ------------------- End of Proc --------------------------	;47f3	c0 	. 
; -- file was Opened - release FCB
	xor a							; a - error code 00 - OK (and also FCB not used flag)			;47f4	af 	. 
	ld (de),a						; set FCB Open flag as "not used"								;47f5	12 	. 
	ret								; --------------------- End of Proc --------------------------	;47f6	c9 	. 

; -- called from BASIC Program - needs extra cleanup
.fromBasicProg:
	call FindFCBForOpen				; Find FCB Block used by this file if file already opened		;47f7	cd 78 47 	. x G 
	pop hl							; restore hl - address of next character in BASIC				;47fa	e1 	. 
	cp 08							; is file Opened? (Error 08   FILE ALREADY OPEN)				;47fb	fe 08 	. . 
	ret nz							; no ------------------- End of Proc --------------------------	;47fd	c0 	. 

; -- file was Opened - release FCB
	ld a,(de)						; a - FCB Open flag												;47fe	1a 	. 
	cp 2							; is file opened and active?									;47ff	fe 02 	. . 
	ld a,0							; a - "not used" value 											;4801	3e 00 	> . 
	ld (de),a						; set as FCB Open flag (release FCB)							;4803	12 	. 
	ret nz							; no ------------------- End of Proc --------------------------	;4804	c0 	. 

; -- file is opened and active (data in sector buffer)
	inc de							; de - address of Access type (read/write) in FCB				;4805	13 	. 
	ld a,(de)						; a - access type (read/write)									;4806	1a 	. 
	or a							; is it 0 (read)?												;4807	b7 	. 
	ret z							; yes ------------------ End of Proc --------------------------	;4808	c8 	. 

; -- file was opened to write - need to flush data from buffer to disk
	push hl							; save hl - address of next character in BASIC					;4809	e5 	. 
	ex de,hl						; hl - address of Access type (read/write) in FCB				;480a	eb 	. 
	ld de,9							; de - offset from Access field to TRK# field in FCB			;480b	11 09 00 	. . . 
	add hl,de						; hl - address of Track Number (TRK#) in FCB					;480e	19 	. 
	ld a,(hl)						; a - Track Number from FCB										;480f	7e 	~ 
	inc hl							; hl - address of Sector Number (TRK#) in FCB					;4810	23 	# 
	ld (iy+TRCK),a					; set as Track Number to write									;4811	fd 77 12 	. w . 
	ld a,(hl)						; a - Sector Number from FCB									;4814	7e 	~ 
	ld (iy+SCTR),a					; set as Sector Number to write									;4815	fd 77 11 	. w . 

; -- write data from sector buffer to disk
	di								; enable interrupts												;4818	f3 	. 

; -- turn on Disk Drive and wait 50 ms
	call PWRON						; Disk power ON													;4819	cd 41 5f 	. A _ 
	push bc							; save bc 														;481c	c5 	. 
	ld bc,50						; bc - number of miliseconds to delay							;481d	01 32 00 	. 2 . 
	call DLY						; delay 50 ms													;4820	cd be 5e 	. . ^ 
	pop bc							; restore bc													;4823	c1 	. 

; -- check if Disk is not Write-Protected
	in a,(FLWRPROT)					; a - read Write Protected flag from FDC						;4824	db 13 	. . 
	or a							; is bit 7 set? (write protected)								;4826	b7 	. 
	ld a,04							; a - Error 04 - DISK WRITE PROTECTED							;4827	3e 04 	> . 
	jp m,ERROR						; yes - go to Error handling routine --------------------------	;4829	fa 41 42 	. A B 

; -- write sector to disk
	call WRITE						; Write a sector to disk										;482c	cd a1 59 	. . Y 
	or a							; was any error?												;482f	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;4830	c2 41 42 	. A B 

; -- no error - power off and exit
	ei								; enable interrupts												;4833	fb 	. 
	call PWROFF						; Disk power OFF												;4834	cd 52 5f 	. R _ 
	pop hl							; restore hl - address of next character in BASIC				;4837	e1 	. 
	ret								; ---------------------- End of Proc --------------------------	;4838	c9 	. 




;***************************************************************************************************
; DOS Command BSAVE
; Syntax: BSAVE "filename", SSSS, EEEE
; ------------------------------------
; Save part of memory to file specified by "filename" to Disk as file Type 'B'. 
; Memory part is defined as all bytes from address SSSS (included) to address EEEE (included).
; Filename may have no more than 8 characters. Both addresses SSSS and EEEE must be provided
; as hexadecimal 16bit number.
; IN: hl - parse point (just after 'LOAD' text)
DCmdBSAVE:
; -- expected required name of file enclosed with double quote chars
	call ParseFilename				; Verify syntax and copy filename to DOS Filename Buffer		;4839	cd 78 53 	. x S 
	push hl							; save hl - parse point											;483c	e5 	. 
	or a							; was any Error?												;483d	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;483e	c2 41 42 	. A B 

; -- expected ',' char 
	pop hl							; restore hl - parse point										;4841	e1 	. 
	rst $08							; Assert next char is ','										;4842	cf 	. 
	defb ','						; next char must be ','											;4843	2c 	, 

; -- save current addresses of BASIC program on stack
	ld de,(SYS_BASIC_END_PTR)		; end of current BASIC Program 									;4844	ed 5b f9 78 	. [ . x 
	push de							; save de - end of program 										;4848	d5 	. 
	ld de,(SYS_BASIC_START_PTR)		; start of current BASIC Program 								;4849	ed 5b a4 78 	. [ . x 
	push de							; save de - start of programm									;484d	d5 	. 

; -- convert hex text (4 chars) into 16bit address - start of memory to save
	call HEX						; de - 16bit address from 4 chars of Hex text					;484e	cd b9 53 	. . S 
	ld a,1							; a - Error 01 - SYNTAX ERROR									;4851	3e 01 	> . 
	jp c,BS_ExitError				; if parse hex error - exit with Error 01 ---------------------	;4853	da b7 48 	. . H 
	ld (SYS_BASIC_START_PTR),de		; no error - save as start of memory to save 					;4856	ed 53 a4 78 	. S . x 

; -- expected ',' char 
	rst $08							; Assert next char is ','										;485a	cf 	. 
	defb ','						; next char must be ','											;485b	2c 	, 

; -- convert hex text (4 chars) into 16bit address - end of memory to save
	call HEX						; de - 16bit address from 4 chars of Hex text					;485c	cd b9 53 	. . S 
	ld a,1							; a - Error 01 - SYNTAX ERROR									;485f	3e 01 	> . 
	jp c,BS_ExitError				; if parse hex error - exit with Error 01 ---------------------	;4861	da b7 48 	. . H 
	inc de							; de - next address after last byte to save						;4864	13 	. 
	ld (SYS_BASIC_END_PTR),de		; save end of current BASIC Program 							;4865	ed 53 f9 78 	. S . x 

; -- verify syntax - must be end of line ('\0') or end of expression ':'
	ld a,(hl)						; a - next parsed char											;4869	7e 	~ 
	or a							; is it \0 ? (end of BASIC line)								;486a	b7 	. 
	jr z,.continue					; yes - continue												;486b	28 07 	( . 
	cp ':'							; is it ':' (end of expression)?								;486d	fe 3a 	. : 
	ld a,1							; a - Error 01 - SYNTAX ERROR									;486f	3e 01 	> . 
	jp nz,BS_ExitError				; if not \0 nor ':' - exit with Error 01 ----------------------	;4871	c2 b7 48 	. . H 

.continue:
; -- set type of file as Binary Program ('B')
	ld (iy+TYPE),'B'				; set type of file as Binary Program ('B')						;4874	fd 36 09 42 	. 6 . B 
	push hl							; save hl - parse point											;4878	e5 	. 

; -- verify start addres is smaller than end address 
	ld hl,(SYS_BASIC_START_PTR)		; hl - start of memory area to save, de - end of area 							;4879	2a a4 78 	* . x 
	or a							; clear Carry flag												;487c	b7 	. 
	sbc hl,de						; difference - is hl >= de ? 									;487d	ed 52 	. R 
	ld a,1							; a - Error 01 - SYNTAX ERROR									;487f	3e 01 	> . 
	jp nc,SAVE_ExitError			; if hl >= de - exit with Error 01 ----------------------------	;4881	d2 9a 48 	. . H 

; -- no error - turn on Disk Drive and wait 2ms
	call PWRON						; Disk power ON													;4884	cd 41 5f 	. A _ 
	push bc							; save bc														;4887	c5 	. 
	ld bc,2							; bc - 2 miliseconds to delay									;4888	01 02 00 	. . . 
	call DLY						; delay 2 ms 													;488b	cd be 5e 	. . ^ 
	pop bc							; restore bc													;488e	c1 	. 

; -- check if Disk is not Write-Protected
	in a,(FLWRPROT)					; a - read Write Protected flag from FDC						;488f	db 13 	. . 
	or a							; is bit 7 set? (write protected)								;4891	b7 	. 
	ld a,04							; a - Error 04 - DISK WRITE PROTECTED							;4892	3e 04 	> . 
	jp m,SAVE_ExitError				; yes - go to Error handling routine --------------------------	;4894	fa 9a 48 	. . H 
	jp DoSaveFile					; continue reusing part of 'SAVEFILE' DOS routine -------------	;4897	c3 79 44 	. y D 


SAVE_ExitError:
; -- was it canceled by user pressing BREAK?
	cp 17							; is it Error 17 - BREAK by user 								;489a	fe 11 	. . 
	jr nz,.exitWithError			; no - exit with other error									;489c	20 18 	  . 

; -- 
	call SEARCH						; Search for file in directory									;489e	cd 13 59 	. . Y 
	cp 2							; was Error 2 - FILE ALREADY EXISTS ?							;48a1	fe 02 	. . 
	ld a,17							; set Error 17 - BREAK by user									;48a3	3e 11 	> . 
	jr nz,.exitWithError			; file not found - ;48a5	20 0f 	  . 

; -- there is Directory Entry for this file - mark as deleted 
	ex de,hl						; hl - address of byte in Dir Entry (just after filename)		;48a7	eb 	. 
	ld de,-10						; 10 bytes from start of Directory Entry						;48a8	11 f6 ff 	. . . 
	add hl,de						; hl - start of Dir Entry - File Type byte						;48ab	19 	. 
	ld (hl),1						; mark file in Directory Entry as deleted 						;48ac	36 01 	6 . 
	call WRITE						; Write sector with Directory to Disk							;48ae	cd a1 59 	. . Y 
	or a							; was any Error?												;48b1	b7 	. 
	jr nz,.exitWithError			; yes - pass it through 										;48b2	20 02 	  . 
	ld a,17							; no - set Error 17 - BREAK by user								;48b4	3e 11 	> . 
.exitWithError:
	pop hl							; restore hl - BASIC Parser Pointer (???)						;48b6	e1 	. 

;***************************************************************************************************
; Restore BASIC Program addresses from Stack and go o DOS Error handler
; IN: a - Error code
BS_ExitError:
	pop de							; restore de - start of program									;48b7	d1 	. 
	ld (SYS_BASIC_START_PTR),de		; store to start of current BASIC Program variable				;48b8	ed 53 a4 78 	. S . x 
	pop de							; restore de - end of program									;48bc	d1 	. 
	ld (SYS_BASIC_END_PTR),de		; store to end of current BASIC Program variable				;48bd	ed 53 f9 78 	. S . x 
	jp ERROR						; got Error handling routine ----------------------------------	;48c1	c3 41 42 	. A B 




;***************************************************************************************************
; DOS Command BLOAD
; Syntax: BLOAD "filename"
; ------------------------
; Load file specified by filename (which has the file type code "B") from a Floppy Disk.
; The address where file will be loaded is already defined on Disk (after saving via BSAVE command).
; Filename may have no more than 8 characters.
; IN: hl - parse point (just after 'BLOAD' text)
DCmdBLOAD:
; -- expected required name of file enclosed with double quote chars
	call CSI						; parse filename and copy it to (iy+FNAM)						;48c4	cd 67 53 	. g S 
	push hl							; save hl - parse point											;48c7	e5 	. 
	or a							; was any Error?												;48c8	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;48c9	c2 41 42 	. A B 

; -- set type of file as Binary Program ('B') 
	ld (iy+TYPE),'B'				; set type of file as Binary Program ('B')						;48cc	fd 36 09 42 	. 6 . B 

; -- save current Program start and end addresses 
	pop hl							; restore hl - parse point										;48d0	e1 	. 
	ld de,(SYS_BASIC_END_PTR)		; de - end of current Program 									;48d1	ed 5b f9 78 	. [ . x 
	push de							; save de - end of current Program								;48d5	d5 	. 
	ld de,(SYS_BASIC_START_PTR)		; de - start of current Program 								;48d6	ed 5b a4 78 	. [ . x 
	push de							; save de - start of current Program							;48da	d5 	. 
	push hl							; save hl - parse point											;48db	e5 	. 

; -- call DOS routine
	call LOAD					; Load a file from disk											;48dc	cd b1 43 	. . C 

; -- restore current Program start and end addresses
	pop hl							; restore hl - parse point										;48df	e1 	. 
	pop de							; restore de - saved start of current Program					;48e0	d1 	. 
	ld (SYS_BASIC_START_PTR),de		; set as Start of current Program 								;48e1	ed 53 a4 78 	. S . x 
	pop de							; restore de - saved end of current Program						;48e5	d1 	. 
	ld (SYS_BASIC_END_PTR),de		; set as End of current Program 								;48e6	ed 53 f9 78 	. S . x 
; -- now check if was any Error 
	or a							; was any Error?												;48ea	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;48eb	c2 41 42 	. A B 
	ret								; no ----------------- End of Proc ----------------------------	;48ee	c9 	. 



;***************************************************************************************************
; DOS Command BRUN
; Syntax: BRUN "filename"
; -----------------------
; Load file specified by filename (which has the file type code "B") from a Floppy Disk and execute it.
; The address where file will be loaded is already defined on Disk (after saving via BSAVE command).
; Filename may have no more than 8 characters.
; IN: hl - parse point (just after 'BRUN' text)
DCmdBRUN:
; -- expected required name of file enclosed with double quote chars
	call CSI						; parse filename and copy it to (iy+FNAM)						;48ef	cd 67 53 	. g S 
	push hl							; save hl - parse point											;48f2	e5 	. 
	or a							; was any Error?												;48f3	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;48f4	c2 41 42 	. A B 

; -- set type of file as Binary Program ('B') and call DOS routine
	ld (iy+TYPE),'B'				; set type of file as Binary Program ('B')						;48f7	fd 36 09 42 	. 6 . B 
	call LOAD					; Load a file from disk											;48fb	cd b1 43 	. . C 
	or a							; was any Error?												;48fe	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	; Error handling routine	;48ff	c2 41 42 	. A B 

; -- execute loaded code from 1st byte
	ld hl,(SYS_BASIC_START_PTR)		; hl - start of loaded Program 									;4902	2a a4 78 	* . x 
	jp (hl)							; execute loaded Program --------------------------------------	;4905	e9 	. 



;***************************************************************************************************
; DOS Command DIR
; Syntax: DIR
; -----------
; Display list of all files on Disk. For every file the file Type will be printed as well.
; For example: T:MYFILE
; File Types: 'T' - BASIC text file, 'B' - binary program, 'D' - data file which should be handled
; by DOS commands like 'IN#' and 'PR#'
; IN: hl - parse point (just after 'BRUN' text)
DCmdDIR:
	push hl							; save hl - parse point											;4906	e5 	. 
	di								; disable interrupts											;4907	f3 	. 

; -- turn on Disk Drive and wait 50 ms
	call PWRON						; Disk power ON													;4908	cd 41 5f 	. A _ 
	push bc							; save bc														;490b	c5 	. 
	ld bc,50						; bc - 50 miliseconds to delay									;490c	01 32 00 	. 2 . 
	call DLY						; delay 50 ms													;490f	cd be 5e 	. . ^ 
	pop bc							; restore bc													;4912	c1 	. 

; -- set 1st sector with Directory Entries to read
	ld (iy+TRCK),0					; set Track Number 0											;4913	fd 36 12 00 	. 6 . . 
	ld (iy+SCTR),0					; set Sector Number 0											;4917	fd 36 11 00 	. 6 . . 

.nextSector:
; -- read Sector with Directory Entries 
	di								; disable interrupts											;491b	f3 	. 
	call READ						; Read sector from disk											;491c	cd 27 5b 	. ' [ 
	or a							; was any Error?												;491f	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;4920	c2 41 42 	. A B 

; -- setup for 1st Directory Entry on this Sector
	ld l,(iy+DBFR)					; hl - address of data from Sector								;4923	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)																				;4926	fd 66 32 	. f 2 
	ld de,6							; de - 6 bytes to skip after filename in Directory Entry		;4929	11 06 00 	. . . 
	ld c,8							; c - 8 entries per Sector										;492c	0e 08 	. . 

.printDirEntry:
; -- check 1st char of Directory Entry - file type, file deleted or end of Directory List
	ld a,(hl)						; a - file type 												;492e	7e 	~ 
	or a							; is it 0? (end of Directory List)								;492f	b7 	. 
	jr z,.exit						; yes - turn off Disk and exit --------------------------------	;4930	28 5d 	( ] 
	cp 1							; is it 1? (deleted entry)										;4932	fe 01 	. . 
	jr nz,.printFilename			; no - print 10 chars of entry (filename) on screen 			;4934	20 08 	  . 

; -- entry deleted - skip 10 chars (without printing on screen) 
	push bc							; save bc														;4936	c5 	. 
	ld bc,10						; bc - 10 chars to skip											;4937	01 0a 00 	. . . 
	add hl,bc						; hl - point to byte just after filename						;493a	09 	. 
	pop bc							; restore bc													;493b	c1 	. 
	jr .testSPACEPress				; skip printing code and continue -----------------------------	;493c	18 0e 	. . 

.printFilename:
; -- print on screen 10 chars from Directory Entry (filetype,';', and filename)
	ld b,10							; b - 10 chars to print on screen								;493e	06 0a 	. . 
.printNextChar:
	ld a,(hl)						; a - char from Driectory Entry									;4940	7e 	~ 
	call SysPrintChar				; call ROM routine to print char on screen						;4941	cd 2a 03 	. * . 
	inc hl							; hl - next char												;4944	23 	# 
	djnz .printNextChar				; keep printing all 10 chars ----------------------------------	;4945	10 f9 	. . 
; -- move cursor to next line
	ld a,CR							; a - new line character										;4947	3e 0d 	> . 
	call SysPrintChar				; call ROM routine to move cursor to next line					;4949	cd 2a 03 	. * . 

.testSPACEPress:
; -- test if SPACE key pressed - to PAUSE printing
	di								; disable interrupts											;494c	f3 	. 
	ld a,(SpaceKeyRow)				; a - read Keyboard row with SPACE key							;494d	3a ef 68 	: . h 
	bit SpaceKeyCol,a				; is SPACE key pressed?											;4950	cb 67 	. g 
	jr nz,.moveToNextEntry			; no - continue listing Directory Entries ---------------------	;4952	20 2d 	  - 
; -- SPACE key is pressed - delay 20 ms 
	push bc							; save bc														;4954	c5 	. 
	ld bc,20						; bc - 20 miliseconds to delay									;4955	01 14 00 	. . . 
	call DLY						; delay 20 ms													;4958	cd be 5e 	. . ^ 
	pop bc							; restore bc													;495b	c1 	. 
.waitKeyReleased:
; -- wait for SPACE Key to be released
	ld a,(SpaceKeyRow)				; a - read Keyboard row with SPACE key							;495c	3a ef 68 	: . h 
	bit SpaceKeyCol,a				; is SPACE key pressed?											;495f	cb 67 	. g 
	jr z,.waitKeyReleased			; yes - wait until released -----------------------------------	;4961	28 f9 	( . 
; -- SPACE key is released - delay 20 ms 
	push bc							; save bc														;4963	c5 	. 
	ld bc,20						; bc - 20 miliseconds to delay									;4964	01 14 00 	. . . 
	call DLY						; delay 20 ms													;4967	cd be 5e 	. . ^ 
	pop bc							; restore bc													;496a	c1 	. 


.waitKeyPressed:
; -- test if SPACE key pressed - to RESUME printing
	ld a,(SpaceKeyRow)				; a - read Keyboard row with SPACE key							;496b	3a ef 68 	: . h 
	bit SpaceKeyCol,a				; is SPACE key pressed?											;496e	cb 67 	. g 
	jr nz,.waitKeyPressed			; no - wait until pressed -------------------------------------	;4970	20 f9 	  . 
; -- SPACE key is pressed - delay 20 ms 
	push bc							; save bc														;4972	c5 	. 
	ld bc,20						; bc - 20 miliseconds to delay									;4973	01 14 00 	. . . 
	call DLY						; delay 20 ms													;4976	cd be 5e 	. . ^ 
	pop bc							; restore bc													;4979	c1 	. 
.waitKeyRelAgain:
; -- wait for SPACE Key to be released
	ld a,(SpaceKeyRow)				; a - read Keyboard row with SPACE key							;497a	3a ef 68 	: . h 
	bit SpaceKeyCol,a				; is SPACE key pressed?											;497d	cb 67 	. g 
	jr z,.waitKeyRelAgain			; yes - wait until released -----------------------------------	;497f	28 f9 	( . 

.moveToNextEntry:
; -- update pointer to next Directory Entry to read 
	add hl,de						; hl - begin of next Entry (skip 6 bytes)						;4981	19 	. 
	dec c							; are 8 entries already printed from this Sector?				;4982	0d 	. 
	jr nz,.printDirEntry			; no - print next Directory Entry -----------------------------	;4983	20 a9 	  . 

; -- 8 entries been read - setup next Sector to read
	inc (iy+SCTR)					; increment Sector Number										;4985	fd 34 11 	. 4 . 
	ld a,(iy+SCTR)					; a - number of next Sector to read								;4988	fd 7e 11 	. ~ . 
	cp 15							; all 14 sectors already read?									;498b	fe 0f 	. . 
	jr nz,.nextSector				; no - read next Sector ---------------------------------------	;498d	20 8c 	  . 

.exit:
	call PWROFF					; Disk power OFF												;498f	cd 52 5f 	. R _ 
	pop hl							; restore hl - parse point										;4992	e1 	. 
	ret								; -------------------- End of Proc ----------------------------	;4993	c9 	. 



;***************************************************************************************************
; DOS Command ERA
; Syntax: ERA "filename"
; ----------------------
; Deleted file specified by filename from Disk. 
; Filename may have no more than 8 characters.
; IN: hl - parse point (just after 'ERA' text)
DCmdERA:
; -- expected required name of file enclosed with double quote chars
	call CSI						; parse filename and copy it to (iy+FNAM)					;4994	cd 67 53 	. g S 
	push hl							; save hl - parse point											;4997	e5 	. 
	or a							; was any Error?												;4998	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;4999	c2 41 42 	. A B 

; -- turn on Disk Drive and wait 50 ms
	di								; disable interrupts											;499c	f3 	. 
	call PWRON						; Disk power ON													;499d	cd 41 5f 	. A _ 
	push bc							; save bc														;49a0	c5 	. 
	ld bc,50						; bc - 50 miliseconds to delay									;49a1	01 32 00 	. 2 . 
	call DLY						; delay 50 ms													;49a4	cd be 5e 	. . ^ 
	pop bc							; restore bc													;49a7	c1 	. 

; -- check if Disk is not Write-Protected
	in a,(FLWRPROT)					; a - read Write Protected flag from FDC						;49a8	db 13 	. . 
	or a							; is bit 7 set? (write protected)								;49aa	b7 	. 
	ld a,04							; a - Error 04 - DISK WRITE PROTECTED							;49ab	3e 04 	> . 
	jp m,ERROR						; yes - go to Error handling routine --------------------------	;49ad	fa 41 42 	. A B 

; -- find Directory Entry for this file
	call SEARCH						; Search for file in directory									;49b0	cd 13 59 	. . Y 
	cp 02							; was Error 2 - FILE ALREADY EXISTS	?							;49b3	fe 02 	. . 
	jr z,.fileFound					; yes - continue deleting file --------------------------------	;49b5	28 09 	( . 
; -- other error or No Error
	or a							; other error?													;49b7	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;49b8	c2 41 42 	. A B 
; -- No Error - means there are no requested file on Disk
	ld a,13							; a - Error 13 - FILE NOT FOUND									;49bb	3e 0d 	> . 
	jp ERROR						; go to Error handling routine --------------------------------	;49bd	c3 41 42 	. A B 

; -- in FINDFILE routine de is set to address of 10th byte of Directory Entry - file Track number
.fileFound:
; -- set track and sector numbers for 1st sector of file 
	ld a,(de)						; a - Track number of 1st file sector 							;49c0	1a 	. 
	inc de							; de - point to Sector Number									;49c1	13 	. 
	ld (iy+NTRK),a					; set Track Number for Sector to delete 						;49c2	fd 77 16 	. w . 
	ld a,(de)						; a - Sector Number of 1st file sector							;49c5	1a 	. 
	ld (iy+NSCT),a					; set Sector Number fo Sector to delete							;49c6	fd 77 15 	. w . 

; -- mark file's Directory Entry as deleted
	ex de,hl						; hl - address in Directory Entry								;49c9	eb 	. 
	ld de,-11						; de - 11 bytes back will be start of Directory Entry 			;49ca	11 f5 ff 	. . . 
	add hl,de						; hl - start of Directory Entry - file type						;49cd	19 	. 
	ld (hl),1						; set file type byte to 1 - entry deleted						;49ce	36 01 	6 . 
	call WRITE						; Write sector with Directory to disk							;49d0	cd a1 59 	. . Y 
	or a							; was any Error?												;49d3	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;49d4	c2 41 42 	. A B 

; -- read Disk Map Sector from Disk
	ld (iy+TRCK),0					; set Track Number 0 											;49d7	fd 36 12 00 	. 6 . . 
	ld (iy+SCTR),15					; set Sector Number 15											;49db	fd 36 11 0f 	. 6 . . 
	call READ						; Read Disk Map sector from disk								;49df	cd 27 5b 	. ' [ 
	or a							; was any Error?												;49e2	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;49e3	c2 41 42 	. A B 
; -- copy sector data to Disk Map buffer
	ld e,(iy+MAPADR)				; de - (dst) address of Disk Map buffer							;49e6	fd 5e 34 	. ^ 4 
	ld d,(iy+MAPADR+1)																				;49e9	fd 56 35 	. V 5 
	ld l,(iy+DBFR)					; hl - (src) address of Sector data read from Disk				;49ec	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)																				;49ef	fd 66 32 	. f 2 
	ld bc,80						; bc - 80 bytes to copy											;49f2	01 50 00 	. P . 
	ldir							; copy Disk Map data 											;49f5	ed b0 	. . 

; -- get all sectors for this file and mark them as unused in Disk Map
.nextFileSector:
; -- read file sector 
	ld a,(iy+NTRK)					; a - Track  Number to read										;49f7	fd 7e 16 	. ~ . 
	or a							; is it 0? (no more sectors used by file)						;49fa	b7 	. 
	jp z,.saveDiskMap				; yes - ;49fb	ca 4f 4a 	. O J 
	ld (iy+TRCK),a					; set as Track Number of sector to read							;49fe	fd 77 12 	. w . 
	ld a,(iy+NSCT)					; a - Sector Number												;4a01	fd 7e 15 	. ~ . 
	ld (iy+SCTR),a					; set as Sector Number of sector to read						;4a04	fd 77 11 	. w . 
	call READ						; Read a sector from disk										;4a07	cd 27 5b 	. ' [ 
	or a							; was any Error?												;4a0a	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;4a0b	c2 41 42 	. A B 
; -- read last 2 bytes to get next sector number and track number
	ld l,(iy+DBFR)					; hl - address of Sector data 									;4a0e	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)																				;4a11	fd 66 32 	. f 2 
	ld de,126						; de - offset from begin of sector data buffer					;4a14	11 7e 00 	. ~ . 
	add hl,de						; hl - points to next Track Number								;4a17	19 	. 
	ld a,(hl)						; a - track number of next sector								;4a18	7e 	~ 
	ld (iy+NTRK),a					; store as next Track Number									;4a19	fd 77 16 	. w . 
	inc hl							; hl - points to next Sector Number								;4a1c	23 	# 
	ld a,(hl)						; a - sector number of next sector								;4a1d	7e 	~ 
	ld (iy+NSCT),a					; stor as next Sector Number									;4a1e	fd 77 15 	. w . 

; -- get Disk Map address 
	ld l,(iy+MAPADR)				; hl - address of Disk Map buffer								;4a21	fd 6e 34 	. n 4 
	ld h,(iy+MAPADR+1)																				;4a24	fd 66 35 	. f 5 
; -- calculate byte offset 
	ld a,(iy+TRCK)					; a - Track Number of sector for next chunk of file				;4a27	fd 7e 12 	. ~ . 
	dec a							; a = a -1 (Disk Map covers sectors from track 1)				;4a2a	3d 	= 
	sla a							; track * 2 (2 bytes in Map covers 1 track)						;4a2b	cb 27 	. ' 
	ld e,a							; e - offset in Disk Map for Track								;4a2d	5f 	_ 
	ld d,0							; de - offset in Disk Map for Track								;4a2e	16 00 	. . 
	ld a,(iy+SCTR)					; a - Sector number for next chunk of file						;4a30	fd 7e 11 	. ~ . 
	cp 8							; set Carry flag if Sector < 8 									;4a33	fe 08 	. . 
	ccf								; invert Carry - will be 1 if Sector >= 8 						;4a35	3f 	? 
	adc hl,de						; hl - address in Disk Map of bitmask with this sector			;4a36	ed 5a 	. Z 
; -- calculate bit number 
	and %0111						; a - bit number for this sector								;4a38	e6 07 	. . 
	inc a							; preincrement for number of rotates 1..8						;4a3a	3c 	< 
	ld b,a							; b - how many times to rotate bitmask							;4a3b	47 	G 
; -- reset bit for this sector (not used)
	ld c,(hl)						; c - bitmask with this sector									;4a3c	4e 	N 
	rlc c							; pre-rotate left (set Carry from 7th bit)						;4a3d	cb 01 	. . 
.loop1:
	rrc c							; rotate right bitmask											;4a3f	cb 09 	. . 
	djnz .loop1						; keep rotate until bit is at position 0						;4a41	10 fc 	. . 
	res 0,c							; clear bit for this sector										;4a43	cb 81 	. . 
	ld b,a							; b - number of rotates to do									;4a45	47 	G 
	rrc c							; pre-rotate right (set Carry from 0th bit)						;4a46	cb 09 	. . 
.loop2:
	rlc c							; rotate left bitmask											;4a48	cb 01 	. . 
	djnz .loop2						; keep rotate until bit returns to its original position		;4a4a	10 fc 	. . 
	ld (hl),c						; store updated byte to Disk Map								;4a4c	71 	q 
	jr .nextFileSector				; get next Sector of file and mark it as unused ---------------	;4a4d	18 a8 	. . 

.saveDiskMap:
; -- clear Sector Buffer
	ld l,(iy+DBFR)					; hl - (src) address of Sector Buffer							;4a4f	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)																				;4a52	fd 66 32 	. f 2 
	push hl							; save hl - address of Sector Buffer							;4a55	e5 	. 
	ld (hl),0						; set 1st byte to 0												;4a56	36 00 	6 . 
	ld e,l							; copy hl to de													;4a58	5d 	] 
	ld d,h							; de - address of Sector Buffer 								;4a59	54 	T 
	inc de							; de - (dst) address of 2db byte in Sector Buffer				;4a5a	13 	. 
	ld bc,127						; bc - 125 bytes to clear										;4a5b	01 7f 00 	.  . 
	ldir							; clear (copy byte 0) Sector Buffer								;4a5e	ed b0 	. . 
; -- copy 80 bytes of Disk Map to Sector Buffer	
	pop de							; restore de - (dst) address of Sector Buffer					;4a60	d1 	. 
	ld l,(iy+MAPADR)				; hl - (src) address of Disk Map buffer							;4a61	fd 6e 34 	. n 4 
	ld h,(iy+MAPADR+1)																				;4a64	fd 66 35 	. f 5 
	ld bc,80						; bc - 80 bytes to copy											;4a67	01 50 00 	. P . 
	ldir							; copy Disk Map to Sector Buffer								;4a6a	ed b0 	. . 
; -- save Disk Map to Disk
	ld (iy+TRCK),0					; set Track Number 0											;4a6c	fd 36 12 00 	. 6 . . 
	ld (iy+SCTR),15					; set Sector Number 15											;4a70	fd 36 11 0f 	. 6 . . 
	call WRITE						; Write Disk Map to sector on Disk								;4a74	cd a1 59 	. . Y 
	or a							; was any Error?												;4a77	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;4a78	c2 41 42 	. A B 
; -- file deleted 
	call PWROFF						; Disk power OFF												;4a7b	cd 52 5f 	. R _ 
	pop hl							; restore hl - parse point										;4a7e	e1 	. 
	ret								; ----------------- End of Proc -------------------------------	;4a7f	c9 	. 



;***************************************************************************************************
; DOS Command REN
; Syntax: REN "oldfilename", "newfilename"
; ----------------------------------------
; Change name of the file specified by oldfilename to newfilename on Disk.
; Both filenames may have no more than 8 characters. File Type stays unchanged. 
; IN: hl - parse point (just after 'REN' text)
DCmdREN:
; -- expected required name of old file enclosed with double quote chars
	push hl							; save hl - parse point											;4a80	e5 	. 
	call ParseFilename				; Verify syntax and copy old filename to DOS Filename Buffer	;4a81	cd 78 53 	. x S 
	or a							; was any Error?												;4a84	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;4a85	c2 41 42 	. A B 
; -- expected ',' char 
	rst $08							; Assert next char is ','										;4a88	cf 	. 
	defb ','						; next char must be ','											;4a89	2c 	, 
; -- expected required name of new file enclosed with double quote chars
	call CSI						; parse new filename and copy it to (iy+FNAM)					;4a8a	cd 67 53 	. g S 
	or a							; was any Error?												;4a8d	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;4a8e	c2 41 42 	. A B 
; -- 
	pop hl							; restore hl - parse point										;4a91	e1 	. 
	push hl							; save hl - parse point (just after 'REN')						;4a92	e5 	. 
	call ParseFilename				; hl - parse point just after '"' char							;4a93	cd 78 53 	. x S 
	inc hl							; skip comma ',' char											;4a96	23 	# 
	push hl							; save hl - start of new filename text (1st '"' char)			;4a97	e5 	. 

; -- turn on Disk Drive and wait 50 ms
	di								; disable interrupts											;4a98	f3 	. 
	call PWRON						; Disk power ON													;4a99	cd 41 5f 	. A _ 
	push bc							; save bc														;4a9c	c5 	. 
	ld bc,50						; bc - 50 miliseconds to delay									;4a9d	01 32 00 	. 2 . 
	call DLY						; delay 50 ms													;4aa0	cd be 5e 	. . ^ 
	pop bc							; restore bc 													;4aa3	c1 	. 

; -- check if Disk is not Write-Protected
	in a,(FLWRPROT)					; a - read Write Protected flag from FDC						;4aa4	db 13 	. . 
	or a							; is bit 7 set? (write protected)								;4aa6	b7 	. 
	ld a,04							; a - Error 04 - DISK WRITE PROTECTED							;4aa7	3e 04 	> . 
	jp m,ERROR						; yes - go to Error handling routine --------------------------	;4aa9	fa 41 42 	. A B 

; -- find Directory Entry for this file
	call SEARCH						; Search for old filename in directory							;4aac	cd 13 59 	. . Y 
	cp 02							; was Error 2 - FILE ALREADY EXISTS	?							;4aaf	fe 02 	. . 
	jp z,.oldFilenameFound			; yes - continue renaming file --------------------------------	;4ab1	ca bd 4a 	. . J 

; -- other error or No Error
	or a							; other error?													;4ab4	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;4ab5	c2 41 42 	. A B 

; -- No Error - means there are no requested file on Disk
	ld a,13							; a - Error 13 - FILE NOT FOUND									;4ab8	3e 0d 	> . 
	jp ERROR						; go to Error handling routine --------------------------------	;4aba	c3 41 42 	. A B 

.oldFilenameFound:
	pop hl							; restore hl - start of new filename text						;4abd	e1 	. 
	call CSI						; parse new filename and copy it to (iy+FNAM)					;4abe	cd 67 53 	. g S 
	ex (sp),hl						; save hl - parse point (after whole command)					;4ac1	e3 	. 
	push hl							; save hl - parse point (just after 'REN')						;4ac2	e5 	. 

; -- check if already exists file with new filename in Directory Entry
	call SEARCH						; Search for new filename in directory							;4ac3	cd 13 59 	. . Y 
	cp 13							; was Error 13 - FILE NOT FOUND ?								;4ac6	fe 0d 	. . 
	jr z,.newFilenameNotFound		; yes - continue renaming 										;4ac8	28 04 	( . 

; -- other error or No Error
	or a							; any other Error?												;4aca	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;4acb	c2 41 42 	. A B 

.newFilenameNotFound:
; -- get sector wit directory Entry for file to rename
	pop hl							; restore hl - parse point (just after 'REN')					;4ace	e1 	. 
	call ParseFilename				; copy old filename to DOS Filename Buffer						;4acf	cd 78 53 	. x S 
	inc hl							; skip ',' char													;4ad2	23 	# 
	push hl							; save hl - start of new filename								;4ad3	e5 	. 
	call SEARCH						; find Directory Entry for old filename							;4ad4	cd 13 59 	. . Y 
	cp 02							; was Error 2 - FILE ALREADY EXISTS ?							;4ad7	fe 02 	. . 
	jp nz,ERROR						; no - go to Error handling routine ---------------------------	;4ad9	c2 41 42 	. A B 

; -- save hl and de registers (end of filename in DOS buffer and Directory Entry buffer)
	pop bc							; bc - start of new filename									;4adc	c1 	. 
	push hl							; save hl - end of old filename in (iy+FNAM)					;4add	e5 	. 
	push de							; save de - end of old filename in Dir Entry Buffer				;4ade	d5 	. 
; -- copy given new filename to DOS buffer
	ld l,c							; copy bc to hl													;4adf	69 	i 
	ld h,b							; hl - start of new filename									;4ae0	60 	` 
	call CSI						; parse new filename and copy it to (iy+FNAM)					;4ae1	cd 67 53 	. g S 
; -- restore hl and de pointers and move them to begin of filename in DOS buffer and Dir Entry
	pop de							; restore de - end of old filename in Dir Entry Buffer			;4ae4	d1 	. 
	pop hl							; restore hl - end of now new filename in (iy+FNAM)				;4ae5	e1 	. 
	ld bc,-8						; bc - 8 bytes of name to move back pointer						;4ae6	01 f8 ff 	. . . 
	add hl,bc						; hl - start of new filename in DOS Buffer						;4ae9	09 	. 
	ex de,hl						; de - start of new filename in DOS buffer						;4aea	eb 	. 
	add hl,bc						; hl - start of old filename in Dir Entry Buffer				;4aeb	09 	. 

; -- fill Directory Entry with new file type and name
	dec hl							; move back hl													;4aec	2b 	+ 
	dec hl							; hl - points to File Type char in Dir Entry					;4aed	2b 	+ 
; -- copy FileType
	ld a,(iy+TYPE+1)				; a - new file Type												;4aee	fd 7e 0a 	. ~ . 
	ld (hl),a						; store in Directory Entry										;4af1	77 	w 
	inc hl							; hl - points to separator char in Dir Entry					;4af2	23 	# 
; -- copy separator
	ld (hl),':'						; store separator char ':'										;4af3	36 3a 	6 : 
	inc hl							; hl - start of filename in Dir Entry							;4af5	23 	# 
; -- copy 8 chars of filename
	ex de,hl						; de - (dst) Dir entry, hl - (src) DOS buffer					;4af6	eb 	. 
	ld bc,8							; bc - 8 chars to copy											;4af7	01 08 00 	. . . 
	ldir							; copy new filename to Directory Entry							;4afa	ed b0 	. . 
	call WRITE						; Write sector with Directory to disk							;4afc	cd a1 59 	. . Y 
	or a							; was any Error?												;4aff	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;4b00	c2 41 42 	. A B 
; -- no error - turn off DIsk and return
	call PWROFF					; Disk power OFF												;4b03	cd 52 5f 	. R _ 
	pop hl							; restore hl - parse point (after whole command)				;4b06	e1 	. 
	ret								; ------------------- End of Proc -----------------------------	;4b07	c9 	. 




;***************************************************************************************************
; DOS Command INIT
; Syntax: INIT
; ----------------
; Initialize the disk (format)
; Used also from DOS jump Table
; IN: IY+DK - selected Drive
; OUT: none						
;***************************************************************************************************
DCmdINIT:
INIT:
; -- turn on disk drive 
	di								; disable interrupts											;4b08	f3 	. 
	call PWRON						; Disk power ON													;4b09	cd 41 5f 	. A _ 

; -- wait 1 sek to have Disk Drive ready
	push bc							; save bc 														;4b0c	c5 	. 
	ld bc,1000						; 1000 ms delay													;4b0d	01 e8 03 	. . . 
	call DLY						; wait 1000 ms 		 											;4b10	cd be 5e 	. . ^ 
	pop bc							; restore bc													;4b13	c1 	. 

; -- check if disk is write protected and raise Error 04 if it's the case
	in a,(FLWRPROT)					; a - read Write Protected flag from FDC						;4b14	db 13 	. . 
	or a							; check if bit 7 is set 										;4b16	b7 	. 
	ld a,04							; Error Code 4 - "?DISK WRITE PROTECTED"						;4b17	3e 04 	> . 
	jp m,ERROR						; yes - go to Error handling routine --------------------------	;4b19	fa 41 42 	. A B 

; -- prepeare sector data to copy on disk 
	push hl							; save hl 														;4b1c	e5 	. 
	push iy							; iy - DOS base address											;4b1d	fd e5 	. . 
	pop hl							; copy to hl													;4b1f	e1 	. 
	ld de,SectorBuffer				; offset to Sector Buffer										;4b20	11 4d 00 	. M . 
	add hl,de						; hl - address of Sector Buffer									;4b23	19 	. 
	ld (iy+TRCK),0					; set Track Number 0											;4b24	fd 36 12 00 	. 6 . . 
	ld (iy+SCTR),0					; set Sector Number 0											;4b28	fd 36 11 00 	. 6 . . 
	ld (iy+UBFR),l					; set Sector buffer as address to copy from						;4b2c	fd 75 0e 	. u . 
	ld (iy+UBFR+1),h																				;4b2f	fd 74 0f 	. t . 

; -- copy Template of sector header into Sector Buffer 
	ex de,hl						; dst - de - address of Sector Buffer							;4b32	eb 	. 
	ld hl,SecHeaderInitData			; src - hl - sector init data template							;4b33	21 4f 4d 	! O M 
	ld bc,24						; Sector Header has 24 bytes to copy							;4b36	01 18 00 	. . . 
	ldir							; copy 24 bytes to Sector Buffer								;4b39	ed b0 	. . 

; clear 128 bytes (sector data) + 2 bytes (checksum)
	ld h,d						; src - hl - 1st byte of Sector Data Area							;4b3b	62 	b 
	ld l,e																							;4b3c	6b 	k 
	ld (hl),0						; clear 1st byte 												;4b3d	36 00 	6 . 
	inc de							; dst - de - naxt byte in buffer								;4b3f	13 	. 
	ld bc,128+2						; 130 bytes to clear (data+checksum)							;4b40	01 82 00 	. . . 
	ldir							; clear 130 bytes in buffer										;4b43	ed b0 	. . 

; -- move drive Head to track 0
	ld (iy+PHASE),%00010001			; set Step Motor to 0001-0001 									;4b45	fd 36 38 11 	. 6 8 . 
	ld b,40							; max 40 tracks to StepOut										;4b49	06 28 	. ( 
	call STPOUT						; execute Track Step Out 										;4b4b	cd 01 5f 	. . _ 
; -- wait 400ms 
	push bc							; save bc														;4b4e	c5 	. 
	ld bc,400						; 400 ms delay													;4b4f	01 90 01 	. . . 
	call DLY						; wait 400 ms Delay												;4b52	cd be 5e 	. . ^ 
	pop bc							; restore bc													;4b55	c1 	. 

; -- set registers hl,de,bc to adresses in buffer for Trk#,Sect#,TSCRC
	ld l,(iy+UBFR)					; hl - address of Copy buffer									;4b56	fd 6e 0e 	. n . 
	ld h,(iy+UBFR+1)																				;4b59	fd 66 0f 	. f . 
	ld de,11						; offset to byte with Track number value						;4b5c	11 0b 00 	. . . 
	add hl,de						; hl - address of Track Number in Sector Buffer					;4b5f	19 	. 
	ld d,h							; de = hl														;4b60	54 	T 
	ld e,l							; de - address of Track Number in Sector Buffer					;4b61	5d 	] 
	inc de							; de - address of Sector Number in Sector Buffer				;4b62	13 	. 
	ld b,d							; bc = de														;4b63	42 	B 
	ld c,e							; bc - address of Sector Number in Sector Buffer				;4b64	4b 	K 
	inc bc							; bc - address of Track+Sector CRC in Sector Buffer				;4b65	03 	. 
	exx								; save bc,de,hl into alt registers								;4b66	d9 	. 


DI_WriteTrack:
; -- wait 100 ms delay
	push bc							; save bc 														;4b67	c5 	. 
	ld bc,100						; 100 ms Delay													;4b68	01 64 00 	. d . 
	call DLY						; wait 100 ms Delay 											;4b6b	cd be 5e 	. . ^ 
	pop bc							; restore bc													;4b6e	c1 	. 

; -- send Write Request to drive
	ld a,(iy+LTHCPY)				; a - last value sent to FLCtrl									;4b6f	fd 7e 33 	. ~ 3 
	res 6,a							; clear bit 6 - Write Request (active LOW)						;4b72	cb b7 	. . 
	ld (iy+LTHCPY),a				; store FLCtrl to shadow register								;4b74	fd 77 33 	. w 3 
	out (FLCTRL),a					; set Flopy Control byte										;4b77	d3 10 	. . 

; -- wait 100 ms delay
	push bc							; save bc 														;4b79	c5 	. 
	ld bc,100						; 100 ms Delay													;4b7a	01 64 00 	. d . 
	call DLY						; wait 100 ms Delay 											;4b7d	cd be 5e 	. . ^ 
	pop bc							; restore bc													;4b80	c1 	. 
; -- 
	ld ix,SectorsSequence			; ix - table of Sectors on Track interlave sequence				;4b81	dd 21 67 4d 	. ! g M 

DI_WriteSector:
	ld l,(iy+UBFR)					; hl - address of Copy buffer 									;4b85	fd 6e 0e 	. n . 
	ld h,(iy+UBFR+1)																				;4b88	fd 66 0f 	. f . 
	ld d,(iy+LTHCPY)				; d - last value sent to FLCtrl									;4b8b	fd 56 33 	. V 3 

; -- write copy buffer to drive bit by bit
	ld b,24+128+2					; 154 bytes to send per sector									;4b8e	06 9a 	. . 

; --------------------------------------------------------------------------------------------------
; IN: b - number of bytes to write
;     d - backed up value sent to FDC Control Register
;     hl - pointer to current byte in Copy Buffer
;     Initial Write Data Bit = 1
DI_WriteByte:
; -- send 1 bit at the time
	ld c,(hl)						; c - byte from Copy buffer to send 							;4b90	4e 	N 

; -- write bit 7 of data byte	
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;4b91	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;4b93	aa 	. 
; -- set CY flag to bit 7 of data byte
	rl c							; Carry flag = bit 7 of data byte - is it 1?					;4b94	cb 11 	. . 
	jp nc,.writeBit7_0				; no - write cell with data bit = 0								;4b96	d2 a4 4b 	. . K 
.writeBit7_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;4b99	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;4b9b	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;4b9d	57 	W 
	dec hl							; delay 6 cycles												;4b9e	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;4b9f	d3 10 	. . 
	jp .contBit7					; continue with next bit 6										;4ba1	c3 af 4b 	. . K 
.writeBit7_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;4ba4	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;4ba6	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;4ba8	57 	W 
	dec hl							; delay 6 cycles												;4ba9	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;4baa	d3 10 	. . 
	jp .contBit7					; continue with next bit 6										;4bac	c3 af 4b 	. . K 
.contBit7:
	inc hl							; delay 6 cycles												;4baf	23 	# 
	jp .delayBit7					; delay 10 cycles												;4bb0	c3 b3 4b 	. . K 
.delayBit7:
	jp .writeBit6Cell				; delay 10 cycles												;4bb3	c3 b6 4b 	. . K 

.writeBit6Cell:
; -- write bit 6 of data byte	
	in a,(FLPOOL)					; send clock to drive controller								;4bb6	db 12 	. . 
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;4bb8	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;4bba	aa 	. 
; -- set CY flag to bit 6 of data byte
	rl c							; Carry flag = bit 6 of data byte - is it 1?					;4bbb	cb 11 	. . 
	jp nc,.writeBit6_0				; no - write cell with data bit = 0								;4bbd	d2 cb 4b 	. . K 
.writeBit6_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;4bc0	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;4bc2	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;4bc4	57 	W 
	dec hl							; delay 6 cycles												;4bc5	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;4bc6	d3 10 	. . 
	jp .contBit6					; continue with next bit 5										;4bc8	c3 d6 4b 	. . K 
.writeBit6_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;4bcb	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;4bcd	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;4bcf	57 	W 
	dec hl							; delay 6 cycles												;4bd0	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;4bd1	d3 10 	. . 
	jp .contBit6					; continue with next bit 5										;4bd3	c3 d6 4b 	. . K 
.contBit6:
	inc hl							; delay 6 cycles												;4bd6	23 	# 
	jp .delayBit6					; delay 10 cycles												;4bd7	c3 da 4b 	. . K 
.delayBit6:
	jp .writeBit5Cell				; delay 10 cycles												;4bda	c3 dd 4b 	. . K 
.writeBit5Cell:
; -- write bit 5 of data byte	
	in a,(FLPOOL)					; send clock to drive controller								;4bdd	db 12 	. . 
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;4bdf	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;4be1	aa 	. 
; -- set CY flag to bit 5 of data byte
	rl c							; Carry flag = bit 5 of data byte - is it 1?					;4be2	cb 11 	. . 
	jp nc,.writeBit5_0				; no - write cell with data bit = 0								;4be4	d2 f2 4b 	. . K 
.writeBit5_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;4be7	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;4be9	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;4beb	57 	W 
	dec hl							; delay 6 cycles												;4bec	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;4bed	d3 10 	. . 
	jp .contBit5					; continue with next bit 4										;4bef	c3 fd 4b 	. . K 
.writeBit5_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;4bf2	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;4bf4	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;4bf6	57 	W 
	dec hl							; delay 6 cycles												;4bf7	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;4bf8	d3 10 	. . 
	jp .contBit5					; continue with next bit 4										;4bfa	c3 fd 4b 	. . K 
.contBit5:
	inc hl							; delay 6 cycles												;4bfd	23 	# 
	jp .delayBit5					; delay 10 cycles												;4bfe	c3 01 4c 	. . L 
.delayBit5:
	jp .writeBit4Cell				; delay 10 cycles												;4c01	c3 04 4c 	. . L 

.writeBit4Cell:
; -- write bit 4 of data byte	
	in a,(FLPOOL)					; send clock to drive controller								;4c04	db 12 	. . 
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;4c06	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;4c08	aa 	. 
; -- set CY flag to bit 4 of data byte
	rl c							; Carry flag = bit 4 of data byte - is it 1?					;4c09	cb 11 	. . 
	jp nc,.writeBit4_0				; no - write cell with data bit = 0								;4c0b	d2 19 4c 	. . L 
.writeBit4_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;4c0e	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;4c10	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;4c12	57 	W 
	dec hl							; delay 6 cycles												;4c13	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;4c14	d3 10 	. . 
	jp .contBit4					; continue with next bit 3										;4c16	c3 24 4c 	. $ L 
.writeBit4_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;4c19	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;4c1b	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL									;4c1d	57 	W 
	dec hl							; delay 6 cycles												;4c1e	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;4c1f	d3 10 	. . 
	jp .contBit4					; continue with next bit 3										;4c21	c3 24 4c 	. $ L 
.contBit4:
	inc hl							; delay 6 cycles												;4c24	23 	# 
	jp .delayBit4					; delay 10 cycles												;4c25	c3 28 4c 	. ( L 
.delayBit4:
	jp .writeBit3Cell				; delay 10 cycles												;4c28	c3 2b 4c 	. + L 

.writeBit3Cell:
; -- write bit 3 of data byte	
	in a,(FLPOOL)					; send clock to drive controller								;4c2b	db 12 	. . 
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;4c2d	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;4c2f	aa 	. 
; -- set CY flag to bit 3 of data byte
	rl c							; Carry flag = bit 3 of data byte - is it 1?					;4c30	cb 11 	. . 
	jp nc,.writeBit3_0				; no - write cell with data bit = 0								;4c32	d2 40 4c 	. @ L 
.writeBit3_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;4c35	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;4c37	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;4c39	57 	W 
	dec hl							; delay 6 cycles												;4c3a	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;4c3b	d3 10 	. . 
	jp .contBit3					; continue with next bit 2										;4c3d	c3 4b 4c 	. K L 
.writeBit3_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;4c40	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;4c42	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;4c44	57 	W 
	dec hl							; delay 6 cycles												;4c45	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;4c46	d3 10 	. . 
	jp .contBit3					; continue with next bit 2										;4c48	c3 4b 4c 	. K L 
.contBit3:
	inc hl							; delay 6 cycles												;4c4b	23 	# 
	jp .delayBit3					; delay 10 cycles												;4c4c	c3 4f 4c 	. O L 
.delayBit3:
	jp .writeBit2Cell				; delay 10 cycles												;4c4f	c3 52 4c 	. R L 

.writeBit2Cell:
; -- write bit 2 of data byte	
	in a,(FLPOOL)					; send clock to drive controller								;4c52	db 12 	. . 
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;4c54	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;4c56	aa 	. 
; -- set CY flag to bit 2 of data byte
	rl c							; Carry flag = bit 2 of data byte - is it 1?					;4c57	cb 11 	. . 
	jp nc,.writeBit2_0				; no - write cell with data bit = 0								;4c59	d2 67 4c 	. g L 
.writeBit2_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;4c5c	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;4c5e	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;4c60	57 	W 
	dec hl							; delay 6 cycles												;4c61	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;4c62	d3 10 	. . 
	jp .contBit2					; continue with next bit 1										;4c64	c3 72 4c 	. r L 
.writeBit2_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;4c67	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;4c69	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;4c6b	57 	W 
	dec hl							; delay 6 cycles												;4c6c	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;4c6d	d3 10 	. . 
	jp .contBit2					; continue with next bit 1										;4c6f	c3 72 4c 	. r L 
.contBit2:
	inc hl							; delay 6 cycles												;4c72	23 	# 
	jp .delayBit2					; delay 10 cycles												;4c73	c3 76 4c 	. v L 
.delayBit2:
	jp .writeBit1Cell				; continue 														;4c76	c3 79 4c 	. y L 

.writeBit1Cell:
; -- write bit 1 of data byte	
	in a,(FLPOOL)					; send clock to drive controller								;4c79	db 12 	. . 
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;4c7b	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;4c7d	aa 	. 
; -- set CY flag to bit 1 of data byte
	rl c							; Carry flag = bit 1 of data byte - is it 1?					;4c7e	cb 11 	. . 
	jp nc,.writeBit1_0				; no - write cell with data bit = 0								;4c80	d2 8e 4c 	. . L 
.writeBit1_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;4c83	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;4c85	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;4c87	57 	W 
	dec hl							; delay 6 cycles												;4c88	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;4c89	d3 10 	. . 
	jp .contBit1					; continue with next bit 0										;4c8b	c3 99 4c 	. . L 
.writeBit1_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;4c8e	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;4c90	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;4c92	57 	W 
	dec hl							; delay 6 cycles												;4c93	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;4c94	d3 10 	. . 
	jp .contBit1					; continue with next bit 0										;4c96	c3 99 4c 	. . L 
.contBit1:
	inc hl							; delay 6 cycles												;4c99	23 	# 
	jp .delayBit1					; delay 10 cycles												;4c9a	c3 9d 4c 	. . L 
.delayBit1:
	jp .writeBit0Cell				; delay 10 cycles												;4c9d	c3 a0 4c 	. . L 

.writeBit0Cell:
; -- write bit 0 of data byte	
	in a,(FLPOOL)					; send clock to drive controller								;4ca0	db 12 	. . 
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;4ca2	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;4ca4	aa 	. 
; -- set CY flag to bit 0 of data byte
	rl c							; Carry flag = bit 0 of data byte - is it 1?					;4ca5	cb 11 	. . 
	jp nc,.writeBit0_0				; no - write cell with data bit = 0								;4ca7	d2 b5 4c 	. . L 
.writeBit0_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;4caa	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;4cac	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;4cae	57 	W 
	dec hl							; delay 6 cycles												;4caf	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;4cb0	d3 10 	. . 
	jp .nextByte					; continue with next byte										;4cb2	c3 c0 4c 	. . L 
.writeBit0_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;4cb5	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;4cb7	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;4cb9	57 	W 
	dec hl							; delay 6 cycles												;4cba	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;4cbb	d3 10 	. . 
	jp .nextByte					; continue with next byte										;4cbd	c3 c0 4c 	. . L 

.nextByte:
	inc hl							; hl was decremented previously									;4cc0	23 	# 
	inc hl							; hl - address of next byte in buffer							;4cc1	23 	# 
	nop								; delay 4 cycles												;4cc2	00 	. 
	dec b							; decrement bytes-to-send counter								;4cc3	05 	. 
	jp nz,DI_WriteByte				; continue to write all 154 bytes do Disk						;4cc4	c2 90 4b 	. . K 


; -- update FLCtrl shadow
	ld (iy+LTHCPY),d				; store value as last sent to FLCtrl							;4cc7	fd 72 33 	. r 3 

; -- update next Sector Number and calculate checksum 
	exx								; restore hl,de,bc -> Trk#, Sect#, TSCRC						;4cca	d9 	. 
	ld a,(ix+1)						; a - next Sector Number										;4ccb	dd 7e 01 	. ~ . 
	inc ix							; increment ix ready for next round								;4cce	dd 23 	. # 
	ld (de),a						; set Sector Number	to next value from inteleave sequence		;4cd0	12 	. 
	add a,(hl)						; add Track number 												;4cd1	86 	. 
	ld (bc),a						; set as checksum value											;4cd2	02 	. 
	ld a,(de)						; a - sector number to check									;4cd3	1a 	. 
	exx								; exchange hl,de,bc with alt registers							;4cd4	d9 	. 
	cp $ff							; check if all sectors written for this track 					;4cd5	fe ff 	. . 
	jp nz,DI_WriteSector			; no - write next Sector										;4cd7	c2 85 4b 	. . K 

; -- next Track
	exx								; restore hl,de,bc -> Trk#, Sect#, TSCRC						;4cda	d9 	. 
	xor a							; a - sector number = 0											;4cdb	af 	. 
	ld (de),a						; set Sector Number to 0										;4cdc	12 	. 
	ld a,(hl)						; a - current Track number										;4cdd	7e 	~ 
	inc a							; increment track												;4cde	3c 	< 
	ld (hl),a						; set new track number											;4cdf	77 	w 
	ld (bc),a						; set as checksum (valid because Sector Number = 0)				;4ce0	02 	. 
	exx								; exchange hl,de,bc with alt registers							;4ce1	d9 	. 
	cp 40							; check if all 40 tracks written								;4ce2	fe 28 	. ( 
	jp z,DI_VerifyDisk				; yes - verify written disk										;4ce4	ca f9 4c 	. . L 

; -- turn off Write Request
	ld a,(iy+LTHCPY)				; a - FLCtrl value from shadow register							;4ce7	fd 7e 33 	. ~ 3 
	or FL_WRITE_REQ					; turn off Write Request										;4cea	f6 40 	. @ 
	ld (iy+LTHCPY),a				; store FLCtrl to shadow register								;4cec	fd 77 33 	. w 3 
	out (FLCTRL),a					; set Flopy Control byte										;4cef	d3 10 	. . 

; -- advance to next track
	ld b,1							; 1 track to step in											;4cf1	06 01 	. . 
	call STPIN						; move Read/Write Head in drive									;4cf3	cd ce 5e 	. . ^ 
	jp DI_WriteTrack				; write next track												;4cf6	c3 67 4b 	. g K 


DI_VerifyDisk:
; -- turn off Write Request
	ld a,(iy+LTHCPY)				; a - FLCtrl value												;4cf9	fd 7e 33 	. ~ 3 
	or FL_WRITE_REQ					; turn off Write Request										;4cfc	f6 40 	. @ 
	ld (iy+LTHCPY),a				; store FLCtrl to shadow register								;4cfe	fd 77 33 	. w 3 
	out (FLCTRL),a					; set Flopy Control byte										;4d01	d3 10 	. . 

; -- move drive Head to track 0, sector 0
	ld b,39							; 39 tracks to step out											;4d03	06 27 	. ' 
	call STPOUT						; move Read/Write Head in drive									;4d05	cd 01 5f 	. . _ 
	ld (iy+TRCK),0					; set Track Number to 0											;4d08	fd 36 12 00 	. 6 . . 
	ld (iy+SCTR),0					; set Sector Number to 0										;4d0c	fd 36 11 00 	. 6 . . 

DI_VerifyTrack:
	ld ix,SectorsSequence			; ix - table of Sectors on Track interlave sequence				;4d10	dd 21 67 4d 	. ! g M 

DI_VerifySector:
; -- try read IDAM for given Track and Sector (only IDAM start, TrackNo, SectorNo and verify Checksum of those two)
	call IDAM			; Read identification address mark (IDAM) 						;4d14	cd ea 53 	. . S 
	jr nz,DI_ExitError				; jump if Error	09 - SECTOR NOT FOUND							;4d17	20 2c 	  , 

; -- sector found
	ld a,(ix+1)						; a - next Sector Number										;4d19	dd 7e 01 	. ~ . 
	inc ix							; increment ix ready for next round								;4d1c	dd 23 	. # 
	ld (iy+SCTR),a					; set Sector Number	to next seq value							;4d1e	fd 77 11 	. w . 
	cp $ff							; check if all sectors for this track 							;4d21	fe ff 	. . 
	jr nz,DI_VerifySector			; no - read next Sector											;4d23	20 ef 	  . 
; -- next track
	xor a							; sector number 0												;4d25	af 	. 
	ld (iy+SCTR),a					; set Sector Number to 0										;4d26	fd 77 11 	. w . 
	ld a,(iy+TRCK)					; a - current Track number										;4d29	fd 7e 12 	. ~ . 
	inc a							; increment track												;4d2c	3c 	< 
	ld (iy+TRCK),a					; set next track number											;4d2d	fd 77 12 	. w . 
	cp 40							; check if all 40 tracks written								;4d30	fe 28 	. ( 
	jr z,DI_ExitOK					; yes - exit with no error										;4d32	28 07 	( . 
; -- more tracks to verify
	ld b,1							; 1 track to step in											;4d34	06 01 	. . 
	call STPIN						; move R/W Head to next track									;4d36	cd ce 5e 	. . ^ 
	jr DI_VerifyTrack				; verify next track												;4d39	18 d5 	. . 

; -- all 40 tracks verified
DI_ExitOK:
; -- move Head back on Track 00
	ld b,39							; 39 tracks to Step Out											;4d3b	06 27 	. ' 
	call STPOUT						; Track step out												;4d3d	cd 01 5f 	. . _ 
	call PWROFF						; Disk power OFF												;4d40	cd 52 5f 	. R _ 
	pop hl							; restore hl 													;4d43	e1 	. 
	ret								; ------------- End of Proc -----------------------------------	;4d44	c9 	. 
DI_ExitError:
	cp 17							; is it Error 17 (BREAK)										;4d45	fe 11 	. . 
	jp z,ERROR						; yes - jump to Error handling routine							;4d47	ca 41 42 	. A B 
	ld a,6							; no - set Error 6 (DISK I/O ERROR)								;4d4a	3e 06 	> . 
	jp ERROR						; jump to Error handling routine ------------------------------ ;4d4c	c3 41 42 	. A B 

SecHeaderInitData:
	db $80,$80,$80,$80,$80,$80,$00	; GAP 1 bytes													;4d4f	80 80 80 80 80 80 00	
	db $fe,$e7,$18,$c3				; IDAM signature 												;4d56	fe e7 18 c3 
	db $00							; Track number													;4d5a	00 	. 
	db $00							; Sector number													;4d5b	00 
	db $00							; Header checksum												;4d5c	00 

SectorGAP2Data:
	db $80,$80,$80,$80,$80,$00		; GAP 2 bytes													;4d5d	80 80 80 80 80 00 
	db $c3,$18,$e7,$fe				; IDAM (reversed) signature										;4d63	c3 18 e7 fe 

SectorsSequence:
	db 0,11,6, 1,12,7, 2,13,8, 3,14,9, 4,15,10, 5		;4d67	00 0b 06 01 0c 07 02 0d 08 03 0e 09 04 0f 0a 05 	. 
	db $ff												;4d77	ff 	. 



;***************************************************************************************************
; DOS Command DRIVE
; Syntax: DRIVE number
; --------------------
; Activate Drive 1 or Drive 2. All DOS operations will be performed on Active Drive.
; Only '1' or '2' is accepted as Drive number  
DCmdDRIVE:

; -- parse argument - drive number 
	call SysEvalByteExpr			; a - parsed integer value										;4d78	cd 1c 2b 	. . + 
	or a							; is it 0? (invalid Drive number)								;4d7b	b7 	. 
	jp z,SysErrRaiseFuncCode		; yes - Raise BASIC FUNCTION CODE Error							;4d7c	ca 4a 1e 	. J . 
	cp 3							; is it 3 or greater? (invalid Drive number)					;4d7f	fe 03 	. . 
	jp nc,SysErrRaiseFuncCode		; yes - Raise BASIC FUNCTION CODE Error							;4d81	d2 4a 1e 	. J . 


;***************************************************************************************************
; Set selected Drive (1 or 2)
; IN: a - drive to select 
SelectDriveNo:
	cp 1							; is it Drive 1 to select?										;4d84	fe 01 	. . 
	jr nz,.selectDrive2				; no - set Drive 2 selected										;4d86	20 05 	  . 
	ld (iy+DK),$10					; set Drive 1 selected 											;4d88	fd 36 0b 10 	. 6 . . 
	ret								; ---------------------- End of Proc --------------------------	;4d8c	c9 	. 
.selectDrive2:
	ld (iy+DK),$80					; set Drive 2 selected 											;4d8d	fd 36 0b 80 	. 6 . . 
	ret								; ---------------------- End of Proc --------------------------	;4d91	c9 	. 


;***************************************************************************************************
; DOS Command IN#
; Syntax: IN# "filaname", var1, var2, ...
; ----------------------------------------
; Load data from file specified by filename (which has the file type code "D") into specified variables.
; File must be previously opened by 'OPEN' command. Variables var1, var2, ... are BASIC variable names.
; Variables can be string or numeric and must match types saved by PR# command.
; Filename may have no more than 8 characters
; NOTE: This command must always be used from inside BASIC program. 
DCmdIN#:
; -- throw ILLEGAL DIRECT Error if current BASIC line <> FFFF
	call SysCheckIllegalDirect		; verify command used from BASIC program 						;4d92	cd 28 28 	. ( ( 

; -- parse first argument - filename
	call ParseFilename				; Verify syntax and copy filename to DOS Filename Buffer		;4d95	cd 78 53 	. x S 
	or a							; was any Error?												;4d98	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine							;4d99	c2 41 42 	. A B 

; -- parse next char - must be ','
	rst 8							; verify this char is ',' (comma) and point hl to next			;4d9c	cf 	. 
	defb ','						; expected char													;4d9d	2c 	, 
	push hl			;4d9e	e5 	. 
	call FindFCBForOpen				; Find FCB Block to use or get one if file already opened		;4d9f	cd 78 47 	. x G 
	cp 008h		;4da2	fe 08 	. . 
	ld a,005h		;4da4	3e 05 	> . 
	jp nz,ERROR		; Error handling routine	;4da6	c2 41 42 	. A B 
	inc de			;4da9	13 	. 
	ld a,(de)			;4daa	1a 	. 
	or a			;4dab	b7 	. 
	ld a,00fh		;4dac	3e 0f 	> . 
	jp nz,ERROR		; Error handling routine	;4dae	c2 41 42 	. A B 
	dec de			;4db1	1b 	. 
	ld a,(de)			;4db2	1a 	. 
	cp 002h		;4db3	fe 02 	. . 
	jr z,l4de2h		;4db5	28 2b 	( + 
	call FlushSectorData		; Flush Sector Data to disk from both FCBs ;4db7	cd a5 4f 	. . O 
	ld a,002h		;4dba	3e 02 	> . 
	ld (de),a			;4dbc	12 	. 
	ex de,hl			;4dbd	eb 	. 
	ld de,0000ah		;4dbe	11 0a 00 	. . . 
	add hl,de			;4dc1	19 	. 
	ld a,(hl)			;4dc2	7e 	~ 
	inc hl			;4dc3	23 	# 
	ld (iy+TRCK),a		;4dc4	fd 77 12 	. w . 
	ld a,(hl)			;4dc7	7e 	~ 
	ld (iy+SCTR),a		;4dc8	fd 77 11 	. w . 
	di			;4dcb	f3 	. 
	call PWRON		; Disk power ON			;4dcc	cd 41 5f 	. A _ 
	push bc			;4dcf	c5 	. 
	ld bc,50		; bc - number of miliseconds to delay							;4dd0	01 32 00 	. 2 . 
	call DLY		; delay 50 ms								;4dd3	cd be 5e 	. . ^ 
	pop bc			;4dd6	c1 	. 
	call READ		; Read a sector from disk						;4dd7	cd 27 5b 	. ' [ 
	or a			;4dda	b7 	. 
	jp nz,ERROR		; Error handling routine	;4ddb	c2 41 42 	. A B 
	ei			;4dde	fb 	. 
	call PWROFF		; Disk power OFF		;4ddf	cd 52 5f 	. R _ 
l4de2h:
	ld b,0c7h		;4de2	06 c7 	. . 
	ld hl,(078a7h)		;4de4	2a a7 78 	* . x 
l4de7h:
	call sub_4df9h		;4de7	cd f9 4d 	. . M 
	ld (hl),a			;4dea	77 	w 
	inc hl			;4deb	23 	# 
	cp 00dh		;4dec	fe 0d 	. . 
	jr z,l4df2h		;4dee	28 02 	( . 
	djnz l4de7h		;4df0	10 f5 	. . 
l4df2h:
	xor a			;4df2	af 	. 
	ld (078a9h),a		;4df3	32 a9 78 	2 . x 
	jp 021bdh		;4df6	c3 bd 21 	. . ! 
sub_4df9h:
	push hl			;4df9	e5 	. 
	push de			;4dfa	d5 	. 
	push bc			;4dfb	c5 	. 
	call FindFCBForOpen				; Find FCB Block to use or get one if file already opened		;4dfc	cd 78 47 	. x G 
	ld hl,0000ch		;4dff	21 0c 00 	! . . 
	ex de,hl			;4e02	eb 	. 
	add hl,de			;4e03	19 	. 
	ld a,(hl)			;4e04	7e 	~ 
	ex de,hl			;4e05	eb 	. 
	ld l,(iy+DBFR)		;4e06	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)		;4e09	fd 66 32 	. f 2 
	add a,l			;4e0c	85 	. 
	ld l,a			;4e0d	6f 	o 
	ld a,000h		;4e0e	3e 00 	> . 
	adc a,h			;4e10	8c 	. 
	ld h,a			;4e11	67 	g 
	ld a,(hl)			;4e12	7e 	~ 
	or a			;4e13	b7 	. 
	jr nz,l4e1ah		;4e14	20 04 	  . 
	ld c,00dh		;4e16	0e 0d 	. . 
	jr l4e5ah		;4e18	18 40 	. @ 
l4e1ah:
	ld c,a			;4e1a	4f 	O 
	ld a,(de)			;4e1b	1a 	. 
	inc a			;4e1c	3c 	< 
	ld (de),a			;4e1d	12 	. 
	cp 07eh		;4e1e	fe 7e 	. ~ 
	jr nz,l4e5ah		;4e20	20 38 	  8 
	xor a			;4e22	af 	. 
	ld (de),a			;4e23	12 	. 
	ld l,(iy+DBFR)		;4e24	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)		;4e27	fd 66 32 	. f 2 
	push de			;4e2a	d5 	. 
	ld de,0007eh		;4e2b	11 7e 00 	. ~ . 
	add hl,de			;4e2e	19 	. 
	pop de			;4e2f	d1 	. 
	ld a,(hl)			;4e30	7e 	~ 
	or a			;4e31	b7 	. 
	jr z,l4e5fh		;4e32	28 2b 	( + 
	ld (iy+TRCK),a		;4e34	fd 77 12 	. w . 
	dec de			;4e37	1b 	. 
	dec de			;4e38	1b 	. 
	ld (de),a			;4e39	12 	. 
	inc hl			;4e3a	23 	# 
	ld a,(hl)			;4e3b	7e 	~ 
	ld (iy+SCTR),a		;4e3c	fd 77 11 	. w . 
	inc de			;4e3f	13 	. 
	ld (de),a			;4e40	12 	. 
	di			;4e41	f3 	. 
	call PWRON		; Disk power ON			;4e42	cd 41 5f 	. A _ 
l4e45h:
	push bc			;4e45	c5 	. 
	ld bc,50		; bc - number of miliseconds to delay							;4e46	01 32 00 	. 2 . 
	call DLY		; delay 50 ms 								;4e49	cd be 5e 	. . ^ 
	pop bc			;4e4c	c1 	. 
	push bc			;4e4d	c5 	. 
	call READ		; Read a sector from disk						;4e4e	cd 27 5b 	. ' [ 
	pop bc			;4e51	c1 	. 
	or a			;4e52	b7 	. 
	jp nz,ERROR		; Error handling routine	;4e53	c2 41 42 	. A B 
	call PWROFF		; Disk power OFF		;4e56	cd 52 5f 	. R _ 
	ei			;4e59	fb 	. 
l4e5ah:
	ld a,c			;4e5a	79 	y 
	pop bc			;4e5b	c1 	. 
	pop de			;4e5c	d1 	. 
	pop hl			;4e5d	e1 	. 
	ret			;4e5e	c9 	. 
l4e5fh:
	ld a,07fh		;4e5f	3e 7f 	>  
	ld (de),a			;4e61	12 	. 
	jr l4e5ah		;4e62	18 f6 	. . 


;***************************************************************************************************
; DOS Command PR#
; Syntax: PR# "filaname", D1, D2, ...
; -----------------------------------
; Send data to file specified by filename (which has the file type code "D") and was previously 
; opened by 'OPEN' command. Data D1, D2, ... are data to be saved and can be string or numeric.
; Filename may have no more than 8 characters
; NOTE: This command must always be used from inside BASIC program. 
DCmdPR#:
; -- throw ILLEGAL DIRECT Error if current BASIC line <> FFFF
	call SysCheckIllegalDirect		; verify command used from BASIC program 						;4e64	cd 28 28 	. ( ( 

; -- parse first argument - filename
	call ParseFilename				; Verify syntax and copy filename to DOS Filename Buffer		;4e67	cd 78 53 	. x S 
	or a							; was any Error?												;4e6a	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine							;4e6b	c2 41 42 	. A B 
	push hl			;4e6e	e5 	. 
	call FindFCBForOpen				; Find FCB Block to use or get one if file already opened		;4e6f	cd 78 47 	. x G 
	cp 008h		;4e72	fe 08 	. . 
	ld a,005h		;4e74	3e 05 	> . 
	jp nz,ERROR		; Error handling routine	;4e76	c2 41 42 	. A B 
	pop hl			;4e79	e1 	. 
	rst 8							; verify this char is ',' (commx) and point hl to next			;4e7a	cf 	. 
	defb ','						; expected char													;4e7b	2c 	, 
l4e7ch:
	dec hl			;4e7c	2b 	+ 
	rst 10h			;4e7d	d7 	. 
	call z,sub_4each		;4e7e	cc ac 4e 	. . N 
l4e81h:
	ret z			;4e81	c8 	. 
	push hl			;4e82	e5 	. 
	cp 02ch		;4e83	fe 2c 	. , 
	jp z,l4eb3h		;4e85	ca b3 4e 	. . N 
	cp 03ah		;4e88	fe 3a 	. : 
	jr z,l4eb7h		;4e8a	28 2b 	( + 
	pop bc			;4e8c	c1 	. 
	call 02337h		;4e8d	cd 37 23 	. 7 # 
	push hl			;4e90	e5 	. 
	rst 20h			;4e91	e7 	. 
	jr z,l4ea6h		;4e92	28 12 	( . 
	call 00fbdh		;4e94	cd bd 0f 	. . . 
	call 02865h		;4e97	cd 65 28 	. e ( 
	ld hl,(07921h)		;4e9a	2a 21 79 	* ! y 
	call sub_4ebah		;4e9d	cd ba 4e 	. . N 
	ld a,020h		;4ea0	3e 20 	>   
	call sub_4ecah		;4ea2	cd ca 4e 	. . N 
	or a			;4ea5	b7 	. 
l4ea6h:
	call z,sub_4ebah		;4ea6	cc ba 4e 	. . N 
	pop hl			;4ea9	e1 	. 
	jr l4e7ch		;4eaa	18 d0 	. . 
sub_4each:
	ld a,00dh		;4eac	3e 0d 	> . 
	call sub_4ecah		;4eae	cd ca 4e 	. . N 
	xor a			;4eb1	af 	. 
	ret			;4eb2	c9 	. 
l4eb3h:
	call sub_4ecah		;4eb3	cd ca 4e 	. . N 
	pop hl			;4eb6	e1 	. 
l4eb7h:
	rst 10h			;4eb7	d7 	. 
	jr l4e81h		;4eb8	18 c7 	. . 
sub_4ebah:
	call 029dah		;4eba	cd da 29 	. . ) 
	call 009c4h		;4ebd	cd c4 09 	. . . 
	inc d			;4ec0	14 	. 
l4ec1h:
	dec d			;4ec1	15 	. 
	ret z			;4ec2	c8 	. 
	ld a,(bc)			;4ec3	0a 	. 
	call sub_4ecah		;4ec4	cd ca 4e 	. . N 
	inc bc			;4ec7	03 	. 
	jr l4ec1h		;4ec8	18 f7 	. . 
sub_4ecah:
	push hl			;4eca	e5 	. 
	push de			;4ecb	d5 	. 
	push bc			;4ecc	c5 	. 
	push af			;4ecd	f5 	. 
	call FindFCBForOpen				; Find FCB Block to use or get one if file already opened		;4ece	cd 78 47 	. x G 
	ex de,hl			;4ed1	eb 	. 
	inc hl			;4ed2	23 	# 
	ld a,(hl)			;4ed3	7e 	~ 
	or a			;4ed4	b7 	. 
	ld a,010h		;4ed5	3e 10 	> . 
	jp z,ERROR		; Error handling routine	;4ed7	ca 41 42 	. A B 
	dec hl			;4eda	2b 	+ 
	ld a,(hl)			;4edb	7e 	~ 
	cp 002h		;4edc	fe 02 	. . 
	jr z,l4f0ch		;4ede	28 2c 	( , 
	call FlushSectorData		; Flush Sector Data to disk from both FCBs ;4ee0	cd a5 4f 	. . O 
	ld de,0000ah		;4ee3	11 0a 00 	. . . 
	add hl,de			;4ee6	19 	. 
	ld a,(hl)			;4ee7	7e 	~ 
	inc hl			;4ee8	23 	# 
	ld (iy+TRCK),a		;4ee9	fd 77 12 	. w . 
	ld a,(hl)			;4eec	7e 	~ 
	inc hl			;4eed	23 	# 
	ld (iy+SCTR),a		;4eee	fd 77 11 	. w . 
	di			;4ef1	f3 	. 

; -- turn on Disk Drive 
	call PWRON						; Disk power ON													;4ef2	cd 41 5f 	. A _ 

; -- check if Disk is not Write-Protected
	in a,(FLWRPROT)					; a - read Write Protected flag from FDC						;4ef5	db 13 	. . 
	or a							; is bit 7 set? (write protected)								;4ef7	b7 	. 
	ld a,04							; a - Error 04 - DISK WRITE PROTECTED							;4ef8	3e 04 	> . 
	jp m,ERROR						; yes - go to Error handling routine --------------------------	;4efa	fa 41 42 	. A B 
	push hl			;4efd	e5 	. 
	call READ		; Read a sector from disk						;4efe	cd 27 5b 	. ' [ 
	or a			;4f01	b7 	. 
	jp nz,ERROR		; Error handling routine	;4f02	c2 41 42 	. A B 
	pop hl			;4f05	e1 	. 
	ld de,0fff4h		;4f06	11 f4 ff 	. . . 
	add hl,de			;4f09	19 	. 
	ld (hl),002h		;4f0a	36 02 	6 . 
l4f0ch:
	ld de,0000ch		;4f0c	11 0c 00 	. . . 
	add hl,de			;4f0f	19 	. 
	ld e,(hl)			;4f10	5e 	^ 
	inc (hl)			;4f11	34 	4 
	ld d,000h		;4f12	16 00 	. . 
	ld l,(iy+DBFR)		;4f14	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)		;4f17	fd 66 32 	. f 2 
	add hl,de			;4f1a	19 	. 
	pop af			;4f1b	f1 	. 
	push af			;4f1c	f5 	. 
	ld (hl),a			;4f1d	77 	w 
	ld a,e			;4f1e	7b 	{ 
	inc a			;4f1f	3c 	< 
	cp 07eh		;4f20	fe 7e 	. ~ 
	jr nz,l4f9ch		;4f22	20 78 	  x 

	di			;4f24	f3 	. 

; -- turn on Disk Drive and wait 2 ms
	call PWRON						; Disk power ON													;4f25	cd 41 5f 	. A _ 
	push bc							; save bc 														;4f28	c5 	. 
	ld bc,2							; bc - number of miliseconds to delay							;4f29	01 02 00 	. . . 
	call DLY						; delay 2 ms													;4f2c	cd be 5e 	. . ^ 
	pop bc							; restore bc													;4f2f	c1 	. 

; -- check if Disk is not Write-Protected
	in a,(FLWRPROT)					; a - read Write Protected flag from FDC						;4f30	db 13 	. . 
	or a							; is bit 7 set? (write protected)								;4f32	b7 	. 
	ld a,04							; a - Error 04 - DISK WRITE PROTECTED							;4f33	3e 04 	> . 
	jp m,ERROR						; yes - go to Error handling routine --------------------------	;4f35	fa 41 42 	. A B 
	ld e,(iy+SCTR)		;4f38	fd 5e 11 	. ^ . 
	ld d,(iy+TRCK)		;4f3b	fd 56 12 	. V . 
	push de			;4f3e	d5 	. 
	call WRITE		; Write a sector to disk						;4f3f	cd a1 59 	. . Y 
	or a			;4f42	b7 	. 
sub_4f43h:
	jp nz,ERROR		; Error handling routine	;4f43	c2 41 42 	. A B 
	call RDMAP		; Read the track map of the disk				;4f46	cd 17 47 	. . G 
	or a			;4f49	b7 	. 
	jp nz,ERROR		; Error handling routine	;4f4a	c2 41 42 	. A B 
	call MAP		; Search for empty sector and allocate it						;4f4d	cd bf 58 	. . X 
	or a			;4f50	b7 	. 
	jp nz,ERROR		; Error handling routine	;4f51	c2 41 42 	. A B 
	call SVMAP		; Save the track map to the disk				;4f54	cd 54 47 	. T G 
	pop de			;4f57	d1 	. 
	ld (iy+SCTR),e		;4f58	fd 73 11 	. s . 
	ld (iy+TRCK),d		;4f5b	fd 72 12 	. r . 
	call READ		; Read a sector from disk						;4f5e	cd 27 5b 	. ' [ 
	or a			;4f61	b7 	. 
	jp nz,ERROR		; Error handling routine	;4f62	c2 41 42 	. A B 
	ld l,(iy+DBFR)		;4f65	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)		;4f68	fd 66 32 	. f 2 
	ld de,0007eh		;4f6b	11 7e 00 	. ~ . 
	add hl,de			;4f6e	19 	. 
	ld a,(iy+NTRK)		;4f6f	fd 7e 16 	. ~ . 
	ld (hl),a			;4f72	77 	w 
	inc hl			;4f73	23 	# 
	ld a,(iy+NSCT)		;4f74	fd 7e 15 	. ~ . 
	ld (hl),a			;4f77	77 	w 
	call WRITE		; Write a sector to disk						;4f78	cd a1 59 	. . Y 
	or a			;4f7b	b7 	. 
	jp nz,ERROR		; Error handling routine	;4f7c	c2 41 42 	. A B 
	call FindFCBForOpen				; Find FCB Block to use or get one if file already opened		;4f7f	cd 78 47 	. x G 
	ex de,hl			;4f82	eb 	. 
	ld de,0000ah		;4f83	11 0a 00 	. . . 
	add hl,de			;4f86	19 	. 
	ld a,(iy+NTRK)		;4f87	fd 7e 16 	. ~ . 
	ld (iy+TRCK),a		;4f8a	fd 77 12 	. w . 
	ld (hl),a			;4f8d	77 	w 
	inc hl			;4f8e	23 	# 
	ld a,(iy+NSCT)		;4f8f	fd 7e 15 	. ~ . 
	ld (iy+SCTR),a		;4f92	fd 77 11 	. w . 
	ld (hl),a			;4f95	77 	w 
	inc hl			;4f96	23 	# 
	xor a			;4f97	af 	. 
	ld (hl),a			;4f98	77 	w 
	call CLEAR		; Clear a sector of the disk					;4f99	cd 49 47 	. I G 
l4f9ch:
	call PWROFF		; Disk power OFF		;4f9c	cd 52 5f 	. R _ 
	ei			;4f9f	fb 	. 
	pop af			;4fa0	f1 	. 
	pop bc			;4fa1	c1 	. 
	pop de			;4fa2	d1 	. 
	pop hl			;4fa3	e1 	. 
	ret			;4fa4	c9 	. 


;***************************************************************************************************
; Flush Sector Data to disk from both File Control Blocks
FlushSectorData:
; -- save registers
	push hl							; save hl  													;4fa5	e5 	. 
	push de							; save de 													;4fa6	d5 	. 
; -- calculate address of FCB1
	push iy							; iy - DOS base address										;4fa7	fd e5 	. . 
	pop hl							; copy to hl												;4fa9	e1 	. 
	ld de,FCB1						; de - offset to File Control Block 1						;4faa	11 17 00 	. . . 
	add hl,de						; hl - address of File Control Block 1						;4fad	19 	. 

; -- flush sector data used by FCB1
	call .flushSector				; flush sector data if file is opened to write				;4fae	cd bb 4f 	. . O 
; -- calculate address of FCB2
	ld de,13						; de - size of FCB - offset to FCB2 from FCB1				;4fb1	11 0d 00 	. . . 
	add hl,de						; hl - address of File Control Block 2						;4fb4	19 	. 

; -- flush sector data used by FCB2
	call .flushSector				; flush sector data if file is opened to write				;4fb5	cd bb 4f 	. . O 
; -- restore registers and exit
	pop de							; restore de												;4fb8	d1 	. 
	pop hl							; restore hl 												;4fb9	e1 	. 
	ret								; ------------------------- End Of Proc -------------------	;4fba	c9 	. 


.flushSector:
; -- check if FCB is used 
	ld a,(hl)						; a - FCB Open flag												;4fbb	7e 	~ 
	or a							; is FCB used?													;4fbc	b7 	. 
	ret z							; no ---------------------- End Of Proc -----------------------	;4fbd	c8 	. 
; -- return if FCB is used but file is not currently active (1)
	cp 2							; is FCB used and file active?									;4fbe	fe 02 	. . 
	ret nz							; no ---------------------- End Of Proc -----------------------	;4fc0	c0 	. 
; -- return if file open and active but for read only
	ld (hl),1						; set FCB used but file is not active							;4fc1	36 01 	6 . 
	inc hl							; hl - point to Access type field								;4fc3	23 	# 
	ld a,(hl)						; a - access type												;4fc4	7e 	~ 
	or a							; is it opened for read?										;4fc5	b7 	. 
	dec hl							; hl - address of FCB											;4fc6	2b 	+ 
	ret z							; yes --------------------- End Of Proc -----------------------	;4fc7	c8 	. 

; -- set Track and Sector Number to Write Sector 
	ld de,10						; de - offset to Track Number (in FCB)							;4fc8	11 0a 00 	. . . 
	add hl,de						; hl - address of Track Number 									;4fcb	19 	. 
	ld a,(hl)						; a - Track Number												;4fcc	7e 	~ 
	ld (iy+TRCK),a					; set as Track Number for write									;4fcd	fd 77 12 	. w . 
	inc hl							; hl - address of Sector NUmber (in FCB)						;4fd0	23 	# 
	ld a,(hl)						; a - Sector Number												;4fd1	7e 	~ 
	ld (iy+SCTR),a					; set as Sector Number for Write								;4fd2	fd 77 11 	. w . 

; -- disable interrupt and write Sector data to Disk
	di								; disable interrupts											;4fd5	f3 	. 

; -- turn on Disk Drive and wait 50 ms
	call PWRON						; Disk power ON													;4fd6	cd 41 5f 	. A _ 
	push bc							; save bc 														;4fd9	c5 	. 
	ld bc,50						; bc - number of miliseconds to delay							;4fda	01 32 00 	. 2 . 
	call DLY						; delay 50 ms													;4fdd	cd be 5e 	. . ^ 
	pop bc							; restore bc													;4fe0	c1 	. 

; -- check if Disk is not Write-Protected
	in a,(FLWRPROT)					; a - read Write Protected flag from FDC						;4fe1	db 13 	. . 
	or a							; is bit 7 set? (write protected)								;4fe3	b7 	. 
	ld a,04							; a - Error 04 - DISK WRITE PROTECTED							;4fe4	3e 04 	> . 
	jp m,ERROR						; yes - go to Error handling routine --------------------------	;4fe6	fa 41 42 	. A B 

; -- flush sector to Disk
	push hl							; save hl														;4fe9	e5 	. 
	call WRITE						; Write a sector to disk										;4fea	cd a1 59 	. . Y 
	pop hl							; restore hl													;4fed	e1 	. 
	or a							; was any Error?												;4fee	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine --------------------------	;4fef	c2 41 42 	. A B 
; -- restore address of FCB in register hl
	ld de,-11						; de - offset back to FCB flag 									;4ff2	11 f5 ff 	. . . 
	add hl,de						; hl - address of FCB											;4ff5	19 	. 
; -- turn drive power off and exit
	call PWROFF						; Disk power OFF												;4ff6	cd 52 5f 	. R _ 
	ei								; enable interrupts												;4ff9	fb 	. 
	ret								; ------------------------- End Of Proc -----------------------	;4ffa	c9 	. 




;***************************************************************************************************
; DOS Command DCOPY
; Syntax: DCOPY "filaname"
;         DCOPY
; ------------------------
; Transfer a single file (specified by filename) or all the files in a diskette from one to another.
; To transfer all files type DCOPY without filename argument.
; Filename may have no more than 8 characters
DCmdDCOPY:
	ld de,(078a2h)		;4ffb	ed 5b a2 78 	. [ . x 
	inc de			;4fff	13 	. 
	ld a,d			;5000	7a 	z 
	or e			;5001	b3 	. 
	ld e,016h		;5002	1e 16 	. . 
	jp nz,019a2h		;5004	c2 a2 19 	. . . 
	ld (iy+DCPYF),1		;5007	fd 36 39 01 	. 6 9 . 
	dec hl			;500b	2b 	+ 
	rst 10h			;500c	d7 	. 
	jr z,l505dh		;500d	28 4e 	( N 
	call CSI		; Command string interpreter					;500f	cd 67 53 	. g S 
	or a			;5012	b7 	. 
	jp nz,ERROR		; Error handling routine	;5013	c2 41 42 	. A B 
	push hl			;5016	e5 	. 
	call sub_5168h		;5017	cd 68 51 	. h Q 
	call sub_5219h		;501a	cd 19 52 	. . R 
	di			;501d	f3 	. 
	call PWRON		; Disk power ON			;501e	cd 41 5f 	. A _ 
	push bc			;5021	c5 	. 
	ld bc,50		; bc - number of miliseconds to delay							;5022	01 32 00 	. 2 . 
	call DLY		; delay 50 ms								;5025	cd be 5e 	. . ^ 
	pop bc			;5028	c1 	. 
	call SEARCH		; Search for file in directory					;5029	cd 13 59 	. . Y 
	cp 02			; was Error 02 - FILE ALREADY EXISTS?	;502c	fe 02 	. . 
	jr z,l5039h		;502e	28 09 	( . 
	or a			;5030	b7 	. 
	jp nz,ERROR		; Error handling routine	;5031	c2 41 42 	. A B 
	ld a,00dh		;5034	3e 0d 	> . 
	jp ERROR		; Error handling routine	;5036	c3 41 42 	. A B 
l5039h:
	ld a,(iy+TYPE+1)		;5039	fd 7e 0a 	. ~ . 
	ld (iy+TYPE),a		;503c	fd 77 09 	. w . 
	cp 'D'		;503f	fe 44 	. D 
	ld a,00ch		;5041	3e 0c 	> . 
	jp z,ERROR		; Error handling routine	;5043	ca 41 42 	. A B 
	call LoadProgramData		;5046	cd d3 43 	. . C 
	or a			;5049	b7 	. 
	jp nz,l5162h		;504a	c2 62 51 	. b Q 
	call sub_5275h		;504d	cd 75 52 	. u R 
	call PWRON		; Disk power ON			;5050	cd 41 5f 	. A _ 
	call SAVE		; Save a file to disk							;5053	cd 6e 44 	. n D 
	or a			;5056	b7 	. 
	jp nz,l5162h		;5057	c2 62 51 	. b Q 
	jp l5137h		;505a	c3 37 51 	. 7 Q 
l505dh:
	push hl			;505d	e5 	. 
	ld hl,0ffc6h		;505e	21 c6 ff 	! . . 
	add hl,sp			;5061	39 	9 
	ld de,SYS_BASIC_PRG		; address of first byte of BASIC program ;5062	11 e9 7a 	. . z 
	or a			;5065	b7 	. 
	sbc hl,de		;5066	ed 52 	. R 
	srl h		;5068	cb 3c 	. < 
	srl h		;506a	cb 3c 	. < 
	srl h		;506c	cb 3c 	. < 
	ld (iy+TRKCNT),h		;506e	fd 74 36 	. t 6 
	ld (iy+TRKPTR),0		;5071	fd 36 37 00 	. 6 7 . 
	ld (iy+TRCK),0		;5075	fd 36 12 00 	. 6 . . 
	ld (iy+SCTR),0		;5079	fd 36 11 00 	. 6 . . 
	call FlushSectorData		; Flush Sector Data to disk from both FCBs ;507d	cd a5 4f 	. . O 
	call sub_5168h		;5080	cd 68 51 	. h Q 
l5083h:
	ld de,SYS_BASIC_PRG		; address of first byte of BASIC program ;5083	11 e9 7a 	. . z 
	ld (SYS_BASIC_START_PTR),de		; start of current BASIC Program ;5086	ed 53 a4 78 	. S . x 
	call sub_5219h		;508a	cd 19 52 	. . R 
	di			;508d	f3 	. 
	call PWRON		; Disk power ON			;508e	cd 41 5f 	. A _ 
l5091h:
	call READ		; Read a sector from disk						;5091	cd 27 5b 	. ' [ 
	or a			;5094	b7 	. 
	jp nz,l5162h		;5095	c2 62 51 	. b Q 
	ld l,(iy+DBFR)		;5098	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)		;509b	fd 66 32 	. f 2 
	ld de,(SYS_BASIC_START_PTR)		; start of current BASIC Program ;509e	ed 5b a4 78 	. [ . x 
	ld bc,00080h		;50a2	01 80 00 	. . . 
	ldir		;50a5	ed b0 	. . 
	ld (SYS_BASIC_START_PTR),de		; start of current BASIC Program ;50a7	ed 53 a4 78 	. S . x 
	inc (iy+SCTR)		;50ab	fd 34 11 	. 4 . 
	ld a,(iy+SCTR)		;50ae	fd 7e 11 	. ~ . 
	cp 010h		;50b1	fe 10 	. . 
	jr nz,l5091h		;50b3	20 dc 	  . 
	ld (iy+SCTR),0		;50b5	fd 36 11 00 	. 6 . . 
	inc (iy+TRCK)		;50b9	fd 34 12 	. 4 . 
	ld a,(iy+TRCK)		;50bc	fd 7e 12 	. ~ . 
	cp 40		;50bf	fe 28 	. ( 
	jr z,l50cbh		;50c1	28 08 	( . 
	sub (iy+TRKPTR)		;50c3	fd 96 37 	. . 7 
	sub (iy+TRKCNT)		;50c6	fd 96 36 	. . 6 
	jr nz,l5091h		;50c9	20 c6 	  . 
l50cbh:
	ld a,(iy+TRKPTR)		;50cb	fd 7e 37 	. ~ 7 
	ld (iy+TRCK),a		;50ce	fd 77 12 	. w . 
	call PWROFF		; Disk power OFF		;50d1	cd 52 5f 	. R _ 
	call sub_5275h		;50d4	cd 75 52 	. u R 
	di			;50d7	f3 	. 

; -- turn on Disk Drive and wait 2 ms
	call PWRON						; Disk power ON													;50d8	cd 41 5f 	. A _ 
	push bc							; save bc 														;50db	c5 	. 
	ld bc,2							; bc - number of miliseconds to delay							;50dc	01 02 00 	. . . 
	call DLY						; delay 2 ms													;50df	cd be 5e 	. . ^ 
	pop bc							; restore bc													;50e2	c1 	. 

; -- check if Disk is not Write-Protected
	in a,(FLWRPROT)					; a - read Write Protected flag from FDC						;50e3	db 13 	. . 
	or a							; is bit 7 set? (write protected)								;50e5	b7 	. 
	ld a,04							; a - Error 04 - DISK WRITE PROTECTED							;50e6	3e 04 	> . 
	jp m,l5162h						; yes - ;50e8	fa 62 51 	. b Q 

	ld hl,SYS_BASIC_PRG		; address of first byte of BASIC program ;50eb	21 e9 7a 	! . z 
	ld (SYS_BASIC_START_PTR),hl		; start of current BASIC Program ;50ee	22 a4 78 	" . x 
l50f1h:
	ld hl,(SYS_BASIC_START_PTR)		; start of current BASIC Program ;50f1	2a a4 78 	* . x 
	ld e,(iy+DBFR)		;50f4	fd 5e 31 	. ^ 1 
	ld d,(iy+DBFR+1)		;50f7	fd 56 32 	. V 2 
	ld bc,128		;50fa	01 80 00 	. . . 
	ldir		;50fd	ed b0 	. . 
	ld (SYS_BASIC_START_PTR),hl		; start of current BASIC Program ;50ff	22 a4 78 	" . x 
	call WRITE		; Write a sector to disk						;5102	cd a1 59 	. . Y 
	or a			;5105	b7 	. 
	jr nz,l5162h		;5106	20 5a 	  Z 
	inc (iy+SCTR)		;5108	fd 34 11 	. 4 . 
	ld a,(iy+SCTR)		;510b	fd 7e 11 	. ~ . 
	cp 010h		;510e	fe 10 	. . 
	jr nz,l50f1h		;5110	20 df 	  . 
	ld (iy+SCTR),0		;5112	fd 36 11 00 	. 6 . . 
	inc (iy+TRCK)		;5116	fd 34 12 	. 4 . 
	ld a,(iy+TRCK)		;5119	fd 7e 12 	. ~ . 
	cp 40		;511c	fe 28 	. ( 
	jr z,l5137h		;511e	28 17 	( . 
	sub (iy+TRKPTR)		;5120	fd 96 37 	. . 7 
	sub (iy+TRKCNT)		;5123	fd 96 36 	. . 6 
	jr nz,l50f1h		;5126	20 c9 	  . 
	ld a,(iy+TRKCNT)		;5128	fd 7e 36 	. ~ 6 
	add a,(iy+TRKPTR)		;512b	fd 86 37 	. . 7 
	ld (iy+TRKPTR),a		;512e	fd 77 37 	. w 7 
	call PWROFF		; Disk power OFF		;5131	cd 52 5f 	. R _ 
	jp l5083h		;5134	c3 83 50 	. . P 
l5137h:
	call PWROFF		; Disk power OFF		;5137	cd 52 5f 	. R _ 
	call ClearBASIC		;513a	cd 44 51 	. D Q 
	ld bc,SysStartBASIC		;513d	01 19 1a 	. . . 
	push bc			;5140	c5 	. 
	jp 01b4dh		;5141	c3 4d 1b 	. M . 



;***************************************************************************************************
; Clear BASIC Program and select D1 drive
ClearBASIC:
; -- clear BASIC program
	ld hl,SYS_BASIC_PRG				; address of first byte of BASIC program 						;5144	21 e9 7a 	! . z 
	ld (SYS_BASIC_START_PTR),hl		; store it as start of current BASIC Program 					;5147	22 a4 78 	" . x 
; -- store two 00 bytes as "end of BASIC" sequence
	ld (hl),0						; 0 as low byte of address										;514a	36 00 	6 . 
	inc hl							; next address in memory										;514c	23 	# 
	ld (hl),0						; store 0000 as address of next BASIC line						;514d	36 00 	6 . 
	inc hl							; next addres after BASIC Program								;514f	23 	# 
; -- set end of BASIC area (including 0 bytes allocated for DIM variables)
	ld (SYS_BASIC_END_PTR),hl		; store it as end of current BASIC Program 						;5150	22 f9 78 	" . x 
	ld (SYS_ARR_START_PTR),hl		; store it as start of area for BASIC arrays					;5153	22 fb 78 	" . x 
	ld (SYS_ARR_END_PTR),hl			; store it as end of area for BASIC arrays						;5156	22 fd 78 	" . x 
; -- select drive D1
	ld (iy+DK),$10					; set Drive 1 selected											;5159	fd 36 0b 10 	. 6 . . 
	ld (iy+DCPYF),0					; clear DCOPY flag												;515d	fd 36 39 00 	. 6 9 . 
	ret								; --------------------- End of Proc ---------------------------	;5161	c9 	. 


l5162h:
	call ClearBASIC		;5162	cd 44 51 	. D Q 
	jp ERROR		; Error handling routine	;5165	c3 41 42 	. A B 
sub_5168h:
	ld hl,l51ech		;5168	21 ec 51 	! . Q 
	call SysMsgOut		;516b	cd a7 28 	. . ( 
	call sub_5192h		;516e	cd 92 51 	. . Q 
	ld a,c			;5171	79 	y 
	call SysPrintChar		;5172	cd 2a 03 	. * . 
	and %0011		;5175	e6 03 	. . 
	ld (iy+SOURCE),a		; set source Drive number (1 or 2) ;5177	fd 77 0d 	. w . 
	ld hl,l5200h		;517a	21 00 52 	! . R 
	call SysMsgOut		;517d	cd a7 28 	. . ( 
	call sub_5192h		;5180	cd 92 51 	. . Q 
	ld a,c			;5183	79 	y 
	call SysPrintChar		;5184	cd 2a 03 	. * . 
	and %0011		;5187	e6 03 	. . 
	ld (iy+DESTIN),a		; set destination Drive number (1 or 2) ;5189	fd 77 10 	. w . 
	ld a,00dh		;518c	3e 0d 	> . 
	call SysPrintChar		;518e	cd 2a 03 	. * . 
	ret			;5191	c9 	. 
sub_5192h:
	ld a,(07aafh)		;5192	3a af 7a 	: . z 
	or a			;5195	b7 	. 
	jr nz,sub_5192h		;5196	20 fa 	  . 
	di			;5198	f3 	. 
	ld e,010h		;5199	1e 10 	. . 
	ld d,e			;519b	53 	S 
	ld hl,(07820h)		;519c	2a 20 78 	*   x 
l519fh:
	ld a,(06800h)		;519f	3a 00 68 	: . h 
	or a			;51a2	b7 	. 
	jp m,l519fh		;51a3	fa 9f 51 	. . Q 
	dec d			;51a6	15 	. 
	jr nz,l51aeh		;51a7	20 05 	  . 
	ld d,e			;51a9	53 	S 
	ld a,040h		;51aa	3e 40 	> @ 
	xor (hl)			;51ac	ae 	. 
	ld (hl),a			;51ad	77 	w 
l51aeh:
	ld a,(06800h)		;51ae	3a 00 68 	: . h 
	or a			;51b1	b7 	. 
	jp p,l51aeh		;51b2	f2 ae 51 	. . Q 
	ld a,(BreakKeybRow)		;51b5	3a df 68 	: . h 
	bit BreakKeyCol,a		;51b8	cb 57 	. W 
	jr nz,l51cbh		;51ba	20 0f 	  . 
	ld a,(068fdh)		;51bc	3a fd 68 	: . h 
	bit 2,a		;51bf	cb 57 	. W 
	jr nz,l51cbh		;51c1	20 08 	  . 
	call ClearBASIC		;51c3	cd 44 51 	. D Q 
	ld a,011h		;51c6	3e 11 	> . 
	jp ERROR		; Error handling routine	;51c8	c3 41 42 	. A B 
l51cbh:
	ld a,(068f7h)		;51cb	3a f7 68 	: . h 
	bit 4,a		;51ce	cb 67 	. g 
	ld c,031h		;51d0	0e 31 	. 1 
	jr z,l51dah		;51d2	28 06 	( . 
	bit 1,a		;51d4	cb 4f 	. O 
	ld c,032h		;51d6	0e 32 	. 2 
	jr nz,l519fh		;51d8	20 c5 	  . 
l51dah:
	push bc			;51da	c5 	. 
	ld bc,100		; bc - number of miliseconds to delay							;51db	01 64 00 	. d . 
	call DLY		; delay 100 ms								;51de	cd be 5e 	. . ^ 
	pop bc			;51e1	c1 	. 
l51e2h:
	ld a,(06800h)		;51e2	3a 00 68 	: . h 
	or 080h		;51e5	f6 80 	. . 
	inc a			;51e7	3c 	< 
	jr nz,l51e2h		;51e8	20 f8 	  . 
	ei			;51ea	fb 	. 
	ret			;51eb	c9 	. 
l51ech:
	dec c			;51ec	0d 	. 
	ld d,e			;51ed	53 	S 
	ld c,a			;51ee	4f 	O 
	ld d,l			;51ef	55 	U 
	ld d,d			;51f0	52 	R 
	ld b,e			;51f1	43 	C 
	ld b,l			;51f2	45 	E 
	jr nz,l5239h		;51f3	20 44 	  D 
	ld c,c			;51f5	49 	I 
	ld d,e			;51f6	53 	S 
	ld c,e			;51f7	4b 	K 
	jr z,$+51		;51f8	28 31 	( 1 
	cpl			;51fa	2f 	/ 
	ld (03f29h),a		;51fb	32 29 3f 	2 ) ? 
	jr nz,l5200h		;51fe	20 00 	  . 
l5200h:
	dec c			;5200	0d 	. 
	ld b,h			;5201	44 	D 
	ld b,l			;5202	45 	E 
	ld d,e			;5203	53 	S 
	ld d,h			;5204	54 	T 
	ld c,c			;5205	49 	I 
	ld c,(hl)			;5206	4e 	N 
	ld b,c			;5207	41 	A 
	ld d,h			;5208	54 	T 
	ld c,c			;5209	49 	I 
	ld c,a			;520a	4f 	O 
	ld c,(hl)			;520b	4e 	N 
	jr nz,l5252h		;520c	20 44 	  D 
	ld c,c			;520e	49 	I 
	ld d,e			;520f	53 	S 
	ld c,e			;5210	4b 	K 
	jr z,l5244h		;5211	28 31 	( 1 
	cpl			;5213	2f 	/ 
	ld (03f29h),a		;5214	32 29 3f 	2 ) ? 
	jr nz,sub_5219h		;5217	20 00 	  . 
sub_5219h:
	ld a,(iy+SOURCE)				; a - source drive (1 or 2) 									;5219	fd 7e 0d 	. ~ . 
	call SelectDriveNo				; Set selected Drive (1 or 2)									;521c	cd 84 4d 	. . M 
	cp (iy+DESTIN)					; is the same as destination Drive 								;521f	fd be 10 	. . . 
	ret nz			;5222	c0 	. 
	ld hl,l5284h		;5223	21 84 52 	! . R 
l5226h:
	call SysMsgOut		;5226	cd a7 28 	. . ( 
	ld hl,l529dh		;5229	21 9d 52 	! . R 
	call SysMsgOut		;522c	cd a7 28 	. . ( 
l522fh:
	ld a,(07aafh)		;522f	3a af 7a 	: . z 
	or a			;5232	b7 	. 
	jr nz,l522fh		;5233	20 fa 	  . 
	di			;5235	f3 	. 
	ld e,010h		;5236	1e 10 	. . 
	ld d,e			;5238	53 	S 
l5239h:
	ld hl,(07820h)		;5239	2a 20 78 	*   x 
l523ch:
	ld a,(06800h)		;523c	3a 00 68 	: . h 
	or a			;523f	b7 	. 
	jp m,l523ch		;5240	fa 3c 52 	. < R 
	dec d			;5243	15 	. 
l5244h:
	jr nz,l524bh		;5244	20 05 	  . 
	ld d,e			;5246	53 	S 
	ld a,040h		;5247	3e 40 	> @ 
sub_5249h:
	xor (hl)			;5249	ae 	. 
	ld (hl),a			;524a	77 	w 
l524bh:
	ld a,(06800h)		;524b	3a 00 68 	: . h 
	or a			;524e	b7 	. 
	jp p,l524bh		;524f	f2 4b 52 	. K R 
l5252h:
	ld a,(BreakKeybRow)		;5252	3a df 68 	: . h 
	bit BreakKeyCol,a		;5255	cb 57 	. W 
	jr nz,l5268h		;5257	20 0f 	  . 
	ld a,(068fdh)		;5259	3a fd 68 	: . h 
	bit 2,a		;525c	cb 57 	. W 
	jr nz,l5268h		;525e	20 08 	  . 
	call ClearBASIC		;5260	cd 44 51 	. D Q 
	ld a,011h		;5263	3e 11 	> . 
	jp ERROR		; Error handling routine	;5265	c3 41 42 	. A B 
l5268h:
	ld a,(SpaceKeyRow)		;5268	3a ef 68 	: . h 
	bit SpaceKeyCol,a		;526b	cb 67 	. g 
	jr nz,l523ch		;526d	20 cd 	  . 
	ld a,(0783ch)		;526f	3a 3c 78 	: < x 
	ld (hl),a			;5272	77 	w 
	ei			;5273	fb 	. 
	ret			;5274	c9 	. 
sub_5275h:
	ld a,(iy+DESTIN)				; a - destination Drive (1 or 2) 								;5275	fd 7e 10 	. ~ . 
	call SelectDriveNo				; Set selected Drive (1 or 2)									;5278	cd 84 4d 	. . M 
	cp (iy+SOURCE)					; is the same as source drive? 									;527b	fd be 0d 	. . . 
	ret nz			;527e	c0 	. 
	ld hl,l52b7h		;527f	21 b7 52 	! . R 
	jr l5226h		;5282	18 a2 	. . 
l5284h:
	dec c			;5284	0d 	. 
	ld c,c			;5285	49 	I 
	ld c,(hl)			;5286	4e 	N 
	ld d,e			;5287	53 	S 
	ld b,l			;5288	45 	E 
	ld d,d			;5289	52 	R 
	ld d,h			;528a	54 	T 
	jr nz,$+85		;528b	20 53 	  S 
	ld c,a			;528d	4f 	O 
	ld d,l			;528e	55 	U 
	ld d,d			;528f	52 	R 
	ld b,e			;5290	43 	C 
	ld b,l			;5291	45 	E 
	jr nz,$+70		;5292	20 44 	  D 
	ld c,c			;5294	49 	I 
	ld d,e			;5295	53 	S 
	ld c,e			;5296	4b 	K 
	ld b,l			;5297	45 	E 
	ld d,h			;5298	54 	T 
	ld d,h			;5299	54 	T 
	ld b,l			;529a	45 	E 
	dec c			;529b	0d 	. 
	nop			;529c	00 	. 
l529dh:
	jr z,$+82		;529d	28 50 	( P 
	ld d,d			;529f	52 	R 
	ld b,l			;52a0	45 	E 
	ld d,e			;52a1	53 	S 
	ld d,e			;52a2	53 	S 
	jr nz,$+85		;52a3	20 53 	  S 
	ld d,b			;52a5	50 	P 
	ld b,c			;52a6	41 	A 
	ld b,e			;52a7	43 	C 
	ld b,l			;52a8	45 	E 
	jr nz,l5302h		;52a9	20 57 	  W 
	ld c,b			;52ab	48 	H 
	ld b,l			;52ac	45 	E 
	ld c,(hl)			;52ad	4e 	N 
	jr nz,l5302h		;52ae	20 52 	  R 
	ld b,l			;52b0	45 	E 
	ld b,c			;52b1	41 	A 
	ld b,h			;52b2	44 	D 
	ld e,c			;52b3	59 	Y 
	add hl,hl			;52b4	29 	) 
	dec c			;52b5	0d 	. 
	nop			;52b6	00 	. 
l52b7h:
	dec c			;52b7	0d 	. 
	ld c,c			;52b8	49 	I 
	ld c,(hl)			;52b9	4e 	N 
	ld d,e			;52ba	53 	S 
	ld b,l			;52bb	45 	E 
	ld d,d			;52bc	52 	R 
	ld d,h			;52bd	54 	T 
	jr nz,$+70		;52be	20 44 	  D 
	ld b,l			;52c0	45 	E 
	ld d,e			;52c1	53 	S 
	ld d,h			;52c2	54 	T 
	ld c,c			;52c3	49 	I 
	ld c,(hl)			;52c4	4e 	N 
	ld b,c			;52c5	41 	A 
	ld d,h			;52c6	54 	T 
	ld c,c			;52c7	49 	I 
	ld c,a			;52c8	4f 	O 
	ld c,(hl)			;52c9	4e 	N 
	jr nz,l5310h		;52ca	20 44 	  D 
	ld c,c			;52cc	49 	I 
	ld d,e			;52cd	53 	S 
	ld c,e			;52ce	4b 	K 
	ld b,l			;52cf	45 	E 
	ld d,h			;52d0	54 	T 
	ld d,h			;52d1	54 	T 
	ld b,l			;52d2	45 	E 
	dec c			;52d3	0d 	. 
	nop			;52d4	00 	. 


;***************************************************************************************************
; DOS Command STATUS
; Syntax: STATUS 
; ------------------
; Display free space left on Disk as number of free sectors and free space in kilobytes.
; For Example: 
;  	624 RECORDS FREE
;  	78.0K BYTES FREE
DCmdSTATUS:
	push hl			;52d5	e5 	. 
	di			;52d6	f3 	. 
	call PWRON		; Disk power ON			;52d7	cd 41 5f 	. A _ 
	push bc			;52da	c5 	. 
	ld bc,50		; bc - number of miliseconds to delay							;52db	01 32 00 	. 2 . 
	call DLY		; delay 50 ms 								;52de	cd be 5e 	. . ^ 
	pop bc			;52e1	c1 	. 
	ld (iy+TRCK),0		;52e2	fd 36 12 00 	. 6 . . 
	ld (iy+SCTR),15		;52e6	fd 36 11 0f 	. 6 . . 
	call READ		; Read a sector from disk						;52ea	cd 27 5b 	. ' [ 
	or a			;52ed	b7 	. 
	jp nz,ERROR		; Error handling routine	;52ee	c2 41 42 	. A B 
	call PWROFF		; Disk power OFF		;52f1	cd 52 5f 	. R _ 
	ld l,(iy+DBFR)		;52f4	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)		;52f7	fd 66 32 	. f 2 
	ld e,000h		;52fa	1e 00 	. . 
	ld d,000h		;52fc	16 00 	. . 
	ld c,04eh		;52fe	0e 4e 	. N 
l5300h:
	ld b,008h		;5300	06 08 	. . 
l5302h:
	ld a,(hl)			;5302	7e 	~ 
l5303h:
	rrc a		;5303	cb 0f 	. . 
	jr c,l5308h		;5305	38 01 	8 . 
	inc de			;5307	13 	. 
l5308h:
	djnz l5303h		;5308	10 f9 	. . 
	inc hl			;530a	23 	# 
	dec c			;530b	0d 	. 
	jr nz,l5300h		;530c	20 f2 	  . 
	ld l,e			;530e	6b 	k 
	ld h,d			;530f	62 	b 
l5310h:
	push hl			;5310	e5 	. 
	call 00fafh		;5311	cd af 0f 	. . . 
	ld hl,MSG_RecordsFree		;5314	21 4a 53 	! J S 
	call SysMsgOut		;5317	cd a7 28 	. . ( 
	pop hl			;531a	e1 	. 
	push hl			;531b	e5 	. 
	srl h		;531c	cb 3c 	. < 
	rr l		;531e	cb 1d 	. . 
	srl h		;5320	cb 3c 	. < 
	rr l		;5322	cb 1d 	. . 
	srl h		;5324	cb 3c 	. < 
	rr l		;5326	cb 1d 	. . 
	call 00fafh		;5328	cd af 0f 	. . . 
	ld a,02eh		;532b	3e 2e 	> . 
	call SysPrintChar		;532d	cd 2a 03 	. * . 
	pop hl			;5330	e1 	. 
	ld a,007h		;5331	3e 07 	> . 
	and l			;5333	a5 	. 
	inc a			;5334	3c 	< 
	ld b,a			;5335	47 	G 
	ld hl,0ff83h		;5336	21 83 ff 	! . . 
	ld de,0007dh		;5339	11 7d 00 	. } . 
l533ch:
	add hl,de			;533c	19 	. 
	djnz l533ch		;533d	10 fd 	. . 
	call 00fafh		;533f	cd af 0f 	. . . 
	ld hl,MSG_KBytesFree		;5342	21 59 53 	! Y S 
	call SysMsgOut		;5345	cd a7 28 	. . ( 
	pop hl			;5348	e1 	. 
	ret			;5349	c9 	. 

MSG_RecordsFree:
	db " RECORDS FREE",CR,0		;534a	20 52 45 43 4f 52 44 53 20 46 52 45 45 0d 00 
MSG_KBytesFree:
	db "K BYTES FREE",CR,0		;5359	4b 20 42 59 54 45 53 20 46 52 45 45 0d 00 




;***************************************************************************************************
; Command string interpreter			
; This subroutine reads the user specified filename and puts into IY+FNAM if the syntax is correct.
; IN: hl - Input text typed by user enclosed with '"' chars 
;          Text must be terminated with 0 (end of BASIC line) or ':' (end of BASIC statement)
; OUT: a - Error code	
;     hl - address of next char after filename	
;***************************************************************************************************
CSI:
	call ParseFilename				; verify syntax and copy filename to DOS Filename Buffer		;5367	cd 78 53 	. x S 
	or a							; is Error 0? - No Error										;536a	b7 	. 
	jp nz,ERROR						; no - jump to Error handling routine -------------------------	;536b	c2 41 42 	. A B 
; -- filename is copied - hl points to next char after filename
	ld a,(hl)						; a - next char in command or BASIC line						;536e	7e 	~ 
	or a							; is it 0? - end of cmd/BASIC line?								;536f	b7 	. 
	ret z							; yes - ------------ End of Proc ------------------------------ ;5370	c8 	. 
; -- inside BASIC line ':' char separates statements
	cp ':'							; is it ':' char? - end of BASIC statement?						;5371	fe 3a 	. : 
	jp nz,SysRaiseSyntaxError		; no -  Raise BASIC Syntax Error routine ----------------------	;5373	c2 97 19 	. . . 
; -- correct statement - return with No Error
	xor a							; a - Error Code 00 - No Error									;5376	af 	. 
	ret								; ----------------- End of Proc -------------------------------	;5377	c9 	. 




;***************************************************************************************************
; Parse Filename
; Verify syntax and copy filename to DOS Filename Buffer		
; IN: iy - DOS base address
;     hl - filename text enclosed with '"' chars
; OUT: a - Error code		
ParseFilename:
; -- fill DOS Filename buffer (8 chars) with ' ' char
	push iy							; save iy - DOS base address									;5378	fd e5 	. . 
	ld b,8							; filename is 8 chars length 									;537a	06 08 	. . 
.next:
	ld (iy+FNAM),' '				; store space char into Filename Buffor							;537c	fd 36 01 20 	. 6 .   
	inc iy							; increment pointer for next char								;5380	fd 23 	. # 
	djnz .next						; fill all 8 bytes with ' ' char	 							;5382	10 f8 	. . 
	pop iy							; restore iy - DOS base address									;5384	fd e1 	. . 

; -- skip trailing spaces 
.skipSpaces:
	ld a,(hl)						; a - char typed by user										;5386	7e 	~ 
	inc hl							; increment for next char										;5387	23 	# 
	cp  ' '							; is it space char?												;5388	fe 20 	.   
	jr z,.skipSpaces				; yes - keep skipping											;538a	28 fa 	( . 
; -- char other than ' '
	dec hl							; point hl to this char (other than ' ')						;538c	2b 	+ 
	rst 8							; verify this char is '"' (double quote) and point hl to next	;538d	cf 	. 
	defb '"'						; expected char													;538e	22			
	ld b,8							; filename has no more than 8 chars max							;538f	06 08 	" . . 
; -- test if filename is empty - Syntax Error
	ld a,(hl)						; a - next char typed by user									;5391	7e 	~ 
	cp '"'							; is it also '"' (double quote)?								;5392	fe 22 	. " 
	jr nz,.copyChars				; no - copy filename to DOS filename buffer						;5394	20 03 	  . 
.exitSyntaxError:
	ld a,1							; a - Error Code 01 - SYNTAX ERROR								;5396	3e 01 	> . 
	ret								; --------------- End of Proc (with Error 1) ------------------	;5398	c9 	. 

.copyChars:
; -- copy filename (max 8 chars) to DOS Filename Buffer
	push iy							; save iy - DOS base address									;5399	fd e5 	. . 
.copyNext:
	ld a,(hl)						; a - char of filename typed by user							;539b	7e 	~ 
	inc hl							; point to next char											;539c	23 	# 
	cp '"'							; is it '"' (double quote) char? - end of filename text			;539d	fe 22 	. " 
	jr z,.exitNoErrPopIY			; yes - return with No Error (0) - No Error -------------------	;539f	28 14 	( . 
	ld (iy+FNAM),a					; store filename char in DOS Filename Buffer					;53a1	fd 77 01 	. w . 
	inc iy							; increment for next byte in filename Buffer					;53a4	fd 23 	. # 
	djnz .copyNext					; copy next char if the max length (8 char) is not exceeded		;53a6	10 f3 	. . 

; -- ignore any following chars until closing '"' char or 0 terminator
	pop iy							; restore iy - DOS base address									;53a8	fd e1 	. . 
.checkNext:
	ld a,(hl)						; a - char of filename typed by user							;53aa	7e 	~ 
	inc hl							; point to nextt char											;53ab	23 	# 
	or a							; is it 0? - end of text w/o closing '"' char					;53ac	b7 	. 
	jr z,.exitSyntaxError			; yes - return with Error 01 - SYNTAX ERROR	-------------------	;53ad	28 e7 	( . 
	cp '"'							; is it '"' (double quote) closing char?						;53af	fe 22 	. " 
	jr z,.exitNoError				; yes - return with No Error (0) - No Error -------------------	;53b1	28 04 	( . 
	jr .checkNext					; other char - continue skipping chars							;53b3	18 f5 	. . 
.exitNoErrPopIY:
	pop iy							; restore iy - DOS base address									;53b5	fd e1 	. . 
.exitNoError:
	xor a							; a - Error 00 - No Error										;53b7	af 	. 
	ret								; ------------------ End of Proc ------------------------------	;53b8	c9 	. 



;*******************************************************************************************************************
; Convert ASCII to HEX		
; This subroutine converts 4 bytes of ASCII pointed to by HL into DE reg pair.
; IN: hl - address of 4 ASCII chars
; OUT: CY flag - 1 if Error, 0 if no error
;      de - converted value (2 bytes/4 nibbles)	
;	   hl - address of next byte after sequence
;*******************************************************************************************************************
HEX:
	call .conv2Chars				; e - converted 2 chars 										;53b9	cd c1 53 	. . S 
	ret c							; return if Error												;53bc	d8 	. 
	ld d,e							; move converted value to high byte								;53bd	53 	S 
	jp .conv2Chars					; e - covvert 2 chars and return								;53be	c3 c1 53 	. . S 

; -- convert 2 chars into 1 byte with value
.conv2Chars:
; -- take first char and convert it to 4 bit value
	ld a,(hl)						; a - char to convert											;53c1	7e 	~ 
	inc hl							; hl - address of next char										;53c2	23 	# 
	call .conv1Char					; convert char into low 4 bits of a								;53c3	cd d5 53 	. . S 
	ret c							; return if Error												;53c6	d8 	. 
; -- move 4 bits to high nibble of byte
	rla								; shift bits 3..0 to 7..4										;53c7	17 	. 
	rla																								;53c8	17 	. 
	rla																								;53c9	17 	. 
	rla																								;53ca	17 	. 
	ld e,a							; store converted to e											;53cb	5f 	_ 
; -- take second char and convert it to 4 bit value
	ld a,(hl)						; a - next char to convert										;53cc	7e 	~ 
	inc hl							; hl - address of next char										;53cd	23 	# 
	call .conv1Char					; convert char into low 4 bits of a								;53ce	cd d5 53 	. . S 
	ret c							; return if Error												;53d1	d8 	. 
; -- combine low and high nibbles into 1 byte
	or e							; add stored bits 7..4 											;53d2	b3 	. 
	ld e,a							; e - 2 chars converted											;53d3	5f 	_ 
	ret								; -------------------- End of Proc ----------------------------	;53d4	c9 	. 
.conv1Char:
; -- chars '0'..'9' 
	cp '0'							; check if less than '0' (illegal char)							;53d5	fe 30 	. 0 
	ret c							; yes - return with Error										;53d7	d8 	. 
	cp '9'+1						; check if greater than '9' - can be 'A'..'F'					;53d8	fe 3a 	. : 
	jr nc,.tryAtoF					; yes - try 'A'..'F'											;53da	30 03 	0 . 
; -- chars '0'..'9' contain its numeric value in low nibble			
	and %00001111					; mask 4 lower bits -> ('0' becomes 0, '1'->1,etc)				;53dc	e6 0f 	. . 
	ret								; -------------------- End of Proc ----------------------------	;53de	c9 	. 
.tryAtoF:
; -- chars 'A'..'F'
	cp 'A'							; check if less than 'A' (illegal char)							;53df	fe 41 	. A 
	ret c							; yes - return with Error										;53e1	d8 	. 
	cp 'F'+1						; check if greater than 'F' (illegal char)						;53e2	fe 47 	. G 
	jr nc,.exit						; yes - set Carry Flag (error) and return						;53e4	30 02 	0 . 
; -- chars 'A'..'F' can be convert by substract 'A' (65) and add 10
	add a,-55						; convert 'A'->10 ($A), 'B'->11 ($B), etc						;53e6	c6 c9 	. . 
; -- since above operation sets CY flag, below inversion will clear it - No Error 
.exit:
	ccf								; invert CY flag 												;53e8	3f 	? 
	ret								; -------------------- End of Proc ----------------------------	;53e9	c9 	. 




;***************************************************************************************************
; Search for identification address mark (IDAM) of the disk
; IN: (iy+TRCK) - requested track
;     (iy+SCTR)	- requested sector	
; OUT: a - Error Code (0 - Success)		
;***************************************************************************************************
IDAM:
	ld h,165						; set Sector Try Counter - try to find Sector 165 times			;53ea	26 a5 	& . 
	ld l,10							; set Try Counter - try to read 10 times						;53ec	2e 0a 	. . 
	jr IDAM_SetTrack				; set requested Track on Drive and start read					;53ee	18 0b 	. . 
ResetTrackTo0:
	ld l,10							; set Try Counter - try to read 10 times						;53f0	2e 0a 	. . 
	ld (iy+PHASE),%00010001			; reset Step Motor lines to 0001-0001 							;53f2	fd 36 38 11 	. 6 8 . 
; -- move Head to Track 00
	ld b,40							; max 40 tracks to Step Out										;53f6	06 28 	. ( 
	call STPOUT						; Track step out												;53f8	cd 01 5f 	. . _ 


;***************************************************************************************************
; Setup Floppy Drive to Read requested Track
IDAM_SetTrack:
	ld a,(iy+TRCK)					; a - requested track number									;53fb	fd 7e 12 	. ~ . 
	sub (iy+DTRCK)					; calculate difference (tracks to step in/out)					;53fe	fd 96 14 	. . . 
	jr z,IDAM_TrackIsSet			; no difference - track is already set							;5401	28 1a 	( . 
	jp p,IDAM_NeedStepIn			; reqested track is greater - need to Step In 					;5403	f2 11 54 	. . T 
; -- requested track is less than current - need to Step Out
	neg								; get positive value of difference								;5406	ed 44 	. D 
	ld b,a							; b - number of tracks to Step Out								;5408	47 	G 
	call STPOUT						; move R/W Head on drive to req track							;5409	cd 01 5f 	. . _ 
	jr IDAM_TrackIsSet				; track is set - calculate T+S checksum and start read	 		;540c	18 0f 	. . 

IDAM_BreakExit:
	jp WaitBreakKeyReleased			; Wait for Break key released									;540e	c3 a4 5e 	. . ^ 
IDAM_NeedStepIn:
; -- reqested track is greater than current - need to Step In
	ld b,a							; b - number of tracks to Step In								;5411	47 	G 
	call STPIN						; move R/W Head on drive to req track							;5412	cd ce 5e 	. . ^ 
; -- wait delay 100 ms
	push bc							; save bc														;5415	c5 	. 
	ld bc,100						; 100 ms to delay												;5416	01 64 00 	. d . 
	call DLY						; delay 100 ms													;5419	cd be 5e 	. . ^ 
	pop bc							; restore bc													;541c	c1 	. 
IDAM_TrackIsSet:
	ld c,FLPOOL						; I/O Port address to pool clock		 						;541d	0e 12 	. . 
; -- calculate expected checksum (track number + sector number)
	ld a,(iy+TRCK)					; a - track number												;541f	fd 7e 12 	. ~ . 
	add a,(iy+SCTR)					; add - sector number											;5422	fd 86 11 	. . . 
	ld d,a							; d = checksum													;5425	57 	W 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register)				;5426	db 11 	. . 
.wait:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5428	ed 78 	. x 
	jp p,.wait						; wait until Clock BIt = 1										;542a	f2 28 54 	. ( T 
	nop								; spare 16 clock cycles - short delay							;542d	00 	. 
	nop																								;542e	00 	. 
	nop																								;542f	00 	. 
	nop																								;5430	00 	. 


;***************************************************************************************************
; Find GAP1
; Read incomming bistream from Floppy Disk until $80 value is found or BREAK key pressed
; NOTE: In order to read 1 byte from FDC we have to read FLDATA register 8 times (bit by bit)
;       FLDATA hardware register will be shifted every time we read it.

; ---------- [1] --- read bits from Disk until $80 received
IDAM_WaitFor80:
; -- test if BREAK key is pressed
	ld a,(BreakKeybRow)				; read Keyboard Row with BREAK key								;5431	3a df 68 	: . h 
	and BreakKeybMask				; mask only BREAK key - if 0 -> key is pressed					;5434	e6 04 	. . 
	jr z,IDAM_BreakExit				; yes - exit reading											;5436	28 d6 	( . 

; -- read data (bit)
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register)				;5438	db 11 	. . 
	ld b,a							; b - store byte 												;543a	47 	G 
.waitClockBit:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;543b	ed 78 	. x 
	jp p,.waitClockBit				; wait until Clock BIt = 1										;543d	f2 3b 54 	. ; T 
; -- test if we have $80 received
	ld a,b							; byte being received											;5440	78 	x 
	cp $80							; is this $80 - GAP1 start sequence								;5441	fe 80 	. . 
	jp nz,IDAM_WaitFor80			; no - keep reding until $80 received (or BREAK key pressed)	;5443	c2 31 54 	. 1 T 

; -- we have $80 received - next byte can be:
; $80 - still GAP1 byte -> keep reading
; other - end of GAP1 -> go to IDAM sequence read
.readByte:
	nop								; delay 4 clock cycles											;5446	00 	. 
	nop								; delay 4 clock cycles											;5447	00 	. 
	nop								; delay 4 clock cycles											;5448	00 	. 
	ld a,0							; delay 7 clock cycles											;5449	3e 00 	> . 
	ld a,0							; delay 7 clock cycles	(26 in total)							;544b	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;544d	db 11 	. . 
.waitClockBit1:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;544f	ed 78 	. x 
	jp p,.waitClockBit1				; wait until Clock BIt = 1										;5451	f2 4f 54 	. O T 
	dec hl							; delay 6 clock cycles											;5454	2b 	+ 
	inc hl							; delay 6 clock cycles											;5455	23 	# 
	dec hl							; delay 6 clock cycles											;5456	2b 	+ 
	inc hl							; delay 6 clock cycles											;5457	23 	# 
	dec hl							; delay 6 clock cycles											;5458	2b 	+ 
	inc hl							; delay 6 clock cycles											;5459	23 	# 
	nop								; delay 4 clock cycles											;545a	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;545b	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 6]		;545d	db 11 	. . 
.waitClockBit2:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;545f	ed 78 	. x 
	jp p,.waitClockBit2				; wait until Clock BIt = 1										;5461	f2 5f 54 	. _ T 
	dec hl							; delay 6 clock cycles											;5464	2b 	+ 
	inc hl							; delay 6 clock cycles											;5465	23 	# 
	dec hl							; delay 6 clock cycles											;5466	2b 	+ 
	inc hl							; delay 6 clock cycles											;5467	23 	# 
	dec hl							; delay 6 clock cycles											;5468	2b 	+ 
	inc hl							; delay 6 clock cycles											;5469	23 	# 
	nop								; delay 4 clock cycles											;546a	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;546b	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 5]		;546d	db 11 	. . 
.waitClockBit3:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;546f	ed 78 	. x 
	jp p,.waitClockBit3				; wait until Clock BIt = 1										;5471	f2 6f 54 	. o T 
	dec hl							; delay 6 clock cycles											;5474	2b 	+ 
	inc hl							; delay 6 clock cycles											;5475	23 	# 
	dec hl							; delay 6 clock cycles											;5476	2b 	+ 
	inc hl							; delay 6 clock cycles											;5477	23 	# 
	dec hl							; delay 6 clock cycles											;5478	2b 	+ 
	inc hl							; delay 6 clock cycles											;5479	23 	# 
	nop								; delay 4 clock cycles											;547a	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;547b	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 4]		;547d	db 11 	. . 
.waitClockBit4:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;547f	ed 78 	. x 
	jp p,.waitClockBit4				; wait until Clock BIt = 1										;5481	f2 7f 54 	.  T 
	dec hl							; delay 6 clock cycles											;5484	2b 	+ 
	inc hl							; delay 6 clock cycles											;5485	23 	# 
	dec hl							; delay 6 clock cycles											;5486	2b 	+ 
	inc hl							; delay 6 clock cycles											;5487	23 	# 
	dec hl							; delay 6 clock cycles											;5488	2b 	+ 
	inc hl							; delay 6 clock cycles											;5489	23 	# 
	nop								; delay 6 clock cycles											;548a	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;548b	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 3]		;548d	db 11 	. . 
.waitClockBit5:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;548f	ed 78 	. x 
	jp p,.waitClockBit5				; wait until Clock BIt = 1										;5491	f2 8f 54 	. . T 
	dec hl							; delay 6 clock cycles											;5494	2b 	+ 
	inc hl							; delay 6 clock cycles											;5495	23 	# 
	dec hl							; delay 6 clock cycles											;5496	2b 	+ 
	inc hl							; delay 6 clock cycles											;5497	23 	# 
	dec hl							; delay 6 clock cycles											;5498	2b 	+ 
	inc hl							; delay 6 clock cycles											;5499	23 	# 
	nop								; delay 4 clock cycles											;549a	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;549b	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 2]		;549d	db 11 	. . 
.waitClockBit6:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;549f	ed 78 	. x 
	jp p,.waitClockBit6				; wait until Clock BIt = 1										;54a1	f2 9f 54 	. . T 
	dec hl							; delay 6 clock cycles											;54a4	2b 	+ 
	inc hl							; delay 6 clock cycles											;54a5	23 	# 
	dec hl							; delay 6 clock cycles											;54a6	2b 	+ 
	inc hl							; delay 6 clock cycles											;54a7	23 	# 
	dec hl							; delay 6 clock cycles											;54a8	2b 	+ 
	inc hl							; delay 6 clock cycles											;54a9	23 	# 
	nop								; delay 4 clock cycles											;54aa	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;54ab	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 1]		;54ad	db 11 	. . 
.waitClockBit7:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;54af	ed 78 	. x 
	jp p,.waitClockBit7				; wait until Clock BIt = 1										;54b1	f2 af 54 	. . T 
	dec hl							; delay 6 clock cycles											;54b4	2b 	+ 
	inc hl							; delay 6 clock cycles											;54b5	23 	# 
	dec hl							; delay 6 clock cycles											;54b6	2b 	+ 
	inc hl							; delay 6 clock cycles											;54b7	23 	# 
	dec hl							; delay 6 clock cycles											;54b8	2b 	+ 
	inc hl							; delay 6 clock cycles											;54b9	23 	# 
	nop								; delay 4 clock cycles											;54ba	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;54bb	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 0]		;54bd	db 11 	. . 
	ld b,a							; store for compare												;54bf	47 	G 
.waitClockBit8:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;54c0	ed 78 	. x 
	jp p,.waitClockBit8				; wait until Clock BIt = 1										;54c2	f2 c0 54 	. . T 



; -- We have 1 byte read - if 80 then still reading GAP1
	ld a,b							; a - byte from Floppy Disk										;54c5	78 	x 
	cp $80							; is it still $80 - GAP1 sequence byte?							;54c6	fe 80 	. . 
	jp z,.readByte					; yes - read next byte from disk								;54c8	ca 46 54 	. F T 

; -- byte from disk is NOT $80 (expected 00 but not verified)


;***************************************************************************************************
;
; Read IDAM sequence 1st byte - $fe
;

; ---------- [2] --- read byte FE - fist in IDAM sequence

IDAM_Read_FE:
	nop								; delay 4 clock cycles											;54cb	00 	. 
	nop								; delay 4 clock cycles											;54cc	00 	. 
	nop								; delay 4 clock cycles											;54cd	00 	. 
	ld a,0							; delay 7 clock cycles											;54ce	3e 00 	> . 
	ld a,0							; delay 7 clock cycles	(26 in total)							;54d0	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;54d2	db 11 	. . 
.waitClockBit1:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;54d4	ed 78 	. x 
	jp p,.waitClockBit1				; wait until Clock BIt = 1										;54d6	f2 d4 54 	. . T 
	dec hl							; delay 6 clock cycles											;54d9	2b 	+ 
	inc hl							; delay 6 clock cycles											;54da	23 	# 
	dec hl							; delay 6 clock cycles											;54db	2b 	+ 
	inc hl							; delay 6 clock cycles											;54dc	23 	# 
	dec hl							; delay 6 clock cycles											;54dd	2b 	+ 
	inc hl							; delay 6 clock cycles											;54de	23 	# 
	nop								; delay 4 clock cycles											;54df	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;54e0	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 6]		;54e2	db 11 	. . 
.waitClockBit2:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;54e4	ed 78 	. x 
	jp p,.waitClockBit2				; wait until Clock BIt = 1										;54e6	f2 e4 54 	. . T 
	dec hl							; delay 6 clock cycles											;54e9	2b 	+ 
	inc hl							; delay 6 clock cycles											;54ea	23 	# 
	dec hl							; delay 6 clock cycles											;54eb	2b 	+ 
	inc hl							; delay 6 clock cycles											;54ec	23 	# 
	dec hl							; delay 6 clock cycles											;54ed	2b 	+ 
	inc hl							; delay 6 clock cycles											;54ee	23 	# 
	nop								; delay 4 clock cycles											;54ef	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;54f0	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 5]		;54f2	db 11 	. . 
.waitClockBit3:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;54f4	ed 78 	. x 
	jp p,.waitClockBit3				; wait until Clock BIt = 1										;54f6	f2 f4 54 	. . T 
	dec hl							; delay 6 clock cycles											;54f9	2b 	+ 
	inc hl							; delay 6 clock cycles											;54fa	23 	# 
	dec hl							; delay 6 clock cycles											;54fb	2b 	+ 
	inc hl							; delay 6 clock cycles											;54fc	23 	# 
	dec hl							; delay 6 clock cycles											;54fd	2b 	+ 
	inc hl							; delay 6 clock cycles											;54fe	23 	# 
	nop								; delay 4 clock cycles											;54ff	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5500	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 4]		;5502	db 11 	. . 
.waitClockBit4:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5504	ed 78 	. x 
	jp p,.waitClockBit4				; wait until Clock BIt = 1										;5506	f2 04 55 	. . U 
	dec hl							; delay 6 clock cycles											;5509	2b 	+ 
	inc hl							; delay 6 clock cycles											;550a	23 	# 
	dec hl							; delay 6 clock cycles											;550b	2b 	+ 
	inc hl							; delay 6 clock cycles											;550c	23 	# 
	dec hl							; delay 6 clock cycles											;550d	2b 	+ 
	inc hl							; delay 6 clock cycles											;550e	23 	# 
	nop								; delay 4 clock cycles											;550f	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5510	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 3]		;5512	db 11 	. . 
.waitClockBit5:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5514	ed 78 	. x 
	jp p,.waitClockBit5				; wait until Clock BIt = 1										;5516	f2 14 55 	. . U 
	dec hl							; delay 6 clock cycles											;5519	2b 	+ 
	inc hl							; delay 6 clock cycles											;551a	23 	# 
	dec hl							; delay 6 clock cycles											;551b	2b 	+ 
	inc hl							; delay 6 clock cycles											;551c	23 	# 
	dec hl							; delay 6 clock cycles											;551d	2b 	+ 
	inc hl							; delay 6 clock cycles											;551e	23 	# 
	nop								; delay 4 clock cycles											;551f	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5520	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 2]		;5522	db 11 	. . 
.waitClockBit6:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5524	ed 78 	. x 
	jp p,.waitClockBit6				; wait until Clock BIt = 1										;5526	f2 24 55 	. $ U 
	dec hl							; delay 6 clock cycles											;5529	2b 	+ 
	inc hl							; delay 6 clock cycles											;552a	23 	# 
	dec hl							; delay 6 clock cycles											;552b	2b 	+ 
	inc hl							; delay 6 clock cycles											;552c	23 	# 
	dec hl							; delay 6 clock cycles											;552d	2b 	+ 
	inc hl							; delay 6 clock cycles											;552e	23 	# 
	nop								; delay 4 clock cycles											;552f	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5530	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 1]		;5532	db 11 	. . 
.waitClockBit7:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5534	ed 78 	. x 
	jp p,.waitClockBit7				; wait until Clock BIt = 1										;5536	f2 34 55 	. 4 U 
	dec hl							; delay 6 clock cycles											;5539	2b 	+ 
	inc hl							; delay 6 clock cycles											;553a	23 	# 
	dec hl							; delay 6 clock cycles											;553b	2b 	+ 
	inc hl							; delay 6 clock cycles											;553c	23 	# 
	dec hl							; delay 6 clock cycles											;553d	2b 	+ 
	inc hl							; delay 6 clock cycles											;553e	23 	# 
	nop								; delay 4 clock cycles											;553f	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5540	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 0]		;5542	db 11 	. . 
	ld b,a							; store for compare												;5544	47 	G 
.waitClockBit8:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5545	ed 78 	. x 
	jp p,.waitClockBit8				; wait until Clock BIt = 1										;5547	f2 45 55 	. E U 

; -- We have 1st byte read (expected $fe)
	ld a,b							; a - byte from Floppy Disk										;554a	78 	x 
	cp $fe							; is it FE (first byte of IDAM)?								;554b	fe fe 	. . 
	jp nz,IDAM_WaitFor80			; no - start over and find byte = $80							;554d	c2 31 54 	. 1 T 

;***************************************************************************************************
;
; Read IDAM sequence 2nd byte - $e7
;

; ---------- [3] --- read byte E7 - second in IDAM sequence

IDAM_Read_E7:
	nop								; delay 4 clock cycles											;5550	00 	. 
	nop								; delay 4 clock cycles											;5551	00 	. 
	nop								; delay 4 clock cycles											;5552	00 	. 
	ld a,0							; delay 7 clock cycles											;5553	3e 00 	> . 
	ld a,0							; delay 7 clock cycles	(26 in total)							;5555	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;5557	db 11 	. . 
.waitClockBit1:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5559	ed 78 	. x 
	jp p,.waitClockBit1				; wait until Clock BIt = 1										;555b	f2 59 55 	. Y U 
	dec hl							; delay 6 clock cycles											;555e	2b 	+ 
	inc hl							; delay 6 clock cycles											;555f	23 	# 
	dec hl							; delay 6 clock cycles											;5560	2b 	+ 
	inc hl							; delay 6 clock cycles											;5561	23 	# 
	dec hl							; delay 6 clock cycles											;5562	2b 	+ 
	inc hl							; delay 6 clock cycles											;5563	23 	# 
	nop								; delay 4 clock cycles											;5564	00 	. 
	ld a,0							; delay 7 clock cycles (47 in total)							;5565	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 6]		;5567	db 11 	. . 
.waitClockBit2:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5569	ed 78 	. x 
	jp p,.waitClockBit2				; wait until Clock BIt = 1										;556b	f2 69 55 	. i U 
	dec hl							; delay 6 clock cycles											;556e	2b 	+ 
	inc hl							; delay 6 clock cycles											;556f	23 	# 
	dec hl							; delay 6 clock cycles											;5570	2b 	+ 
	inc hl							; delay 6 clock cycles											;5571	23 	# 
	dec hl							; delay 6 clock cycles											;5572	2b 	+ 
	inc hl							; delay 6 clock cycles											;5573	23 	# 
	nop								; delay 4 clock cycles											;5574	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5575	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 5]		;5577	db 11 	. . 
.waitClockBit3:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5579	ed 78 	. x 
	jp p,.waitClockBit3				; wait until Clock BIt = 1										;557b	f2 79 55 	. y U 
	dec hl							; delay 6 clock cycles											;557e	2b 	+ 
	inc hl							; delay 6 clock cycles											;557f	23 	# 
	dec hl							; delay 6 clock cycles											;5580	2b 	+ 
	inc hl							; delay 6 clock cycles											;5581	23 	# 
	dec hl							; delay 6 clock cycles											;5582	2b 	+ 
	inc hl							; delay 6 clock cycles											;5583	23 	# 
	nop								; delay 4 clock cycles											;5584	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5585	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 4]		;5587	db 11 	. . 
.waitClockBit4:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5589	ed 78 	. x 
	jp p,.waitClockBit4				; wait until Clock BIt = 1										;558b	f2 89 55 	. . U 
	dec hl							; delay 6 clock cycles											;558e	2b 	+ 
	inc hl							; delay 6 clock cycles											;558f	23 	# 
	dec hl							; delay 6 clock cycles											;5590	2b 	+ 
	inc hl							; delay 6 clock cycles											;5591	23 	# 
	dec hl							; delay 6 clock cycles											;5592	2b 	+ 
	inc hl							; delay 6 clock cycles											;5593	23 	# 
	nop								; delay 4 clock cycles											;5594	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5595	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 3]		;5597	db 11 	. . 
.waitClockBit5:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5599	ed 78 	. x 
	jp p,.waitClockBit5				; wait until Clock BIt = 1										;559b	f2 99 55 	. . U 
	dec hl							; delay 6 clock cycles											;559e	2b 	+ 
	inc hl							; delay 6 clock cycles											;559f	23 	# 
	dec hl							; delay 6 clock cycles											;55a0	2b 	+ 
	inc hl							; delay 6 clock cycles											;55a1	23 	# 
	dec hl							; delay 6 clock cycles											;55a2	2b 	+ 
	inc hl							; delay 6 clock cycles											;55a3	23 	# 
	nop								; delay 4 clock cycles											;55a4	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;55a5	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 2]		;55a7	db 11 	. . 
.waitClockBit6:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;55a9	ed 78 	. x 
	jp p,.waitClockBit6				; wait until Clock BIt = 1										;55ab	f2 a9 55 	. . U 
	dec hl							; delay 6 clock cycles											;55ae	2b 	+ 
	inc hl							; delay 6 clock cycles											;55af	23 	# 
	dec hl							; delay 6 clock cycles											;55b0	2b 	+ 
	inc hl							; delay 6 clock cycles											;55b1	23 	# 
	dec hl							; delay 6 clock cycles											;55b2	2b 	+ 
	inc hl							; delay 6 clock cycles											;55b3	23 	# 
	nop								; delay 4 clock cycles											;55b4	00 	. 
	ld a,0							; delay 7 clock cycles											;55b5	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 1]		;55b7	db 11 	. . 
.waitClockBit7:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;55b9	ed 78 	. x 
	jp p,.waitClockBit7				; wait until Clock BIt = 1										;55bb	f2 b9 55 	. . U 
	dec hl							; delay 6 clock cycles											;55be	2b 	+ 
	inc hl							; delay 6 clock cycles											;55bf	23 	# 
	dec hl							; delay 6 clock cycles											;55c0	2b 	+ 
	inc hl							; delay 6 clock cycles											;55c1	23 	# 
	dec hl							; delay 6 clock cycles											;55c2	2b 	+ 
	inc hl							; delay 6 clock cycles											;55c3	23 	# 
	nop								; delay 4 clock cycles											;55c4	00 	. 
	ld a,0							; delay 7 clock cycles											;55c5	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 0]		;55c7	db 11 	. . 
	ld b,a							; store for compare												;55c9	47 	G 
.waitClockBit8:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;55ca	ed 78 	. x 
	jp p,.waitClockBit8				; wait until Clock BIt = 1										;55cc	f2 ca 55 	. . U 

; -- We have 2nd byte read (expected $e7)
	ld a,b							; a - byte from Floppy Disk										;55cf	78 	x 
	cp $e7							; is it E7 (second byte of IDAM)?								;55d0	fe e7 	. . 
	jp nz,IDAM_WaitFor80			; no - start over and find byte = $80							;55d2	c2 31 54 	. 1 T 


;***************************************************************************************************
;
; Read IDAM sequence 3rd byte - $18
;

; ---------- [4] --- read byte 18 - third in IDAM sequence

IDAM_Read_18:
	nop								; delay 4 clock cycles											;55d5	00 	. 
	nop								; delay 4 clock cycles											;55d6	00 	. 
	nop								; delay 4 clock cycles											;55d7	00 	. 
	ld a,0							; delay 7 clock cycles											;55d8	3e 00 	> . 
	ld a,0							; delay 7 clock cycles	(26 in total)							;55da	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;55dc	db 11 	. . 
.waitClockBit1:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;55de	ed 78 	. x 
	jp p,.waitClockBit1				; wait until Clock BIt = 1										;55e0	f2 de 55 	. . U 
	dec hl							; delay 6 clock cycles											;55e3	2b 	+ 
	inc hl							; delay 6 clock cycles											;55e4	23 	# 
	dec hl							; delay 6 clock cycles											;55e5	2b 	+ 
	inc hl							; delay 6 clock cycles											;55e6	23 	# 
	dec hl							; delay 6 clock cycles											;55e7	2b 	+ 
	inc hl							; delay 6 clock cycles											;55e8	23 	# 
	nop								; delay 4 clock cycles											;55e9	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;55ea	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 6]		;55ec	db 11 	. . 
.waitClockBit2:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;55ee	ed 78 	. x 
	jp p,.waitClockBit2				; wait until Clock BIt = 1										;55f0	f2 ee 55 	. . U 
	dec hl							; delay 6 clock cycles											;55f3	2b 	+ 
	inc hl							; delay 6 clock cycles											;55f4	23 	# 
	dec hl							; delay 6 clock cycles											;55f5	2b 	+ 
	inc hl							; delay 6 clock cycles											;55f6	23 	# 
	dec hl							; delay 6 clock cycles											;55f7	2b 	+ 
	inc hl							; delay 6 clock cycles											;55f8	23 	# 
	nop								; delay 4 clock cycles											;55f9	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;55fa	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 5]		;55fc	db 11 	. . 
.waitClockBit3:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;55fe	ed 78 	. x 
	jp p,.waitClockBit3				; wait until Clock BIt = 1										;5600	f2 fe 55 	. . U 
	dec hl							; delay 6 clock cycles											;5603	2b 	+ 
	inc hl							; delay 6 clock cycles											;5604	23 	# 
	dec hl							; delay 6 clock cycles											;5605	2b 	+ 
	inc hl							; delay 6 clock cycles											;5606	23 	# 
	dec hl							; delay 6 clock cycles											;5607	2b 	+ 
	inc hl							; delay 6 clock cycles											;5608	23 	# 
	nop								; delay 4 clock cycles											;5609	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;560a	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 4]		;560c	db 11 	. . 
.waitClockBit4:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;560e	ed 78 	. x 
	jp p,.waitClockBit4				; wait until Clock BIt = 1										;5610	f2 0e 56 	. . V 
	dec hl							; delay 6 clock cycles											;5613	2b 	+ 
	inc hl							; delay 6 clock cycles											;5614	23 	# 
	dec hl							; delay 6 clock cycles											;5615	2b 	+ 
	inc hl							; delay 6 clock cycles											;5616	23 	# 
	dec hl							; delay 6 clock cycles											;5617	2b 	+ 
	inc hl							; delay 6 clock cycles											;5618	23 	# 
	nop								; delay 4 clock cycles											;5619	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;561a	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 3]		;561c	db 11 	. . 
.waitClockBit5:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;561e	ed 78 	. x 
	jp p,.waitClockBit5				; wait until Clock BIt = 1										;5620	f2 1e 56 	. . V 
	dec hl							; delay 6 clock cycles											;5623	2b 	+ 
	inc hl							; delay 6 clock cycles											;5624	23 	# 
	dec hl							; delay 6 clock cycles											;5625	2b 	+ 
	inc hl							; delay 6 clock cycles											;5626	23 	# 
	dec hl							; delay 6 clock cycles											;5627	2b 	+ 
	inc hl							; delay 6 clock cycles											;5628	23 	# 
	nop								; delay 4 clock cycles											;5629	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;562a	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 2]		;562c	db 11 	. . 
.waitClockBit6:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;562e	ed 78 	. x 
	jp p,.waitClockBit6				; wait until Clock BIt = 1										;5630	f2 2e 56 	. . V 
	dec hl							; delay 6 clock cycles											;5633	2b 	+ 
	inc hl							; delay 6 clock cycles											;5634	23 	# 
	dec hl							; delay 6 clock cycles											;5635	2b 	+ 
	inc hl							; delay 6 clock cycles											;5636	23 	# 
	dec hl							; delay 6 clock cycles											;5637	2b 	+ 
	inc hl							; delay 6 clock cycles											;5638	23 	# 
	nop								; delay 4 clock cycles											;5639	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;563a	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 1]		;563c	db 11 	. . 
.waitClockBit7:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;563e	ed 78 	. x 
	jp p,.waitClockBit7				; wait until Clock BIt = 1										;5640	f2 3e 56 	. > V 
	dec hl							; delay 6 clock cycles											;5643	2b 	+ 
	inc hl							; delay 6 clock cycles											;5644	23 	# 
	dec hl							; delay 6 clock cycles											;5645	2b 	+ 
	inc hl							; delay 6 clock cycles											;5646	23 	# 
	dec hl							; delay 6 clock cycles											;5647	2b 	+ 
	inc hl							; delay 6 clock cycles											;5648	23 	# 
	nop								; delay 4 clock cycles											;5649	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;564a	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 0]		;564c	db 11 	. . 
	ld b,a							; store for compare												;564e	47 	G 
.waitClockBit8:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;564f	ed 78 	. x 
	jp p,.waitClockBit8				; wait until Clock BIt = 1										;5651	f2 4f 56 	. O V 

; -- We have 3rd byte read (expected $18)
	ld a,b							; a - byte from Floppy Disk										;5654	78 	x 
	cp $18							; is it 18 (third byte of IDAM)?								;5655	fe 18 	. . 
	jp nz,IDAM_WaitFor80			; no - start over and find byte = $80							;5657	c2 31 54 	. 1 T 

;***************************************************************************************************
;
; Read IDAM sequence 4th byte - $c3
;

; ---------- [5] --- read byte C3 - forth in IDAM sequence

IDAM_Read_C3:
	nop								; delay 4 clock cycles											;565a	00 	. 
	nop								; delay 4 clock cycles											;565b	00 	. 
	nop								; delay 4 clock cycles											;565c	00 	. 
	ld a,0							; delay 7 clock cycles											;565d	3e 00 	> . 
	ld a,0							; delay 7 clock cycles	(26 in total)							;565f	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;5661	db 11 	. . 
.waitClockBit1:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5663	ed 78 	. x 
	jp p,.waitClockBit1				; wait until Clock BIt = 1										;5665	f2 63 56 	. c V 
	dec hl							; delay 6 clock cycles											;5668	2b 	+ 
	inc hl							; delay 6 clock cycles											;5669	23 	# 
	dec hl							; delay 6 clock cycles											;566a	2b 	+ 
	inc hl							; delay 6 clock cycles											;566b	23 	# 
	dec hl							; delay 6 clock cycles											;566c	2b 	+ 
	inc hl							; delay 6 clock cycles											;566d	23 	# 
	nop								; delay 4 clock cycles											;566e	00 	. 
	ld a,0							; delay 7 clock cycles											;566f	3e 00 	> . 
	ld a,0							; delay 7 clock cycles	(54 in total)							;5671	3e 00 	> . 
.waitClockBit2:
; [!] Not sure why we are shifting FDC data register so many times while waiting for Clock pulse [!]
; -- wait for FDC Clock Pulse
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7,6,...]	;5673	db 11 	. . 
	in a,(c)						; read Clock Bit from Flopy Drive								;5675	ed 78 	. x 
	jp p,.waitClockBit2				; wait until Clock BIt = 1										;5677	f2 73 56 	. s V 
	dec hl							; delay 6 clock cycles											;567a	2b 	+ 
	inc hl							; delay 6 clock cycles											;567b	23 	# 
	dec hl							; delay 6 clock cycles											;567c	2b 	+ 
	inc hl							; delay 6 clock cycles											;567d	23 	# 
	dec hl							; delay 6 clock cycles											;567e	2b 	+ 
	inc hl							; delay 6 clock cycles											;567f	23 	# 
	nop								; delay 4 clock cycles											;5680	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5681	3e 00 	> . 
.waitClockBit3:
; -- wait for FDC Clock Pulse
; [!] Still not sure why we are shifting FDC data register so many times while waiting for Clock pulse [!]
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7,6...]	;5683	db 11 	. 
	in a,(c)						; read Clock Bit from Flopy Drive								;5685	ed 78 	. x 
	jp p,.waitClockBit3				; wait until Clock BIt = 1										;5687	f2 83 56 	. . V 
	dec hl							; delay 6 clock cycles											;568a	2b 	+ 
	inc hl							; delay 6 clock cycles											;568b	23 	# 
	dec hl							; delay 6 clock cycles											;568c	2b 	+ 
	inc hl							; delay 6 clock cycles											;568d	23 	# 
	dec hl							; delay 6 clock cycles											;568e	2b 	+ 
	inc hl							; delay 6 clock cycles											;568f	23 	# 
	nop								; delay 4 clock cycles	(40 cycles in total)					;5690	00 	. 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 4]		;5691	db 11 	. . 
.waitClockBit4:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5693	ed 78 	. x 
	jp p,.waitClockBit4				; wait until Clock BIt = 1										;5695	f2 93 56 	. . V 
	dec hl							; delay 6 clock cycles											;5698	2b 	+ 
	inc hl							; delay 6 clock cycles											;5699	23 	# 
	dec hl							; delay 6 clock cycles											;569a	2b 	+ 
	inc hl							; delay 6 clock cycles											;569b	23 	# 
	dec hl							; delay 6 clock cycles											;569c	2b 	+ 
	inc hl							; delay 6 clock cycles											;569d	23 	# 
	nop								; delay 4 clock cycles											;569e	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;569f	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 3]		;56a1	db 11 	. . 
.waitClockBit5:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;56a3	ed 78 	. x 
	jp p,.waitClockBit5				; wait until Clock BIt = 1										;56a5	f2 a3 56 	. . V 
	dec hl							; delay 6 clock cycles											;56a8	2b 	+ 
	inc hl							; delay 6 clock cycles											;56a9	23 	# 
	dec hl							; delay 6 clock cycles											;56aa	2b 	+ 
	inc hl							; delay 6 clock cycles											;56ab	23 	# 
	dec hl							; delay 6 clock cycles											;56ac	2b 	+ 
	inc hl							; delay 6 clock cycles											;56ad	23 	# 
	nop								; delay 4 clock cycles											;56ae	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;56af	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 2]		;56b1	db 11 	. . 
.waitClockBit6:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;56b3	ed 78 	. x 
	jp p,.waitClockBit6				; wait until Clock BIt = 1										;56b5	f2 b3 56 	. . V 
	dec hl							; delay 6 clock cycles											;56b8	2b 	+ 
	inc hl							; delay 6 clock cycles											;56b9	23 	# 
	dec hl							; delay 6 clock cycles											;56ba	2b 	+ 
	inc hl							; delay 6 clock cycles											;56bb	23 	# 
	dec hl							; delay 6 clock cycles											;56bc	2b 	+ 
	inc hl							; delay 6 clock cycles											;56bd	23 	# 
	nop								; delay 4 clock cycles											;56be	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;56bf	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 1]		;56c1	db 11 	. . 
.waitClockBit7:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;56c3	ed 78 	. x 
	jp p,.waitClockBit7				; wait until Clock BIt = 1										;56c5	f2 c3 56 	. . V 
	dec hl							; delay 6 clock cycles											;56c8	2b 	+ 
	inc hl							; delay 6 clock cycles											;56c9	23 	# 
	dec hl							; delay 6 clock cycles											;56ca	2b 	+ 
	inc hl							; delay 6 clock cycles											;56cb	23 	# 
	dec hl							; delay 6 clock cycles											;56cc	2b 	+ 
	inc hl							; delay 6 clock cycles											;56cd	23 	# 
	nop								; delay 4 clock cycles											;56ce	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;56cf	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 0]		;56d1	db 11 	. . 
	ld b,a							; store for compare												;56d3	47 	G 
.waitClockBit8:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;56d4	ed 78 	. x 
	jp p,.waitClockBit8				; wait until Clock BIt = 1										;56d6	f2 d4 56 	. . V 

; -- We have 4th byte read (expected $c3)

	ld a,b							; a - byte from Floppy Disk										;56d9	78 	x 
	cp $c3							; is it c3 (fourth byte of IDAM)?								;56da	fe c3 	. . 
	jp nz,IDAM_WaitFor80			; no - start over and find byte = $80							;56dc	c2 31 54 	. 1 T 


;***************************************************************************************************
;
; Read Track Number from IDAM sequence
;

; ---------- [6] --- read Track Number

IDAM_Read_TrkNo:
	nop								; delay 4 clock cycles											;56df	00 	. 
	nop								; delay 4 clock cycles											;56e0	00 	. 
	nop								; delay 4 clock cycles											;56e1	00 	. 
	ld a,0							; delay 7 clock cycles											;56e2	3e 00 	> . 
	ld a,0							; delay 7 clock cycles	(26 in total)							;56e4	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;56e6	db 11 	. . 
.waitClockBit1:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;56e8	ed 78 	. x 
	jp p,.waitClockBit1				; wait until Clock BIt = 1										;56ea	f2 e8 56 	. . V 
	dec hl							; delay 6 clock cycles											;56ed	2b 	+ 
	inc hl							; delay 6 clock cycles											;56ee	23 	# 
	dec hl							; delay 6 clock cycles											;56ef	2b 	+ 
	inc hl							; delay 6 clock cycles											;56f0	23 	# 
	dec hl							; delay 6 clock cycles											;56f1	2b 	+ 
	inc hl							; delay 6 clock cycles											;56f2	23 	# 
	nop								; delay 4 clock cycles											;56f3	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;56f4	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 6]		;56f6	db 11 	. . 
.waitClockBit2:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;56f8	ed 78 	. x 
	jp p,.waitClockBit2				; wait until Clock BIt = 1										;56fa	f2 f8 56 	. . V 
	dec hl							; delay 6 clock cycles											;56fd	2b 	+ 
	inc hl							; delay 6 clock cycles											;56fe	23 	# 
	dec hl							; delay 6 clock cycles											;56ff	2b 	+ 
	inc hl							; delay 6 clock cycles											;5700	23 	# 
	dec hl							; delay 6 clock cycles											;5701	2b 	+ 
	inc hl							; delay 6 clock cycles											;5702	23 	# 
	nop								; delay 4 clock cycles											;5703	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5704	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 5]		;5706	db 11 	. . 
.waitClockBit3:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5708	ed 78 	. x 
	jp p,.waitClockBit3				; wait until Clock BIt = 1										;570a	f2 08 57 	. . W 
	dec hl							; delay 6 clock cycles											;570d	2b 	+ 
	inc hl							; delay 6 clock cycles											;570e	23 	# 
	dec hl							; delay 6 clock cycles											;570f	2b 	+ 
	inc hl							; delay 6 clock cycles											;5710	23 	# 
	dec hl							; delay 6 clock cycles											;5711	2b 	+ 
	inc hl							; delay 6 clock cycles											;5712	23 	# 
	nop								; delay 4 clock cycles											;5713	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5714	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 4]		;5716	db 11 	. . 
.waitClockBit4:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5718	ed 78 	. x 
	jp p,.waitClockBit4				; wait until Clock BIt = 1										;571a	f2 18 57 	. . W 
	dec hl							; delay 6 clock cycles											;571d	2b 	+ 
	inc hl							; delay 6 clock cycles											;571e	23 	# 
	dec hl							; delay 6 clock cycles											;571f	2b 	+ 
	inc hl							; delay 6 clock cycles											;5720	23 	# 
	dec hl							; delay 6 clock cycles											;5721	2b 	+ 
	inc hl							; delay 6 clock cycles											;5722	23 	# 
	nop								; delay 4 clock cycles											;5723	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5724	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 3]		;5726	db 11 	. . 
.waitClockBit5:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5728	ed 78 	. x 
	jp p,.waitClockBit5				; wait until Clock BIt = 1										;572a	f2 28 57 	. ( W 
	dec hl							; delay 6 clock cycles											;572d	2b 	+ 
	inc hl							; delay 6 clock cycles											;572e	23 	# 
	dec hl							; delay 6 clock cycles											;572f	2b 	+ 
	inc hl							; delay 6 clock cycles											;5730	23 	# 
	dec hl							; delay 6 clock cycles											;5731	2b 	+ 
	inc hl							; delay 6 clock cycles											;5732	23 	# 
	nop								; delay 4 clock cycles											;5733	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5734	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 2]		;5736	db 11 	. . 
.waitClockBit6:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5738	ed 78 	. x 
	jp p,.waitClockBit6				; wait until Clock BIt = 1										;573a	f2 38 57 	. 8 W 
	dec hl							; delay 6 clock cycles											;573d	2b 	+ 
	inc hl							; delay 6 clock cycles											;573e	23 	# 
	dec hl							; delay 6 clock cycles											;573f	2b 	+ 
	inc hl							; delay 6 clock cycles											;5740	23 	# 
	dec hl							; delay 6 clock cycles											;5741	2b 	+ 
	inc hl							; delay 6 clock cycles											;5742	23 	# 
	nop								; delay 4 clock cycles											;5743	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5744	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 1]		;5746	db 11 	. . 
.waitClockBit7:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5748	ed 78 	. x 
	jp p,.waitClockBit7				; wait until Clock BIt = 1										;574a	f2 48 57 	. H W 
	ld a,(iy+TRCK)					; a - requested track number 									;574d	fd 7e 12 	. ~ . 
	ld b,a							; b - requested track number									;5750	47 	G 
	nop								; delay 4 clock cycles 											;5751	00 	. 
	jp .continue1					; delay 10 clock cycles											;5752	c3 55 57 	. U W 
.continue1:
	jp .continue2					; delay 10 clock cycles											;5755	c3 58 57 	. X W 
.continue2:
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register)  [bit 0]		;5758	db 11 	. . 
	ex af,af'						; save a (byte from Floppy Disk) in alt register				;575a	08 	. 
.waitClockBit8:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;575b	ed 78 	. x 
	jp p,.waitClockBit8				; wait until Clock BIt = 1										;575d	f2 5b 57 	. [ W 

; -- We have Track number byte read (expected the same as requested)

	ex af,af'						; restore a - track number read from disk 						;5760	08 	. 
	cp b							; is the same as requested (in IY+TRCK)							;5761	b8 	. 
	jp z,IDAM_Read_SecNo			; yes - continue to read Sector number 							;5762	ca 6c 57 	. l W 

; -- wrong track number

	dec l							; decrement Try Counter - is it 0?								;5765	2d 	- 
	jp nz,IDAM_SetTrack				; no - set Track on Drive and start again						;5766	c2 fb 53 	. . S 
	jp ResetTrackTo0				; yes - no more try - Reset Track to 0 and try 10 times again 	;5769	c3 f0 53 	. . S 


;***************************************************************************************************
;
; Read Sector Number from IDAM sequence
;

; ---------- [7] --- read Sector Number

IDAM_Read_SecNo:
	nop								; delay 4 clock cycles											;576c	00 	. 
	nop								; delay 4 clock cycles											;576d	00 	. 
	nop								; delay 4 clock cycles											;576e	00 	. 
	jp .continue					; delay 10 clock cycles 										;576f	c3 72 57 	. r W 
.continue:
	ld a,0							; delay 7 clock cycles											;5772	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;5774	db 11 	. . 
.waitClockBit1:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5776	ed 78 	. x 
	jp p,.waitClockBit1				; wait until Clock BIt = 1										;5778	f2 76 57 	. v W 
	dec hl							; delay 6 clock cycles											;577b	2b 	+ 
	inc hl							; delay 6 clock cycles											;577c	23 	# 
	dec hl							; delay 6 clock cycles											;577d	2b 	+ 
	inc hl							; delay 6 clock cycles											;577e	23 	# 
	dec hl							; delay 6 clock cycles											;577f	2b 	+ 
	inc hl							; delay 6 clock cycles											;5780	23 	# 
	nop								; delay 4 clock cycles											;5781	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5782	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 6]		;5784	db 11 	. . 
.waitClockBit2:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5786	ed 78 	. x 
	jp p,.waitClockBit2				; wait until Clock BIt = 1										;5788	f2 86 57 	. . W 
	dec hl							; delay 6 clock cycles											;578b	2b 	+ 
	inc hl							; delay 6 clock cycles											;578c	23 	# 
	dec hl							; delay 6 clock cycles											;578d	2b 	+ 
	inc hl							; delay 6 clock cycles											;578e	23 	# 
	dec hl							; delay 6 clock cycles											;578f	2b 	+ 
	inc hl							; delay 6 clock cycles											;5790	23 	# 
	nop								; delay 4 clock cycles											;5791	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5792	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 5]		;5794	db 11 	. . 
.waitClockBit3:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5796	ed 78 	. x 
	jp p,.waitClockBit3				; wait until Clock BIt = 1										;5798	f2 96 57 	. . W 
	dec hl							; delay 6 clock cycles											;579b	2b 	+ 
	inc hl							; delay 6 clock cycles											;579c	23 	# 
	dec hl							; delay 6 clock cycles											;579d	2b 	+ 
	inc hl							; delay 6 clock cycles											;579e	23 	# 
	dec hl							; delay 6 clock cycles											;579f	2b 	+ 
	inc hl							; delay 6 clock cycles											;57a0	23 	# 
	nop								; delay 4 clock cycles											;57a1	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;57a2	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 4]		;57a4	db 11 	. . 
.waitClockBit4:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;57a6	ed 78 	. x 
	jp p,.waitClockBit4				; wait until Clock BIt = 1										;57a8	f2 a6 57 	. . W 
	dec hl							; delay 6 clock cycles											;57ab	2b 	+ 
	inc hl							; delay 6 clock cycles											;57ac	23 	# 
	dec hl							; delay 6 clock cycles											;57ad	2b 	+ 
	inc hl							; delay 6 clock cycles											;57ae	23 	# 
	dec hl							; delay 6 clock cycles											;57af	2b 	+ 
	inc hl							; delay 6 clock cycles											;57b0	23 	# 
	nop								; delay 4 clock cycles											;57b1	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;57b2	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 3]		;57b4	db 11 	. . 
.waitClockBit5:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;57b6	ed 78 	. x 
	jp p,.waitClockBit5				; wait until Clock BIt = 1										;57b8	f2 b6 57 	. . W 
	dec hl							; delay 6 clock cycles											;57bb	2b 	+ 
	inc hl							; delay 6 clock cycles											;57bc	23 	# 
	dec hl							; delay 6 clock cycles											;57bd	2b 	+ 
	inc hl							; delay 6 clock cycles											;57be	23 	# 
	dec hl							; delay 6 clock cycles											;57bf	2b 	+ 
	inc hl							; delay 6 clock cycles											;57c0	23 	# 
	nop								; delay 4 clock cycles											;57c1	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;57c2	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 2]		;57c4	db 11 	. . 
.waitClockBit6:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;57c6	ed 78 	. x 
	jp p,.waitClockBit6				; wait until Clock BIt = 1										;57c8	f2 c6 57 	. . W 
	dec hl							; delay 6 clock cycles											;57cb	2b 	+ 
	inc hl							; delay 6 clock cycles											;57cc	23 	# 
	dec hl							; delay 6 clock cycles											;57cd	2b 	+ 
	inc hl							; delay 6 clock cycles											;57ce	23 	# 
	dec hl							; delay 6 clock cycles											;57cf	2b 	+ 
	inc hl							; delay 6 clock cycles											;57d0	23 	# 
	nop								; delay 4 clock cycles											;57d1	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;57d2	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 1]		;57d4	db 11 	. . 
.waitClockBit7:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;57d6	ed 78 	. x 
	jp p,.waitClockBit7				; wait until Clock BIt = 1										;57d8	f2 d6 57 	. . W 
	ld a,(iy+SCTR)					; a - requested sector number 									;57db	fd 7e 11 	. ~ . 
	ld b,a							; b - requested sector number 									;57de	47 	G 
	nop								; delay 4 clock cycles											;57df	00 	. 
	jp .continue1					; delay 10 clock cycles											;57e0	c3 e3 57 	. . W 
.continue1:
	jp .continue2					; delay 10 clock cycles											;57e3	c3 e6 57 	. . W 
.continue2:
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 0]		;57e6	db 11 	. . 
	ex af,af'						; save a (byte from Floppy Disk) in alt register				;57e8	08 	. 
.waitClockBit8:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;57e9	ed 78 	. x 
	jp p,.waitClockBit8				; wait until Clock BIt = 1										;57eb	f2 e9 57 	. . W 

; -- We have Sector Number byte read (expected the same as requested)

	ex af,af'						; restore a - Sector Number read from disk 						;57ee	08 	. 
	cp b							; is the same as requested (in IY+SCTR)							;57ef	b8 	. 
	jp z,IDAM_Read_Crc				; yes - continue to read Checksum Byte 							;57f0	ca fb 57 	. . W 

; -- wrong Sector Number

	dec h							; decrement Sector Try Counter - is it 0?						;57f3	25 	% 
	jp nz,IDAM_WaitFor80			; no - start over and read next sector on this track			;57f4	c2 31 54 	. 1 T 

; -- been trying too many times - return with Error

	ld a,09							; Error code 09 - SECTOR NOT FOUND								;57f7	3e 09 	> . 
	or a							; clear Carry Flag												;57f9	b7 	. 
	ret								; -------------- End of proc (with Error) ---------------------	;57fa	c9 	. 

;***************************************************************************************************
;
; Read and verify Checksum for Track and Sector Number
;

; ---------- [8] --- read/verify Track+Sector Number CRC


IDAM_Read_Crc:
	nop								; delay 4 clock cycles											;57fb	00 	. 
	nop								; delay 4 clock cycles											;57fc	00 	. 
	nop								; delay 4 clock cycles											;57fd	00 	. 
	jp .continue1					; delay 10 clock cycles											;57fe	c3 01 58 	. . X 
.continue1:
	ld a,0							; delay 7 clock cycles	(29 in total)							;5801	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;5803	db 11 	. . 
.waitClockBit1:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5805	ed 78 	. x 
	jp p,.waitClockBit1				; wait until Clock BIt = 1										;5807	f2 05 58 	. . X 
	dec hl							; delay 6 clock cycles											;580a	2b 	+ 
	inc hl							; delay 6 clock cycles											;580b	23 	# 
	dec hl							; delay 6 clock cycles											;580c	2b 	+ 
	inc hl							; delay 6 clock cycles											;580d	23 	# 
	dec hl							; delay 6 clock cycles											;580e	2b 	+ 
	inc hl							; delay 6 clock cycles											;580f	23 	# 
	nop								; delay 4 clock cycles											;5810	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5811	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 6]		;5813	db 11 	. . 
.waitClockBit2:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5815	ed 78 	. x 
	jp p,.waitClockBit2				; wait until Clock BIt = 1										;5817	f2 15 58 	. . X 
	dec hl							; delay 6 clock cycles											;581a	2b 	+ 
	inc hl							; delay 6 clock cycles											;581b	23 	# 
	dec hl							; delay 6 clock cycles											;581c	2b 	+ 
	inc hl							; delay 6 clock cycles											;581d	23 	# 
	dec hl							; delay 6 clock cycles											;581e	2b 	+ 
	inc hl							; delay 6 clock cycles											;581f	23 	# 
	nop								; delay 4 clock cycles											;5820	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5821	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 5]		;5823	db 11 	. . 
.waitClockBit3:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5825	ed 78 	. x 
	jp p,.waitClockBit3				; wait until Clock BIt = 1										;5827	f2 25 58 	. % X 
	dec hl							; delay 6 clock cycles											;582a	2b 	+ 
	inc hl							; delay 6 clock cycles											;582b	23 	# 
	dec hl							; delay 6 clock cycles											;582c	2b 	+ 
	inc hl							; delay 6 clock cycles											;582d	23 	# 
	dec hl							; delay 6 clock cycles											;582e	2b 	+ 
	inc hl							; delay 6 clock cycles											;582f	23 	# 
	nop								; delay 4 clock cycles											;5830	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5831	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 4]		;5833	db 11 	. . 
.waitClockBit4:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5835	ed 78 	. x 
	jp p,.waitClockBit4				; wait until Clock BIt = 1										;5837	f2 35 58 	. 5 X 
	dec hl							; delay 6 clock cycles											;583a	2b 	+ 
	inc hl							; delay 6 clock cycles											;583b	23 	# 
	dec hl							; delay 6 clock cycles											;583c	2b 	+ 
	inc hl							; delay 6 clock cycles											;583d	23 	# 
	dec hl							; delay 6 clock cycles											;583e	2b 	+ 
	inc hl							; delay 6 clock cycles											;583f	23 	# 
	nop								; delay 4 clock cycles											;5840	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5841	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 3]		;5843	db 11 	. . 
.waitClockBit5:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5845	ed 78 	. x 
	jp p,.waitClockBit5				; wait until Clock BIt = 1										;5847	f2 45 58 	. E X 
	dec hl							; delay 6 clock cycles											;584a	2b 	+ 
	inc hl							; delay 6 clock cycles											;584b	23 	# 
	dec hl							; delay 6 clock cycles											;584c	2b 	+ 
	inc hl							; delay 6 clock cycles											;584d	23 	# 
	dec hl							; delay 6 clock cycles											;584e	2b 	+ 
	inc hl							; delay 6 clock cycles											;584f	23 	# 
	nop								; delay 4 clock cycles											;5850	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5851	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 2]		;5853	db 11 	. . 
.waitClockBit6:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5855	ed 78 	. x 
	jp p,.waitClockBit6				; wait until Clock BIt = 1										;5857	f2 55 58 	. U X 
	dec hl							; delay 6 clock cycles											;585a	2b 	+ 
	inc hl							; delay 6 clock cycles											;585b	23 	# 
	dec hl							; delay 6 clock cycles											;585c	2b 	+ 
	inc hl							; delay 6 clock cycles											;585d	23 	# 
	dec hl							; delay 6 clock cycles											;585e	2b 	+ 
	inc hl							; delay 6 clock cycles											;585f	23 	# 
	nop								; delay 4 clock cycles											;5860	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5861	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 1]		;5863	db 11 	. . 
.waitClockBit7:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5865	ed 78 	. x 
	jp p,.waitClockBit7				; wait until Clock BIt = 1										;5867	f2 65 58 	. e X 
	dec hl							; delay 6 clock cycles											;586a	2b 	+ 
	inc hl							; delay 6 clock cycles											;586b	23 	# 
	dec hl							; delay 6 clock cycles											;586c	2b 	+ 
	inc hl							; delay 6 clock cycles											;586d	23 	# 
	dec hl							; delay 6 clock cycles											;586e	2b 	+ 
	inc hl							; delay 6 clock cycles											;586f	23 	# 
	nop								; delay 4 clock cycles											;5870	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5871	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 0]		;5873	db 11 	. . 

; -- We have IDAM Crc read (expected the same as calculated before for this track and sector)

	cp d							; is it the same as calculated?									;5875	ba 	. 
	jp nz,IDAM_WaitFor80			; no - start over and read again								;5876	c2 31 54 	. 1 T 

; -- Found requested Sector and Crc is OK - return with Error 00 
	
	xor a							; set Error Code 00 - NO ERROR									;5879	af 	. 
	ret								; -------------------- End of Proc ----------------------------	;587a	c9 	. 





;***************************************************************************************************
; Create an entry in the disk directory
; IN: (iy+FNAM) - name of file to create
;     (iy+TYPE) - type of file to create ('T','B', etc)
;     Interrupt disabled
; OUT: a - Error code
;     (iy+NTRK) - Track where is 1st sector for data
;     (iy+NSCT) - 1st sector for data
;***************************************************************************************************
CREATE:
; -- check if requested fire already exists
	call SEARCH						; Search for file in Disk Directory 							;587b	cd 13 59 	. . Y 
	cp 13							; Error 13 - File Not Found?									;587e	fe 0d 	. . 
	jr z,.checkSpace				; yes - continute and check if there is enough space			;5880	28 02 	( . 
	or a							; other error? (FILE ALREADY EXISTS, CHECKSUM ERROR, etc)?		;5882	b7 	. 
	ret nz							; yes ------------------- End of Proc (with Error) ------------	;5883	c0 	. 

.checkSpace:
; -- check if there is enough space for new Entry in Directory
	call FIND						; Search empty space in Directory								;5884	cd 68 59 	. h Y 
	or a							; was any Error? 												;5887	b7 	. 
	ret nz							; yes - ------------ End of Proc (with Error) -----------------	;5888	c0 	. 

; -- hl will point to address in Data Buffer with empty space for new Directory Entry
	ld d,(iy+SCTR)					; d - Sector Number with empty Directory Entry					;5889	fd 56 11 	. V . 
	push de							; save de - Sector number										;588c	d5 	. 
	push hl							; save hl - address in Data Buffer								;588d	e5 	. 
; -- find first not used Sector on Disk
	call MAP						; Search for empty sector in Map and mark it as used (allocate)	;588e	cd bf 58 	. . X 
	pop hl							; restore hl - address in Data Buffer of Directory Entry		;5891	e1 	. 
	pop de							; restore d - Sector Number with empty Directory Entry			;5892	d1 	. 
	or a							; any Sector allocate error? 									;5893	b7 	. 
	ret nz							; yes --------------- End of Proc (with Error) ----------------	;5894	c0 	. 


; -- read Sector with empty space for new Directory Entry
	ld (iy+SCTR),d					; set Sector Number (track is still 0)							;5895	fd 72 11 	. r . 
	push hl							; save hl - address in Data Buffer of new Directory Entry		;5898	e5 	. 
	call READ						; Read a sector from disk into Data Buffer						;5899	cd 27 5b 	. ' [ 
	pop hl							; restore hl - address in Data Buffer of new Directory Entry	;589c	e1 	. 
	or a							; any Sector Read error? 										;589d	b7 	. 
	ret nz							; yes --------------- End of Proc (with Error) ----------------	;589e	c0 	. 

; -- create Directory Entry - fill with data
	ex de,hl						; de - address in Data Buffer (Entry block)						;589f	eb 	. 
; -- store File Type
	ld a,(iy+TYPE)					; a - File Type specified by user								;58a0	fd 7e 09 	. ~ . 
	ld (de),a						; store as 1st char in Directory Entry							;58a3	12 	. 
; -- store constant separator char
	inc de							; de - address of separator										;58a4	13 	. 
	ld a,':'						; a - separator char ':'										;58a5	3e 3a 	> : 
	ld (de),a						; store as 2nd char in Directory Entry							;58a7	12 	. 
; -- store filename (8 chars)
	inc de							; de - address of filename area									;58a8	13 	. 
	push iy							; iy - DOS base address											;58a9	fd e5 	. . 
	pop hl							; hl - DOS base address											;58ab	e1 	. 
	inc hl							; hl - points to filename field									;58ac	23 	# 
	ld bc,8							; bc - 8 chars to copy											;58ad	01 08 00 	. . . 
	ldir							; copy filename													;58b0	ed b0 	. . 
; -- store file start Track number
	ld a,(iy+NTRK)					; a - Track number 												;58b2	fd 7e 16 	. ~ . 
	ld (de),a						; store as 10th byte in Directory Entry							;58b5	12 	. 
; -- store file start Sector number
	inc de							; de - address of start Sector number byte						;58b6	13 	. 
	ld a,(iy+NSCT)					; a - Sector number												;58b7	fd 7e 15 	. ~ . 
	ld (de),a						; store as 11th byte in Directory Entry							;58ba	12 	. 
	call WRITE						; Write back sector with Directory Entries to disk				;58bb	cd a1 59 	. . Y 
	ret								; ---------- End of Proc (with Error from WRITESECTOR) --------	;58be	c9 	. 




;***************************************************************************************************
; Search for an empty sector in the allocation map.
;---------------------------------------------------------------------------------------------------
; IN: (iy+MAPADR) - address of Disk Map data
; OUT: a - Error Code
;      hl - address in Disk Map data of byte bitmap for empty sector
;      (iy+NSCT) - number of first not used Serctor
;      (iy+NTRK) - Track number with first not used Serctor
;      Allocated Sector bit is set to 1 in Allocation Map
;***************************************************************************************************
MAP:
; -- setup starting point
	ld (iy+NTRK),1					; start search from Track 1										;58bf	fd 36 16 01 	. 6 . . 
	ld (iy+NSCT),0					; start search from Sector 0									;58c3	fd 36 15 00 	. 6 . . 
	ld l,(iy+MAPADR)																				;58c7	fd 6e 34 	. n 4 
	ld h,(iy+MAPADR+1)				; hl - address of Disk Map data									;58ca	fd 66 35 	. f 5 
	dec hl							; hl - point to byte just before Disk Map data					;58cd	2b 	+ 
.nextMapByte:
	inc hl							; hl - address of Map byte										;58ce	23 	# 
	ld c,(hl)						; c - 8 bit for 8 disk sectors - bit set means sector is used	;58cf	4e 	N 
.checkNextBit:
	rrc c							; Carry flag - least significant bit - is Sector used?			;58d0	cb 09 	. . 
	jr nc,.markSectorUsed			; no - mark it as Used and update Disk Map in buffer			;58d2	30 2b 	0 + 

; -- current Sector is used - get next sector number
	inc (iy+NSCT)					; increment Sector number										;58d4	fd 34 15 	. 4 . 
	ld a,(iy+NSCT)					; a - sector number												;58d7	fd 7e 15 	. ~ . 
	cp 8							; is it 8? - sector marked in next Map Byte						;58da	fe 08 	. . 
	jr nz,.checkNextBit				; no - check next bit of current Map Byte						;58dc	20 f2 	  . 

; -- 8 sectors checked - get next byte from Disk Map
	inc hl							; hl - address of Map byte										;58de	23 	# 
	ld c,(hl)						; c - 8 bit for 8 disk sectors - bit set means sector is used	;58df	4e 	N 
.checkNextBit1:
	rrc c							; Carry flag - least significant bit - is Sector used?			;58e0	cb 09 	. . 
	jr nc,.markSectorUsed			; no - mark it as Used and update Disk Map in buffer			;58e2	30 1b 	0 . 

; -- current Sector is used - get next sector number
	inc (iy+NSCT)					; increment Sector number										;58e4	fd 34 15 	. 4 . 
	ld a,(iy+NSCT)					; a - sector number												;58e7	fd 7e 15 	. ~ . 
	cp 16							; is it 16? - sector marked in next Map Byte					;58ea	fe 10 	. . 
	jr nz,.checkNextBit1			; no - check next bit of current Map Byte						;58ec	20 f2 	  . 

; -- 16 sectors checked (whole track) - set sector 0 on next track 
	ld (iy+NSCT),0					; set Sector number 0											;58ee	fd 36 15 00 	. 6 . . 
	inc (iy+NTRK)					; increment Track number										;58f2	fd 34 16 	. 4 . 
	ld a,(iy+NTRK)					; a - Track number												;58f5	fd 7e 16 	. ~ . 
	cp 40							; is it 40? - all Tracks checked already?						;58f8	fe 28 	. ( 
	jr nz,.nextMapByte				; no - continue to check all 40 tracks 							;58fa	20 d2 	  . 

; -- all sectors on all tracks are used - return Error 07 - DISK FULL
	ld a,7							; a - Error 07 - DISK FULL										;58fc	3e 07 	> . 
	ret								; ----------------- End of Proc (with Error) ------------------	;58fe	c9 	. 

; -- found 1st empty sector - mark it as used (allocate) and update Disk Map
.markSectorUsed:
; -- update Map Byte
	rlc c							; rotate back Map Byte so bit 0 is for current sector 			;58ff	cb 01 	. . 
	set 0,c							; set current Sector as used									;5901	cb c1 	. . 
; -- restore place and order of bits in Map Byte  
	ld a,(iy+NSCT)					; a - current Sector number										;5903	fd 7e 15 	. ~ . 
	and %0111						; a - how many times we rotated Map Byte so far					;5906	e6 07 	. . 
	inc a							; pre increment counter											;5908	3c 	< 
	ld b,a							; b - loop couner for rotate Map Byte back						;5909	47 	G 
	rrc c							; rotate Map Byte to match current Sector						;590a	cb 09 	. . 
.rotateBack:
	rlc c							; rotate Map Byte												;590c	cb 01 	. . 
	djnz .rotateBack				; continute to rotate Map Byte b times							;590e	10 fc 	. . 
	ld (hl),c						; store back modified byte to Disk Map memory					;5910	71 	q 
	xor a							; a - Error 00 - NO ERROR										;5911	af 	. 
	ret								; ---------------------- End of Proc --------------------------	;5912	c9 	. 





;***************************************************************************************************
; Search for matching of filename from IY+FNAM with that in the disk directory.
; IN: interrupt disabled
;     (iy+FNAM) - name of file to find
; OUT: a - Error code
; --- in case Error 02 - FILE ALREADY EXISTS ----
;      de - address of file Track Number (next byte after filename in loaded Directory Entry)
;      (iy+TYPE+1) - type of file 
;      (iy+SCTR) - Sector Number of directory entry 
;      (iy+TRCK) - Track Number of directory entry 
;      Buffer (iy+DBFR) sector with directory entry
;***************************************************************************************************
SEARCH:
; -- setup starting condition: data buffer, track and sector number 
	ld l,(iy+DBFR)					; hl - address of DOS Data Buffer								;5913	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)																				;5916	fd 66 32 	. f 2 
	ld (iy+TRCK),0					; search will start from Track Number 0							;5919	fd 36 12 00 	. 6 . . 
	ld (iy+SCTR),0					; search will start from Sector Number 0						;591d	fd 36 11 00 	. 6 . . 

; -- read Sector from Disk and compare all directory entries
.readNextSector:
	call READ						; Read a sector from disk into iy+SectorBuffer					;5921	cd 27 5b 	. ' [ 
	or a							; was any Error? 												;5924	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine							;5925	c2 41 42 	. A B 

; -- we have sector with disk directory entries - read Directory Entry
	ld b,8							; b - 8 Directory Entries in 1 Sector							;5928	06 08 	. . 
	ld l,(iy+DBFR)																					;592a	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)				; hl - address of Data Buffer with 1st directory entry			;592d	fd 66 32 	. f 2 
	push iy							; iy - DOS base address											;5930	fd e5 	. . 
	pop de							; copy to de register											;5932	d1 	. 
	inc de							; de + 1 - address of searched filename in DOS base structure	;5933	13 	. 
.compareEntry:
	ld a,(hl)						; a - 1st char from disk - fileType								;5934	7e 	~ 
	or a							; is it 0? - no more directory entries in data					;5935	b7 	. 
	ret z							; yes - ------------ End of Proc (No Error) -------------------	;5936	c8 	. 

; -- filetype other than 0
	push de							; save de - address of filename to find (to compare)			;5937	d5 	. 
	push hl							; save hl - address in Data Buffer of directory entry			;5938	e5 	. 
	cp 1							; is filetype = 1 (deleted file entry)							;5939	fe 01 	. . 
	jr z,.nextDirEntry				; yes - get next directory entry								;593b	28 16 	( . 
; -- filetype other than 0 or 1
	ld (iy+TYPE+1),a				; store filetype in filetype field of DOS structure (2nd byte)	;593d	fd 77 0a 	. w . 
	inc hl							; skip 1 byte from Data Buffer (that will be ':')				;5940	23 	# 
	inc hl							; hl - points to filename chars in Data Buffer					;5941	23 	# 


; -- compare if filename from Data Buffer (entry) equals searched fileane
	ld c,8							; c - max 8 chars of filename									;5942	0e 08 	. . 
	ex de,hl						; de - address in Data Buffer, hl - address in DOS structure	;5944	eb 	. 
.compareNextChar:
	ld a,(de)						; a - char of filename to find									;5945	1a 	. 
	cp (hl)							; is it equal to char of filename from Disk?					;5946	be 	. 
	jr nz,.nextDirEntry				; no - skip to next Directory Entry								;5947	20 0a 	  . 
	inc hl							; yes - point to next char from Disk							;5949	23 	# 
	inc de							; de - point to next char of filename to find					;594a	13 	. 
	dec c							; decrement chars to compare counter - all compared?			;594b	0d 	. 
	jr nz,.compareNextChar			; no - continute to compare all 8 chars							;594c	20 f7 	  . 
; -- filenames match
	pop af							; discard (hl) from Stack Pointer								;594e	f1 	. 
	pop af							; discard (de) from Stack Pointer								;594f	f1 	. 
	ld a,2							; a - Error 02 - FILE ALREADY EXISTS							;5950	3e 02 	> . 
	ret								; ------------------ End of Proc (with Error 02) --------------	;5952	c9 	. 
.nextDirEntry:
; -- deleted file 
	pop hl							; restore hl - address in Data Buffer of directory entry		;5953	e1 	. 
	ld de,16						; de - 16 bytes per directory entry 							;5954	11 10 00 	. . . 
	add hl,de						; hl - point to next entry										;5957	19 	. 
	pop de							; restore de - address of filename to find (to compare)			;5958	d1 	. 
	djnz .compareEntry				; continue to compare all 8 dir entries in this Sector			;5959	10 d9 	. . 

; -- all 8 entries compared - read next Sector 
	inc (iy+SCTR)					; increment Sector number (track still 0) to read				;595b	fd 34 11 	. 4 . 
	ld a,(iy+SCTR)					; a - next sector number										;595e	fd 7e 11 	. ~ . 
	cp 15							; is it 15? - end of disk directory (only 14 sectors) 			;5961	fe 0f 	. . 
	jr nz,.readNextSector			; no - continure to search all 14 sectors						;5963	20 bc 	  . 

; -- all 14 sectors scaned 
	ld a,13							; a - Error 13 - FILE NOT FOUND									;5965	3e 0d 	> . 
	ret								; ------------------ End of Proc (with Error 13) --------------	;5967	c9 	. 





;***************************************************************************************************
; Search for an empty space in the directory.
;---------------------------------------------------------------------------------------------------
; IN: Interrupt disabled.
; OUT: a - Error Code
;      hl - address od first empty directory entry (in Data Buffer)
;      (iy+SCTR) - sector with empty entry (already loaded to Data Buf)
;      (iy+TRCK) - track where is sector with empty entry (already loaded to Data Buf)
;***************************************************************************************************
FIND:
; -- setup starting condition: data buffer, track and sector number 
	ld l,(iy+DBFR)					; hl - address of DOS Data Buffer								;5968	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)																				;596b	fd 66 32 	. f 2 
	ld (iy+TRCK),0					; search will start from Track Number 0							;596e	fd 36 12 00 	. 6 . . 
	ld (iy+SCTR),0					; search will start from Sector Number 0						;5972	fd 36 11 00 	. 6 . . 

; -- read Sector from Disk and find first empty place for directory entry
.readNextSector:
	call READ						; Read a sector from disk into iy+SectorBuffer					;5976	cd 27 5b 	. ' [ 
	or a							; was any Error? 												;5979	b7 	. 
	jp nz,ERROR						; yes - go to Error handling routine							;597a	c2 41 42 	. A B 

; -- we have sector with disk directory entries - read Directory Entry
	ld b,8							; b - 8 Directory Entries in one Sector							;597d	06 08 	. . 
	ld l,(iy+DBFR)																					;597f	fd 6e 31 	. n 1 
	ld h,(iy+DBFR+1)				; hl - address of Data Buffer with 1st directory/file entry		;5982	fd 66 32 	. f 2 
.checkDirEntry:
	ld a,(hl)						; a - 1st char from disk - fileType								;5985	7e 	~ 
	or a							; is it 0? - no more directory entries in data					;5986	b7 	. 
	ret z							; yes - ------------ End of Proc (No Error) -------------------	;5987	c8 	. 

; -- filetype other than 0	
	cp 1							; is filetype = 1 (deleted file entry)?							;5988	fe 01 	. . 
	jr nz,.nextDirEntry				; no - get next directory entry									;598a	20 02 	  . 
; -- deleted file entry - we can reuse it - return with No Error
	xor a							; a - Error 00 - NO ERROR										;598c	af 	. 
	ret								; ------------------ End of Proc (No Error) -------------------	;598d	c9 	. 

.nextDirEntry:
	ld de,16						; de - 16 bytes per directory entry 							;598e	11 10 00 	. . . 
	add hl,de						; hl - point to next entry										;5991	19 	. 
	djnz .checkDirEntry				; continue to check all 8 dir entries in this Sector			;5992	10 f1 	. . 

; -- all 8 entries checked - read next Sector 
	inc (iy+SCTR)					; increment Sector number (track still 0) to read				;5994	fd 34 11 	. 4 . 
	ld a,(iy+SCTR)					; a - next sector number										;5997	fd 7e 11 	. ~ . 
	cp 15							; is it 15? - end of disk directory (only 14 sectors) 			;599a	fe 0f 	. . 
	jr nz,.readNextSector			; no - continure to search all 14 sectors						;599c	20 d8 	  . 

; -- all 14 sectors scaned 
	ld a,3							; a - Error 03 - DIRECTORY FULL									;599e	3e 03 	> . 
	ret								; ---------------- End of Proc (with Error) -------------------	;59a0	c9 	. 



;***************************************************************************************************
; Write sector to disk.
;---------------------------------------------------------------------------------------------------
; Write the content of the buffer pointed to by iy+DBFR to the track and sector 
; specified by user.
; IN: (iy+TRCK) - track number
;     (iy+SCTR) - sector number
;     (iy+DBFR) - address of 128 bytes buffer with data to write
; OUT: a - Error code
;***************************************************************************************************
WRITE:
; -- calculate CRC
	call CalcSectorCRC				; Calculate Sector Checksum and sore in de register				;59a1	cd 10 5b 	. . [ 
	push de							; save de - calculated Checksum of Sector data					;59a4	d5 	. 

; -- store Checksum into Sector Buffer  
	push iy							; iy - DOS base address											;59a5	fd e5 	. . 
	pop hl							; copy to hl													;59a7	e1 	. 
	ld de,SectorCRCBuf				; de - offset where CRC to be stored (just after sector data)	;59a8	11 cd 00 	. . . 
	add hl,de						; hl - address in Sector Buffer to store Checksum 				;59ab	19 	. 
	pop de							; restore de - calculated Checksum of Sector data				;59ac	d1 	. 
	ld (hl),e						; store LSB of Checksum											;59ad	73 	s 
	inc hl							; hl - points to MSB											;59ae	23 	# 
	ld (hl),d						; store MSB of Checksum											;59af	72 	r 

; -- find sector to write to and set ready to write data
	push iy							; iy - DOS base address											;59b0	fd e5 	. . 
	pop hl							; copy to hl													;59b2	e1 	. 
	ld de,SectorHeader				; de - offset to Sector Header bytes							;59b3	11 43 00 	. C . 
	add hl,de						; hl - address of Sector Header bytes							;59b6	19 	. 
	ld b,10+128+2					; 10 bytes GAP2+IDAM, 128 bytes Sector Data, 2 bytes CRC		;59b7	06 8c 	. . 
	exx								; save bc,de,hl to alternate registers							;59b9	d9 	. 
	call IDAM			; Read identification address mark (Disk head on start sector)	;59ba	cd ea 53 	. . S 
	jp z,.setWriteReqActive			; 0 - no error - set Write Request and continue					;59bd	ca c6 59 	. . Y 

; -- we have Error - was it canceled by user (pressing Break Key)?
	cp 17							; was it Error 17 - BREAK?										;59c0	fe 11 	. . 
	ret z							; yes -------------- End of Proc (with Error) -----------------	;59c2	c8 	. 

; -- other error - return with Error 9 - SECTOR NOT FOUND
	ld a,9							; a - Error 9 - SECTOR NOT FOUND								;59c3	3e 09 	> . 
	ret								; ------------------ End of Proc (with Error) -----------------	;59c5	c9 	. 


.setWriteReqActive:
	exx								; restore bc,de,hl from alternate registers						;59c6	d9 	. 
; -- set Write Request bit in hardware Floppy Control Register
	ld d,(iy+LTHCPY)				; d - last value sent to FLCtrl									;59c7	fd 56 33 	. V 3 
	res 6,d							; clear bit 6 - Write Request (active)							;59ca	cb b2 	. . 
	ld a,d							; a - new value of Control bits									;59cc	7a 	z 
	out (FLCTRL),a					; set Write Request Bit to 0 (active)							;59cd	d3 10 	. . 

; --------------------------------------------------------------------------------------------------
; IN: b - number of bytes to write
;     d - backed up value sent to FDC Control Register
;     hl - pointer to current byte in Copy Buffer
WR_WriteByte:
	ld c,(hl)						; c - byte from buffer to send		 							;59cf	4e 	N 

; -- write bit 7 of data byte	
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;59d0	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;59d2	aa 	. 
; -- set CY flag to bit 7 of data byte
	rl c							; Carry flag = bit 7 of data byte - is it 1?					;59d3	cb 11 	. . 
	jp nc,.writeBit7_0				; no - write cell with data bit = 0								;59d5	d2 e3 59 	. . Y 
.writeBit7_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;59d8	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;59da	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;59dc	57 	W 
	dec hl							; delay 6 cycles												;59dd	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;59de	d3 10 	. . 
	jp .contBit7					; continue with next bit 6										;59e0	c3 ee 59 	. . Y 
.writeBit7_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;59e3	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;59e5	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;59e7	57 	W 
	dec hl							; delay 6 cycles												;59e8	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;59e9	d3 10 	. . 
	jp .contBit7					; continue with next bit 6										;59eb	c3 ee 59 	. . Y 
.contBit7:
	inc hl							; delay 6 cycles												;59ee	23 	# 
	jp .delayBit7					; delay 10 cycles												;59ef	c3 f2 59 	. . Y 
.delayBit7:
	jp .writeBit6Cell				; delay 10 cycles												;59f2	c3 f5 59 	. . Y 

.writeBit6Cell:
; -- write bit 6 of data byte	
	in a,(FLPOOL)					; send clock to drive controller								;59f5	db 12 	. . 
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;59f7	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;59f9	aa 	. 
; -- set CY flag to bit 6 of data byte
	rl c							; Carry flag = bit 6 of data byte - is it 1?					;59fa	cb 11 	. . 
	jp nc,.writeBit6_0				; no - write cell with data bit = 0								;59fc	d2 0a 5a 	. . Z 
.writeBit6_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;59ff	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;5a01	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;5a03	57 	W 
	dec hl							; delay 6 cycles												;5a04	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;5a05	d3 10 	. . 
	jp .contBit6					; continue with next bit 5										;5a07	c3 15 5a 	. . Z 
.writeBit6_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;5a0a	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;5a0c	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;5a0e	57 	W 
	dec hl							; delay 6 cycles												;5a0f	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;5a10	d3 10 	. . 
	jp .contBit6					; continue with next bit 5										;5a12	c3 15 5a 	. . Z 
.contBit6:
	inc hl							; delay 6 cycles												;5a15	23 	# 
	jp .delayBit6					; delay 10 cycles												;5a16	c3 19 5a 	. . Z 
.delayBit6:
	jp .writeBit5Cell				; delay 10 cycles												;5a19	c3 1c 5a 	. . Z 

.writeBit5Cell:
; -- write bit 5 of data byte	
	in a,(FLPOOL)					; send clock to drive controller								;5a1c	db 12 	. . 
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;5a1e	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;5a20	aa 	. 
; -- set CY flag to bit 5 of data byte
	rl c							; Carry flag = bit 5 of data byte - is it 1?					;5a21	cb 11 	. . 
	jp nc,.writeBit5_0				; no - write cell with data bit = 0								;5a23	d2 31 5a 	. 1 Z 
.writeBit5_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;5a26	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;5a28	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;5a2a	57 	W 
	dec hl							; delay 6 cycles												;5a2b	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;5a2c	d3 10 	. . 
	jp .contBit5					; continue with next bit 4										;5a2e	c3 3c 5a 	. < Z 
.writeBit5_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;5a31	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;5a33	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;5a35	57 	W 
	dec hl							; delay 6 cycles												;5a36	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;5a37	d3 10 	. . 
	jp .contBit5					; continue with next bit 4										;5a39	c3 3c 5a 	. < Z 
.contBit5:
	inc hl							; delay 6 cycles												;5a3c	23 	# 
	jp .delayBit5					; delay 10 cycles												;5a3d	c3 40 5a 	. @ Z 
.delayBit5:
	jp .writeBit4Cell				; delay 10 cycles												;5a40	c3 43 5a 	. C Z 

.writeBit4Cell:
; -- write bit 4 of data byte	
	in a,(FLPOOL)					; send clock to drive controller								;5a43	db 12 	. . 
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;5a45	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;5a47	aa 	. 
; -- set CY flag to bit 4 of data byte
	rl c							; Carry flag = bit 4 of data byte - is it 1?					;5a48	cb 11 	. . 
	jp nc,.writeBit4_0				; no - write cell with data bit = 0								;5a4a	d2 58 5a 	. X Z 
.writeBit4_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;5a4d	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;5a4f	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;5a51	57 	W 
	dec hl							; delay 6 cycles												;5a52	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;5a53	d3 10 	. . 
	jp .contBit4					; continue with next bit 3										;5a55	c3 63 5a 	. c Z 
.writeBit4_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;5a58	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;5a5a	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;5a5c	57 	W 
	dec hl							; delay 6 cycles												;5a5d	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;5a5e	d3 10 	. . 
	jp .contBit4					; continue with next bit 3										;5a60	c3 63 5a 	. c Z 
.contBit4:
	inc hl							; delay 6 cycles												;5a63	23 	# 
	jp .delayBit4					; delay 10 cycles												;5a64	c3 67 5a 	. g Z 
.delayBit4:
	jp .writeBit3Cell				; delay 10 cycles												;5a67	c3 6a 5a 	. j Z 

.writeBit3Cell:
; -- write bit 3 of data byte	
	in a,(FLPOOL)					; send clock to drive controller								;5a6a	db 12 	. . 
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;5a6c	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;5a6e	aa 	. 
; -- set CY flag to bit 3 of data byte
	rl c							; Carry flag = bit 3 of data byte - is it 1?					;5a6f	cb 11 	. . 
	jp nc,.writeBit3_0				; no - write cell with data bit = 0								;5a71	d2 7f 5a 	.  Z 
.writeBit3_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;5a74	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;5a76	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;5a78	57 	W 
	dec hl							; delay 6 cycles												;5a79	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;5a7a	d3 10 	. . 
	jp .contBit3					; continue with next bit 2										;5a7c	c3 8a 5a 	. . Z 
.writeBit3_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;5a7f	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;5a81	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;5a83	57 	W 
	dec hl							; delay 6 cycles												;5a84	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;5a85	d3 10 	. . 
	jp .contBit3					; continue with next bit 2										;5a87	c3 8a 5a 	. . Z 
.contBit3:
	inc hl							; delay 6 cycles												;5a8a	23 	# 
	jp .delayBit3					; delay 10 cycles												;5a8b	c3 8e 5a 	. . Z 
.delayBit3:
	jp .writeBit2Cell				; delay 10 cycles												;5a8e	c3 91 5a 	. . Z 

.writeBit2Cell:
; -- write bit 2 of data byte	
	in a,(FLPOOL)					; send clock to drive controller								;5a91	db 12 	. . 
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;5a93	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;5a95	aa 	. 
; -- set CY flag to bit 2 of data byte
	rl c							; Carry flag = bit 2 of data byte - is it 1?					;5a96	cb 11 	. . 
	jp nc,.writeBit2_0				; no - write cell with data bit = 0								;5a98	d2 a6 5a 	. . Z 
.writeBit2_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;5a9b	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;5a9d	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;5a9f	57 	W 
	dec hl							; delay 6 cycles												;5aa0	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;5aa1	d3 10 	. . 
	jp .contBit2					; continue with next bit 1										;5aa3	c3 b1 5a 	. . Z 
.writeBit2_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;5aa6	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;5aa8	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;5aaa	57 	W 
	dec hl							; delay 6 cycles												;5aab	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;5aac	d3 10 	. . 
	jp .contBit2					; continue with next bit 1										;5aae	c3 b1 5a 	. . Z 
.contBit2:
	inc hl							; delay 6 cycles												;5ab1	23 	# 
	jp .delayBit2					; delay 10 cycles												;5ab2	c3 b5 5a 	. . Z 
.delayBit2:
	jp .writeBit1Cell				; delay 10 cycles												;5ab5	c3 b8 5a 	. . Z 

.writeBit1Cell:
; -- write bit 1 of data byte	
	in a,(FLPOOL)					; send clock to drive controller								;5ab8	db 12 	. . 
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;5aba	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;5abc	aa 	. 
; -- set CY flag to bit 1 of data byte
	rl c							; Carry flag = bit 1 of data byte - is it 1?					;5abd	cb 11 	. . 
	jp nc,.writeBit1_0				; no - write cell with data bit = 0								;5abf	d2 cd 5a 	. . Z 
.writeBit1_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;5ac2	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;5ac4	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;5ac6	57 	W 
	dec hl							; delay 6 cycles												;5ac7	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;5ac8	d3 10 	. . 
	jp .contBit1					; continue with next bit 0										;5aca	c3 d8 5a 	. . Z 
.writeBit1_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;5acd	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;5acf	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;5ad1	57 	W 
	dec hl							; delay 6 cycles												;5ad2	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;5ad3	d3 10 	. . 
	jp .contBit1					; continue with next bit 0										;5ad5	c3 d8 5a 	. . Z 
.contBit1:
	inc hl							; delay 6 cycles												;5ad8	23 	# 
	jp .delayBit1					; delay 10 cycles												;5ad9	c3 dc 5a 	. . Z 
.delayBit1:
	jp .writeBit0Cell				; delay 10 cycles												;5adc	c3 df 5a 	. . Z 

.writeBit0Cell:
; -- write bit 0 of data byte	
	in a,(FLPOOL)					; send clock to drive controller								;5adf	db 12 	. . 
	ld a,FL_WRITE_DATA				; bit 5 (Write Data) to toggle 									;5ae1	3e 20 	>   
	xor d							; invert last sent Write Data Bit (0->1 or 1>0)					;5ae3	aa 	. 
; -- set CY flag to bit 0 of data byte
	rl c							; Carry flag = bit 0 of data byte - is it 1?					;5ae4	cb 11 	. . 
	jp nc,.writeBit0_0				; no - write cell with data bit = 0								;5ae6	d2 f4 5a 	. . Z 
.writeBit0_1:
; -- write cell with bit=1 - 0-1 or 1-0
	out (FLCTRL),a					; set Write Data Bit 											;5ae9	d3 10 	. . 
	xor FL_WRITE_DATA				; toggle bit 5 (Write Data 0->1 or 1->0)						;5aeb	ee 20 	.   
	ld d,a							; save as last value sent to FLCTRL								;5aed	57 	W 
	dec hl							; delay 6 cycles												;5aee	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit 											;5aef	d3 10 	. . 
	jp .nextByte					; continue with next byte										;5af1	c3 ff 5a 	. . Z 
.writeBit0_0:
; -- write cell with bit=0 - 0-0 or 1-1
	out (FLCTRL),a					; set Write Data Bit 											;5af4	d3 10 	. . 
	xor %00000000					; no change of Write Data Bit (0->0) (delay 7 cycles)			;5af6	ee 00 	. . 
	ld d,a							; save as last value sent to FLCTRL								;5af8	57 	W 
	dec hl							; delay 6 cycles												;5af9	2b 	+ 
	out (FLCTRL),a					; set Write Data Bit (unchanged)								;5afa	d3 10 	. . 
	jp .nextByte					; continue with next byte										;5afc	c3 ff 5a 	. . Z 

.nextByte:
	inc hl							; hl was decremented previously									;5aff	23 	# 
	inc hl							; hl - address of next byte in buffer							;5b00	23 	# 
	nop								; delay 4 cycles												;5b01	00 	. 
	dec b							; decrement bytes-to-send counter								;5b02	05 	. 
	jp nz,WR_WriteByte				; continue to write all 140 bytes do Disk						;5b03	c2 cf 59 	. . Y 

; -- reset Wriite Request bit and update FLCtrl shadow
	set 6,d							; set bit 6 - Write Request (inactive)							;5b06	cb f2 	. . 
	ld a,d							; a - new value of FDC Conntrol Register						;5b08	7a 	z 
	out (FLCTRL),a					; set Flopy Control byte										;5b09	d3 10 	. . 
	ld (iy+LTHCPY),a				; store FLCtrl to shadow register								;5b0b	fd 77 33 	. w 3 

; -- return with No Error
	xor a							; a - Error 0 - NO ERROR										;5b0e	af 	. 
	ret								; ------------------- End of Proc -----------------------------	;5b0f	c9 	. 


;***************************************************************************************************
; Calculate Sector Checksum and sore in de register
; It is a 16bit sum of 128 bytes stored in Sector Buffer
; IN: (iy+SectorBuffer) - 128 bytes of data 
; OUT: de - calculated checksum
CalcSectorCRC:
; -- setup address of data to calculate checksum
	push iy							; iy - DOS base address											;5b10	fd e5 	. . 
	pop hl							; copy to hl register											;5b12	e1 	. 
	ld de,SectorBuffer				; de offset from DOS base to Buffer with Sector data			;5b13	11 4d 00 	. M . 
	add hl,de						; hl - address of first byte in Sector Buffer					;5b16	19 	. 
; -- just get first byte - no point to add it to 0
	ld e,(hl)						; e - low byte of checksum of first byte						;5b17	5e 	^ 
	ld d,$00						; de - checksum of first byte									;5b18	16 00 	. . 
	ld b,128-1						; number of bytes to add to checksum (1 added already)			;5b1a	06 7f 	.  
.addNext:
	inc hl							; hl - points to next byte in Sector Buffer						;5b1c	23 	# 
; -- 16 bit addition of de and byte
	ld a,e							; a - low byte of checksum										;5b1d	7b 	{ 
	add a,(hl)						; add byte from buffer											;5b1e	86 	. 
	ld e,a							; store back to e register										;5b1f	5f 	_ 
	ld a,0							; a - high byte to add											;5b20	3e 00 	> . 
	adc a,d							; add Carry flag from adding low bytes							;5b22	8a 	. 
	ld d,a							; de - checksum new value										;5b23	57 	W 
	djnz .addNext					; continue until 127 bytes added								;5b24	10 f6 	. . 
	ret								; ----------------------- End of Proc -------------------------	;5b26	c9 	. 




;***************************************************************************************************
; Read sector from disk
;---------------------------------------------------------------------------------------------------
; Read the content of specified Sector on specified Track into DOS Data Buffer
; IN: (iy+TRCK) - Track number to read
;     (iy+SCTR) - Sector number to read
;	  (iy+DBFR) - address of 128 byte buffer to store sector
;     interrupt disabled
; OUT: a - Error Code
;***************************************************************************************************
READ:
; -- set number of tries
	ld (iy+RETRY),10				; try to read sector max 10 times								;5b27	fd 36 13 0a 	. 6 . . 
RD_StartRead:
	call IDAM						; find and Read IDAM header for requested Sector				;5b2b	cd ea 53 	. . S 
	jp z,.sectorFound				; if 0 (No Error) continue to read Sector Data					;5b2e	ca 37 5b 	. 7 [ 

; -- can't find or read specified Sector
	cp 17							; was it BREAK error (canceled by user)?						;5b31	fe 11 	. . 
	ret z							; yes -------------- End of Proc (with Error 17) --------------	;5b33	c8 	. 
; -- other error - return with SECTOR NOT FOUND Error
	ld a,9							; a - Error 09 - SECTOR NOT FOUND								;5b34	3e 09 	> . 
	ret								; ------------------ End of Proc (with Error 09) --------------	;5b36	c9 	. 


.sectorFound:
; -- set destination address to store Sector data of destination 
	push iy							; iy - DOS base address											;5b37	fd e5 	. . 
	pop hl							; copy to hl 													;5b39	e1 	. 
	ld de,SectorBuffer-1			; add offset from DOS base to Sector Buffer -1					;5b3a	11 4c 00 	. L . 
	add hl,de						; hl - points to byte just before Sector Buffer memory			;5b3d	19 	. 
; -- set number of bytes to read - 128 bytes Sector data, 2 bytes Data Checksum, 1 - ???
	ld e,128+3						; e - number of bytes to read from Disk (128 + 2 + 1)			;5b3e	1e 83 	. . 
	jr RD_ReadyRead					; wait for Clock Bit and synchronize to byte 80					;5b40	18 03 	. . 

RD_BreakExit:
	jp WaitBreakKeyReleased			; Wait for Break key released									;5b42	c3 a4 5e 	. . ^ 

RD_ReadyRead:
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;5b45	db 11 	. . 
.waitClockBit:
	in a,(c)						; read Clock Bit from Flopy Drive								;5b47	ed 78 	. x 
	jp p,.waitClockBit				; wait until Clock BIt = 1										;5b49	f2 47 5b 	. G [ 
	nop								; delay 4 clock cycles											;5b4c	00 	. 
	nop								; delay 4 clock cycles											;5b4d	00 	. 
	nop								; delay 4 clock cycles											;5b4e	00 	. 
	nop								; delay 4 clock cycles											;5b4f	00 	. 


;***************************************************************************************************
; Find GAP2
; Read incomming bistream from Floppy Disk until $80 value is found or BREAK key pressed
; NOTE: In order to read 1 byte from FDC we have to read FLDATA register 8 times (bit by bit)
;       FLDATA hardware register will be shifted every time we read it.

; ---------- [1] --- read bits from Disk until $80 received

RD_WaitFor80:
; -- test if BREAK key is pressed
	ld a,(BreakKeybRow)				; read Keyboard Row with BREAK key								;5b50	3a df 68 	: . h 
	and BreakKeybMask				; mask only BREAK key - if 0 -> key is pressed					;5b53	e6 04 	. . 
	jr z,RD_BreakExit				; yes - exit reading											;5b55	28 eb 	( . 

; -- read data (bit)
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register)				;5b57	db 11 	. . 
	ld b,a							; b - store byte 												;5b59	47 	G 
.waitClockBit:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5b5a	ed 78 	. x 
	jp p,.waitClockBit				; wait until Clock BIt = 1										;5b5c	f2 5a 5b 	. Z [ 
; -- test if we have $80 received
	ld a,b							; byte being received											;5b5f	78 	x 
	cp $80							; is this $80 - GAP2 start sequence								;5b60	fe 80 	. . 
	jp nz,RD_WaitFor80				; no - keep reding until $80 received (or BREAK key pressed)	;5b62	c2 50 5b 	. P [ 

; -- we have $80 received - next byte can be:
; $80 - still GAP2 byte -> keep reading
; other - end of GAP1 -> go to IDAM (ending) sequence read
.readByte:
	nop								; delay 4 clock cycles											;5b65	00 	. 
	nop								; delay 4 clock cycles											;5b66	00 	. 
	nop								; delay 4 clock cycles											;5b67	00 	. 
	ld a,0							; delay 7 clock cycles											;5b68	3e 00 	> . 
	ld a,0							; delay 7 clock cycles	(26 in total)							;5b6a	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;5b6c	db 11 	. . 
.waitClockBit1:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5b6e	ed 78 	. x 
	jp p,.waitClockBit1				; wait until Clock BIt = 1										;5b70	f2 6e 5b 	. n [ 
	dec hl							; delay 6 clock cycles											;5b73	2b 	+ 
	inc hl							; delay 6 clock cycles											;5b74	23 	# 
	dec hl							; delay 6 clock cycles											;5b75	2b 	+ 
	inc hl							; delay 6 clock cycles											;5b76	23 	# 
	dec hl							; delay 6 clock cycles											;5b77	2b 	+ 
	inc hl							; delay 6 clock cycles											;5b78	23 	# 
	nop								; delay 4 clock cycles											;5b79	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5b7a	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 6]		;5b7c	db 11 	. . 
.waitClockBit2:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5b7e	ed 78 	. x 
	jp p,.waitClockBit2				; wait until Clock BIt = 1										;5b80	f2 7e 5b 	. ~ [ 
	dec hl							; delay 6 clock cycles											;5b83	2b 	+ 
	inc hl							; delay 6 clock cycles											;5b84	23 	# 
	dec hl							; delay 6 clock cycles											;5b85	2b 	+ 
	inc hl							; delay 6 clock cycles											;5b86	23 	# 
	dec hl							; delay 6 clock cycles											;5b87	2b 	+ 
	inc hl							; delay 6 clock cycles											;5b88	23 	# 
	nop								; delay 4 clock cycles											;5b89	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5b8a	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 5]		;5b8c	db 11 	. . 
.waitClockBit3:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5b8e	ed 78 	. x 
	jp p,.waitClockBit3				; wait until Clock BIt = 1										;5b90	f2 8e 5b 	. . [ 
	dec hl							; delay 6 clock cycles											;5b93	2b 	+ 
	inc hl							; delay 6 clock cycles											;5b94	23 	# 
	dec hl							; delay 6 clock cycles											;5b95	2b 	+ 
	inc hl							; delay 6 clock cycles											;5b96	23 	# 
	dec hl							; delay 6 clock cycles											;5b97	2b 	+ 
	inc hl							; delay 6 clock cycles											;5b98	23 	# 
	nop								; delay 4 clock cycles											;5b99	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5b9a	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 4]		;5b9c	db 11 	. . 
.waitClockBit4:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5b9e	ed 78 	. x 
	jp p,.waitClockBit4				; wait until Clock BIt = 1										;5ba0	f2 9e 5b 	. . [ 
	dec hl							; delay 6 clock cycles											;5ba3	2b 	+ 
	inc hl							; delay 6 clock cycles											;5ba4	23 	# 
	dec hl							; delay 6 clock cycles											;5ba5	2b 	+ 
	inc hl							; delay 6 clock cycles											;5ba6	23 	# 
	dec hl							; delay 6 clock cycles											;5ba7	2b 	+ 
	inc hl							; delay 6 clock cycles											;5ba8	23 	# 
	nop								; delay 4 clock cycles											;5ba9	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5baa	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 3]		;5bac	db 11 	. . 
.waitClockBit5:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5bae	ed 78 	. x 
	jp p,.waitClockBit5				; wait until Clock BIt = 1										;5bb0	f2 ae 5b 	. . [ 
	dec hl							; delay 6 clock cycles											;5bb3	2b 	+ 
	inc hl							; delay 6 clock cycles											;5bb4	23 	# 
	dec hl							; delay 6 clock cycles											;5bb5	2b 	+ 
	inc hl							; delay 6 clock cycles											;5bb6	23 	# 
	dec hl							; delay 6 clock cycles											;5bb7	2b 	+ 
	inc hl							; delay 6 clock cycles											;5bb8	23 	# 
	nop								; delay 4 clock cycles											;5bb9	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5bba	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 2]		;5bbc	db 11 	. . 
.waitClockBit6:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5bbe	ed 78 	. x 
	jp p,.waitClockBit6				; wait until Clock BIt = 1										;5bc0	f2 be 5b 	. . [ 
	dec hl							; delay 6 clock cycles											;5bc3	2b 	+ 
	inc hl							; delay 6 clock cycles											;5bc4	23 	# 
	dec hl							; delay 6 clock cycles											;5bc5	2b 	+ 
	inc hl							; delay 6 clock cycles											;5bc6	23 	# 
	dec hl							; delay 6 clock cycles											;5bc7	2b 	+ 
	inc hl							; delay 6 clock cycles											;5bc8	23 	# 
	nop								; delay 4 clock cycles											;5bc9	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5bca	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 1]		;5bcc	db 11 	. . 
.waitClockBit7:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5bce	ed 78 	. x 
	jp p,.waitClockBit7				; wait until Clock BIt = 1										;5bd0	f2 ce 5b 	. . [ 
	dec hl							; delay 6 clock cycles											;5bd3	2b 	+ 
	inc hl							; delay 6 clock cycles											;5bd4	23 	# 
	dec hl							; delay 6 clock cycles											;5bd5	2b 	+ 
	inc hl							; delay 6 clock cycles											;5bd6	23 	# 
	dec hl							; delay 6 clock cycles											;5bd7	2b 	+ 
	inc hl							; delay 6 clock cycles											;5bd8	23 	# 
	nop								; delay 4 clock cycles											;5bd9	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in totoal)							;5bda	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 0]		;5bdc	db 11 	. . 
	ld b,a							; store for compare												;5bde	47 	G 
.waitClockBit8:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5bdf	ed 78 	. x 
	jp p,.waitClockBit8				; wait until Clock BIt = 1										;5be1	f2 df 5b 	. . [ 


; -- We have 1 byte read - if 80 then still reading GAP2
	ld a,b							; a - byte from Floppy Disk										;5be4	78 	x 
	cp $80							; is it still $80 - GAP2 sequence byte?							;5be5	fe 80 	. . 
	jp z,.readByte					; yes - read next byte from disk								;5be7	ca 65 5b 	. e [ 

; -- byte from disk is NOT $80 (expected 00 but not verified)



;***************************************************************************************************
;
; Read IDAM (ending) sequence 1st byte - $c3
;

; ---------- [2] --- read byte C3 - fist in IDAM (ending) sequence

RD_IDAM_C3:
	nop								; delay 4 clock cycles											;5bea	00 	. 
	nop								; delay 4 clock cycles											;5beb	00 	. 
	nop								; delay 4 clock cycles											;5bec	00 	. 
	ld a,0							; delay 7 clock cycles											;5bed	3e 00 	> . 
	ld a,0							; delay 7 clock cycles	(26 in total)							;5bef	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;5bf1	db 11 	. . 
.waitClockBit1:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5bf3	ed 78 	. x 
	jp p,.waitClockBit1				; wait until Clock BIt = 1										;5bf5	f2 f3 5b 	. . [ 
	dec hl							; delay 6 clock cycles											;5bf8	2b 	+ 
	inc hl							; delay 6 clock cycles											;5bf9	23 	# 
	dec hl							; delay 6 clock cycles											;5bfa	2b 	+ 
	inc hl							; delay 6 clock cycles											;5bfb	23 	# 
	dec hl							; delay 6 clock cycles											;5bfc	2b 	+ 
	inc hl							; delay 6 clock cycles											;5bfd	23 	# 
	nop								; delay 4 clock cycles											;5bfe	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5bff	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 6]		;5c01	db 11 	. . 
.waitClockBit2:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5c03	ed 78 	. x 
	jp p,.waitClockBit2				; wait until Clock BIt = 1										;5c05	f2 03 5c 	. . \ 
	dec hl							; delay 6 clock cycles											;5c08	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c09	23 	# 
	dec hl							; delay 6 clock cycles											;5c0a	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c0b	23 	# 
	dec hl							; delay 6 clock cycles											;5c0c	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c0d	23 	# 
	nop								; delay 4 clock cycles											;5c0e	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5c0f	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 5]		;5c11	db 11 	. . 
.waitClockBit3:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5c13	ed 78 	. x 
	jp p,.waitClockBit3				; wait until Clock BIt = 1										;5c15	f2 13 5c 	. . \ 
	dec hl							; delay 6 clock cycles											;5c18	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c19	23 	# 
	dec hl							; delay 6 clock cycles											;5c1a	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c1b	23 	# 
	dec hl							; delay 6 clock cycles											;5c1c	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c1d	23 	# 
	nop								; delay 4 clock cycles											;5c1e	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5c1f	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 4]		;5c21	db 11 	. . 
.waitClockBit4:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5c23	ed 78 	. x 
	jp p,.waitClockBit4				; wait until Clock BIt = 1										;5c25	f2 23 5c 	. # \ 
	dec hl							; delay 6 clock cycles											;5c28	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c29	23 	# 
	dec hl							; delay 6 clock cycles											;5c2a	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c2b	23 	# 
	dec hl							; delay 6 clock cycles											;5c2c	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c2d	23 	# 
	nop								; delay 4 clock cycles											;5c2e	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5c2f	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 3]		;5c31	db 11 	. . 
.waitClockBit5:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5c33	ed 78 	. x 
	jp p,.waitClockBit5				; wait until Clock BIt = 1										;5c35	f2 33 5c 	. 3 \ 
	dec hl							; delay 6 clock cycles											;5c38	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c39	23 	# 
	dec hl							; delay 6 clock cycles											;5c3a	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c3b	23 	# 
	dec hl							; delay 6 clock cycles											;5c3c	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c3d	23 	# 
	nop								; delay 4 clock cycles											;5c3e	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5c3f	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 2]		;5c41	db 11 	. . 
.waitClockBit6:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5c43	ed 78 	. x 
	jp p,.waitClockBit6				; wait until Clock BIt = 1										;5c45	f2 43 5c 	. C \ 
	dec hl							; delay 6 clock cycles											;5c48	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c49	23 	# 
	dec hl							; delay 6 clock cycles											;5c4a	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c4b	23 	# 
	dec hl							; delay 6 clock cycles											;5c4c	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c4d	23 	# 
	nop								; delay 4 clock cycles											;5c4e	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5c4f	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 1]		;5c51	db 11 	. . 
.waitClockBit7:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5c53	ed 78 	. x 
	jp p,.waitClockBit7				; wait until Clock BIt = 1										;5c55	f2 53 5c 	. S \ 
	dec hl							; delay 6 clock cycles											;5c58	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c59	23 	# 
	dec hl							; delay 6 clock cycles											;5c5a	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c5b	23 	# 
	dec hl							; delay 6 clock cycles											;5c5c	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c5d	23 	# 
	nop								; delay 4 clock cycles											;5c5e	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5c5f	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 0]		;5c61	db 11 	. . 
	ld b,a							; store for compare												;5c63	47 	G 
.waitClockBit8:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5c64	ed 78 	. x 
	jp p,.waitClockBit8				; wait until Clock BIt = 1										;5c66	f2 64 5c 	. d \ 

; -- We have 1st byte read (expected $c3)

	ld a,b							; a - byte from Floppy Disk										;5c69	78 	x 
	cp $c3							; is it C3 (first byte of IDAM ending)?							;5c6a	fe c3 	. . 
	jp nz,RD_WaitFor80				; no - start over and find byte = $80							;5c6c	c2 50 5b 	. P [ 

;***************************************************************************************************
;
; Read IDAM (ending) sequence 2nd byte - $18
;

; ---------- [3] --- read byte 18 - second in IDAM sequence

RD_IDAM_18:
	nop								; delay 4 clock cycles											;5c6f	00 	. 
	nop								; delay 4 clock cycles											;5c70	00 	. 
	nop								; delay 4 clock cycles											;5c71	00 	. 
	ld a,0							; delay 7 clock cycles											;5c72	3e 00 	> . 
	ld a,0							; delay 7 clock cycles	(26 in total)							;5c74	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;5c76	db 11 	. . 
.waitClockBit1:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5c78	ed 78 	. x 
	jp p,.waitClockBit1				; wait until Clock BIt = 1										;5c7a	f2 78 5c 	. x \ 
	dec hl							; delay 6 clock cycles											;5c7d	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c7e	23 	# 
	dec hl							; delay 6 clock cycles											;5c7f	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c80	23 	# 
	dec hl							; delay 6 clock cycles											;5c81	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c82	23 	# 
	nop								; delay 4 clock cycles											;5c83	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5c84	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 6]		;5c86	db 11 	. . 
.waitClockBit2:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5c88	ed 78 	. x 
	jp p,.waitClockBit2				; wait until Clock BIt = 1										;5c8a	f2 88 5c 	. . \ 
	dec hl							; delay 6 clock cycles											;5c8d	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c8e	23 	# 
	dec hl							; delay 6 clock cycles											;5c8f	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c90	23 	# 
	dec hl							; delay 6 clock cycles											;5c91	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c92	23 	# 
	nop								; delay 4 clock cycles											;5c93	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5c94	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 5]		;5c96	db 11 	. . 
.waitClockBit3:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5c98	ed 78 	. x 
	jp p,.waitClockBit3				; wait until Clock BIt = 1										;5c9a	f2 98 5c 	. . \ 
	dec hl							; delay 6 clock cycles											;5c9d	2b 	+ 
	inc hl							; delay 6 clock cycles											;5c9e	23 	# 
	dec hl							; delay 6 clock cycles											;5c9f	2b 	+ 
	inc hl							; delay 6 clock cycles											;5ca0	23 	# 
	dec hl							; delay 6 clock cycles											;5ca1	2b 	+ 
	inc hl							; delay 6 clock cycles											;5ca2	23 	# 
	nop								; delay 4 clock cycles											;5ca3	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5ca4	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 4]		;5ca6	db 11 	. . 
.waitClockBit4:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5ca8	ed 78 	. x 
	jp p,.waitClockBit4				; wait until Clock BIt = 1										;5caa	f2 a8 5c 	. . \ 
	dec hl							; delay 6 clock cycles											;5cad	2b 	+ 
	inc hl							; delay 6 clock cycles											;5cae	23 	# 
	dec hl							; delay 6 clock cycles											;5caf	2b 	+ 
	inc hl							; delay 6 clock cycles											;5cb0	23 	# 
	dec hl							; delay 6 clock cycles											;5cb1	2b 	+ 
	inc hl							; delay 6 clock cycles											;5cb2	23 	# 
	nop								; delay 4 clock cycles											;5cb3	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5cb4	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 3]		;5cb6	db 11 	. . 
.waitClockBit5:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5cb8	ed 78 	. x 
	jp p,.waitClockBit5				; wait until Clock BIt = 1										;5cba	f2 b8 5c 	. . \ 
	dec hl							; delay 6 clock cycles											;5cbd	2b 	+ 
	inc hl							; delay 6 clock cycles											;5cbe	23 	# 
	dec hl							; delay 6 clock cycles											;5cbf	2b 	+ 
	inc hl							; delay 6 clock cycles											;5cc0	23 	# 
	dec hl							; delay 6 clock cycles											;5cc1	2b 	+ 
	inc hl							; delay 6 clock cycles											;5cc2	23 	# 
	nop								; delay 4 clock cycles											;5cc3	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5cc4	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 2]		;5cc6	db 11 	. . 
.waitClockBit6:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5cc8	ed 78 	. x 
	jp p,.waitClockBit6				; wait until Clock BIt = 1										;5cca	f2 c8 5c 	. . \ 
	dec hl							; delay 6 clock cycles											;5ccd	2b 	+ 
	inc hl							; delay 6 clock cycles											;5cce	23 	# 
	dec hl							; delay 6 clock cycles											;5ccf	2b 	+ 
	inc hl							; delay 6 clock cycles											;5cd0	23 	# 
	dec hl							; delay 6 clock cycles											;5cd1	2b 	+ 
	inc hl							; delay 6 clock cycles											;5cd2	23 	# 
	nop								; delay 4 clock cycles											;5cd3	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5cd4	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 1]		;5cd6	db 11 	. . 
.waitClockBit7:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5cd8	ed 78 	. x 
	jp p,.waitClockBit7				; wait until Clock BIt = 1										;5cda	f2 d8 5c 	. . \ 
	dec hl							; delay 6 clock cycles											;5cdd	2b 	+ 
	inc hl							; delay 6 clock cycles											;5cde	23 	# 
	dec hl							; delay 6 clock cycles											;5cdf	2b 	+ 
	inc hl							; delay 6 clock cycles											;5ce0	23 	# 
	dec hl							; delay 6 clock cycles											;5ce1	2b 	+ 
	inc hl							; delay 6 clock cycles											;5ce2	23 	# 
	nop								; delay 4 clock cycles											;5ce3	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5ce4	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 0]		;5ce6	db 11 	. . 
	ld b,a							; store for compare												;5ce8	47 	G 
.waitClockBit8:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5ce9	ed 78 	. x 
	jp p,.waitClockBit8				; wait until Clock BIt = 1										;5ceb	f2 e9 5c 	. . \ 

; -- We have 2nd byte read (expected $18)

	ld a,b							; a - byte from Floppy Disk										;5cee	78 	x 
	cp $18							; is it 18 (second byte of IDAM ending)?						;5cef	fe 18 	. . 
	jp nz,READ						; no - start over and Read a sector from disk					;5cf1	c2 27 5b 	. ' [ 


;***************************************************************************************************
;
; Read IDAM (ending) sequence 3rd byte - $E7
;

; ---------- [4] --- read byte E7 - third in IDAM (ending) sequence

RD_IDAM_E7:
	nop								; delay 4 clock cycles											;5cf4	00 	. 
	nop								; delay 4 clock cycles											;5cf5	00 	. 
	nop								; delay 4 clock cycles											;5cf6	00 	. 
	ld a,0							; delay 7 clock cycles											;5cf7	3e 00 	> . 
	ld a,0							; delay 7 clock cycles	(26 in total)							;5cf9	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;5cfb	db 11 	. . 
.waitClockBit1:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5cfd	ed 78 	. x 
	jp p,.waitClockBit1				; wait until Clock BIt = 1										;5cff	f2 fd 5c 	. . \ 
	dec hl							; delay 6 clock cycles											;5d02	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d03	23 	# 
	dec hl							; delay 6 clock cycles											;5d04	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d05	23 	# 
	dec hl							; delay 6 clock cycles											;5d06	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d07	23 	# 
	nop								; delay 4 clock cycles											;5d08	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5d09	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 6]		;5d0b	db 11 	. . 
.waitClockBit2:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5d0d	ed 78 	. x 
	jp p,.waitClockBit2				; wait until Clock BIt = 1										;5d0f	f2 0d 5d 	. . ] 
	dec hl							; delay 6 clock cycles											;5d12	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d13	23 	# 
	dec hl							; delay 6 clock cycles											;5d14	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d15	23 	# 
	dec hl							; delay 6 clock cycles											;5d16	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d17	23 	# 
	nop								; delay 4 clock cycles											;5d18	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5d19	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 5]		;5d1b	db 11 	. . 
.waitClockBit3:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5d1d	ed 78 	. x 
	jp p,.waitClockBit3				; wait until Clock BIt = 1										;5d1f	f2 1d 5d 	. . ] 
	dec hl							; delay 6 clock cycles											;5d22	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d23	23 	# 
	dec hl							; delay 6 clock cycles											;5d24	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d25	23 	# 
	dec hl							; delay 6 clock cycles											;5d26	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d27	23 	# 
	nop								; delay 4 clock cycles											;5d28	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5d29	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 4]		;5d2b	db 11 	. . 
.waitClockBit4:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5d2d	ed 78 	. x 
	jp p,.waitClockBit4				; wait until Clock BIt = 1										;5d2f	f2 2d 5d 	. - ] 
	dec hl							; delay 6 clock cycles											;5d32	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d33	23 	# 
	dec hl							; delay 6 clock cycles											;5d34	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d35	23 	# 
	dec hl							; delay 6 clock cycles											;5d36	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d37	23 	# 
	nop								; delay 4 clock cycles											;5d38	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5d39	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 3]		;5d3b	db 11 	. . 
.waitClockBit5:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5d3d	ed 78 	. x 
	jp p,.waitClockBit5				; wait until Clock BIt = 1										;5d3f	f2 3d 5d 	. = ] 
	dec hl							; delay 6 clock cycles											;5d42	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d43	23 	# 
	dec hl							; delay 6 clock cycles											;5d44	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d45	23 	# 
	dec hl							; delay 6 clock cycles											;5d46	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d47	23 	# 
	nop								; delay 4 clock cycles											;5d48	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5d49	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 2]		;5d4b	db 11 	. . 
.waitClockBit6:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5d4d	ed 78 	. x 
	jp p,.waitClockBit6				; wait until Clock BIt = 1										;5d4f	f2 4d 5d 	. M ] 
	dec hl							; delay 6 clock cycles											;5d52	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d53	23 	# 
	dec hl							; delay 6 clock cycles											;5d54	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d55	23 	# 
	dec hl							; delay 6 clock cycles											;5d56	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d57	23 	# 
	nop								; delay 4 clock cycles											;5d58	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5d59	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 1]		;5d5b	db 11 	. . 
.waitClockBit7:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5d5d	ed 78 	. x 
	jp p,.waitClockBit7				; wait until Clock BIt = 1										;5d5f	f2 5d 5d 	. ] ] 
	dec hl							; delay 6 clock cycles											;5d62	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d63	23 	# 
	dec hl							; delay 6 clock cycles											;5d64	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d65	23 	# 
	dec hl							; delay 6 clock cycles											;5d66	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d67	23 	# 
	nop								; delay 4 clock cycles											;5d68	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5d69	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 0]		;5d6b	db 11 	. . 
	ld b,a							; store for compare												;5d6d	47 	G 
.waitClockBit8:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5d6e	ed 78 	. x 
	jp p,.waitClockBit8				; wait until Clock BIt = 1										;5d70	f2 6e 5d 	. n ] 

; -- We have 3rd byte read (expected $e7)

	ld a,b							; a - byte from Floppy Disk										;5d73	78 	x 
	cp $e7							; is it E7 (third byte of IDAM ending)?							;5d74	fe e7 	. . 
	jp nz,READ						; no - start over and Read a sector from disk					;5d76	c2 27 5b 	. ' [ 

;***************************************************************************************************
;
; Read IDAM (ending) sequence 4th byte - $FE
;

; ---------- [5] --- read byte FE - forth in IDAM (ending) sequence

RD_IDAM_FE:
	nop								; delay 4 clock cycles											;5d79	00 	. 
	nop								; delay 4 clock cycles											;5d7a	00 	. 
	nop								; delay 4 clock cycles											;5d7b	00 	. 
	ld a,0							; delay 7 clock cycles											;5d7c	3e 00 	> . 
	ld a,0							; delay 7 clock cycles	(26 in total)							;5d7e	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;5d80	db 11 	. . 
.waitClockBit1:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5d82	ed 78 	. x 
	jp p,.waitClockBit1				; wait until Clock BIt = 1										;5d84	f2 82 5d 	. . ] 
	dec hl							; delay 6 clock cycles											;5d87	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d88	23 	# 
	dec hl							; delay 6 clock cycles											;5d89	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d8a	23 	# 
	dec hl							; delay 6 clock cycles											;5d8b	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d8c	23 	# 
	nop								; delay 4 clock cycles											;5d8d	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5d8e	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 6]		;5d90	db 11 	. . 
.waitClockBit2:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5d92	ed 78 	. x 
	jp p,.waitClockBit2				; wait until Clock BIt = 1										;5d94	f2 92 5d 	. . ] 
	dec hl							; delay 6 clock cycles											;5d97	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d98	23 	# 
	dec hl							; delay 6 clock cycles											;5d99	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d9a	23 	# 
	dec hl							; delay 6 clock cycles											;5d9b	2b 	+ 
	inc hl							; delay 6 clock cycles											;5d9c	23 	# 
	nop								; delay 4 clock cycles											;5d9d	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5d9e	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 5]		;5da0	db 11 	. . 
.waitClockBit3:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5da2	ed 78 	. x 
	jp p,.waitClockBit3				; wait until Clock BIt = 1										;5da4	f2 a2 5d 	. . ] 
	dec hl							; delay 6 clock cycles											;5da7	2b 	+ 
	inc hl							; delay 6 clock cycles											;5da8	23 	# 
	dec hl							; delay 6 clock cycles											;5da9	2b 	+ 
	inc hl							; delay 6 clock cycles											;5daa	23 	# 
	dec hl							; delay 6 clock cycles											;5dab	2b 	+ 
	inc hl							; delay 6 clock cycles											;5dac	23 	# 
	nop								; delay 4 clock cycles											;5dad	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5dae	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 4]		;5db0	db 11 	. . 
.waitClockBit4:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5db2	ed 78 	. x 
	jp p,.waitClockBit4				; wait until Clock BIt = 1										;5db4	f2 b2 5d 	. . ] 
	dec hl							; delay 6 clock cycles											;5db7	2b 	+ 
	inc hl							; delay 6 clock cycles											;5db8	23 	# 
	dec hl							; delay 6 clock cycles											;5db9	2b 	+ 
	inc hl							; delay 6 clock cycles											;5dba	23 	# 
	dec hl							; delay 6 clock cycles											;5dbb	2b 	+ 
	inc hl							; delay 6 clock cycles											;5dbc	23 	# 
	nop								; delay 4 clock cycles											;5dbd	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5dbe	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 3]		;5dc0	db 11 	. . 
.waitClockBit5:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5dc2	ed 78 	. x 
	jp p,.waitClockBit5				; wait until Clock BIt = 1										;5dc4	f2 c2 5d 	. . ] 
	dec hl							; delay 6 clock cycles											;5dc7	2b 	+ 
	inc hl							; delay 6 clock cycles											;5dc8	23 	# 
	dec hl							; delay 6 clock cycles											;5dc9	2b 	+ 
	inc hl							; delay 6 clock cycles											;5dca	23 	# 
	dec hl							; delay 6 clock cycles											;5dcb	2b 	+ 
	inc hl							; delay 6 clock cycles											;5dcc	23 	# 
	nop								; delay 4 clock cycles											;5dcd	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5dce	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 2]		;5dd0	db 11 	. . 
.waitClockBit6:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5dd2	ed 78 	. x 
	jp p,.waitClockBit6				; wait until Clock BIt = 1										;5dd4	f2 d2 5d 	. . ] 
	dec hl							; delay 6 clock cycles											;5dd7	2b 	+ 
	inc hl							; delay 6 clock cycles											;5dd8	23 	# 
	dec hl							; delay 6 clock cycles											;5dd9	2b 	+ 
	inc hl							; delay 6 clock cycles											;5dda	23 	# 
	dec hl							; delay 6 clock cycles											;5ddb	2b 	+ 
	inc hl							; delay 6 clock cycles											;5ddc	23 	# 
	nop								; delay 4 clock cycles											;5ddd	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5dde	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 1]		;5de0	db 11 	. . 
.waitClockBit7:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5de2	ed 78 	. x 
	jp p,.waitClockBit7				; wait until Clock BIt = 1										;5de4	f2 e2 5d 	. . ] 
	dec hl							; delay 6 clock cycles											;5de7	2b 	+ 
	inc hl							; delay 6 clock cycles											;5de8	23 	# 
	dec hl							; delay 6 clock cycles											;5de9	2b 	+ 
	inc hl							; delay 6 clock cycles											;5dea	23 	# 
	dec hl							; delay 6 clock cycles											;5deb	2b 	+ 
	inc hl							; delay 6 clock cycles											;5dec	23 	# 
	nop								; delay 4 clock cycles											;5ded	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5dee	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 0]		;5df0	db 11 	. . 
	ld b,a			;5df2	47 	G 
.waitClockBit8:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5df3	ed 78 	. x 
	jp p,.waitClockBit8				; wait until Clock BIt = 1										;5df5	f2 f3 5d 	. . ] 

; -- We have 4th byte read (expected $fe)

	ld a,b							; a - byte from Floppy Disk										;5df8	78 	x 
	cp $fe							; is it FE (fourth byte of IDAM ending)?						;5df9	fe fe 	. . 
	jp nz,READ						; no - start over and  Read a sector from disk					;5dfb	c2 27 5b 	. ' [ 

;***************************************************************************************************
;
; Read Sector Data Bytes and Checksum (128+2 bytes) 
;

; ---------- [6] --- read Sector Data Byte

RD_DataByte:
	nop								; delay 4 clock cycles											;5dfe	00 	. 
	nop								; delay 4 clock cycles											;5dff	00 	. 
	nop								; delay 4 clock cycles											;5e00	00 	. 
	ld a,0							; delay 7 clock cycles											;5e01	3e 00 	> . 
	ld a,0							; delay 7 clock cycles	(26 in total)							;5e03	3e 00 	> . 

RD_NextDataByte:
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 7]		;5e05	db 11 	. . 
.waitClockBit1:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5e07	ed 78 	. x 
	jp p,.waitClockBit1				; wait until Clock BIt = 1										;5e09	f2 07 5e 	. . ^ 
	dec hl							; delay 6 clock cycles											;5e0c	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e0d	23 	# 
	dec hl							; delay 6 clock cycles											;5e0e	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e0f	23 	# 
	dec hl							; delay 6 clock cycles											;5e10	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e11	23 	# 
	nop								; delay 4 clock cycles											;5e12	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5e13	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 6]		;5e15	db 11 	. . 
.waitClockBit2:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5e17	ed 78 	. x 
	jp p,.waitClockBit2				; wait until Clock BIt = 1										;5e19	f2 17 5e 	. . ^ 
	dec hl							; delay 6 clock cycles											;5e1c	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e1d	23 	# 
	dec hl							; delay 6 clock cycles											;5e1e	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e1f	23 	# 
	dec hl							; delay 6 clock cycles											;5e20	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e21	23 	# 
	nop								; delay 4 clock cycles											;5e22	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5e23	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 5]		;5e25	db 11 	. . 
.waitClockBit3:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5e27	ed 78 	. x 
	jp p,.waitClockBit3				; wait until Clock BIt = 1										;5e29	f2 27 5e 	. ' ^ 
	dec hl							; delay 6 clock cycles											;5e2c	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e2d	23 	# 
	dec hl							; delay 6 clock cycles											;5e2e	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e2f	23 	# 
	dec hl							; delay 6 clock cycles											;5e30	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e31	23 	# 
	nop								; delay 4 clock cycles											;5e32	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5e33	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 4]		;5e35	db 11 	. . 
.waitClockBit4:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5e37	ed 78 	. x 
	jp p,.waitClockBit4				; wait until Clock BIt = 1										;5e39	f2 37 5e 	. 7 ^ 
	dec hl							; delay 6 clock cycles											;5e3c	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e3d	23 	# 
	dec hl							; delay 6 clock cycles											;5e3e	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e3f	23 	# 
	dec hl							; delay 6 clock cycles											;5e40	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e41	23 	# 
	nop								; delay 4 clock cycles											;5e42	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5e43	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 3]		;5e45	db 11 	. . 
.waitClockBit5:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5e47	ed 78 	. x 
	jp p,.waitClockBit5				; wait until Clock BIt = 1										;5e49	f2 47 5e 	. G ^ 
	dec hl							; delay 6 clock cycles											;5e4c	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e4d	23 	# 
	dec hl							; delay 6 clock cycles											;5e4e	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e4f	23 	# 
	dec hl							; delay 6 clock cycles											;5e50	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e51	23 	# 
	nop								; delay 4 clock cycles											;5e52	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5e53	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 2]		;5e55	db 11 	. . 
.waitClockBit6:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5e57	ed 78 	. x 
	jp p,.waitClockBit6				; wait until Clock BIt = 1										;5e59	f2 57 5e 	. W ^ 
	dec hl							; delay 6 clock cycles											;5e5c	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e5d	23 	# 
	dec hl							; delay 6 clock cycles											;5e5e	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e5f	23 	# 
	dec hl							; delay 6 clock cycles											;5e60	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e61	23 	# 
	nop								; delay 4 clock cycles											;5e62	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5e63	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 1]		;5e65	db 11 	. . 
.waitClockBit7:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5e67	ed 78 	. x 
	jp p,.waitClockBit7				; wait until Clock BIt = 1										;5e69	f2 67 5e 	. g ^ 
	dec hl							; delay 6 clock cycles											;5e6c	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e6d	23 	# 
	dec hl							; delay 6 clock cycles											;5e6e	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e6f	23 	# 
	dec hl							; delay 6 clock cycles											;5e70	2b 	+ 
	inc hl							; delay 6 clock cycles											;5e71	23 	# 
	nop								; delay 4 clock cycles											;5e72	00 	. 
	ld a,0							; delay 7 clock cycles	(47 in total)							;5e73	3e 00 	> . 
	in a,(FLDATA)					; a - read byte from disk (shift FLDATA register) [bit 0]		;5e75	db 11 	. . 
	ex af,af'						; save a (byte from Floppy Disk) in alt register				;5e77	08 	. 
.waitClockBit8:
; -- wait for FDC Clock Pulse
	in a,(c)						; read Clock Bit from Flopy Drive								;5e78	ed 78 	. x 
	jp p,.waitClockBit8				; wait until Clock BIt = 1										;5e7a	f2 78 5e 	. x ^ 

; -- We have Data byte from Disk

	inc hl							; increment address in Sector Buffer to store new Byte			;5e7d	23 	# 
	dec e							; decrement number of bytes to read from Disk					;5e7e	1d 	. 
	jr z,RD_VerifyCRC				; if all read verify Sector Data Checksum						;5e7f	28 07 	( . 

; -- store Data Byte into Sector Buffer and read next byte
	ex af,af'						; restore a - Data Byte from Disk								;5e81	08 	. 
	ld (hl),a						; store Data Byte in Sector Buffer								;5e82	77 	w 
	ld a,r							; delay 9 clock cycles											;5e83	ed 5f 	. _ 
	jp RD_NextDataByte				; start read next Data Byte										;5e85	c3 05 5e 	. . ^ 

;***************************************************************************************************
;
; Verify Sector Data Checksum
;

; ---------- [7] --- read Track Number

RD_VerifyCRC:
	call CalcSectorCRC				; de - sum of all 128 bytes from Sector Buffer					;5e88	cd 10 5b 	. . [ 
	inc hl							; hl - points to next byte from Disk (checksum LSB)				;5e8b	23 	# 
	ld a,(hl)						; a - checksum LSB from Disk									;5e8c	7e 	~ 
	cp e							; is equal to calculated ?										;5e8d	bb 	. 
	jr nz,RD_Error					; no - try read again or exit with Error 10 - CHECKSUM ERROR	;5e8e	20 05 	  . 
	inc hl							; hl - points to next byte from Disk (checksum MSB)				;5e90	23 	# 
	ld a,(hl)						; a - checksum MSB from Disk									;5e91	7e 	~ 
	cp d							; is equal to calculated ?										;5e92	ba 	. 
	jr z,RS_ExitOK					; yes - exit with Error 0 - NO ERROR							;5e93	28 0d 	( . 

RD_Error:
	ld a,(iy+RETRY)					; a - number of read tries when CRC error 						;5e95	fd 7e 13 	. ~ . 
	dec a							; decrement Try Counter	- is it already 0?						;5e98	3d 	= 
	ld (iy+RETRY),a					; store back number of tries									;5e99	fd 77 13 	. w . 
	jp nz,RD_StartRead				; no - start Read Sector again									;5e9c	c2 2b 5b 	. + [ 
; -- no more try - exit with Error 10 - CHECKSUM ERROR
	ld a,10							; a - Error 10 - CHECKSUM ERROR									;5e9f	3e 0a 	> . 
	ret								; --------------------- End of Proc (with Error) --------------	;5ea1	c9 	. 

RS_ExitOK:
; -- Success
	xor a							; a - Error 00 - NO ERROR										;5ea2	af 	. 
	ret								; --------------------- End of Proc ---------------------------	;5ea3	c9 	. 



;***************************************************************************************************
; Wait for Break key released
; IN: none
; OUT: a - Error code (17) - BREAK pressed
WaitBreakKeyReleased:
; -- wait until Break key is released
	ld a,(BreakKeybRow)				; read Keyboard row with Break key								;5ea4	3a df 68 	: . h 
	and BreakKeybMask				; mask only BREAK key - if 0 -> Break is pressed				;5ea7	e6 04 	. . 
	jr z,WaitBreakKeyReleased		; yes - wait until released										;5ea9	28 f9 	( . 
; -- wait 20 ms
	push bc							; save bc														;5eab	c5 	. 
	ld bc,20						; number of ms to wait											;5eac	01 14 00 	. . . 
	call DLY						; wait 20 ms delay												;5eaf	cd be 5e 	. . ^ 
	pop bc							; restore bc 													;5eb2	c1 	. 
; -- confirm that Break key is released
	ld a,(BreakKeybRow)				; read Keyboard row with Break key								;5eb3	3a df 68 	: . h 
	and BreakKeybMask				; mask only BREAK key - if 0 -> Break is pressed				;5eb6	e6 04 	. . 
	jr z,WaitBreakKeyReleased		; yes - wait until released										;5eb8	28 ea 	( . 
; -- Break key released - set Error Code and return
	ld a,17							; a - Error 17 - BREAK											;5eba	3e 11 	> . 
	or a							; clear CY flag													;5ebc	b7 	. 
	ret								; -------------------- End of Proc ----------------------------	;5ebd	c9 	. 




;***************************************************************************************************
; Delay n miliseconds
; Routine is tuned for CPU running at 3.58 MHz
;---------------------------------------------------------------------------------------------------
; IN: BC - number of miliseconds to delay
; OUT: none 
;***************************************************************************************************
DLY:
	push bc							; save bc - number of miliseconds								;5ebe	c5 	. 
; -- setup 1ms loop 
	ld bc,137						; number of loop iteration per 1 ms								;5ebf	01 89 00 	. . . 
.loop:
	dec bc							; decrement loop counter										;5ec2	0b 	. 
	ld a,b							; test if counter is 0											;5ec3	78 	x 
	or c							; is bc == 0 ?													;5ec4	b1 	. 
	jr nz,.loop						; no - continue loop											;5ec5	20 fb 	  . 
; -- decrement number of miliseconds of wait
	pop bc							; restore bc - miliseconds counter								;5ec7	c1 	. 
	dec bc							; decrement miliseconds counter									;5ec8	0b 	. 
	ld a,b							; test if counter is 0											;5ec9	78 	x 
	or c							; is bc == 0 ?													;5eca	b1 	. 
	jr nz,DLY						; no - wait another milisecond									;5ecb	20 f1 	  . 
	ret								; -------------------- End of Proc ----------------------------	;5ecd	c9 	. 



;***************************************************************************************************
; Step the stepper N tracks inwards specified by register b 
;---------------------------------------------------------------------------------------------------
; NOTE: Stepper Phase variable contains 4 bits values duplicated in high and low nibble
; this way futher rotation operations used by StepIn and StepOut don't need any corrections
; IN: b - how many tracks to stepin
;***************************************************************************************************
STPIN:
; -- calculate maximum number of tracks we can step in from current
	ld a,(iy+DTRCK)					; a - current Track Number										;5ece	fd 7e 14 	. ~ . 
	add a,b							; add number of tracks requested								;5ed1	80 	. 
	cp 40							; is final Track number >= 40?									;5ed2	fe 28 	. ( 
	jr c,.continue					; no - continue													;5ed4	38 02 	8 . 

; -- DOS supports only 40 tracks - force last one
	ld a,39							; set final target Track number to 39							;5ed6	3e 27 	> ' 

.continue:
	ld (iy+DTRCK),a					; set final number as current track number						;5ed8	fd 77 14 	. w . 
	sla b							; b - physical steps needed (b * 2 steps per Track)				;5edb	cb 20 	.   

.doStepIn:
; -- calculate and store new Step Phase 
	ld a,(iy+PHASE)					; a - current Step Phase										;5edd	fd 7e 38 	. ~ 8 
	ld c,a							; c - save current Step Phase									;5ee0	4f 	O 
	rlca							; rotate left to get next Phase (i.e. 0001 -> 0010)				;5ee1	07 	. 

; -- write Half-Step Phase to FDC (combined old and new bits)
; -- example: when old Phase was 0001 and new Phase is 0010 then combined Phase is 0011
	push af							; save a - new Step Phase										;5ee2	f5 	. 
	ld (iy+PHASE),a					; set new value as current Step Phase							;5ee3	fd 77 38 	. w 8 
	or c							; a - combine old and new values to Half-Step Phase				;5ee6	b1 	. 
; -- write Step Phase
	call WriteStepPhase				; write Half-Step to FDC - move Disk Head						;5ee7	cd 32 5f 	. 2 _ 
; -- delay 2 ms
	push bc							; save bc - physical steps needed								;5eea	c5 	. 
	ld bc,2							; number of miliseconds to delay								;5eeb	01 02 00 	. . . 
	call DLY						; delay 2 ms 													;5eee	cd be 5e 	. . ^ 
	pop bc							; restore bc - physical steps needed							;5ef1	c1 	. 
; -- write Step Phase
	pop af							; restore a - new Step Phase									;5ef2	f1 	. 
	call WriteStepPhase				; write new Step Phase to FDC - move Disk Head					;5ef3	cd 32 5f 	. 2 _ 
; -- delay 14 ms
	push bc							; save bc - physical steps needed								;5ef6	c5 	. 
	ld bc,14						; number of miliseconds to delay								;5ef7	01 0e 00 	. . . 
	call DLY						; delay 14 ms													;5efa	cd be 5e 	. . ^ 
	pop bc							; restore bc - physical steps needed							;5efd	c1 	. 
	djnz .doStepIn					; continue to Step-in required times							;5efe	10 dd 	. . 
	ret								; ----------------------- End of Proc -------------------------	;5f00	c9 	. 



;***************************************************************************************************
; Step the stepper N tracks outwards specified by register b 
;---------------------------------------------------------------------------------------------------
; NOTE: Stepper Phase variable contains 4 bits values duplicated in high and low nibble
; this way futher rotation operations used by StepIn and StepOut don't need any corrections
; IN: b - how many tracks to step out
;***************************************************************************************************
STPOUT:
; -- calculate maximum number of tracks we can step out from current
	ld a,(iy+DTRCK)					; a - current Track Number										;5f01	fd 7e 14 	. ~ . 
	sub b							; subtract number of tracks requested - is result < 0 ?			;5f04	90 	. 
	jp p,.continue					; no - continue													;5f05	f2 09 5f 	. . _ 

; -- DOS supports tracks from 0 to 39 - force first one
	xor a							; set final target Track number to 0							;5f08	af 	. 

.continue:
	ld (iy+DTRCK),a					; set final number as current track number						;5f09	fd 77 14 	. w . 
	sla b							; b - physical steps needed (b * 2 steps per Track)				;5f0c	cb 20 	.   

.doStepOut:
; -- calculate and store new Step Phase 
	ld a,(iy+PHASE)					; a - current Step Phase										;5f0e	fd 7e 38 	. ~ 8 
	ld c,a							; c - save current Step Phase									;5f11	4f 	O 
	rrca							; rotate right to get next Phase (i.e. 0100 -> 0010)			;5f12	0f 	. 

; -- write Half-Step Phase to FDC (combined old and new bits)
; -- example: when old Phase was 0100 and new Phase is 0010 then combined Phase is 0110
	push af							; save a - new Step Phase										;5f13	f5 	. 
	ld (iy+PHASE),a					; set new value as current Step Phase							;5f14	fd 77 38 	. w 8 
	or c							; a - combine old and new values to Half-Step Phase				;5f17	b1 	. 
; -- write Step Phase
	call WriteStepPhase				; write Half-Step to FDC - move Disk Head						;5f18	cd 32 5f 	. 2 _ 
; -- delay 2 ms
	push bc							; save bc - physical steps needed								;5f1b	c5 	. 
	ld bc,2							; number of miliseconds to delay								;5f1c	01 02 00 	. . . 
	call DLY						; delay 2 ms 													;5f1f	cd be 5e 	. . ^ 
	pop bc							; restore bc - physical steps needed							;5f22	c1 	. 
; -- write Step Phase
	pop af							; restore a - new Step Phase									;5f23	f1 	. 
	call WriteStepPhase				; write new Step Phase to FDC - move Disk Head					;5f24	cd 32 5f 	. 2 _ 
	push bc							; save bc - physical steps needed								;5f27	c5 	. 
	ld bc,14						; number of miliseconds to delay								;5f28	01 0e 00 	. . . 
	call DLY						; delay 14 ms 													;5f2b	cd be 5e 	. . ^ 
	pop bc							; restore bc - physical steps needed							;5f2e	c1 	. 
	djnz .doStepOut					; continue to Step-out required times							;5f2f	10 dd 	. . 
	ret								; ----------------------- End of Proc -------------------------	;5f31	c9 	. 


;***************************************************************************************************
; Write new Step Phase bits to Floppy Disk COntroller
; IN: a - new Step Phase in lower 4 bits 
WriteStepPhase:
	and FL_STEPPER_MASK				; only lower 4 bits of value									;5f32	e6 0f 	. . 
	ld c,a							; c - new Step Phase bits										;5f34	4f 	O 
	ld a,%11110000					; mask to select only high 4 bits								;5f35	3e f0 	> . 
	and (iy+LTHCPY)					; a - FLCtrl last value w/o Step Phase bits						;5f37	fd a6 33 	. . 3 
	or c							; a - add new Step Phase bits									;5f3a	b1 	. 
	ld (iy+LTHCPY),a				; store FLCtrl to shadow register								;5f3b	fd 77 33 	. w 3 
	out (FLCTRL),a					; set Flopy Control byte										;5f3e	d3 10 	. . 
	ret								; ------------------ End of Proc ------------------------------	;5f40	c9 	. 


;***************************************************************************************************
; Disk power ON
; --------------------------------------------------------------------------------------------------
; Turn ON the power of the drive selected in DOS vector IY+DK. 
; IN: IY+DK: $10 - Drive 1 selected, $80 - Drive 2 selected
; OUT: ---
; Registers affected: A
;***************************************************************************************************
PWRON:
; -- get current state of FDD Step Motor
	ld a,(iy+PHASE)					; get current Step Motor Phase									;5f41	fd 7e 38 	. ~ 8 
	and FL_STEPPER_MASK				; only 4 low bits												;5f44	e6 0f 	. . 
; -- add bits sent before to Floppy Drive Control Register 
	or (iy+LTHCPY)					; add last byte sent to FLCtrl 									;5f46	fd b6 33 	. . 3 
; -- select drive
	or (iy+DK)						; set bit for selected drive 									;5f49	fd b6 0b 	. . . 
; -- write new parameters to Control register and it's shadow
	ld (iy+LTHCPY),a				; store FLCtrl to shadow register								;5f4c	fd 77 33 	. w 3 
	out (FLCTRL),a					; set Flopy Control byte										;5f4f	d3 10 	. . 
	ret								; ------------------ End of Proc ------------------------------	;5f51	c9 	. 


;***************************************************************************************************
; Disk power OFF
;---------------------------------------------------------------------------------------------------
; Turn OFF the power to the disk. 
; Both disks are turned OFF no matter which one was selected in iy+DK.
; IN: ---
; OUT: ---
;***************************************************************************************************
PWROFF:
; -- get bits sent before to Floppy Drive Control Register 
	ld a,(iy+LTHCPY)				; get last byte sent to FLCtrl 									;5f52	fd 7e 33 	. ~ 3 
; -- clear WriteReq bit (deactivate) 
	or FL_WRITE_REQ					; set bit 6 - Write Request (inactive)							;5f55	f6 40 	. @ 
; -- disable drive D1 and D2 and set Step Motor Phase to 0-0-0-0
	and %01100000					; clear all bits except WriteReq and Write Data					;5f57	e6 60 	. ` 
; -- write new parameters to Control register and it's shadow
	ld (iy+LTHCPY),a				; store FLCtrl to shadow register								;5f59	fd 77 33 	. w 3 
	out (FLCTRL),a					; set Flopy Control byte										;5f5c	d3 10 	. . 
	ret								; ------------------ End of Proc ------------------------------	;5f5e	c9 	. 
	
	
;***************************************************************************************************
; END	
	ds	30, $00						;5f5f	00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 	. 
									;5f6f	00 00 00 00 00 00 00 00 00 00 00 00 00 00 	. 
	ds  131, $ff					;5f7d	ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff 	. 
									;5f8d	ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff 	. 
									;5f9d	ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff 	. 
									;5fad	ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff 	. 
									;5fbd	ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff 	. 
									;5fcd	ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff 	. 
									;5fdd	ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff 	. 
									;5fed	ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff 	. 
									;5ffd	ff ff ff 	. 
