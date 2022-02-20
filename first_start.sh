#!/bin/bash
sudo -i
echo "Run UPDATE"
yum update -y
echo "Run Install zfs repo"
yum install -y https://zfsonlinux.org/epel/zfs-release.el7_9.noarch.rpm
echo "Run Install zfs package plus wget"
yum install -y epel-release kernel-devel zfs wget
echo "Run configure zfs"
yum-config-manager --disable zfs
yum-config-manager --enable zfs-kmod
#можно пропустить, установлен ранее, но видимо из всех инструкций копипастом идет
yum install -y zfs
#добавим, чтобы модуль zfs подгружался в не зависимости от найден ли zfs pool в системе или нет
echo "Run enable load zfs module at boot time"
echo zfs >/etc/modules-load.d/zfs.conf
echo "Run reboot"
reboot
