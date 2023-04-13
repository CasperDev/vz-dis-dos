

SVMAP - Save allocation Map to disk.
------------------------------------

.. admonition:: Syntax:

	.. code:: Z80
		
		CALL 4017H

	.. cmdoption:: Input: 
		
		The corresponding drive must be switched on.
		
		The current allocation map is in the DOS work area іп MAPAREA.

	.. cmdoption:: Exit: 
		
		The sector map was written to sector 15 of track 0 on the floppy disk
		in the selected drive.

		The drive remains powered on.

	.. cmdoption:: Registers used: 
		
		AF, BC. DE, HL

	.. cmdoption:: Error handling: 
		
		In the event of an error, this routine automatically branches
		to the ERROR routine. Custom error handling is not possible.

The sectors allocation map is transferred from the
corresponding buffer of the DOS work area (MAPAREA) to the data buffer and
written from there to sector 15 of track 0 on the diskette.

Note that you must turn the drive on and off by yourself.

Before saving, check that the floppy disk is not write-protected,

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		DI 					; disable interrupts
		LD A,10H 			; select Drive 1
		LD (IY+11),A
		CALL 4008H 			; and turn on
		LD BC,50 			; 50 ms delay
		CALL 4038H
		IN A,(13H) 			; check write protection
		OR A
		LD A,4
		JP M,400EH 			; read only!
		CALL 4017H 			; write back allocation map
		CALL 400BH 			; turn off drive
		EI 					; enable interrupts again
		...

	The sector allocation overview is written back from the DOS work area
	(MAPAREA) to the diskette in drive 1 (track 0, sector 15).
	
Internally called routines: WRITE

