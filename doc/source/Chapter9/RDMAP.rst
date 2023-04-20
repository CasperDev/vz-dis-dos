

RDMAP - Load allocation Map
---------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 4011H

	.. cmdoption:: Input: 
		
		The corresponding drive must be switched on.
	
	.. cmdoption:: Exit: 
		
		The sector allocation map is located in the 80-byte buffer at the end
		of the :ref:`DOS work area` (MAPAREA).

		The drive remains powered on.

	.. cmdoption:: Registers used: 
		
		AF, BC. DE, HL

	.. cmdoption:: Error handling: 
		
		In the event of an error, this routine automatically branches
		to the ERROR routine. Custom error handling is not possible.

The sectors allocation map is loaded from sector 15
of track 0 from the diskette into the main memory and transferred to the
MAPAREA at the end of the :ref:`DOS work area`.

Note that you are responsible for turning the drive on and off yourself.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		DI 				; disable interrupts
		LD A,10H 		; select Drive 1
		LD (IY+11),A
		CALL 4008H 		; and turn on
		LD BC,50
		CALL 4038H 		; 50 ms delay
		CALL 4011H 		; load allocation map
		CALL 400BH 		; turn off the drive
		LD L,(IY+52) 	; start address of allocation map ..
		LD H,(IY+53) 	; .. into HL
		EI 				; enable interrupts again
		...

	The sector occupancy overview is loaded from the floppy disk in
	Drive 1. The start address of the MAPAREA is then made available in
	the register pair HL.

	
Internally called routines: READ