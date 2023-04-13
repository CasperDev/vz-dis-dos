

Structure and organization of the diskette
==========================================


Structure of the diskette after initialization
----------------------------------------------

Before you can work with a floppy disk, it must have the basic structure of tracks and
sectors.

This basic structure is written to the diskette using the initialization (INIT command).
It consists of 40 tracks with 16 sectors each, each with 128 bytes of data capacity.
As noted in the "Recording Structure" section, each sector is followed by a certain
"overhead" consisting of necessary synchronization and addressing fields. This
results in a total length of 154 bytes per sector.

Such a sector has the following basic structure:

.. |br| raw:: html

	<br />

+---------------+-----------------------------------+------------------+
| Bytes 0-6     | Address synchronization           | 7 * X'80'        |
+---------------+-----------------------------------+------------------+
| Bytes 7-10    | Address mark                      | X'FE E7 18 C3'   |
+---------------+-----------------------------------+------------------+
| Bytes 11-13   | Address field |br|                |                  |
|               | 11 - track number (0-39) |br|     |                  |
|               | 12 - sector number (0-15) |br|    |                  |
|               | 13 - checksum "address field"     |                  |
|               | (Track# + Sector#)                |                  | 
+---------------+-----------------------------------+------------------+
| Bytes 14-19   | Data synchronization              | 6 * X'80'        |
+---------------+-----------------------------------+------------------+
| Bytes 20-23   | Data mark                         | X'C3 18 E7 FE'   |
+---------------+-----------------------------------+------------------+
| Bytes 24-151  | Data field                        | 128 bytes        |
+---------------+-----------------------------------+------------------+
| Bytes 152-153 | checksum "data field"             |                  |
+---------------+-----------------------------------+------------------+

Each sector is written completely during initialization, with the data field and
checksum (bytes 24 - 153) being set to X'00'.

The sectors are not numbered consecutively around the disk, but arranged in jumps
of three (see Figure 1.6). This achieves the effect that consecutive sectors of a track
can be reached during one revolution of the disk if a certain processing time in
between is not exceeded.

This is 94 ms from the end of a sector until the beginning of the next sector appears
in the numerical order under the read/write head. 94 ms is a huge amount of time, in
which, computer can do extensive data manipulation.

Of the tracks on a floppy disk, 39 are available for storing programs and data,
The first track of a diskette (track 0) is used for diskette management. It contains the
table of contents of the diskette and a sector allocation overview.


Table of Contents
-----------------

The table of contents of the diskette is in the first 15 sectors of track 0 (sector 0 - 14).

Each entry occupies a space of 16 bytes. |br|
This gives a capacity of 8 entries per sector and 8 x 15 = 120 entries in the whole
directory (see error message ``?DIRECTORY FULL``).

An entry in the table of contents has the following structure:

+-----------+-----------------------------------------------------------+
| Byte 0    | occupancy status / file type   |br|                       |
|           | ``0`` - end of used entries in the table of contents |br| |
|           | ``1`` - released entry (e.g. after a "ERA") |br|          |
|           | ``D`` - entry refers to a data file |br|                  |
|           | ``T`` - entry refers to a text file (BASIC program) |br|  |
|           | ``B`` - entry refers to a binary file (machine Program)   |
+-----------+-----------------------------------------------------------+
| Byte 1    | separator (always ``':'``)                                |
+-----------+-----------------------------------------------------------+
| Bytes 2-9 | file name                                                 |
+-----------+-----------------------------------------------------------+
| Byte 10-11| address of the first sector of this file                  |
+-----------+-----------------------------------------------------------+
| Byte 10   | track number                                              |
+-----------+-----------------------------------------------------------+
| Byte 11   | sector number                                             |
+-----------+-----------------------------------------------------------+
| Byte 12-13| only with file type = ``T`` or ``B`` |br|                 |
|           | Program start address in memory                           |
+-----------+-----------------------------------------------------------+
| Byte 14-15| only with file type = ``T`` or ``B`` |br|                 |
|           | Program end address in memory                             |
+-----------+-----------------------------------------------------------+


With the "DIR" command, the first 10 bytes of each assigned entry are simply output
on the screen without any preparation.

If a file is deleted, only the status byte (byte 0) is set to '1'. All other entries are
retained.


The sector administration
-------------------------


The last sector of track 0 contains the allocation overview for the disk sectors.

A bit is reserved there for each sector from track 1, which indicates whether the
corresponding sector is free (bit = 0) or occupied (bit = 1).

With 39 tracks and 16 sectors per track, this results in 624 required bits or 78 bytes
containing relevant information in this sector.

When writing a file, this allocation overview is used to determine the sectors required
for storage. The sectors are always occupied from front to back and any gaps that
may have arisen are filled in by deleting them.

Mapping example:

.. code:: sh
	
	Track 0 / Sector 15
	
	Byte 0 ⇒ Track 0, Sectors 0 - 7
	Byte 1 ⇒ Track 0, Sectors 8 - 15
	Byte 2 ⇒ Track 0, Sectors 0 - 7
	...
	Byte 77 ⇒ Track 39, Sectors 8 - 15


Storage of programs and files
-----------------------------

All programs stored on the diskette receive a corresponding entry in the table of
contents, with the type of file or program being noted in the first byte.

This type designation is the only difference between text files (BASIC programs) and
binary files (machine programs). The recording structures are identical.

The different type identifiers result in different handling after loading or starting such
a program (see the LOAD/RUN or BLOAD/BRUN command descriptions).

Bytes 10 and 11 of the table of contents contain a pointer to the first sector occupied
by this program.

Bytes 12 - 15 of the table of contents contain information about the memory area to
which this program is to be transferred when loading. Bytes 12 and 13 contain the
start address and bytes 14 and 15 the end address of the transfer area.

The data sectors contain in bytes 0 - 125 of the data field a 1:1 copy of the memory
area, i.e. in binary data representation.

The sectors occupied by a program do not have to be physically consecutive, but
can be scattered on the diskette. In order to still be able to read a program in one go,
the individual sectors are indexed one below the other.

In bytes 126 and 127 of the sector there is a pointer to the next sector of this
program (track and sector number) or '0' in the last occupied sector.

Data files with the type designation 'D' do not contain information about a memory
area to be occupied in the table of contents, bytes 12 - 15 are irrelevant.

Bytes 10 and 11 also contain the pointer to the first occupied sector.

As with the programs, the individual sectors of the file are linked to one another.

Each sector of a data file contains the actual data in the first 126 bytes of the sector
and a pointer to the next occupied sector or '0' at the end of the file in the last two
bytes.

The structure of the data in the first 126 bytes differs from the other two file types.

Data representation is in ASCII format only. Storage is based on data records, with
each PR# command writing a complete data record to the file.

Records contain a defined end identifier. This is the ASCII character for "Carriage
Return" X'0D'.

A data record is not based on sector boundaries. There can be several records in
one sector; a data record can also extend over several sectors. Except for the first
record of a file, records do not have to start on a sector boundary either.

Within the data records, the various data fields are separated from one another by
commas; they are assigned to the variables defined in the IN# command when they
are read.




