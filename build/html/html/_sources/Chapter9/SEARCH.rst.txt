


SEARCH - Find file in table of contents
---------------------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 402CH

	.. cmdoption:: Input: 

		- Filename in FNAM (IY+1)
		- The drive must be powered on.

	.. cmdoption:: Exit: 
		
		If file exists,
		
		- type of file in TYPE+1 (IY+10).
		- The sector of the table of contents with the entry found is
		  in the data buffer.
		- Register DE points to the byte after the name.
		- SCTR and TRCK contain the address of the sector.

	.. cmdoption:: Registers used: 
		
		AF, BC, DE, HL

	.. cmdoption:: Error handling: 
		
		- A = 0 File does not exists
		- A = 2 File already exists
		- A = 9 An address mark was not found
		- A =10 A checksum error occurred during reading
		- A =13 File does not exists
		- A =17 BREAK key pressed
  
The SEARCH routine checks whether a file with the name stored in FNAM
already exists in the table of contents of the addressed diskette.

The result of the search is transferred in the A register.

	A = 2 	means that there is a corresponding entry
		  	The sector of the table of contents is in the data buffer and DE
			points to the byte after the name of the entry found (= address of
			the 1st sector of this file).

			The SCTR and TRCK fields of the DOS vectors contain the
			sector address within the table of contents.

			The TYPE+1 (IY+10) field contains the type of the found file.
			You may have to evaluate this yourself.

	A = 0 or A = 13 have the same meaning.
			The specified file is not in the table of contents of the diskette.
			
			- A=0 - the end of valid entries has been reached.
			- А=13 - the end of the table of contents has been reached.
			
			All other values of A indicate an error or fact that BREAK key was pressed.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		DI 					; disable interrupts
		LD (IY+11),10H 		; select Drive 1
		CALL 4008H 			; and turn on
		LD BC,50 			; 50 ms delay
		CALL 4038H
		CALL 4011H 			; load allocation map
		LD HL,DNAM 			; filename text
		CALL 401DH 			; copy filename to FNAN
		CALL 4026H 			; find file in table of contents
		OR A
		JR Z,A1 			; unavailable!
		CP 0DH
		JR Z,A1 			; unavailable!
		CP 2 				; error?
		JP NZ,400EH 		; yes, to the ERROR routine
		IN A,(13H) 			; check write protection
		OR A
		LD A,4
		JP M,400EH 			; read only, to the ERROR routine
		EX DE,HL 			; address of entry in HL
		LD DE,-10 			; HL to the beginning of the entry
		ADD HL,DE
		LD (HL),1 			; release entry
		CALL 4023H 			; write back sector of table of contents
		...
		... 		release occupied sectors in the allocation map
		...
		A1: CALL 4017H 		; write back allocation map
		CALL 400BH 			; turn off drive
		EI 					; enable interrupts again
		...
		DNAM: DEFM '"DIARY":'

	The "DIARY" file, if present, is deleted from the directory of the diskette
	in drive 1. If not there, the delete routine is skipped.

	Note that this example has not been fully coded out. In addition to
	deleting the entry in the table of contents, you must also release all
	occupied sectors of this file in the allocation map.

Internally called routines: READ

