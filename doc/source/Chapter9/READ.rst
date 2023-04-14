

READ - Read sector from disk
----------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 4035H
	
	.. cmdoption:: Input: 
		
		- The drive must be powered on.
		- Address of the sector to be read in SCTR (IY+17) and TRCK (IY+18) of
		  the DOS vectors.
		- RETRY (IY+19) = number of read attempts

	.. cmdoption:: Exit: 
		
		The read sector is in the data buffer.

	.. cmdoption:: Registers used: 
		
		AF, BC, DE, HL

	.. cmdoption:: Error handling: 
		
		- A = 0 Ok, sector was read
		- A = 9 An address mark was not found
		- A =10 Checksum wrong
		- A =17 :kbd:`BREAK` key pressed
  

The sector addressed with SCTR and TRCK is transferred from the diskette to
the data buffer.

The checksum is determined and compared at the end of the sector with the
value stored there.

In the RETRY (IY+19) field of the DOS vectors you can specify how many
read attempts should be made if the checksum is incorrect (default value =
10).

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		DI 					; disable interrupts
		LD (IY+11),80H 		; select Drive 2
		CALL 4008H 			; and turn on
		LD BC,50 			; 50 ms delay
		CALL 4038H
		LD (IY+17),14 		; set Sector Number in SCTR
		LD (IY+18),28 		; set Track Number in TRCK
		CALL 4035H 			; read sector
		OR A 				; error occurred?
		JP NZ,400EH 		; yes, to the ERROR routine
		CALL 400BH 			; turn off drive
		EI 					; enable interrupts again
		...

	Sector 14 data on track 28 is transferred from the disk in drive 2 to the
	data buffer.
	
Internally called routines: IDAM

