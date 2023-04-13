

IDAM - Look for the address mark on the diskette
------------------------------------------------

.. admonition:: Syntax:

	.. code:: Z80
		
		CALL 4023H

	.. cmdoption:: Input: 
		
		- The corresponding drive must be switched on.
		- SCTR (IY+17) = Sector Number
		- TRCK (IY+18) = Track Number
  
	.. cmdoption:: Exit: 
		
		If the return jump is error-free, the read/write head is located directly
		in front of the data mark of the sector being searched for.

	.. cmdoption:: Registers used: 
		
		AF, BC. DE, HL

	.. cmdoption:: Error handling: 
		
		- A = 0 - Address mark found
		- A = 9 - Address mark not found
		- A = 17 - BREAK key pressed

		- if A = 0, Z flag is set
		- if A <> 0, Z flag is clear


This routine is used to position the read/write head in front of the data mark of
this sector before writing or reading a sector.

IDAM first positions the head over the desired track and then reads address
mark after address mark until the desired sector is found. The writing or
reading process for the data field must then begin immediately, since the
diskette continues to rotate.

IDAM is already integrated in the READ and WRITE routines for reading or
writing a sector.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		DI 				; disable interrupts
		LD A,80H 		; select Drive 2
		LD (IY+11),A
		CALL 4008H 		; and turn on
		LD BC,50 		; 50 ms delay
		CALL 4038H
		LD (IY+17),6 	; Sector Number
		LD (IY+18),14 	; Track Number
		CALL 4023 		; search sector
		JP NZ,400EH 	; error or BREAK
		...
		...		Read or write sector
		...

	The read/write head should be positioned in front of the data mark of
	sector 6 of track 14 for subsequent reading or writing.

Internally called routines: STPIN, STPOUT

