
.. _tips for programming:

5. Programming tips
===================

.. hint:: Tip 1
	:class: error

As already mentioned in the description of the last sections, there is the
problem that when a program is aborted due to an error or the :kbd:`BREAK` key,
not all files are necessarily closed correctly.

A restart of such a program after error correction or similar usually leads to the
message ``?FILE ALREADY OPEN``.

You can now manually complete these files in direct mode if their names are
known.

However, this is not sufficient for new files to be created in a program. Such
files must then also be deleted, otherwise the file will be updated when :guilabel:`OPEN`
is repeated and you will have your data in the file more than once.
In all these cases, the following procedure is recommended:

At the end of all programs under development you define a block with
:guilabel:`CLOSE` calls and possibly also delete calls for all files addressed in the
program. If the program is interrupted as mentioned above, simply call
this routine with :guilabel:`RUN` line number.

In a program, you edit the three files DAT1, DAT2 for reading, and
DAT3 is recreated.

.. code:: BASIC
	:class: hint

	...
	...           own program
	...
	4800 END
	20000 CLOSE "DAT1"
	20010 CLOSE "DAT2"
	20020 CLOSE "DAT3"
	20030 ERA "DAT3"
	20040 END

If a program is interrupted, you can use :guilabel:`RUN 20000` to clean up your
files and restart your program without any problems after correction.



.. hint:: Tip 2

It is often necessary that a file must be present on the diskette when the
program is started (see program example "Address Directory"), although it
does not contain any data afterwards.

Apply a similar technique to chen by defining the following lines at the end of
the actual program:


.. code:: BASIC
	:class: hint

	...
	...           own program
	...
	6000 END
	10000 OPEN "MAILBOX",1
	10010 CLOSE "MAILBOX"
	10020 END

With RUN 10000 you create an empty file "MAILBOX" on the floppy disk.

.. hint:: Tip 3

A bottleneck of LASER-D0S is that the file names must be specified directly in
the commands and cannot be replaced by variables.

How can you still edit different files in one program?

Knowledge of the BASIC program structure is required to understand the
following solution.

Here are the most important points:

* The start address of a BASIC program can be found in memory
  locations 78A4H and 78A5H (30884 and 30885 decimal).
* A BASIC line has the following structure:

  - 2 bytes - pointer to the next line
  - 2 bytes - line number
  - n bytes - line text
  - 1 byte - line end identifier (Х'00")

  BASIC keywords contained in line text, apart from the DOS commands,
  are represented in the text as one-character "TOKENS".
  The space inserted between the line number and the line text in a
  program listing is not part of the line.

If these conditions are taken into account, the example below can be easily
understood and reproduced.

The main point of this example is that all file calls are located at the beginning
of the program, so they can be counted more easily and are not shifted when
the program is changed later.

After selection by the user, a program evaluates one of three possible files
DAT1, DAT2 or DAT3.

.. code:: BASIC
	:class: hint

	10 GOTO 100
	20 OPEN "DAT1",0:RETURN
	30 IN# "DAT1",A$.B$,C:RETURN
	40 CLOSE "DAT1":RETURN
	100 CLEAR 1000
	110 A=PEEK(30885)*256+PEEK(30884)
	120 CLS
	130 INPUT "FILE VERSION (1-3)";X$
	140 IF X$<"1" OR X$>"3" THEN 120
	150 POKE A+23,ASC(X$)
	160 POKE A+42,ASC(X$)
	170 POKE A+69,ASC(X$)
	180 GOSUB 20
	190 GOSUB 30
	...
	...      edit the data, if necessary several records
	...      read with GOSUB 30
	...
	400 GOSUB 40
	410 END


Line 10 jumps to the actual beginning of the program.

In lines 20, 30 and 40 the file calls are defined as individual subroutines.

The program start address is determined in line 110.

Lines 130 and 140 ask for the desired file version.

If correct, this is transferred to the file names of lines 20, 30 and 40 in lines
150, 160 and 170.

Lines 180, 190 and 400 indicate file processing by calling subroutines as an
example.


