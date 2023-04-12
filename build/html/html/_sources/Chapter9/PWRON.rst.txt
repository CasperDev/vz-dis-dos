
.. title:: PWRON


PWRON - Turn on a drive
-----------------------

.. admonition:: Syntax:
	
	.. code:: asm

		CALL 4008H

	.. cmdoption:: Input
		
  		DK (IY+11) in the DOS vectors = Drive identifier
		
			X'10' = Drive 1
		
			X'80' = Drive 2

	.. cmdoption:: Exit: 

		none

	.. cmdoption:: Registers used: 
		
		A

	.. cmdoption:: Error handling: 
		
		none

The drive selected in DK will be powered on. The drive motor runs and the red
LED on the front of the drive lights up.

You should wait a few milliseconds for the rotation speed to stabilize before
accessing this drive.

.. admonition:: Example:
	:class: hint

	.. code:: z80
		
		loop:
		...
		...
		DI 				; disable interrupts
		LD A,80H		; select Drive 2
		LD (IY+11),A	; test 
		CALL 4008H 		; turn on the drive
		LD BC,50 		; 50 ms delay
		CALL 0x4038
		CALL loop
		...
		...
		


Drive 2 turns on, then the program waits 50ms for stabilization.

