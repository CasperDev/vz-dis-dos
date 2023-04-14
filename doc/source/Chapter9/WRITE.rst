

WRITE - Write sector to disk
----------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 4032H

	.. cmdoption:: Input: 
		
		- The drive must be powered on.
		- The sector to be written must be in the data buffer.
		- The address of the sector to be written must be in the SCTR and TRCK
		  fields of the DOS vectors.

	.. cmdoption:: Exit: 
		
		The sector in the data buffer was transferred to the diskette.

	.. cmdoption:: Registers used: 
		
		AF, BC, DE, HL, BC', DE', HL'

	.. cmdoption:: Error handling: 
		
		- A = 0 Ok, sector written
		- A = 9 An address mark was not found
		- A =17 :kbd:`BREAK` key pressed


The sensitive data in the data buffer are transferred to the addressed sector of
the diskette. The checksum is determined and placed at the end of the sector.

The sector is transferred including the data mark (10 bytes) in front of the data
buffer and the checksum, means a total of 140 bytes are written to the diskette.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		DI 					; disable interrupts
		LD (IY+11),10H 		; select Drive 1
		CALL 4008H 			; and turn on
		LD BC,50 			; 50 ms delay
		CALL 4038H
		IN A,(13H) 			; check write protection
		OR A
		LD A,4
		JP M,400EH 			; read only, to the ERROR routine
		LD (IY+17),10 		; set Sector Number in SCTR
		LD (IY+18),5 		; set Track Number in TRCK
		CALL 4023H 			; write sector to disk
		OR A 				; error occurred?
		JP NZ,400EH 		; yes, to the ERROR routine
		CALL 400BH 			; turn off drive
		EI 					; enable interrupts again
		...

	The data from the data buffer is written to track 5, sector 10 of the
	floppy disk in drive 1.

Internally called routines: IDAM

