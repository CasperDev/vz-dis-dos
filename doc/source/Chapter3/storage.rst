


Storage and processing of data
==============================


File organization and access
----------------------------

The LASER-DOS allows you to save data on the diskette from a BASIC program and
then process them again.

This data is stored in special data files with the type code ``"D"``.

The storage form offered is "sequential". Sequential means that the data in the file is
stored one after the other, like on a cassette. Reading or writing data always begins
at the beginning of the file, further read and write calls access the subsequent
positions of the file.

In contrast to this is the "direct" type of access (random access), with which any data
in a file can be accessed directly. Unfortunately, the LASER-DOS does not support
this type of memory as standard. However, it can easily be reproduced with a little
knowledge of assembler/machine language and the help routines described in the
last chapter.

Sequential access is data flow oriented, i.e. the number of characters for a write or
read process can vary. This is also referred to as data records of variable length,
where a data record is the sum of the data elements that are written to or read from
the diskette with a write or read call.

Sequential files represent the simplest form of data storage and retrieval. They are
ideal for storing raw data without wasting a lot of space between each data element.
Data is read back in the same order as it was written.

In order to be able to access a data file, it must first be opened. A special :guilabel:`OPEN` call
is available for this purpose. With the opening you also specify the type of access,
whether data should be written or read.

After completing the data manipulations, each data file should be closed with a :guilabel:`CLOSE` call.

	
When editing data files, there are a few important points to keep in mind:

* If a file that does not exist is opened for writing, it is created anew and
  positioned at the start of the file.

* If an existing file is opened for writing, it is positioned at the end of the file, i.e.
  the file is extended with the following write calls.

* If you want to rewrite an existing file from the beginning, you must first delete
  it.

* After opening, reading always begins at the beginning of the file. If you are
  looking for data within a file, you must read over the preceding ones.

* To update a sequential file, read in the source file and write the updated data
  to a new file.

* When reading the file, the exact structure of the data record to be read must
  be known. This does not refer to the length of the sentence and the individual
  elements; However, you must know the number of elements and the format of
  each element (string, integer, etc.) and provide an appropriate receiving field
  for each element.

* Within the file, the data is stored exclusively in ASCII format. The individual
  elements are separated by commas. For example, the number 1.2345 takes
  up 8 bytes of storage, including a space for the sign at the beginning and
  another space at the end. The text "ROBERT MAIER" takes up 12 bytes on
  the disk.

* A data record should not be longer than 200 bytes, otherwise problems with
  the internal data structure of BASIC will occur when reading.

  The 200 bytes count

	* the individual characters
	* the commas as element separators
	* for numbers, the sign and an additional space
	* a final RETURN (CR) at the end of the sentence
	* A maximum of two files can be opened at the same time, whereby the types
	  of access can be the same or mixed.

  .. warning:: 

	If your system reports :token:`DISK BASIC V1.0`, work with one file at a time to be on
	the safe side. The management of two open files is still incorrect there and
	can lead to significant data loss.

* The DOS does not tell you when the end of the file is reached when reading,
  you have to determine this yourself, for example by writing a specific end
  identifier as the last in the file.


Example of sequential output:
+++++++++++++++++++++++++++++

We want to store a table of English to metric conversion data.

.. csv-table::
	:header-rows: 1
	:delim: |
	:align: center

	English unit | Metric unit
	1 Inch| 2.54001cm
	1 Mile| 1.60935 km
	1 Acre| 4046.86 qm
	1 Cubic Inch| 0.01639 ltr
	1 U.S. Gallon| 3.785 ltr
	1 Liquid Quart| 0.9463 ltr
	1 lbs |0.45359 kg

The data should be structured as follows on the diskette and entered in a data file
called "ENG>MET":

	**"English unit -> Metric unit” , conversion factor**

e.g. "IN->CM", 2.54001

The following program creates such a file.

.. code:: BASIC
	:class: hint

	10 OPEN "ENG>MET",1
	20 FOR I% = 1 TO 7
	30 READ E$,F
	40 PR# "ENG>MET",E$,F
	50 NEXT
	60 CLOSE "ENG>MET"
	70 DATA "IN->CM",2.54001,"MI->KM",1.60935,"ACRE->QKM",4046.86E-6
	80 DATA "CU.IN->LTR",1.638716E-2,"GAL->LTR",3.785
	90 DATA "LIQ.QT->LTR",0.9463,"LB->KG",0.45359
	100 END

