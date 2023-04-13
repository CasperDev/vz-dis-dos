

FIND - Look for a free entry in table of contents
-------------------------------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 402FH

	.. cmdoption:: Input: 
		
		The drive must be powered on.

	.. cmdoption:: Exit: 
		
		- SCTR = Sector Number
		- TRCK = Track Number
		- The addressed sector of the table of contents is in the data buffer.
		- HL points to the beginning of the free entry.

	.. cmdoption:: Registers used: 
		
		AF, BC, DE, HL

	.. cmdoption:: Error handling: 
		
		- A = 0 Ok, free entry determined
		- A = 3 no free entry available
		- A = 9 An address mark was not found
		- A =10 A checksum error occurred during reading
		- A =13 File does not exists
		- A =17 BREAK key pressed


A free entry is determined in the table of contents of the activated floppy disk.

The result is transmitted in register A.

If successful (A=0), the corresponding sector of the table of contents is in the
data buffer and register pair HL points to the beginning of the free entry.

The SCTR and TRCK fields contain the address of this sector. An entry can
now be made there.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		DI 					; disable interrupts
		LD (IY+11),10H 		; select Drive 1
		CALL 4008H 			; and turn on
		LD BC,50 			; 50 ms delay
		CALL 4038H
		CALL 402FH 			; determine free entry
		OR A 				; successful?
		JP NZ,400EH 		; no, to the ERROR routine
		CALL 400BH 			; turn off drive
		EI 					; enable interrupts again
		...

	A free entry in the table of contents is determined on the diskette in
	drive 1.

Internally called routines: READ


