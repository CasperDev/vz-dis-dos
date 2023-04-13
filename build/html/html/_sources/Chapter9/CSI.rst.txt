

CSI - Interpret command parameters.
-----------------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 401DH

	.. cmdoption:: Input: 
		
		HL = starting address of a file name enclosed in double quotes.
		This must end with X'00' or ':'.

	.. cmdoption:: Exit: 
		
		The file name was checked and transferred to the FNAM field
		of the DOS vectors.

		HL = address of terminator

	.. cmdoption:: Registers used: 
		
		AF, B. HL

	.. cmdoption:: Error handling: 
		
		If the file name is not enclosed in quotation marks
		or not correctly terminated, this routine branches to BASIC
		and the message ``?SYNTAX ERROR`` is displayed.

The first eight characters of a filename enclosed in quotation marks are
transferred to the FNAM field of the DOS vectors.

A BASIC line end identifier X'00' or a command separator ':' must be located
after the closing quotation mark.

This routine is used by DOS-BASIC to check the syntax.

Disk access does not take place.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		  LD HL,DNAM1 		; address of filename
		  CALL 401DH 		; are transmitted to FNAM
		...
		DNAM1: DEFM '"MAILBOX":'

	The file name "MAILBOX" is transferred to the DOS vector FNAM for
	subsequent addressing.

