#!/bin/bash
sudo mount /mnt/kingston
DATESTAMP=$(date +%Y%m%d)
sudo rsync -aP --del --exclude .rvm/ --exclude .bundle/ --exclude .cache/ --exclude Videos/ --exclude anaconda3/ --exclude old.sqsh --exclude '*.iso' /home/rmoore/ /mnt/kingston/rmoore/
sudo btrfs subvolume sync /mnt/kingston/rmoore/
echo "waiting for a bit so you can review"
sleep 180
sudo btrfs subvolume snapshot -r /mnt/kingston/rmoore/ /mnt/kingston/backup/${DATESTAMP}
sudo btrfs subvolume sync /mnt/kingston/backup/${DATESTAMP}
sudo btrfs filesystem sync /mnt/kingston/
sudo umount /mnt/kingston
