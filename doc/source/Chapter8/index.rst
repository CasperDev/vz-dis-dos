

8. Communication between the DOS and the Floppy Disk Controller
===============================================================


The connection between the DOS and the floppy disk controller is established via 4
input/output ports. These are ports 10H in hexadecimal notation. 11H, 12H and 13H.

.. admonition:: PORT 10H = command register (O/P LATCH)

	The control information is transferred to the command register of the floppy
	disk controller via this port.

		* Bit 7 = Drive 2 - select (1 = yes)
		* Bit 6 = Access type (0 = write, 1 = read)
		* Bit 5 = Output pulse when writing to diskette
		* Bit 4 = Drive 1 - select (1 = yes)
		* Bits 3-0 = Step phases for disk head adjustment

	A copy of the port contents is kept in the DOS vectors in the LTHCPY field.

	This field is initialized with '0110 0001'.

	The current step phases are held and processed in the "PHASE" field of the
	DOS vectors.

	The selected drive is in the DK field.

	When a drive is powered on, drive select (DK) and step phase (PHASE) are
	linked to the contents of LTHCPY.

.. admonition:: PORT 11H = READ and STROBE SHIFT register

	The data is read from the diskette via this port. They are inserted serially from
	the left bit by bit by the floppy disk control.

.. admonition:: PORT 12H = POLL DATA

	This port is used for synchronization when reading.

	A negative pulse is generated when the next bit is available at port 11.

.. admonition:: PORT 13H = READ/WRITE PROTECT STATUS

	The write protection status of a floppy disk can be determined via this port
	(write protection notch taped over or not).

	The result is passed in bit 7.
	(1 = read only)


	