| Line 10 creates the file "ENG>MET" and opens it for writing.
| In line 40, one data record is written to the file.
| Line 50 closes the "ENG>MET” file again.

Example of sequential input:
++++++++++++++++++++++++++++

The following program reads the "ENG>MET" file into two parallel matrices and then
asks about conversion problems.

.. code:: BASIC
	:class: hint
	:force:

	10 CLEAR 1000
	20 DIM E$(6),F(6)
	30 OPEN "ENG>MET",0
	40 FOR I% = 0 TO 6
	50 IN# "ENG>MET",E$(I%),F(I%)
	60 NEXT
	70 CLOSE "ENG>MET"
	100 CLS: PRINT "CONVERSION ENGLISH=>METRIC"
	110 PRINT: FOR I%=0 TO 6
	120 PRINT TAB(4); USING "(## ) % % ";I%,E$(I%)
	130 NEXT
	140 PRINT @320, "WHICH CONVERSION (0-6)";
	150 INPUT W%: IF W% > 6 THEN 190
	160 INPUT "ENGLISH VALUE";V
	170 PRINT "THE METRIC VALUE IS" V*F(W%)
	180 INPUT "CONTINUE WITH <RETURN>";X
	190 GOTO 100


Line 30 opens the file for input. Reading begins at the beginning of the file.
In line 50, a data set with the elements E$ (unit) and F (factor) is read and distributed
to the matrices. 

Note that the variable list when reading in is the same as the write command in the
previous program. 

In line 70 the file is closed again. 

Updating a file
+++++++++++++++

If you want to add one or more records to an existing file, open this file for writing
and simply enter additional data records with :ref:`PR# <cmdPR#>`, which will be appended to the
existing database.

If you want to change data within a file, we recommend the following procedure (not
with :token:`DISK BASIC V1.0`).

  1. Open the file to be edited for reading.
  2. Open a second new file for writing
  3. Read a record and edit the data
  4. Write the record to the new file
  5. Repeat points 3 and 4 to the end of the file
  6. Close both files
  7. Delete the source file
  8. Rename the new file to the original file

With DISK BASIC V1.0, the only solution is to read the file to be processed
completely іп the memory, process it and write it completely into the new file.
However, this limits the size of the file to the available memory.

.. _cmdOPEN:

OPEN - Open a file.
-------------------

.. admonition:: Syntax:
	
	.. code:: BASIC

		OPEN "name",n
		"name" - File/program name, max. 8 characters,
		         enclosed in quotation marks.
		n - type of access
		    0 - Read
		    1 - Write

	Permitted only in program mode.

The :guilabel:`OPEN` command opens a data file (type = ``D``) for writing or reading.

The :guilabel:`OPEN` command creates a file control block internally for each open file,
which contains function codes and pointers.

Furthermore, the following is positioned on the data according to the access
code:
* When reading, always at the beginning of the file
* When writing to a new file, to the beginning of the file
* When writing to an existing file at the end of the file,

Since there are only two file control blocks in the system, only two files can be
open at a time. The type of access is irrelevant, both can be opened for
writing, both for reading or one for reading and the second for writing (see
restriction DISK BASIC V1.0 on the previous pages).

.. admonition:: Example:
	:class: hint

	.. code:: BASIC

		OPEN "TEST",0

	The "TEST" data file is opened for reading.

A data file can only be opened once at a time. Attempting to open the same
file again results in an error message.

Since the file control blocks (:ref:`FCB`) are located outside the BASIC programs, a
file remains open if the calling program was aborted before the :guilabel:`CLOSE` call
due to an error or by pressing the :kbd:`BREAK` key and is perhaps no longer in
memory. Such a file can no longer be opened without further ado.

If it happen that a BASIC program is aborted without properly closing its files,
you should do so with a direct command (:guilabel:`CLOSE "filename"`).

