

CREATE - Write an entry in the table of contents
------------------------------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 4026H

	.. cmdoption:: Input: 
		
		- filename in FNAM (IY+1)
		- File Type in TYPE (IY+9)
		- The allocation map must be loaded (MAPAREA).
		- The drive must be powered on.

	.. cmdoption:: Exit: 
		
		The file was entered in the table of contents, the first data sector
		for this file was reserved.

	.. cmdoption:: Registers used: 
		
		AF, BC. DE, HL

	.. cmdoption:: Error handling: 
		
		- A = 0 Entry made
		- A = 2 File already exists
		- A = 3 no space in the table of contents
		- A = 7 no free sector (disk full)
		- A = 9 An address mark was not found
		- A =10 A checksum error occurred during reading
		- A =17 :keyword:`BREAK` key pressed

An entry is made in the directory for the file specified in :keyword:`FNAM` and the first
free sector is reserved for this file.

First, SEARCH checks whether a file with the same name already exists. If
not, a free entry in the table of contents is determined with FIND and a first
free sector is searched for with MAP. If both were successful, the entry is
made in the table of contents.

To do this, the file type, separator ':', file name and the address of the first
sector are entered in the 16-byte entry found in the table of contents, and the
table of contents is written back.

The allocation map should then also be written back to the diskette, otherwise
the first sector will not be definitively assigned. If you forget this, it will later
lead to a double allocation of this sector and possibly to an inextricable mess
of the data.

Of course, rascals can take advantage of this and make two different entries
for the same file with different names in the table of contents. Sensible ???

Before calling CREATE, you should definitely check the write protection of the
diskette.

The success of the action can be checked by evaluating the A register.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		DI 						; disable interrupts
		LD (IY+11),10H 			; select Drive 1
		CALL 4008H 				; and turn on
		LD BC,50 				; 50 ms delay
		CALL 4038H
		IN A,(13H) 				; check write protection
		OR A
		LD A,4
		JP M,400EH 				; read only!
		CALL 4011H 				; load allocation map
		LD HL,DNAM 				; filenames in the field
		CALL 401DH 				; copy to FNAM
		LD (IY+9),'B' 			; set Type = 'B'
		CALL 4026H 				; enter the file in the table of contents
		OR A 					; error occured?
		JP NZ,400EH 			; yes, to the ERROR routine
		CALL 4017H 				; write back allocation map
		CALL 400BH 				; turn off the drive
		EI 						; allow interrupts again
		...
		DNAM: DEFM '“KARTEI”:'

	An entry is made in the table of contents of the diskette in drive 1 for
	the binary file "KARTEI" (type = ``B``).

Internally called routines: SEARCH, FIND, MAP, READ, WRITE

