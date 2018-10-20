@echo Const LinkDate = '%date%'; > LinkDate.inc
del mst.exe
C:\UTIL\FPC\bin\i386-win32\fpc.exe -B mst.pas -dlinktime -TWin32 -O3 > errors.txt