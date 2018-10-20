@echo Const LinkDate = '%date%'; > LinkDate.inc
del mstdos32.exe
C:\UTIL\FPC\bin\go32v2\fpc.exe -B mst.pas -dlinktime -omstdos32.exe -O3 > errors.txt