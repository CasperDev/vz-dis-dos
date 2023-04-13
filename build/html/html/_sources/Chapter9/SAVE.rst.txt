

SAVE - Saving a program or memory area to floppy disk
-----------------------------------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 4044H
	
	.. cmdoption:: Input: 
		
		- 78A4/A5 = Start address of the memory area
		- 78F9/FA = End address+1 of the memory area
		- The drive must be powered on.
		- FNAM (IY+1) = file/program name
		- TYPE (IY+9) = type of file

	.. cmdoption:: Exit: 
		
		The addressed memory area was transferred to the diskette
		and entered in the table of contents under the specified name.

	.. cmdoption:: Registers used: 
		
		AF, BC, DE, HL

	.. cmdoption:: Error handling: 
		
		If errors occur, the SAVE routine branches directly
		to the ERROR routine. Own error handling is not possible.

A memory area or program is transferred from memory to floppy disk. Start
and end addresses of data to be transferred are in the corresponding BASIC
pointers 78A4 and 78F9.

This adresses are entered in the table of contents under the name specified in
FNAM and the type entered in the first byte of TYPE.

You must first switch on the floppy disk yourself; it is turned off by the SAVE
routine when the save process is complete.

You should also check the write protection beforehand.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		LD HL,8000H 			; start address
		LD (78A4),HL
		LD HL,9000H 			; end address + 1
		LD (78F9),HL
		LD HL,DNAM 				; filename to FNAM
		CALL 401DH 				; register
		LD (IY+9),'B' 			; file type 'B' (binary)
		LD (IY+11),10H 			; select Drive 1
		CALL 4008H 				; and turn on
		IN A,(13H) 				; check write protection
		OR A
		LD A,4
		JP M,400EH 				; read only, to the ERROR routine
		CALL 4044H 				; write memory area to diskette
		EI 						; enable interrupts again
		...
		DNAM: DEFM '“TESTDAT”:'

	The memory area 8000 - 8FFF is transferred to the diskette under
	the name "TESTDAT" with type ``"B"``.

Internally called routines: READ, CREATE, MAP, SEARCH, WRITE


