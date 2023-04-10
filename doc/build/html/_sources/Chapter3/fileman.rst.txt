


File management functions
=========================

DIR - Display of the table of contents
--------------------------------------

.. admonition:: Syntax: 
	
	.. code:: BASIC

		DIR
	
	Allowed as direct command and in program mode.

The DIR command displays a directory of all programs and files stored on the
diskette on the screen.

The listing includes file type and file name.

.. admonition:: Possible file types:

	``T`` = BASIC - program (text file)
	
	``B`` = machine program (binary file)
	
	``D`` = data file


.. admonition:: Example:
	:class: hint

	.. code:: BASIC
		
		DIR
		B:SCHACH
		B:KALACH
		T:AB.LAND
		T:ANSCHR
		D:KARTEI
		READY

	The disk contains:

	* two machine programs, SCHACH and KALAH,
	* two BASIC programs, AB.LAND and ANSCHR and
	* a data file called KARTEI.

The listing can be stopped by pressing the space bar (SPACE) and continued
with the same key.

.. admonition:: Possible Errors:
	:class: error

	``?DISK I/O ERROR`` The table of contents of the diskette
	could not be read properly.





SAVE - Saving a BASIC program to floppy disk
--------------------------------------------

.. admonition:: Syntax:
	
	.. code:: BASIC

		SAVE "name"
		"name" - program name with a maximum of 8 characters,
		         enclosed in quotation marks.

	Allowed as direct command and in program mode.

A BASIC program in memory is saved on the floppy disk under the file name
"name".

The program is given the type designation ``"T"`` (text file).

In direct mode, the completion of the storage process is indicated with
READY.

In program mode, the program is continued with the command following
"SAVE".

.. admonition:: Example:
	:class: hint

	.. code:: BASIC

		SAVE "KARTEI"

	transfers a BASIC program in memory to the floppy disk under the
	name "KARTEI".

.. admonition:: Possible Errors:
	:class: error

	``?SYNTAX ERROR`` 
	
	* no file name specified
	* Filename not in quotes
	* No end of line (RETURN) or command separator ``":"`` after the file name.
  

	``?DISK WRITE PROTECTED`` The disk's write-protect notch is
	taped over.

	``?FILE ALREADY EXISTS`` A file with the same name already exists on
	the diskette.

	``?DIRECTORY FULL`` There is no more space in the table of
	contents (maximum 120 entries).

	``?DISK FULL`` There are not enough free sectors on the
	diskette for the program.

	``?DISK I/O ERROR`` An error occurred while writing or reading
	the floppy disk..

The writing process can be aborted at any time by pressing the BREAK key.
However, depending on when the key is pressed, the entry in the table of contents is
not always deleted (error in DOS).

In order to ensure problem-free diskette management, you should therefore check
the table of contents with DIR in such a case and, if necessary, delete the file
manually with ERA.


LOAD - Loading a BASIC program from diskette
--------------------------------------------

.. admonition:: Syntax: 

	.. code:: BASIC

		LOAD "name"
		"name" - program name with a maximum of 8 characters,
		         enclosed in quotation marks.

	Allowed as direct command and in program mode.

A BASIC program saved on the diskette with the file name "name" is loaded
into memory.

The completion of the storage process is indicated with READY.

.. admonition:: Example:
	:class: hint

	.. code:: BASIC

		LOAD "KFZ"

	Transfers the BASIC program KFZ from the diskette to the memory.

You can then look at a BASIC program loaded in this way with LIST and modify it if
necessary.

.. admonition:: Warning:
	:class: warning

	Before writing a modified program back to the diskette, you must either first delete
	the program on it with "ERA" or give the modified program a different name.

.. admonition:: Example:
	:class: hint

	.. code:: BASIC

		LOAD "XYZ"
		>READY
		LIST
		...
		...		modify
		... 
		ERA "XYZ"
		>READY
		SAVE "XYZ"

After the program has been read in, direct mode (BASIC warm start) is always
accessed, regardless of whether the call was made directly or from within a program.

The reading process can be aborted at any time by pressing the BREAK key.

