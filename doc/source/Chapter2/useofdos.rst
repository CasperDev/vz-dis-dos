
.. |br| raw:: html

	<br />

Use of DOS commands
===================


Commands - Syntax
-----------------

The available commands are entered without any special identification like usual
BASIC statements.

Most of these commands can be used both in BASIC programs and in direct mode,
i.e. for immediate execution from the screen.

However, a select few are limited to one mode or another. When exactly which
command may be used is noted in the detailed descriptions.

In terms of syntax, the commands can be divided into three categories:

.. rubric:: Commands that do not address a file:

.. code-block:: sh
  	:class: hint
	
	command [parameter]


.. rubric:: Commands that address a file:
  
.. code:: sh
	:class: hint

	command "filename" [,parameter]

.. rubric:: Commands that address two files:

.. code:: sh
	:class: hint

	command "filename1","filename2"


Parameters are additional information required by some commands. If several
parameters are required, they must be separated by commas.

A small restriction arises when using it within BASIC programs.
The additional diskette commands are not recognized if they are specified directly
after a :guilabel:`THEN` or :guilabel:`ELSE` in :guilabel:`IF` statements.

They must always be entered as an independent command either at the beginning of
a line or after a command separator ``":"``.

.. code:: basic
	:class: hint

	100 IF A= 1 THEN RUN "XYZ" wrong
	100 IF A= 1 THEN :RUN "XYZ" correct

or

.. code:: basic
	:class: hint

	100 IF A <> 1 THEN 120
	110 RUN "XYZ"
	120 ......


File Types and Specifications
-----------------------------


There are three different types of files in LASER-DOS:

* BASIC program files
    with the label ``"T"`` as file type (= text file).
    
	BASIC programs are stored on the diskette in this file type.


* Machine program files
    with the label ``"B"`` as file type (=binary file).
    
	Machine programs are stored on the diskette in this file type.


* Data files
    with the label ``"D"`` as file type (=data).

    Your personal data is saved in this file type if you want to store it on the
    diskette from a BASIC program.

BASIC and machine programs are stored on the diskette in the same format. The
different type designation is only in the table of contents and causes different
handling when loading and starting.

Data files have a completely different structure, which means that there are also
restrictions when using individual commands.

If you want to address a file on the floppy disk or create a new one, you must specify
a file name in the commands, which is entered in the table of contents of the floppy
disk.

A file name can be a maximum of eight characters long and can consist of any
sequence of letters, characters or numbers.

In the commands, the file name must always be given in quotation marks. In contrast
to other BASIC commands, the final quotation mark must not be forgotten, even if no
further information is given.

Unfortunately, LASER-DOS does not allow using a string variable instead of the file
name; this must always be specified in full directly in the command. This complicates
the flexible handling of different data files. How you can still help yourself is noted in
chapter 5 :ref:`"Tips for programming" <tips for programming>`.



