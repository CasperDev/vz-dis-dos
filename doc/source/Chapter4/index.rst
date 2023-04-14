
.. _Error Messages:

4. Error Messages
=================

Summarized list of possible DOS error messages and their probable causes.

.. |br| raw:: html

	<br />


+--------------------------------+---------------------------------------------------+
| ``?DIRECTORY FULL``            | An attempt was made to save a program |br|        | 
|                                | or a file on the floppy disk whose directory |br| |
|                                | already contains 120 entries. |br|                |
|                                | |br|                                              |
+--------------------------------+---------------------------------------------------+
| ``?DISK BUFFER FULL``          | An attempt was made to open a file with |br|      |
|                                | OPEN, although two files are already open. |br|   |
|                                | |br|                                              |
+--------------------------------+---------------------------------------------------+
| ``?DISK FULL``                 | There is no more free sector on the floppy        |
|                                | disk. |br|                                        |
|                                | |br|                                              |
+--------------------------------+---------------------------------------------------+
| ``?DISK I/O ERROR``            | An error occurred while writing or reading. |br|  |
|                                | e.g. address stamp not found; checksum  |br|      |
|                                | wrong etc. |br|                                   |
|                                | |br|                                              |
+--------------------------------+---------------------------------------------------+
| ``?DISK WRITE PROTECTED``      | An attempt was made to write to a floppy |br|     |
|                                | disk with the write-protect notch taped over. |br||
|                                | |br|                                              |
+--------------------------------+---------------------------------------------------+
| ``?FILE ALREADY EXISTS``       | A program to be stored on the diskette is |br|    |
|                                | already there. |br|                               |
|                                | |br|                                              |
+--------------------------------+---------------------------------------------------+
| ``?FILE ALREADY OPEN``         | An OPEN call was issued to a file that is |br|    |
|                                | already open. |br|                                |
|                                | |br|                                              |
+--------------------------------+---------------------------------------------------+
| ``?FILE NOT FOUND``            | A file addressed for reading or a program to |br| |
|                                | be loaded is not present on the diskette. |br|    |
|                                | |br|                                              |
+--------------------------------+---------------------------------------------------+
| ``?FILE NOT OPEN``             | An attempt was made to use ІN# or PR# to |br|     |
|                                | change a file that has not previously been |br|   |
|                                | opened.|br|                                       |  
|                                | |br|                                              |
+--------------------------------+---------------------------------------------------+
| ``?FILE TYPE MISMATCH``        | An attempt was made to access a file |br|         |
|                                | with the wrong type. |br|                         |
|                                | LOAD/RUN - file type not equal to "Т" |br|        |
|                                | BLOAD/BRUN - file type not equal to "B" |br|      |
|                                | OPEN - file type not equal to "D" |br|            |
|                                | DCOPY - file type equal to "D" |br|               |
|                                | |br|                                              |
+--------------------------------+---------------------------------------------------+
|``?ILLEGAL DIRECT``             | An attempt was made to use a DCOPY |br|           |
|                                | command in program mode, or an OPEN, IN#, |br|    |
|                                | or PR# command in direct mode.|br|                |
|                                | |br|                                              |
+--------------------------------+---------------------------------------------------+
| ``?ILLEGAL READ``              | The IN# command was issued for a file |br|        |
|                                | that is open for writing. |br|                    |
|                                | |br|                                              |
+--------------------------------+---------------------------------------------------+
| ``?ILLEGAL WRITE``             | The PR# command was issued for a file |br|        | 
|                                | that is open for reading. |br|                    |
|                                | |br|                                              |
+--------------------------------+---------------------------------------------------+
|``?INSUFFICIENT MEMORY FOR DOS``| An attempt was made to initialize the |br|        |
|                                | DOS system on a LASER 110 or VZ200 |br|           |
|                                | without memory expansion. |br|                    |
|                                | |br|                                              |
+--------------------------------+---------------------------------------------------+



