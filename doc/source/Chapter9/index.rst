

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

.. code:: asm
	:class: hint

	CALL xxxxH

The following subroutines can be reached via this jump table:

.. csv-table:: 
	:delim: |

	Name   | Call | Function
	PWRON  | CALL 4008H | Turn on the drive
	PWROFF | CALL 400BH | Turn off the drive
	ERROR  | CALL 400EH | DOS error handling
	RDMAP  | CALL 4011H | Load sector occupancy Map
	CLEAR  | CALL 4014H | Delete sector
	SVMAP  | CALL 4017H | Write allocation Map sector
	INIT   | CALL 401AH | Initialize disk
	CSI    | CALL 401DH | Interpret command parameters
	HEX    | CALL 4020H | Conversion ASCII to HEX
	IDAM   | CALL 4023H | Look for the address mark on the diskette
	CREATE | CALL 4026H | Write an entry in the table of contents
	MAP    | CALL 4029H | Detect a free sector
	SEARCH | CALL 402CH | Find file in table of contents
	FIND   | CALL 402FH | Look for free space in the table of contents
	WRITE  | CALL 4032H | Write sector to disk
	READ   | CALL 4035H | Read sector from disk
	DLY    | CALL 4038H | n milliseconds delay
	STPIN  | CALL 403BH | Advance head n tracks inward
	STPOUT | CALL 403EH | Advance head n tracks outward
	LOAD   | CALL 4041H | Load a program
	SAVE   | CALL 4044H | Save a program


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
in the DOS work area as temporary storage. Remember that each time a sector is
read or written, its content is modified.

The operating system generates an interrupt every 20 ms, which is normally used to
update the screen content and evaluate the keyboard.

However, these interruptions are not desirable for disk accesses, where very precise
time intervals are important; they would make error-free access impossible.

For this reason you must switch off the interrupts with DI (disable interrupts) and
then switch them on again with EI (enable interrupts) before each diskette access.

In many cases, you must also check whether the diskette to be edited is
write-protected; otherwise, write operations are still performed.

.. toctree:: 

	PWRON
	PWROFF
	ERROR
	RDMAP
	CLEAR
	SVMAP
	INIT
	CSI