.. admonition:: Possible Errors:
	:class: error

	``?SYNTAX ERROR``
	
	* no file name specified
	* Filename not in quotes
	* No end of line (RETURN) or command separator ``":"`` after the file name.

	``?FILE NOT FOUND`` No program with the specified name could
	be found on the diskette..

	``?FILE TYPE MISMATCH`` A file with the same name was found on the
	diskette, but this is not a BASIC program
	(file type = ``T``).

	``?DISK I/O ERROR`` An error occurred while reading from the
	floppy disk. (faulty disk or centering problems)


RUN - Load and start a BASIC program
------------------------------------

.. admonition:: Syntax: 
	
	.. code:: BASIC
		
		RUN "name"
		"name" - program name with a maximum of 8 characters,
		         enclosed in quotation marks.

	Allowed as direct command and in program mode.

A BASIC program saved under "name" on the diskette is loaded into memory
and executed.

.. admonition:: Example:
	:class: hint

	.. code:: BASIC

		RUN "GRAFIK"

	The BASIC program "GRAFIK" is loaded and executed.

.. admonition:: Possible Errors:
	:class: error

	``?SYNTAX ERROR``
	
	* no file name specified
	* Filename not in quotes
	* No end of line (RETURN) or command separator ``":"`` after the file name.

	``?FILE NOT FOUND`` No program with the specified name could
	be found on the diskette..

	``?FILE TYPE MISMATCH`` A file with the same name was found on the
	diskette, but this is not a BASIC program
	(file type = ``T``).

	``?DISK I/O ERROR`` An error occurred while reading from the
	floppy disk. (faulty disk or centering problems)


BSAVE - Saving a machine program on diskette
--------------------------------------------

.. admonition:: Syntax: 
	
	.. code:: BASIC
	
		BSAVE "name",aaaa,eeee
		"name" - program name with a maximum of 8 characters,
		         enclosed in quotation marks.
		aaaa   - Program start address, 4 digits;
		         in hexadecimal notation.
		eeee   - Program end address, 4 digits;
		    	 in hexadecimal notation.

	Allowed as direct command and in program mode.

A machine program in memory is written to the floppy disk from address
"aaaa" to address "eeee" with the file name "name".

It receives the type designation ``"B"`` (binary file) in the table of contents.
In direct mode, the completion of the storage process is indicated with
READY. In program mode, the program is continued with the command
following BSAVE.


Instead of a machine program, this command can also be used to transfer any
memory area to the diskette and then load it again with BLOAD.

Only BRUN requires an executable machine program as this is started
immediately after loading.

.. admonition:: Example:
	:class: hint

	.. code:: BASIC
		
		BSAVE "BOWLING",8000,94FF

	The "BOWLING" machine program is transferred to the diskette from
	address 8000H to address 94FFH.

.. admonition:: Possible Errors:
	:class: error

	``?SYNTAX ERROR``

	* no file name specified
	* Filename not in quotes
	* Start and/or end address missing
	* Start or end address not 4 digits hexadecimal (0~F)
	* parameters not separated by comma,
  
	``?DISK WRITE PROTECTED`` The disk's write-protect notch is taped over.

	``?FILE ALREADY EXISTS`` A file with the same name already exists on
	the diskette.

	``?DIRECTORY FULL`` There is no more space in the table of
	contents (maximum 128 entries).

	``?DISK FULL`` There are not enough free sectors on the
	diskette for the program.

	``?DISK I/O ERROR`` An error occurred while reading from the
	floppy disk. (faulty disk or centering problems)

The writing process can be aborted at any time by pressing the BREAK button.
However, depending on when the key is pressed, the entry in the table of contents is
not always deleted (error in DOS).

In order to ensure problem-free diskette management, you should therefore check
the table of contents with DIR in such a case and, if necessary, delete the file
manually with ERA.



BLOAD - Loading a machine program from diskette
-----------------------------------------------

.. admonition:: Syntax: 
	
	.. code:: BASIC

		BLOAD "name"
		"name" - program name with a maximum of 8 characters,
		         enclosed in quotation marks.

	Allowed as direct command and in program mode.

