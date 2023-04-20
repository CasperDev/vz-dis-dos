
The Floppy Disk Controller
==========================

A **LASER DI40** Floppy Disk Controller is required to connect a drive to a computer.

This is connected to the computer's system bus and has two 20-pin plug-in
connections on the back for connecting one or two drives.

The task of the floppy disk control is the implementation of logical orders, such as
"Read a program" in single steps for specific control of the drives, e.g. step pulses
for track adjustment, read a bit, write a bit, motor on, motor off, etc.

The floppy disk control also contains the floppy disk operating system (Disk
Operating System), DOS for short. This is stored on 8K ROMs and expands the
BASIC language range of the computer with :ref:`17 commands <DOS commands>` that are required to
operate the floppy disk station. These include :option:`INIT` for diskette initialization,
:option:`SAVE` and :option:`LOAD` for saving or loading a BASIC program.

This diskette operating system is addressed using addresses 4000 - 5FFF
(hexadecimal), which have been reserved for this expansion purpose. A :ref:`310-byte
work area <DOS work area>` is also reserved at the end of the RAM area.