.. admonition:: Possible Errors:
	:class: error

	``?ILLEGAL DIRECT`` An attempt was made to execute the :guilabel:`OPEN`
	command in direct mode.

	``?SYNTAX ERROR``

	* one or both parameters are missing
	* no comma as separator
	* filename not in quotes
	* access type not 0 or 1

	``?FILE ALREADY OPEN`` File is already open, if necessary close it
	with the direct command :guilabel:`CLOSE`.

	``?FILE TYPE MISMATCH`` The file addressed in the :guilabel:`OPEN` command is
	not a data file
	
	``?FILE NOT FOUND`` A file to be opened for reading does not exist
	on the diskette.

	``?DISK BUFFER FULL`` Two files are already open and no more file
	control block is available.

	``?DISK I/O ERROR`` An error occurred while reading from the
	floppy disk.


.. _cmdPR#:

PR# - Writing records to a file
-------------------------------

.. admonition:: Syntax: 
	
	.. code:: BASIC

		PR# "name",item list
		"name" - File/program name, max. 8 characters,
		         enclosed in quotation marks.
		item list - List of variables and values to be written to the file.
		            The individual elements are to be separated by commas

	Permitted only in program mode.

Assembles a data record from the values in the element list and causes it to
be written to the data file.

This must first have been opened for writing with an :guilabel:`OPEN` command.

.. admonition:: Example:
	:class: hint

	.. code:: BASIC

		200 A1 = -40.456: B$ = "STRING-VALUE"
		210 OPEN "TEST",1
		220 PR# "TEST",A1,B$,"THE VAR'S"
		230 CLOSE "TEST"
		240 END

After opening the "TEST" file in line 210, a data record is compiled in line 220
and written to this file.

The data record contains the current values of Al and B$ and also the
character string "THE VAR'S". The values can later be read in again with an
:guilabel:`IN#` command.

It must be ensured that the element list of the :guilabel:`IN#` command is the same as
that of the :guilabel:`PR#` command with regard to the number and type of elements.

The values represented by the item list should not exceed 200 characters in
total. In addition to the values themselves, this also includes all separators
(commas) between the values, in the case of numeric values the sign position
and a trailing space and finally the end of data record identifier (CR).

The record in the previous example would be 31 characters long

	-40,456 ,STRING VALUE, THAT'S IT

Unfortunately, when creating the element list, one often does not know exactly
how large the individual variables will be at the time of storage. Then only
careful estimation helps. Always stay on the safe side and, if in doubt, split
your element list into several :guilabel:`PR#` commands.

Unfortunately, the :guilabel:`PR#` command does not notice when a data record is too
long. This is simply written to the diskette in its entirety. Reading in with the
IN# command then causes problems, whereby in the simplest case "only"
data is lost.

.. admonition:: Possible Errors:
	:class: error

	``?ILLEGAL DIRECT`` An attempt was made to execute the :guilabel:`PR#`
	command in direct mode.

	``?SYNTAX ERROR``

	* no file name specified
	* Filename not in quotes
	* no item in the list
	* no comma as separator
  
	``?FILE NOT OPEN`` File was not previously opened.

	``?ILLEGAL WRITE`` The file has been opened for reading.

	``?DISK WRITE PROTECTED`` The disk's write-protect notch is taped over.

	``?DISK FULL`` No more free sectors could be found on the
	diskette.

	``?DISK I/O ERROR`` An error occurred while reading or writing to
	the diskette.

.. warning:: 

	If one of these errors occurs, the program is terminated with the
	corresponding error message. Please note that this file was not closed
	afterwards, you should do this manually.

.. _cmdIN#: 

IN# - Reading records from a file
---------------------------------

.. admonition:: Syntax:
	
	.. code:: BASIC

		IN# "name",item list
		"name" - File/program name, max. 8 characters,
		         enclosed in quotation marks.
		item list - List of variables and values to be written to the file.
		            The individual elements are to be separated by commas

	Permitted only in program mode.

:guilabel:`IN#` reads a record from the specified file and assigns the elements of that
record to the specified variables.

The file must first have been opened for reading with an :guilabel:`OPEN` command.

