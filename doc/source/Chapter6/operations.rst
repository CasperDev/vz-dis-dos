


Operation of the program
------------------------

The program is loaded and started with :guilabel:`RUN "ANSCHR"`. Immediately after the start,
the content of the "MAILROX" file is transferred to the program-internal matrices.
This file must be on the diskette, otherwise the program is terminated after an error
message is output.

After the loading process, the menu is displayed

.. parsed-literal::

	(1) NEW ENTRY
	(2) UPDATE ENTRY
	(3) DELETE ENTRY
	(4) READ ENTRY
	(5) LIST SORTED
	(6) EXIT PROGRAM


You select one of these functions by entering the corresponding number.

After completing functions 1 to 5, which in my opinion are self-explanatory, the
program returns to the menu output.

After completing function 6, the program is terminated.

If the data content was changed during the program run, the addresses are sorted
alphabetically by last name and first name, if necessary, before functions 5 and 6 are
executed.

In function 6, the data are written back to the diskette when changes have been
made.

When starting the program, it expects the MAILBOX file to be present. If you are
using the program for the first time, no such data is present on the diskette. You can
create an empty "MAILBOX" file on the diskette with the following procedure:

.. code:: BASIC
	:class: hint

	LOAD "ANSCHR"
	RUN 3000
	RUN

This creates a file "MAILBOX" and then starts the actual main program.


