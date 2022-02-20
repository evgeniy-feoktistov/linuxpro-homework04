# linuxpro-homework04
# linuxpro-homework04
# Домашнее задание - практические навыки работы с ZFS
0. [Подготовка](#0)
1. [Определить алгоритм с наилучшим сжатием](#1)
2. [Определение настроек пула](#2)
3. [Работа со снапшотом, поиск сообщения от преподавателя](#3)
4. [Работа со снапшотом, поиск сообщения от преподавателя](#4)

* * *
<a name="0"/>

## Подготовка:
Обновил тестовую машину до 7.9 с 7.8, так как репозиторий ушел в архивные и zfs при запуске не установлена.
```bash
[root@zfs ~]# cat /etc/redhat-release
CentOS Linux release 7.9.2009 (Core)

[root@zfs ~]# yum install https://zfsonlinux.org/epel/zfs-release.el7_9.noarch.rpm
Loaded plugins: fastestmirror
zfs-release.el7_9.noarch.rpm                                                                             | 5.4 kB  00:00:00
Examining /var/tmp/yum-root-oZRJ7J/zfs-release.el7_9.noarch.rpm: zfs-release-1-10.noarch
Marking /var/tmp/yum-root-oZRJ7J/zfs-release.el7_9.noarch.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package zfs-release.noarch 0:1-10 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

================================================================================================================================
 Package                      Arch                    Version                  Repository                                  Size
================================================================================================================================
Installing:
 zfs-release                  noarch                  1-10                     /zfs-release.el7_9.noarch                  3.1 k

Transaction Summary
================================================================================================================================
Install  1 Package

Total size: 3.1 k
Installed size: 3.1 k
Is this ok [y/d/N]: y
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : zfs-release-1-10.noarch                                                                                      1/1
  Verifying  : zfs-release-1-10.noarch                                                                                      1/1

Installed:
  zfs-release.noarch 0:1-10

Complete!

[root@zfs ~]# rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
[root@zfs ~]# yum install -y epel-release
[root@zfs ~]# yum install -y kernel-devel
[root@zfs ~]# yum install -y zfs
[root@zfs ~]# yum-config-manager --disable zfs
[root@zfs ~]# yum-config-manager --enable zfs-kmod
[root@zfs ~]# yum install -y zfs
[root@zfs ~]# echo zfs >/etc/modules-load.d/zfs.conf
...
...
Complete!
# По инструкции https://openzfs.github.io/openzfs-docs/Getting%20Started/RHEL-based%20distro/index.html
```

* * *
<a name="1"/>

## 1. Определить алгоритм с наилучшим сжатием
Смотрим список всех дисков, которые есть в виртуальной машине:
```bash
[vagrant@zfs ~]$ sudo -i
[root@zfs ~]#
[root@zfs ~]#
[root@zfs ~]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0  512M  0 disk
sdc      8:32   0  512M  0 disk
sdd      8:48   0  512M  0 disk
sde      8:64   0  512M  0 disk
sdf      8:80   0  512M  0 disk
sdg      8:96   0  512M  0 disk
sdh      8:112  0  512M  0 disk
sdi      8:128  0  512M  0 disk
```
Создаём 4 пула из двух дисков в режиме RAID-1:
```bash
[root@zfs ~]# zpool create storage01 mirror /dev/sdb /dev/sdc
[root@zfs ~]# zpool create storage02 mirror /dev/sdd /dev/sde
[root@zfs ~]# zpool create storage03 mirror /dev/sdf /dev/sdg
[root@zfs ~]# zpool create storage04 mirror /dev/sdh /dev/sdi
```
Смотрим информацию о пулах:
```bash
[root@zfs ~]# zpool list
NAME        SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
storage01   480M   100K   480M        -         -     0%     0%  1.00x    ONLINE  -
storage02   480M   100K   480M        -         -     0%     0%  1.00x    ONLINE  -
storage03   480M   100K   480M        -         -     0%     0%  1.00x    ONLINE  -
storage04   480M   100K   480M        -         -     0%     0%  1.00x    ONLINE  -
```
Добавим разные алгоритмы сжатия в каждый пул:
```bash
[root@zfs ~]# zfs set compression=lzjb storage01
[root@zfs ~]# zfs set compression=lz4 storage02
[root@zfs ~]# zfs set compression=gzip-9 storage03
[root@zfs ~]# zfs set compression=zle storage04
```
Проверим, что все пулы системы имеют разные методы сжатия:
```bash
[root@zfs ~]# zfs get all | grep compression
storage01  compression           lzjb                   local
storage02  compression           lz4                    local
storage03  compression           gzip-9                 local
storage04  compression           zle                    local
```
Скачаем один и тот же файл в каждый пул:
```bash
[root@zfs ~]# for i in {1..4}; do wget -P /storage0$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
--2022-02-19 09:05:07--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40784369 (39M) [text/plain]
Saving to: ‘/storage01/pg2600.converter.log’

100%[======================================================================================>] 40,784,369  1.67MB/s   in 28s

2022-02-19 09:05:36 (1.39 MB/s) - ‘/storage01/pg2600.converter.log’ saved [40784369/40784369]

--2022-02-19 09:05:36--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40784369 (39M) [text/plain]
Saving to: ‘/storage02/pg2600.converter.log’

100%[======================================================================================>] 40,784,369  1.44MB/s   in 40s

2022-02-19 09:06:16 (1005 KB/s) - ‘/storage02/pg2600.converter.log’ saved [40784369/40784369]

--2022-02-19 09:06:16--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40784369 (39M) [text/plain]
Saving to: ‘/storage03/pg2600.converter.log’

100%[======================================================================================>] 40,784,369  1.02MB/s   in 34s

2022-02-19 09:06:51 (1.14 MB/s) - ‘/storage03/pg2600.converter.log’ saved [40784369/40784369]

--2022-02-19 09:06:51--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40784369 (39M) [text/plain]
Saving to: ‘/storage04/pg2600.converter.log’

100%[======================================================================================>] 40,784,369   645KB/s   in 46s

2022-02-19 09:07:38 (863 KB/s) - ‘/storage04/pg2600.converter.log’ saved [40784369/40784369]
```
Проверим:
```bash
[root@zfs ~]# ls -l /storage0*
/storage01:
total 22015
-rw-r--r--. 1 root root 40784369 Feb  2 09:01 pg2600.converter.log

/storage02:
total 17970
-rw-r--r--. 1 root root 40784369 Feb  2 09:01 pg2600.converter.log

/storage03:
total 10948
-rw-r--r--. 1 root root 40784369 Feb  2 09:01 pg2600.converter.log

/storage04:
total 39856
-rw-r--r--. 1 root root 40784369 Feb  2 09:01 pg2600.converter.log
```
Видим, что storage03 имеет самый эффективный метод сжатия.
Проверим, сколько места занимает один и тот же файл в разных пулах и
проверим степень сжатия файлов:
```bash
[root@zfs ~]# zfs list
NAME        USED  AVAIL     REFER  MOUNTPOINT
storage01  21.6M   330M     21.5M  /storage01
storage02  17.7M   334M     17.6M  /storage02
storage03  10.8M   341M     10.7M  /storage03
storage04  39.1M   313M     38.9M  /storage04

[root@zfs ~]# zfs get all | grep compressratio | grep -v ref
storage01  compressratio         1.81x                  -
storage02  compressratio         2.22x                  -
storage03  compressratio         3.64x                  -
storage04  compressratio         1.00x                  -
```
Таким образом, у нас получается, что алгоритм gzip-9 самый эффективный
по сжатию.

* * *
<a name="2"/>

## 2. Определение настроек пула
скачаем файл
```bash
[root@zfs ~]# wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg' -O archive.tar.gz
--2022-02-19 10:45:17--  https://docs.google.com/uc?export=download&id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg
Resolving docs.google.com (docs.google.com)... 108.177.14.194, 2a00:1450:4010:c0f::c2
Connecting to docs.google.com (docs.google.com)|108.177.14.194|:443... connected.
HTTP request sent, awaiting response... 303 See Other
Location: https://doc-0c-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/ch1i9t3a32tg9p6p4e5nh9hdv93ioth0/1645341675000/16189157874053420687/*/1KRBNW33QWqbvbVHa3hLJivOAt60yukkg?e=download [following]
Warning: wildcards not supported in HTTP.
--2022-02-19 10:45:22--  https://doc-0c-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/ch1i9t3a32tg9p6p4e5nh9hdv93ioth0/1645341675000/16189157874053420687/*/1KRBNW33QWqbvbVHa3hLJivOAt60yukkg?e=download
Resolving doc-0c-bo-docs.googleusercontent.com (doc-0c-bo-docs.googleusercontent.com)... 64.233.161.132, 2a00:1450:4010:c01::84
Connecting to doc-0c-bo-docs.googleusercontent.com (doc-0c-bo-docs.googleusercontent.com)|64.233.161.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 7275140 (6.9M) [application/x-gzip]
Saving to: ‘archive.tar.gz’

100%[======================================================================================>] 7,275,140   7.72MB/s   in 0.9s

2022-02-19 10:45:24 (7.72 MB/s) - ‘archive.tar.gz’ saved [7275140/7275140]
```
Разархивируем его
```bash
[root@zfs ~]# tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb
```
Проверим, возможно ли импортировать данный каталог в пул:
```bash
[root@zfs ~]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
        (Note that they may be intentionally disabled if the
        'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
        some features will not be available without an explicit 'zpool upgrade'.
 config:

        otus                         ONLINE
          mirror-0                   ONLINE
            /root/zpoolexport/filea  ONLINE
            /root/zpoolexport/fileb  ONLINE
```
Данный вывод показывает имя пула otus, тип RAID-1 и его состав
Сделаем импорт данного пула к нам в ОС:
```bash
[root@zfs ~]# zpool import -d zpoolexport/ otus
```
Посмотрим его состояние после импорта:
```bash
[root@zfs ~]# zpool status
  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
        The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
        the pool may no longer be accessible by software that does not support
        the features. See zpool-features(7) for details.
config:

        NAME                         STATE     READ WRITE CKSUM
        otus                         ONLINE       0     0     0
          mirror-0                   ONLINE       0     0     0
            /root/zpoolexport/filea  ONLINE       0     0     0
            /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors

```
Посмотрим все параметры пула:
```bash
[root@zfs ~]# zpool get all otus
NAME  PROPERTY                       VALUE                          SOURCE
otus  size                           480M                           -
otus  capacity                       0%                             -
otus  altroot                        -                              default
otus  health                         ONLINE                         -
otus  guid                           6554193320433390805            -
otus  version                        -                              default
otus  bootfs                         -                              default
otus  delegation                     on                             default
otus  autoreplace                    off                            default
otus  cachefile                      -                              default
otus  failmode                       wait                           default
otus  listsnapshots                  off                            default
otus  autoexpand                     off                            default
otus  dedupratio                     1.00x                          -
otus  free                           478M                           -
otus  allocated                      2.09M                          -
otus  readonly                       off                            -
otus  ashift                         0                              default
otus  comment                        -                              default
otus  expandsize                     -                              -
otus  freeing                        0                              -
otus  fragmentation                  0%                             -
otus  leaked                         0                              -
otus  multihost                      off                            default
otus  checkpoint                     -                              -
otus  load_guid                      5530623316803986721            -
otus  autotrim                       off                            default
otus  compatibility                  off                            default
otus  feature@async_destroy          enabled                        local
otus  feature@empty_bpobj            active                         local
otus  feature@lz4_compress           active                         local
otus  feature@multi_vdev_crash_dump  enabled                        local
otus  feature@spacemap_histogram     active                         local
otus  feature@enabled_txg            active                         local
otus  feature@hole_birth             active                         local
otus  feature@extensible_dataset     active                         local
otus  feature@embedded_data          active                         local
otus  feature@bookmarks              enabled                        local
otus  feature@filesystem_limits      enabled                        local
otus  feature@large_blocks           enabled                        local
otus  feature@large_dnode            enabled                        local
otus  feature@sha512                 enabled                        local
otus  feature@skein                  enabled                        local
otus  feature@edonr                  enabled                        local
otus  feature@userobj_accounting     active                         local
otus  feature@encryption             enabled                        local
otus  feature@project_quota          active                         local
otus  feature@device_removal         enabled                        local
otus  feature@obsolete_counts        enabled                        local
otus  feature@zpool_checkpoint       enabled                        local
otus  feature@spacemap_v2            active                         local
otus  feature@allocation_classes     enabled                        local
otus  feature@resilver_defer         enabled                        local
otus  feature@bookmark_v2            enabled                        local
otus  feature@redaction_bookmarks    disabled                       local
otus  feature@redacted_datasets      disabled                       local
otus  feature@bookmark_written       disabled                       local
otus  feature@log_spacemap           disabled                       local
otus  feature@livelist               disabled                       local
otus  feature@device_rebuild         disabled                       local
otus  feature@zstd_compress          disabled                       local
otus  feature@draid                  disabled                       local
```
И посмотрим все параметры файловой системы пула otus:
```bash
[root@zfs ~]# zfs get all otus
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclmode               discard                default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              off                    default
otus  redundant_metadata    all                    default
otus  overlay               on                     default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default
```
Посмотрим конкретные параметры:
```bash
[root@zfs ~]# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
```
Разрешен за запись и чтение:
```bash
[root@zfs ~]# zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default
```
Значение recordsize:
```bash
[root@zfs ~]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
```
Тип сжатия:
```bash
[root@zfs ~]# zfs get compression otus
NAME  PROPERTY     VALUE           SOURCE
otus  compression  zle             local
```
Алгоритм контрольной суммы:
```bash
[root@zfs ~]# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
```

* * *
<a name="3"/>

## 3. Работа со снапшотом, поиск сообщения от преподавателя

Скачаем файл, указанный в задании:
```bash
[root@zfs ~]# wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&e' -O otus_task2.file
--2022-02-19 11:14:43--  https://docs.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&e
Resolving docs.google.com (docs.google.com)... 108.177.14.194, 2a00:1450:4010:c0e::c2
Connecting to docs.google.com (docs.google.com)|108.177.14.194|:443... connected.
HTTP request sent, awaiting response... 303 See Other
Location: https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/sn14jtbodub3pqetruu5gskmiai999q9/1645343250000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?e=download [following]
Warning: wildcards not supported in HTTP.
--2022-02-19 11:14:43--  https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/sn14jtbodub3pqetruu5gskmiai999q9/1645343250000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?e=download
Resolving doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)... 74.125.205.132, 2a00:1450:4010:c02::84
Connecting to doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)|74.125.205.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 5432736 (5.2M) [application/octet-stream]
Saving to: ‘otus_task2.file’

100%[======================================================================================>] 5,432,736   8.47MB/s   in 0.6s

2022-02-19 11:14:44 (8.47 MB/s) - ‘otus_task2.file’ saved [5432736/5432736]
```

```bash
[root@zfs ~]# ll otus_task2.file
-rw-r--r--. 1 root root 5432736 Feb 19 11:14 otus_task2.file
```
Восстановим данные из снапшота:
```bash
[root@zfs ~]# zfs receive otus/test@today < otus_task2.file
```
Ищем фай "secret_message"
```bash
[root@zfs ~]# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message
```
Смотрим содержимое:
```bash
[root@zfs ~]# cat /otus/test/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome
```


* * *
<a name="4"/>

## 4. Подготовим скрипт, для конфигурации сервера: установка zfs. Сделаю по своему пункту "Подготовка"

Еще раз прогоним порядок подготовки:
```bash
yum update -y
yum install https://zfsonlinux.org/epel/zfs-release.el7_9.noarch.rpm
yum install -y epel-release kernel-devel zfs
yum-config-manager --disable zfs
yum-config-manager --enable zfs-kmod
yum install -y zfs
#добавим, чтобы модуль zfs подгружался в не зависимости от найден ли zfs pool в системе или нет
echo zfs >/etc/modules-load.d/zfs.conf
```
Запишем все в скрипт first_start.sh и поправим Vagrant файл.
```bash
ujack@ubuntu2004:~/linuxpro-homework04$ cat Vagrantfile
# -*- mode: ruby -*-
# vim: set ft=ruby :
disk_controller = 'IDE' # MacOS. This setting is OS dependent. Details https://github.com/hashicorp/vagrant/issues/8105
MACHINES = {
        :zfs => {
                :box_name => "centos/7",
                :box_version => "2004.01",
                :provision => "first_start.sh",
                :disks => {
                :sata1 => {
                :dfile => './sata1.vdi',
                :size => 512,
                :port => 1
                },
                :sata2 => {
                :dfile => './sata2.vdi',
                :size => 512, # Megabytes
                :port => 2
                },
                :sata3 => {
                :dfile => './sata3.vdi',
                :size => 512,
                :port => 3
                },
                :sata4 => {
                :dfile => './sata4.vdi',
                :size => 512,
                :port => 4
                },
                :sata5 => {
                :dfile => './sata5.vdi',
                :size => 512,
                :port => 5
                },
                :sata6 => {
                :dfile => './sata6.vdi',
                :size => 512,
                :port => 6
                },
                :sata7 => {
                :dfile => './sata7.vdi',
                :size => 512,
                :port => 7
                },
                :sata8 => {
                :dfile => './sata8.vdi',
                :size => 512,
                :port => 8
                },
                }
        },
}

Vagrant.configure("2") do |config|
        MACHINES.each do |boxname, boxconfig|
                config.vm.define boxname do |box|
                        box.vm.box = boxconfig[:box_name]
                        box.vm.box_version = boxconfig[:box_version]
                        box.vm.host_name = "zfs"
                        box.vm.provider :virtualbox do |vb|
                                vb.customize ["modifyvm", :id, "--memory", "1024"]
                                needsController = false
                        boxconfig[:disks].each do |dname, dconf|
                                unless File.exist?(dconf[:dfile])
                                vb.customize ['createhd', '--filename', dconf[:dfile], '--variant', 'Fixed', '--size', dconf[:size]]
                        needsController = true
                        end
                end
                        if needsController == true
                                vb.customize ["storagectl", :id, "--name", "SATA", "--add", "sata" ]
                                boxconfig[:disks].each do |dname, dconf|
                                vb.customize ['storageattach', :id, '--storagectl', 'SATA', '--port', dconf[:port], '--device', 0, '--type', 'hdd', '--medium', dconf[:dfile]]
                                end
                        end
                end

                box.vm.provision "shell", path: boxconfig[:provision]
                end
        end
end

```
first_start.sh
```bash
ujack@ubuntu2004:~/linuxpro-homework04$ cat first_start.sh
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
```
После инициализации виртуалки, проверяем , что zfs работает/подгружен (любой командой zfs...)
```bash
ujack@ubuntu2004:~/linuxpro-homework04$ vagrant ssh
[vagrant@zfs ~]$ sudo -i
[root@zfs ~]# zpool
missing command
usage: zpool command args ...
...
```

