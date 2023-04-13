

LOAD - Loading a program or memory area
---------------------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 4041H

	.. cmdoption:: Input: 
		
		- Filename in FNAM (IY+1)
		- Filoe Type in TYPE (IY+9)

	.. cmdoption:: Exit: 
		- 78A4/A5 = starting address
		- 78F9/FA = ending address + 1

	.. cmdoption:: Registers used: 
		
		AF, BC, DE, HL

	.. cmdoption:: Error handling: 
		
		- A = 0 Ok
		- A = 9 An address mark was not found
		- A =10 A checksum error
		- A =12 File found but wrong type
		- A =13 File does not exists
		- A =17 BREAK key pressed

The program specified in the FNAM field is transferred from the diskette to the
memory.

After successful completion, the start address and the end addresst+1 of the
memory area are transferred in the BASIC communication area at address
78A4/A5 and at address 78F9/FA.

This routine only works with files that contain the start address in bytes 12 and
13 of the table of contents and the end address + 1 in bytes 14 and 15, ie not
with standard data files.

If a program is saved with the BASIC commands SAVE or BSAVE or by
machine programs with the routine SAVE, this entry is made automatically.

The LOAD routine automatically turns the drive on and off and also turns off
interrupts.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		LD (IY+11),80H 			; select Drive 2
		LD HL,DNAM 				; filename to FNAM
		CALL 401DH 				; register
		LD (IY+9),'B' 			; file type 'B' (binary)
		CALL 4041H 				; load program
		OR A 					; error occurred?
		JP NZ,400EH 			; yes, to the ERROR routine
		EI 						; enable interrupts again
		...
		DNAM: DEFM '“GRAFDR”:'

	The binary file or machine program "GRAFDR" is transferred from the
	floppy disk in drive 1 into memory.

Internally called routines: SEARCH, READ


