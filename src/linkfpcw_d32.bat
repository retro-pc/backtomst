@echo Const LinkDate = '%date%'; > LinkDate.inc
del mstdos32.exe
C:\UTIL\FPC\bin\i386-win32\fpc.exe -B mst.pas -dlinktime -Tgo32v2 -omstdos32.exe -O3 > errors.txt