

The program Structure
---------------------

The program has a modular structure, i.e. each function is implemented in a
self-contained routine.

After starting, the "MAILBOX" file is first read in (lines 220 - 280).

Note that for this file a solution was chosen for the end identifier, in which a label with
a short alphanum. text is saved. The label is read and evaluated in lines 240 and
250, the "real" record is read in line 280.

The individual program routines for address processing (functions 1-3) will not be
discussed in detail. These have nothing to do directly with the DOS.

You can analyze the routines yourself if necessary.

Just a hint. A "SHELL" SORT procedure was used to sort the addresses (lines 2200
- 2390), which is somewhat more complicated in terms of structure, but considerably
better in terms of runtime than the simple and usual "BUBBLE" SORT.

The data is written back to the diskette in lines 1800 to 1920.

For security reasons, the data is first written to a temporary "TEMP" file. The old
"MAILBOX" file is then deleted and the temporary file is then renamed "MAILBOX".
Dis has the advantage that if errors occur during writing (DISK FULL or similar), at
least the old file is still available.

If you are interested in the program, simply type it in and save it on the floppy disk
with SAVE "ANSCHR".


