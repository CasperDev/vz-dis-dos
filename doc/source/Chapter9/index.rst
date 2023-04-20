
.. toctree:: 
	:maxdepth: 2



9. The most important DOS routines and their application іп machine programs.
=============================================================================

Call and Overview
-----------------

As already mentioned several times, the DOS occupies the address space 4000H to
5FFFH. It is in ROM chips built into the floppy disk controller. The floppy disk
controller is connected to the system bus of the computer.

The presence of a floppy disk controller is determined when the computer is
switched on by checking a specific byte sequence (AA 55 E7 18). If this byte
sequence is found, the subsequent initialization routine is called automatically, which
among other things attaches a BASIC vector so that the special DOS commands can
be recognized and executed.

This is the RESTART 10 vector at address 7803H in the BASIC communications
area. If this vector is called up by BASIC within the command analysis (at address
1D5AH), the DOS first checks whether a special DOS command is present. If no, the
program continues with the normal BASIC command execution. If a DOS command
is recognized, the necessary execution routines are called in DOS.

The DOS vector area at the end of the memory is also built up by the DOS
initialization routine and filled with initial values.

You can also check within a machine program whether a floppy disk controller is
connected to the system bus by checking the corresponding byte sequence at
address 4000H.

The DOS itself consists of a number of self-contained routines. A large part of it can
also be called from machine programs, so that individual diskette and data handling
can be programmed and executed there.

You could use it to edit the existing file system of DOS, but you could also create
completely new structures and forms of processing, such as the previously
mentioned files with direct access, which are not supported by DOS.

Jumping to the individual routines directly at their start addresses would be one of
the possible uses. However, you would then fix the programs to a D0S version, since
each time the DOS changes, some of these addresses are also shifted.

A more elegant solution is to use a jump table at the beginning of the DOS, which
was created by the manufacturer for this purpose and allows the most important
subroutines to be called.

It is called using the Z80 command

.. code:: Z80
	:class: hint

	CALL xxxxH

The following subroutines can be reached via this jump table:

.. role:: Z80(code)
	:language: Z80
	:class: highlight

.. csv-table:: 
	:delim: |

	Name   | Call | Function
	:doc:`PWRON <PWRON>` | :Z80:`CALL 4008H` | Turn on the drive
	:doc:`PWROFF <PWROFF>` | :Z80:`CALL 400BH` | Turn off the drive
	:doc:`ERROR <ERROR>`  | :Z80:`CALL 400EH` | DOS error handling
	:doc:`RDMAP <RDMAP>`  | :Z80:`CALL 4011H` | Load sector occupancy Map
	:doc:`CLEAR <CLEAR>`  | :Z80:`CALL 4014H` | Delete sector
	:doc:`SVMAP <SVMAP>`  | :Z80:`CALL 4017H` | Write allocation Map sector
	:doc:`INIT <INIT>`   | :Z80:`CALL 401AH` | Initialize disk
	:doc:`CSI <CSI>`    | :Z80:`CALL 401DH` | Interpret command parameters
	:doc:`HEX <HEX>`    | :Z80:`CALL 4020H` | Conversion ASCII to HEX
	:doc:`IDAM <IDAM>`   | :Z80:`CALL 4023H` | Look for the address mark on the diskette
	:doc:`CREATE <CREATE>` | :Z80:`CALL 4026H` | Write an entry in the table of contents
	:doc:`MAP <MAP>`    | :Z80:`CALL 4029H` | Detect a free sector
	:doc:`SEARCH <SEARCH>` | :Z80:`CALL 402CH` | Find file in table of contents
	:doc:`FIND <FIND>`   | :Z80:`CALL 402FH` | Look for free space in the table of contents
	:doc:`WRITE <WRITE>`  | :Z80:`CALL 4032H` | Write sector to disk
	:doc:`READ <READ>`   | :Z80:`CALL 4035H` | Read sector from disk
	:doc:`DLY <DLY>`    | :Z80:`CALL 4038H` | n milliseconds delay
	:doc:`STPIN <STPIN>`  | :Z80:`CALL 403BH` | Advance head n tracks inward
	:doc:`STPOUT <STPOUT>` | :Z80:`CALL 403EH` | Advance head n tracks outward
	:doc:`LOAD <LOAD>`   | :Z80:`CALL 4041H` | Load a program
	:doc:`SAVE <SAVE>`   | :Z80:`CALL 4044H` | Save a program


However, before you call one of these subroutines, very specific input parameters
often have to be set, e.g. entry of the file name in the DOS vector, drive selection in
the DK field, etc...

It is also important to know which results such a subroutine returns where and which
possible error codes are reported.

You should also know which registers are changed in the subroutines
so you can save them beforehand.

The following pages describe each of these subroutines with their input and output
values, registers used and error codes. In addition, there is a function description
and an application/call example.

Two additional functions that you cannot access via the jump table but can easily be
programmed yourself are also listed. These are the drive selection and checking the
write protection of the floppy disk.

Be careful not to change register IY in your program. The start address of the DOS
vectors is entered there during the initialization, which not only the DOS, but also you
constantly need when using the routines mentioned above.

Some routines return error codes in register A. In any case, you should check
whether your call was successful or not.

All data that is moved between the computer and the floppy disk uses the data buffer
in the :ref:`DOS work area` as temporary storage. Remember that each time a sector is
read or written, its content is modified.

The operating system generates an interrupt every 20 ms, which is normally used to
update the screen content and evaluate the keyboard.

However, these interruptions are not desirable for disk accesses, where very precise
time intervals are important; they would make error-free access impossible.

For this reason you must switch off the interrupts with DI (disable interrupts) and
then switch them on again with EI (enable interrupts) before each diskette access.

In many cases, you must also check whether the diskette to be edited is
write-protected; otherwise, write operations are still performed.

DOS Vector functions
--------------------

.. toctree::

	PWRON
	PWROFF
	ERROR
	RDMAP
	CLEAR
	SVMAP
	INIT
	CSI
	HEX
	IDAM
	CREATE
	MAP
	SEARCH
	FIND
	WRITE
	READ
	DLY
	STPIN
	STPOUT
	LOAD
	SAVE

DOS Extra functions
--------------------

To supplement these routines, two more functions are listed here that you will find in
many of the previous examples.

.. _procDRIVE:

DRIVE - Selecting a drive
+++++++++++++++++++++++++

This function cannot be accessed via the jump table.

However, it is easy to do as you just need to put the correct code of the
selected drive in the DK (IY+11) field of the DOS vectors.

.. admonition:: Example:
	:class: hint

	.. code-block:: Z80

      LD (IY+11),10H		; Drive 1
      LD (IY+11),80H		; Drive 2
  
This code is used by the PWRON routine to select the correct drive and turn it
on.

.. _procWPROCT:

WPROCT - Check write protection
+++++++++++++++++++++++++++++++

In many cases, you are responsible for checking the write-protection status of
a diskette before performing a write operation.

You can get the information about this via port 13H. If the diskette's
write-protection notch is taped over, bit 7 of this port is set to 1.

To do this, the drive must be selected and switched on.

.. admonition:: Example:
	:class: hint

	.. code-block:: Z80

		...
		IN A,(13H) 				; read in port 13
		OR A 					; check byte
		LD A,4 					; set error code
		JP M,400EH 				; if negative, then the disk is
								; write-protected.
		...


If the diskette is write-protected, error code 4 branches to the ERROR routine
and the message ``"?DISK WRITE PROTECTED"`` is output there



