
.. _DOS commands:

Commands - Overview
===================

The 17 additional disk commands can be functionally divided into three groups.

General Instructions
--------------------

.. option:: INIT
	
	**Initialize a floppy disk.** (See :ref:`Command description <cmdINIT>`).
	
	This command puts the basic structure on the diskette,
	i.e. it is divided into tracks and sectors.
	

.. option:: DRIVE n 
	
	**Drive selection.** (See :ref:`Command description <cmdDRIVE>`).

	This allows you to select one of the two attachable drives
	for further processing.

.. option:: DCOPY 
	
	**Copy disks.** (See :ref:`Command description <cmdDCOPY>`).

 	With this command you copy the contents of one floppy
	disk to another.

.. option:: STATUS 
	
	**Output diskette status.** (See :ref:`Command description <cmdSTATUS>`).

	With :guilabel:`STATUS` you can display the space still available
	on the diskette.	
	(only from DISK BASIC V 1.2)

File Management Features
------------------------

.. option:: DIR 
	
	**Output of the table of contents.** (See :ref:`Command description <cmdDIR>`).

	All programs and files stored on the disk are listed on the
	screen.

.. option:: SAVE "name" 
	
	**Save a BASIC program.** (See :ref:`Command description <cmdSAVE>`).

	A BASIC program in memory is written to disk with
	the filename "name".

.. option:: LOAD "name" 
	
	**Load a BASIC program.** (See :ref:`Command description <cmdLOAD>`).

	The BASIC program marked with "name" is read from
	the diskette.

.. option:: RUN "name" 
	
	**Load and start a BASIC program.** (See :ref:`Command description <cmdRUN>`).

	The BASIC program marked with "name" is read
	from the diskette and started immediately.

.. option:: BSAVE "name",aaaa,eeee 
	
	**Saving a machine program** (See :ref:`Command description <cmdBSAVE>`).

	A machine program in the memory is written to the
	diskette with the file name "name".

.. option:: BLOAD "name" 
	
	**Loading a machine program.** (See :ref:`Command description <cmdBLOAD>`).

	The machine program specified with "name" is
	read in from the diskette.

.. option:: BRUN "name" 
	
	**Loading and starting a machine program.** (See :ref:`Command description <cmdBRUN>`).

	The machine program specified with "name" is
	read in from the diskette and started.

.. option:: REN "name1",”name2” 
	
	**Rename a file.** (See :ref:`Command description <cmdREN>`).

	The file named "name1" will be renamed to
	"name2" on the disk.

.. option:: ERA "name" 
	
	**Delete a file.** (See :ref:`Command description <cmdERA>`).

	The file labeled "name" is deleted from the floppy
	disk.

.. option:: DCOPY "name" 
	
	**Copy a program.** (See :ref:`Command description <cmdDCOPYfile>`).

	The BASIC or machine program identified by
	"name" is copied to another diskette.


Storage and processing of data
------------------------------

.. option:: OPEN "name",n 
	
	**Open a data file.** (See :ref:`Command description <cmdOPEN>`).

	The data file designated with "name" is opened for
	writing or reading.

.. option:: PR# "name",var1[,var2…,varn] 
	
	**Write іп a data file.** (See :ref:`Command description <cmdPR#>`).

	The variables specified in the command are
	combined into a data record and written to the data
	file designated with "name".

.. option:: IN# "name",var1[,var2…,varn] 
	
	**Reading from a data file.** (See :ref:`Command description <cmdIN#>`).

	A data record is read from the data file denoted by
	"name" and transferred іпto the specified variables.

.. option:: CLOSE "name" 
	
	**Closing a data file.** (See :ref:`Command description <cmdCLOSE>`).

	The data file denoted by "name" is closed.

	