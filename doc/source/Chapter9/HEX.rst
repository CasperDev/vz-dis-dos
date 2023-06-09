

HEX - Conversion ASCII to HEX.
------------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 4020H

	.. cmdoption:: Input: 
		
		HL = Start address of a 4-byte hexadecimal number
		in ASCII format.

	.. cmdoption:: Exit: 
		
		- DE = equivalent hexadecimal value (binary)
		- HL = Input address + 4

	.. cmdoption:: Registers used: 
		
		AF, DE, HL

	.. cmdoption:: Error handling: 
		
		- Carry = 0 - no error
		- Carry = 1 - conversion failed


This routine can be used to convert a hexadecimal address input from the
keyboard to its binary equivalent.

This routine is used by DOS BASIC, e.g. by the :guilabel:`BSAVE` command, to interpret
and accept the program start address and end address.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		  LD HL,ASCII 			; Address ASCII value
		  CALL 4020H			; convert
		  JR NC,A1 				; Carry=0? ok, go to A1
		  LD A,1 				; Carry=1, "SYNTAX ERROR"
		  JP 400EH 				; output via ERROR routine
		A1:	LD (BIN),DE 		; save binary value
		...
		ASCII:	DEFM 'A31C'
		BIN:	DEFS 2

	The character string in the "ASCII" field is converted into the hexadecimal
	value and stored in the "BIN" field.

