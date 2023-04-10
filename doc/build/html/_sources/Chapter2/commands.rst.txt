

Commands - Overview
===================

The 17 additional disk commands can be functionally divided into three groups.

General Instructions
--------------------

.. cmdoption:: INIT 
	
	Initialize a floppy disk.
	
	This command puts the basic structure on the diskette,
	i.e. it is divided into tracks and sectors.

.. cmdoption:: DRIVE n 
	
	Drive selection.

	This allows you to select one of the two attachable drives
	for further processing.

.. cmdoption:: DCOPY 
	
	Copy disks.

 	With this command you copy the contents of one floppy
	disk to another.

.. cmdoption:: STATUS 
	
	Output diskette status.

	With **"STATUS"** you can display the space still available
	on the diskette.	
	(only from DISK BASIC V 1.2)

File Management Features
------------------------

.. cmdoption:: DIR 
	
	Output of the table of contents.

	All programs and files stored on the disk are listed on the
	screen.

.. cmdoption:: SAVE "name" 
	
	Save a BASIC program.

	A BASIC program in memory is written to disk with
	the filename "name".

.. cmdoption:: LOAD "name" 
	
	Load a BASIC program.

	The BASIC program marked with "name" is read from
	the diskette.

.. cmdoption:: RUN "name" 
	
	Load and start a BASIC program.

	The BASIC program marked with "name" is read
	from the diskette and started immediately.

.. cmdoption:: BSAVE "name",aaaa,eeee 
	
	Saving a machine program

	A machine program in the memory is written to the
	diskette with the file name "name".

.. cmdoption:: BLOAD "name" 
	
	Loading a machine program.

	The machine program specified with "name" is
	read in from the diskette.

.. cmdoption:: BRUN "name" 
	
	Loading and starting a machine program.

	The machine program specified with "name" is
	read in from the diskette and started.

.. cmdoption:: REN "name1",”name2” 
	
	Rename a file.

	The file named "name1" will be renamed to
	"name2" on the disk.

.. cmdoption:: ERA "name" 
	
	Delete a file.

	The file labeled "name" is deleted from the floppy
	disk.

.. cmdoption:: DCOPY "name" 
	
	Copy a program.

	The BASIC or machine program identified by
	"name" is copied to another diskette.


Storage and processing of data
------------------------------

.. cmdoption:: OPEN "name",n 
	
	Open a data file.

	The data file designated with "name" is opened for
	writing or reading.

.. cmdoption:: PR# "name",var1[,var2…,varn] 
	
	Write іп a data file.

	The variables specified in the command are
	combined into a data record and written to the data
	file designated with "name".

.. cmdoption:: IN# "name",var1[,var2…,varn] 
	
	Reading from a data file.

	A data record is read from the data file denoted by
	"name" and transferred іпto the specified variables.

.. cmdoption:: CLOSE "name" 
	
	Closing a data file.

	The data file denoted by "name" is closed.

	