A machine program stored on the diskette with the file name "name" is loaded
into the memory.

With a direct command, the end of the loading process is indicated with
READY, in program mode the program is continued with the command
following BLOAD.

.. admonition:: Example:
	:class: hint

	.. code:: BASIC

		BLOAD "UPR01"
		
		Machine program UPR01 is loaded from the diskette.

The command is particularly suitable for loading machine program routines
saved with BSAVE from a BASIC program and calling them as subroutines via
USR.

.. admonition:: Example:
	:class: hint

	.. code:: BASIC

		...
		220 BLOAD "UPR01": 'LOAD SUBPROGRAM
		230 POKE 30862,0: 'LSB START ADDRESS = 00
		240 POKE 30863,176: 'MSB START ADDRESS = B0
		250 A = USR(0): 'CALL SUBROUTINE
		...

	The subprogram UPR01 is to be loaded from diskette 
	and called at address В000.

.. admonition:: Possible Errors:
	:class: error

	``?SYNTAX ERROR``
	
	* no file name specified
	* Filename not in quotes
	* No end of line (RETURN) or command separator ``":"`` after the file name.

	``?FILE NOT FOUND`` No program with the specified name could
	be found on the diskette.

	``?FILE TYPE MISMATCH`` A file with the same name was found on the
	diskette, but this is not a machine program
	(file type = ``B``).

	``?DISK I/O ERROR`` An error occurred while reading from the
	floppy disk. (faulty disk or centering problems)

BRUN - Loading and starting a machine program
---------------------------------------------

.. admonition:: Syntax: 

	.. code:: BASIC

		BRUN "name"
		"name" - program name with a maximum of 8 characters,
		         enclosed in quotation marks.

	Allowed as direct command and in program mode.

A machine program stored on the floppy disk under the file name "name" is
loaded into memory and executed.

The program starts exclusively at the program start address (see BSAVE).

.. admonition:: Example:
	:class: hint

	.. code:: BASIC

		BRUN "FIFFI"

	The "FIFFI" machine program is loaded and started.


.. admonition:: Possible Errors:
	:class: error

	``?SYNTAX ERROR``
	
	* no file name specified
	* Filename not in quotes
	* No end of line (RETURN) or command
	  separator ``":"`` after the file name.

	``?FILE NOT FOUND`` No program with the specified name could
	be found on the diskette.

	``?FILE TYPE MISMATCH`` A file with the same name was found on the
	diskette, but this is not a machine program
	(file type = ``B``).

	``?DISK I/O ERROR`` An error occurred while reading from the
	floppy disk. (faulty disk or centering problems)

REN - Renaming files and programs
---------------------------------

.. admonition:: Syntax: 
	
	.. code:: BASIC

		REN "name1","name2"
		"name1" - File/program name, old, max. 8 characters,
		          enclosed in quotation marks.
		"name2" - File/program name, new, max. 8 characters,
		          enclosed in quotation marks.

	Allowed as direct command and in program mode.

A program or file on the disk under the name "name1" is renamed "name2".

.. admonition:: Example:
	:class: hint

	.. code:: BASIC

		REN "OTTO","ANTON"

	The "OTTO" file is renamed to "ANTON".

.. admonition:: Possible Errors:
	:class: error

	``?SYNTAX ERROR`` 
	
	* "name1" and/or "name2" are missing.
	* "name1" or "name2 not in quotes
	* names not separated by commas

	``?DISK WRITE PROTECTED`` The disk's write-protect notch is taped over.

	``?FILE NOT FOUND`` The file named "name1" is not on the disk.

	``?FILE ALREADY EXISTS`` The file named "name2" already exists on
	the diskette.

	``?DISK I/O ERROR`` An error occurred while reading from the
	floppy disk. (faulty disk or centering problems)





DCOPY - Copy a program
----------------------

.. admonition:: Syntax: 
	
	.. code:: BASIC

		DCOPY "name"
		"name" - program name with a maximum of 8 characters,
		         enclosed in quotation marks.

	Only permitted as a direct command,.

