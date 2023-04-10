

Memory resident workspaces
==========================


To process the diskettes, DOS creates various data structures in the last 310 bytes
of the available RAM memory, which contain processing vectors, file management
blocks and input/output buffers (Figure 1.7).

.. figure:: ../_static/Figure7_1.jpg
	:width: 640
	:align: center

	Figure 7.1 The memory areas of DOS


DOS vectors
-----------

The first 67 bytes of this DOS work area contain the DOS vectors.

The address of the start of the DOS vectors is stored by DOS during system
initialization to the Z80 register 'IY'. DOS expects that this register will not be
changed by user programs, otherwise a system crash will inevitably occur and data
on the diskette may also be destroyed (bitter experience of the author).

The DOS vector area is structured as follows:

**DOSVTR = IY**

.. |br| raw:: html

	<br />

+-----------+-----+-------+----------------------------------------------+
|Name       |Bytes| Offset| Description                                  |
+-----------+-----+-------+----------------------------------------------+
|FILNO      |1    |IY+0   |File number. |br|                             |                    
|           |     |       |When processing a data file, this is the |br| |
|           |     |       |number of the file management block           |
|           |     |       |(FCB) used. |br|                              | 
|           |     |       |0 = FCB1 , 1 = FCB2 |br|                      |
+-----------+-----+-------+----------------------------------------------+
|FNAM       |8    |IY+1   |Filename |br|                                 |
|           |     |       |Name of the file to edit. must be |br|        |
|           |     |       |entered by the user program before |br|       |
|           |     |       |each file/program access. |br|                |
+-----------+-----+-------+----------------------------------------------+
|TYPE       |2    |IY+9   |File Type |br|                                |
|           |     |       |Byte 1 = target type. |br|                    |
|           |     |       |Byte 2 = actual type. |br|                    |
|           |     |       |From the user program, the type of file |br|  |
|           |     |       |to be processed is in the first byte. |br|    |
+-----------+-----+-------+----------------------------------------------+
|DK         |1    |IY+11  |Selected Drive. |br|                          | 
|           |     |       |X'10' = Drive 1 |br|                          |
|           |     |       |X'80' = Drive 2 |br|                          |
|           |     |       |X'10' is set during initialization. |br|      |
+-----------+-----+-------+----------------------------------------------+
|RQST       |1    |IY+12  |Access type. |br|                             |
|           |     |       |0 = read |br|                                 |
|           |     |       |1 = write |br|                                |
|           |     |       |Must be set by the user program. |br|         | 
|           |     |       |With BASIC, this is done with the |br|        |
|           |     |       |With BASIC, this is done with the |br|        |
|           |     |       |With BASIC, this is done with the |br|        |
|           |     |       |OPEN command. |br|                            |
+-----------+-----+-------+----------------------------------------------+
|SOURCE     |1    |IY+13  |Starting drive (source) used by |br|          | 
|           |     |       |DCOPY command (1 or 2) |br|                   |
+-----------+-----+-------+----------------------------------------------+
|UBFR       |2    |IY+14  |Address of a user buffer area to or |br|      |
|           |     |       |from which data is to be transferred. |br|    |
|           |     |       |When loading and saving programs, |br|        |
|           |     |       |this is the program area. |br|                |
|           |     |       |When reading data files, it is the |br|       |
|           |     |       |BASIC input/output buffer |br|                |
+-----------+-----+-------+----------------------------------------------+
|DESTIN     |1    |IY+16  |Target drive for the DCOPY command |br|       |
|           |     |       |(1 or 2) |br|                                 |
+-----------+-----+-------+----------------------------------------------+
|SCTR       |1    |IY+17  |Number of the Sector to be addressed |br|     |
+-----------+-----+-------+----------------------------------------------+
|TRCK       |1    |IY+18  |Number of the Track to be addressed |br|      |
+-----------+-----+-------+----------------------------------------------+
|RETRY      |1    |IY+19  |Retry counter for read errors |br|            |
|           |     |       |(checksum). |br|                              |
|           |     |       |Set to 10 upon initialization. |br|           |
+-----------+-----+-------+----------------------------------------------+
|DTRCK      |1    |IY+20  |Current track number over which the |br|      |
|           |     |       |read/write head is located. |br|              |
+-----------+-----+-------+----------------------------------------------+
|NSCT       |1    |IY+21  |Marker field for the next sector to be |br|   |
|           |     |       |addressed. |br|                               | 
+-----------+-----+-------+----------------------------------------------+
|NTRK       |1    |IY+22  |Marker field for the next track to be |br|    |
|           |     |       |addressed. |br|                               |
+-----------+-----+-------+----------------------------------------------+
|FCB1       |13   |IY+23  |File management block 1. |br|                 |
|           |     |       |(see Structure description)  |br|             |
+-----------+-----+-------+----------------------------------------------+
|FCB2       |13   |IY+36  |File management block 2. |br|                 | 
|           |     |       |(see Structure description) |br|              |
+-----------+-----+-------+----------------------------------------------+
|DBFR       |2    |IY+49  |Pointer to the DOS data buffer for |br|       |
|           |     |       |writing and reading a sector This is |br|     |
|           |     |       |located immediately after the DOS |br|        |
|           |     |       |vectors in the work area. |br|                |
+-----------+-----+-------+----------------------------------------------+
|LTHCPY     |1    |IY+51  |Copy of the command byte sent to the |br|     |
|           |     |       |Floppy Disk Controller. |br|                  |
+-----------+-----+-------+----------------------------------------------+
|MAPADR     |2    |IY+52  |Pointer to the DOS buffer in which the |br|   |
|           |     |       |sector occupancy overview is |br|             |
|           |     |       |temporarily stored. |br|                      |
|           |     |       |This is behind the data buffer in the |br|    |
|           |     |       |work area. |br|                               |
+-----------+-----+-------+----------------------------------------------+
|TRKCNT     |1    |IY+54  |Track counter for the DCOPY |br|              |
|           |     |       |command |br|                                  |
+-----------+-----+-------+----------------------------------------------+
|TRKPTR     |1    |IY+55  |Track pointer for the DCOPY |br|              |
|           |     |       |command |br|                                  | 
+-----------+-----+-------+----------------------------------------------+
|PHASE      |1    |IY+56  |Step pulse raster for track adjustment. |br|  |
+-----------+-----+-------+----------------------------------------------+
|DCPYF      |1    |IY+57  |Flag for DCOPY |br|                           | 
+-----------+-----+-------+----------------------------------------------+
|RESVE      |10   |IY+58  |reserved for extensions. |br|                 |
+-----------+-----+-------+----------------------------------------------+


