


ERROR - Error handling
----------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 400EH

		or

		JP 400EH

	.. cmdoption:: Input: 
		
		A = Error code (0 - 17)

	.. cmdoption:: Exit: 
		
		Jump to the BASIC interpreter

	.. cmdoption:: Registers used: 
		
		AF, BC. DE, HL

	.. cmdoption:: Error handling: 
		
		none


A powered-on drive is powered off. The drive motor stops and the LED on the
front of the drive goes out.

An error message is output according to the error code transferred in the A
register. A possibly switched on drive is switched off (with error code > 1).

This routine differs from the other routines insofar as it jumps to the BASIC
interpreter instead of to the calling program.

The stack pointer is set to the BASIC stack.

.. csv-table:: 
	:delim: |


	Reg A | Generated message | Further process
	0 | none | to the BASIC interpreter (1B9AH)
	1 | ?SYNTAX ERROR | Release and further expiry about 1997H
	2 | ?FILE ALREADY EXISTS | to the BASIC interpreter (1B9AH)
	3 | ?DIRECTORY FULL | to the BASIC interpreter (1B9AH)
	4 | ?DISK WRITE PROTECTED | to the BASIC interpreter (1B9AH)
	5 | ?FILE NOT OPEN | to the BASIC interpreter (1B9AH)
	6 | ?DISK I/O ERROR | to the BASIC interpreter (1B9AH)
	7 | ?DISK FULL | to the BASIC interpreter (1B9AH)
	8 | ?FILE ALREADY OPEN | to the BASIC interpreter (1B9AH)
	9 | ?SECTOR NOT FOUND | to the BASIC interpreter (1B9AH)
	10 | ?CHECKSUM ERROR | to the BASIC interpreter (1B9AH)
	11 | ?UNSUPPORTED DEVICE | to the BASIC interpreter (1B9AH)
	12 | ?FILE TYPE MISMATCH | to the BASIC interpreter (1B9AH)
	13 | ?FILE NOT FOUND | to the BASIC interpreter (1B9AH)
	14 | ?DISK BUFFER FULL | to the BASIC interpreter (1B9AH)
	15 | ?ILLEGAL READ | to the BASIC interpreter (1B9AH)
	16 | ?ILLEGAL WRITE | to the BASIC interpreter (1B9AH)
	17 | ?BREAK | to the BREAK routine (1DA0H) in BASIC

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		LD A,7 			; Error code 7
		CALL 400EH 		; Output message "DISK FULL"
		
	The message "?DISK FULL" is output and then BASIC responds with
	READY.

.. note:: Note:

	Using the line number field in the BASIC communication area (78A2H), the
	ERROR routine distinguishes whether it is a direct command or a program
	command.

	If field 78A2H/78A3H contains a value not equal to X'FFFF', this is interpreted
	as a line number and this is output after the error message (error codes 1-16).

This function can perhaps also be useful when testing machine programs by
setting specific values in 78A2H/78A3H which, if an error occurs, give you an
indication of the corresponding point in the program.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		OR A 			; check if error occurred
		JR Z,XY 		; no, go on!
		LD HL,10 		; set row identifier
		JP 400EH 		; call error routine
		XY: ...
		
	If A contains a value not equal to 0, the corresponding error message
	is output with information about the location of the occurrence.
	e.g. A= 3, then "?DIRECTORY FULL IN 10".


