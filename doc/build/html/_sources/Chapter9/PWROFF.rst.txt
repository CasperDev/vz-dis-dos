

PWROFF - Turn off a drive
-------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 400BH

	.. cmdoption:: Input:

		none

	.. cmdoption:: Exit:

		none

	.. cmdoption:: Registers used: 
		
		A

	.. cmdoption:: Error handling: 
		
		none

A powered-on drive is powered off. The drive motor stops and the LED on the
front of the drive goes out.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		CALL 400BH 		; turn off the drive
		...


