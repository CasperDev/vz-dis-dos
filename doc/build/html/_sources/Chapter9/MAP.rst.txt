

MAP - Detect a free sector on the disk
--------------------------------------

.. admonition:: Syntax:

	.. code:: Z80

		CALL 4029H

	.. cmdoption:: Input: 
		
		- filename in FNAM (IY+1)
		- File Type in TYPE (IY+9)

	.. cmdoption:: Exit: 
		
		- NSCT (IY+21) = Sector Number
		- NTRK (IY+22) = Track Number
		- The sector addressed with NSCT and NTRK was reserved іп internal
		  allocation map (MAPAREA)

	.. cmdoption:: Registers used: 
		
		AF, BC, HL

	.. cmdoption:: Error handling: 
		
		- A = 0 sector found
		- A = 7 no free sector (disk full)
  
This routine determines a free sector in the internal allocation map in DOS
vectors (MAPAREA), which should previously be filled with the current
allocation map from track 0, sector 15 of the diskette.

If a free sector is determined, the corresponding bit in the allocation map is
set to 1.

Please note, however, that a final allocation has only taken place when the
allocation map has been written back to the diskette.

The result (the sector address) is passed in the NSCT and NTRK fields of the
DOS vectors. If you want to access the sector, e.g. with WRITE, you must first
transfer this address to the SCTR and TRCK fields.

No disk access is performed by the MAP routine.

.. admonition:: Example:
	:class: hint

	.. code:: Z80

		...
		DI 					; disable interrupts
		LD (IY+11),80H 		; select Drive 2
		CALL 4008H 			; and turn on
		LD BC,50 			; 50 ms delay
		CALL 4011H 			; load allocation map
		CALL 4029H 			; determine free sector
		OR A 				; error occured?
		JP NZ,400EH 		; yes, to the ERROR routine
		CALL 4017H 			; write back allocation map
		CALL 400BH 			; turn off the drive
		EI 					; allow interrupts again
		...

	A free sector is determined and allocated on the diskette in drive 2. The
	sector address is passed in the NSCT and NTRK fields of the DOS
	vectors.

