

Basics of floppy disk storage
=============================

The Drive
---------

There are a large number of different floppy disk systems of all kinds
manufacturers. One of the main classifications of these drives is the size of the
floppy disks. These vary from 3 1/2 inches to 5 1/4 inches to 8 inches. The floppy
disk drive **LASER DD20** is a 5 1/4 inch Drive, which is very sdimilar in terms of
presentation and technical structure to TEAC drives.

Floppy disk drives work with a round, rotating disc (called floppy disk)
which, like a tape, is covered with a magnetizable layer. The data is written to these
or read from again using a read/write head.

In order to be able to access any position on this disk, the read/write head has
to be movable. For this purpose it is mounted on a rail and can be moved across
the disc.

To write or read data, the head is simply moved in or out the desired distance and
then waits for the desired data to rotate past underneath it (Figure 1.2).
For the sake of clarity and retrieval, the head has fixed grid positions, 
which in turn create concentric circles of data on the disk. The
various disk systems have between 35 and 88 grids.

In **LASER DD20** there are 40.

The resulting circles of data on the floppy disk are called tracks. 
Each individual track can be accessed directly and precisely 
by the adjustment mechanism of the head.

Within a track, the data is recorded bit by bit one after the other, that is "sequentially"
in computer terms. As a result, after the head has been positioned over the track, it
naturally takes an average of half a turn of the disc before the desired data is
reached .

.. figure:: ../_static/Figure1_2.jpg
	:width: 640
	:align: center

	Figure 1.2 Data access on a floppy disk

The time it takes to access the data you want depends on how fast the head 
can be positioned on the particular track and how fast the disk is spinning.

With the **LASER DD20**, the diskette is driven at 80 revolutions per minute. The
time to move the head from one track to the next is about 20 milliseconds
This results in an average access time of 500 milliseconds.

During a read/write operation, the floppy disk is held firmly like an audio tape
pressed against the read/write head. This is covered with a piece of felt
works, which presses the diskette from above onto the head via a lever macaw.
This lever arm is connected to the locking lever on the front of the drive.
If this is in a vertical position (closed), the diskette is upside down
pressed; in the horizontal position, the diskette is free (Figure 1.3).

An electronic head-loading procedure is common to many other drives
which does not exist here.

.. figure:: ../_static/Figure1_3.jpg
	:width: 640
	:align: center

	Figure 1.3 Representation of a floppy disk in the drive

If you've been paying attention, you must have noticed that a floppy disk is always
written from the bottom up, which is different from how you actually think it is when
you put it in.

The drive mechanism is also connected to the locking lever. Closing the lever
(vertical) centers the disk drive hole on a cone driven by the motor via a belt. How
exactly a disk is centered on the cone is one of the critical components of the drive.

The position of a track always refers to the center of the diskette. Therefore, reliable
writing and retrieval of the data depends very much on how precisely the diskette is
centered. Unfortunately, the **LASER DD20** drive tends to not press the floppy disks
precisely onto the canoes. Please note the help and control options mentioned in the
:ref:`Inserting a floppy disk` section.

To protect the floppy disks, the drive motor is only switched on immediately before
the Write or Read operations - turned on and then immediately turned off again. You
will receive a visual indication of this process in the form of a lit LED (light emitting
diode) on the front of the drive. If this lights up, you should not remove or insert a
disk (see :ref:`head pressing process <Inserting a floppy disk>`).

