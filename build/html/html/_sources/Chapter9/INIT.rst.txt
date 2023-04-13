

INIT - Initialize disk.
-----------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 401AH

	.. cmdoption:: Input: 
		
		DK (IY+11) = Drive identifier.
		* X'10' = Drive 1
		* X'80' = Drive 2

	.. cmdoption:: Exit: 
		
		The floppy disk in the selected drive has been initialized.

	.. cmdoption:: Registers used: 
		
		AF, BC. DE, HL

	.. cmdoption:: Error handling: 
		
		In the event of an error, this routine automatically branches
		to the ERROR routine. Custom error handling is not possible.

A diskette in the selected drive is reinitialized, i.e. it is divided into 40 tracks
with 16 sectors each and provided with the appropriate synchronization and
identification marks.

All data previously on this diskette will be erased.

This routine handles the powering on and off of the drive itself.

The write protection is checked by INIT, the interrupts are switched off at the
beginning.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		LD A,10H 			; select Drive
		LD (IY+11),A
		CALL 401A 			; initialize disk
		EI 					; enable interrupts
		...

	The floppy disk in drive 1 is initialized.

Internally called routines: IDAM, STPIN, STPOUT, DLY

