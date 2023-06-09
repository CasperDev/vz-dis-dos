

STPOUT - Reset read/write head n tracks
---------------------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 403EH
	
	.. cmdoption:: Input: 
		
		- The drive must be powered on.
		- B = number of tracks

	.. cmdoption:: Exit: 
		
		- The read/write head was reset the corresponding number of tracks.
		- DTRCK (IY+20) contains the new current track number.
  
	.. cmdoption:: Registers used: 
		
		AF, BC

	.. cmdoption:: Error handling:
		
		none

The read/write head is reset by the number of tracks contained іп B, but up to
track 0 at most.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		DI 					; disable interrupts
		LD (IY+11),10H 		; select Drive 1
		CALL 4008H 			; and turn on
		LD BC,50 			; 50 ms delay
		CALL 4038H
		LD B,5 				; reset head 5 tracks
		CALL 403EH
		CALL 400BH 			; turn off drive
		EI 					; enable interrupts again
		...
		
