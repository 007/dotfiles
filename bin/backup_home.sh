sudo mount -o remount,relatime /media/rmoore/5abeab22-56d5-4cbd-a8ee-e782b66dc839
rsync -aP --del --exclude .rvm/ --exclude .cache/ /home/rmoore/ /media/rmoore/5abeab22-56d5-4cbd-a8ee-e782b66dc839/rmoore/
sync
#time mksquashfs /home/rmoore /media/rmoore/5abeab22-56d5-4cbd-a8ee-e782b66dc839/rmoore-20151031.sqsh -comp xz -Xbcj ia64,x86 -Xdict-size 1048576 -b 1048576 -info -progress | tee /tmp/backup.log
sync
umount /media/rmoore/5abeab22-56d5-4cbd-a8ee-e782b66dc839