.. admonition:: Example:
	:class: hint

	.. code:: BASIC

		200 OPEN "TEST",0
		210 IN# "TEST",X,A$,B$
		220 CLOSE "TEST"
		...
		...

This example refers to the data set created in the example of the :guilabel:`PR#`
command in the "TEST" file. The data stored there are assigned to the
variables of the :guilabel:`IN#` command in sequence.

After executing line 210, the variables contain the following values:

.. code:: BASIC
	:class: hint

	X = -40.456
	A$ = "STRING-VALUE"
	B$ = "THE VAR'S"

The element list of the :guilabel:`IN#` command must correspond to that of the :guilabel:`PR#`
command with regard to the number and type of variables. Likewise, the order
must be observed for different types, the naming is irrelevant.

If records are read continuously from a file with :guilabel:`IN#`, it is difficult to recognize
the end of the file at the right time. There is no special "END OF FILE”
identifier for LASER-DOS.

There are various possible solutions:

* the number of records is known, they are counted with a counter in the
  reading program,
* a second small file contains the sentence counter for the main file.
* A short label consisting of only one alphanumeric character (e.g. :guilabel:`PR#`
  "name", "A") is written in front of each correct record.
  
  In the reading program, this identifier is first read before each reading
  of a data record (e.g., :guilabel:`IN#` “name”, A$) If the receiving string variable is
  then empty, the end of the file has been reached.

.. admonition:: Possible Errors:
	:class: error

	``?ILLEGAL DIRECT`` An attempt was made to execute the :guilabel:`IN#`
	command in direct mode.

	``?SYNTAX ERROR``
	
	* no file name specified
	* Filename not in quotes
	* no item in the list
	* no comma as separator

	``?FILE NOT OPEN`` File was not previously opened.

	``?ILLEGAL WRITE`` The file has been opened for reading.

	``?ILLEGAL READ`` The file was opened for writing.

	``?DISK I/O ERROR`` An error occurred while reading or writing to
	the diskette.

	``?REDO`` The type of one of the specified variables
	does not match the data read in from the diskette.
	The program continues to run, the variable remains empty.

	``?EXTRA IGNORED`` In the variable list of the :guilabel:`IN#` command
	fewer variables are given than values
	are present in the data set, the
	numbered values are ignored, the program continues.

	``??`` The variable list contains more variables
	than there are values in the data set. The
	frogram now expects the missing values to
	be entered via the keyboard.

.. warning:: 
	
	If one of these errors occurs (except ``REDO``, ``EXTRA IGNORED`` and ``??``), the
	program is terminated after the corresponding message has been output.
	Please note that this file was not closed, you should do this manually.

.. _cmdCLOSE:

CLOSE - Closing a data file
---------------------------

.. admonition:: Syntax: 
	
	.. code:: BASIC

		CLOSE "name"
		"name" - File/program name, max. 8 characters,
		         enclosed in quotation marks.

	Allowed as direct command and in program mode.

A previously processed data file is closed with the :guilabel:`CLOSE` command..

If a file is open for reading or an inactive file (i.e. the last file access was not to
this file) or in direct mode, only the file control block (:ref:`FCB` = File Control Block)
is released again. Disk access does not take place.

However, if the :guilabel:`CLOSE` command is given in program mode and the file to be
closed is open for writing and is currently active, the last sector in the buffer is
also written back to the diskette so that no data is lost.

It is good programmer practice to close any open file after use. However, it is
essential for output files, unless you accept the possibility of data loss.

.. admonition:: Example:
	:class: hint

		CLOSE "MAILBOX"

	The "MAILBOX" data file is closed.

It is always necessary to close and reopen a file if you want to change the
type of access (e.g. from writing to reading).

If the file to be closed is not open at all, i.e. there is no open file control block
for this file, the :guilabel:`CLOSE` command is skipped without any error message. This
is especially useful for closing all files used in a program prophylactically at
the end without checking which ones are currently open.

.. admonition:: Possible Errors:
	:class: error

	``?SYNTAX ERROR``
	
	* no file name specified
	* Filename not in quotes
  
	``?DISK WRITE PROTECTED`` The disk's write-protect notch is taped over.

	``?DISK I/O ERROR`` An error occurred while reading or writing to
	the diskette.



