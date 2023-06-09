

General Instructions
====================

.. _cmdinit:

INIT - Prepare a floppy disk
----------------------------

.. admonition:: Syntax

	.. code:: basic
	
		INIT
		
	Allowed as direct command and in program mode.

The :guilabel:`INIT` command prepares a floppy disk for storing programs or data; it will
be "initialized".

This means that the basic structure shown in the :ref:`"Recording structure" <record structure>` 
section will be produced on the diskette.

40 tracks with 16 sectors each are set up and all address and data marks are
written.

After writing, each sector is individually addressed and read.

The entire initialization process takes about 2-3 minutes.

After correct implementation, BASIC responds with READY and the next
command can be entered.

The initialization process can be aborted at any time by pressing the :kbd:`BREAK`
button.

.. warning:: 
	
	With the :guilabel:`INIT` command, a non-write-protected diskette is overwritten without
	any further checking, i.e. any data on it is lost.

.. admonition:: Possible Errors
	:class: error

	``?DISK WRITE PROTECTED`` The disk's write-protect notch is taped over.

	``?DISK I/O ERROR`` - An error occurred during the check read.
	(faulty disk or bad centering - see :ref:`Insertion <inserting a floppy disk>`)

.. _cmdDrive:

DRIVE - Drive selection
-----------------------

.. admonition:: Syntax

	.. code:: basic
	
		DRIVE n
		n = drive number (1 or 2)
		
	Allowed as direct command and in program mode.


The :guilabel:`DRIVE` command is used to select one of the two drives that can be
connected.

After switching on the computer and after each copy command (:guilabel:`DCOPY`),
drive 1 is automatically selected.

If you want to access drive 2, you must first switch to it with :guilabel:`DRIVE 2`.

All DOS commands, except :guilabel:`DCOPY`, are executed on the selected drive.
Therefore, make sure that you have always selected the correct drive. An
:guilabel:`INIT` command, e.g. on the wrong drive, inevitably leads to the destruction of
a floppy disk with important data that happens to be there.


If you are not sure which drive is currently selected, execute a corresponding
:guilabel:`DRIVE` command (:guilabel:`DRIVE 1` or :guilabel:`DRIVE 2`) to be safe.

The DRIVE command. only changes the DOS internal pointers, a floppy disk
access does not take place.

.. admonition:: Possible Errors:
	:class: error

	``?FUNCTION CODE ERROR`` Wrong drive selection (not 1 or 2)


.. _cmdDCOPY:

DCOPY - Copy disk
-----------------

.. admonition:: Syntax 

	.. code:: BASIC
		
		DCOPY

	Allowed only as a direct command.

The :guilabel:`DCOPY` command without any further parameters results in a complete
copy of a floppy disk onto a second initialized floppy disk.

Copying is possible with one or two drives. With only one drive, however, you
will have to change the diskettes several times during the copying process.

After entering the command, you will first be prompted to select the source
and target drives.

.. code:: BASIC
	:class: hint

	SOURCE DISK (1/2)?
	DESTINATION DISK (1/2)?

Answer each of these questions by pressing the :kbd:`1` or :kbd:`2` key.

Only own one drive; so answer "1" to each question.

Command execution can be aborted with :kbd:`CTRL` + :kbd:`BREAK`.

After the drive has been selected, the copying process begins. The entire
RAM memory is used for this in order to have to switch between the source
and target drive as little as possible.

If you copy from one drive to a second, the entire copying process runs
automatically. If there is only one drive (from 1 to 1 or from 2 to 2), you will
have the opportunity to insert the correct diskette before each read or write
operation.

.. code:: BASIC
	:class: hint

	INSERT SOURCE DISKETTE
	(PRESS SPACE WHEN READY)

before each reading from the source diskette, or

.. code:: BASIC
	:class: hint

	INSERT DESTINATION DISKETTE
	(PRESS SPACE WHEN READY)

before each write to the target disk.

You can interrupt the copying process at any time by pressing the :kbd:`BREAK` key.

The completion of the copying process is indicated with READY.

.. warning:: 

	* Note that the target disk must first be initialized.
 		
	* Data on the target diskette will be overwritten (ensure the correct drive 
      and diskette selection).
	
	* The entire available RAM area is overwritten by :guilabel:`DCOPY`, i.e. data 
	  or programs located there must first be saved or then reloaded.
	
	* When using "Extended BASIC" the computer has to be re-initialized (switch off/on).
	
	* After completion, drive 1 is always selected, regardless of a previous :guilabel:`DRIVE` command.

.. admonition:: Possible Errors:
	:class: error


	``?ILLEGAL DIRECT`` An attempt was made to call the :guilabel:`DCOPY`
	command from a program.

	``?DISK WRITE PROTECTED`` The target disk's write-protect notch is
	taped over.

	``?DISK I/O ERROR`` Write or read error on one of the 
	two disks. (defective or bad centering)

.. admonition:: Note:
	:class: information
	
	This is one of the most important DOS commands.

	As already mentioned at the beginning, no floppy disk is a reliable data
	storage device in the long run (abrasion).

	So make a copy of every diskette that contains programs and data that are
	important to you

	* after the initial creation or acquisition
	* after any significant change in content.

.. _cmdSTATUS:

STATUS - Display the diskette status
------------------------------------

.. admonition:: Syntax `(only from DISK BASIC V 1.2)`
	
	.. code:: BASIC
		
		STATUS

	Allowed as direct command and in program mode.

The :guilabel:`STATUS` command determines and displays the space still available on
the diskette.

The output comes in two forms. The first line shows the number of free
sectors in the form:

.. code:: BASIC
	:class: hint
	
	nn RECORDS FREE

In the second line, the free bytes are specified in the form:

.. code:: BASIC

	nn.nnn K BYTES FREE

.. admonition:: Example:
	:class: hint
	
	.. code:: basic
		
		STATUS
		80 RECORDS FREE
		10.0 K BYTES FREE

.. admonition:: Possible Errors:
	:class: error
	
	``?DISK I/O ERROR`` The occupancy overview of the diskette
	could not be read correctly.


	