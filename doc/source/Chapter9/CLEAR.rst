

CLEAR - Deleting a sector on the floppy disk
--------------------------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 4014H

	.. cmdoption:: Input: 
		
		* The corresponding drive must be switched on.
		* SCTR (IY+17) = Sector Number
		* TRCK (IY+18) = Track Number

	.. cmdoption:: Exit: 
		
		The addressed sector is physically erased from the disk.

	.. cmdoption:: Registers used: 
		
		AF, BC. DE, HL

	.. cmdoption:: Error handling: 
		
		In the event of an error, this routine automatically branches
		to the ERROR routine.Custom error handling is not possible.


The sector addressed in the DOS vectors SCTR (IY+17) and TRCK (IY+18) is
physically erased on the diskette, i.e. overwritten with binary zeros (X'00').

Note that you have to take care of switching the drive on and off yourself.

Before erasing the sector, make sure the disk is not write-protected.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		DI 					; disable interrupts
		LD A,80H 			; select Drive 2
		LD (IY+11),A
		CALL 4008H 			; and turn on
		LD BC,50 			; 50 ms delay
		CALL 4038H
		IN A,(13H) 			; check write protection
		OR A
		LD A,4
		JP M,400EH 			; read only!
		LD (IY+17),12 		; set Sector Number
		LD (IY+18),28 		; set Track Number
		CALL 4014H 			; erase sector
		CALL 400BH 			; turn off drive
		EI 					; enable interrupts again
		...

	Sector 12 in track 28 of the disk in drive 2 will be erased.

Internally called routines: WRITE

