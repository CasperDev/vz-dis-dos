

STPIN - Advance read/write head n tracks
----------------------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 403BH

	.. cmdoption:: Input: 
		
		- The drive must be powered on.
		- B = number of tracks

	.. cmdoption:: Exit: 
		
		- The read/write head was set in front of the corresponding
		  number of tracks.
		- DTRCK (IY+20) contains the new current track number.

	.. cmdoption:: Registers used: 
		
		AF, BC

	.. cmdoption:: Error handling: 
		
		none

The read/write head is advanced by the number of tracks contained in B, but
up to track 39 at most.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		DI 					; disable interrupts
		LD (IY+11),10H 		; select Drive 1
		CALL 4008H 			; and turn on
		LD BC,50 			; 50 ms delay
		CALL 4038H
		LD B,10 			; put head in front of tracks
		CALL 403BH
		CALL 400BH 			; turn off drive
		EI 					; enable interrupts again
		...