The DCOPY command with specification of a program name causes this
program to be copied from one diskette to another.

After entering the command, you will first be prompted to specify the source
and target drives.

.. code:: BASIC
	:class: hint

	SOURCE DISK (1/2)?
	DESTINATION DISK (1/2)?

Answer each of these two questions by pressing the '1' or '2' key.

If you only have one drive, answer '1' to each question.

You can abort command execution with CTRL/BREAK.

After selecting the drive, the copying process begins. The copying takes place
by calling the LOAD and SAVE routines, as they are also used with LOAD and
BLOAD, or with SAVE and BSAVE.

For this reason, it is not possible to copy a single data file (file type = D) with
the DCOPY command, as this is structured differently.
If you are copying to only one drive (SOURCE DISK = DESTINATION DISK),
you will be prompted before loading

.. code:: BASIC
	:class: hint
	
	INSERT SOURCE DISKETTE
	(PRESS SPACE WHEN READY)

and before writing the prompt

.. code:: BASIC
	:class: hint

	INSERT DESTINATION DISKETTE
	(PRESS SPACE WHEN READY)

If you have inserted the correct diskette, press the spacebar to continue the
function.

You can interrupt the copying process at any time with the BREAK button. If
you do this during the writing process, please note the information on SAVE
and BSAVE.

When copying is complete, the message READY appears.

.. admonition:: Example: (system outputs are marked with '>')
	:class: hint

	.. code:: BASIC

		>READY
		DCOPY "EMIL"
		>SOURCE DISK (1/2)?
		1
		>DESTINATION DISK (1/2)?
		1
		>INSERT SOURCE DISKETTE
		>(PRESS SPACE WHEN READY)
		spacebar
		...
		...      loading process
		...
		>INSERT DESTINATION DISKETTE
		>(PRESS SPACE WHEN READY)
		spacebar
		... 
		...      saving process
		...
		>READY

	The program to be copied overwrites its original memory area in RAM.

After copying is complete, drive 1 is always selected, regardless of a previous DRIVE
command.

.. admonition:: Possible Errors:
	:class: error

	``?ILLEGAL DIRECT`` An attempt was made to call the DCOPY
	command from a program.

	``?SYNTAX ERROR`` 
	
	* no file name specified
	* Filename not in quotes
	* No end of line (RETURN) or command
	  separator ``":"`` after the file name.

	``?FILE NOT FOUND`` No program with the specified name could
	be found on the diskette..

	``?FILE TYPE MISMATCH`` An attempt was made to copy a data file.

	``?DISK WRITE PROTECTED`` The target disk's write-protect notch is taped
	over.

	``?FILE ALREADY EXISTS`` A program named "name" already exists on
	the target disk.

	``?DIRECTORY FULL`` The table of contents of the destination disk
	is full. The program can no longer be
	entered (max. 128 files/programs).

	``?DISK FULL`` There is no more space on the destination
	disk.

	``?DISK I/O ERROR`` An error occurred while reading from the
	floppy disk. (faulty disk or centering problems)


ERA - Delete a file or program on the floppy disk
-------------------------------------------------

.. admonition:: Syntax: 
	
	.. code:: BASIC
		
		ERA "name"
		"name" - File/program name, max. 8 characters,
		         enclosed in quotation marks.

	Allowed as direct command and in program mode.

A program or data file designated by "name" is deleted from the diskette.
To do this, the entry in the table of contents is deleted and all sectors occupied
by this file are released.

.. admonition:: Example:
	:class: hint

	.. code:: BASIC

		ERA "DAT1"

	The file named "DAT1" will be deleted.

.. admonition:: Possible Errors:
	:class: error

	``?SYNTAX ERROR``
	
	* no file name specified
	* Filename not in quotes
 
	``?DISK WRITE PROTECTED`` The target disk's write-protect notch is taped
	over.

	``?FILE NOT FOUND`` No program with the specified name could
	be found on the diskette..

	``?DISK I/O ERROR`` An error occurred while reading from the
	floppy disk. (faulty disk or centering problems)