File Control Blocks (FCB)
-------------------------


Within the DOS vectors are two 13 byte file management blocks, FCB1 and FCB2.

These are required when processing data files in order to keep status and control
information about the file being accessed.

A free file management block is determined by the OPEN command and provided
with the necessary parameters for the file to be opened.

The IN# and PR# commands are based on the relevant file management block, e.g.
which sector of the file is to be read and at which byte of this sector processing is to
be continued.

The file management blocks are released again by the CLOSE command.

Since there are only two of these blocks, only two files can be open at the same
time.

The File Control Block has the following structure:

FCB1 or FCB2

+-----------+-----+-------+----------------------------------------------------+
|Name       |Bytes| Offset| Description                                        |
+-----------+-----+-------+----------------------------------------------------+
|FLAG       |1    |0      |Indicates the status of the FCB. |br|               |
|           |     |       |0 - FCB not used                         |br|       | 
|           |     |       |1 - FCB used, file currently not active |br|        |
|           |     |       |2 - FCR used, file active.           |br|           |
|           |     |       |Active means that currently a current sector of |br||
|           |     |       |this file is in the data buffer for processing |br| |
+-----------+-----+-------+----------------------------------------------------+
|ACCESS     |1    |1      |Access type for this file. |br|                     | 
|           |     |       |0 - read |br|                                       |
|           |     |       |1 - write |br|                                      |
+-----------+-----+-------+----------------------------------------------------+
|FNAM       |8    |2      |Filename |br|                                       |
+-----------+-----+-------+----------------------------------------------------+
|TRK#       |1    |10     |Track Number |br|                                   |
+-----------+-----+-------+----------------------------------------------------+
|SCTR#      |1    |11     |Sector Number of currently processed Sector |br|    |
+-----------+-----+-------+----------------------------------------------------+
|PTR        |1    |12     |Pointer to the next byte to be processed  |br|      |
|           |     |       |in the above sector. |br|                           | 
+-----------+-----+-------+----------------------------------------------------+


Input/Output Buffer
-------------------

In the DOS work area there are two buffer areas, one for temporary storage of the
sectors to be read or written and a second for the sector occupancy overview.

**Data Buffer (DBFR)**

This buffer has a size of 154 bytes and serves as a buffer for direct data exchange
with the floppy disk.

When writing, the sectors are transferred from the data buffer to the diskette; when
reading, the sectors are transferred from the diskette to the data buffer.

During initialization, the 18 bytes of the data mark are set in front of the data buffer,
so that a complete information block (data mark + data field) is available when a
sector is written.

During normal read/write operations, only the first 128 bytes of the data buffer are
used to hold a sector's data field.

The full length of 154 bytes is only required during diskette initialization to
accommodate a complete sector, including all sync fields, address fields, and
identifiers.

**Allocation Map Sector (MAP)**

At the end of the DOS work area there is an 80-byte buffer area in which the 
Allocation Map from sector 15 of track 0 on the diskette is buffered.

When saving a program or writing a data file, the sectors are selected and allocated
exclusively in this buffer area after the current sector has been read in at the
beginning. Only when the saving process for the program is complete, the
Allocation Map (MAP) is written back to the diskette.


