

DLY - n milliseconds delay
--------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 4038H

	.. cmdoption:: Input: 
		
		BC = number of milliseconds.

	.. cmdoption:: Exit: 
		
		none
	
	.. cmdoption:: Registers used: 
		
		AF, BC

	.. cmdoption:: Error handling: 
		
		none

This routine causes a delay whose duration in milliseconds is determined by
the entry in the register pair BC.

.. admonition:: Example:
	:class: hint

	.. code:: Z80
		
		DI 					; disable interrupts
		LD BC,1000 			; 1 sec delay
		CALL 4038H
		EI 					; enable interrupts again
		...

	Causes a delay of one second.

