
unit fdrawcmd;
interface

Uses Windows;

{
  Automatically converted by H2Pas 1.0.0 from fdrawcmd.h
  The following command line parameters were used:
    fdrawcmd.h
}

{$IFDEF FPC}
{.$PACKRECORDS C}
{$PACKRECORDS 1}
{$ENDIF}


  { fdrawcmd.sys 1.0.1.11 }
  { }
  { Low-level floppy filter, by Simon Owen }
  { }
  { http://simonowen.com/fdrawcmd/ }
  { }
  { Macro definition for defining IOCTL and FSCTL function control codes.  Note }
  { that function codes 0-2047 are reserved for Microsoft Corporation, and }
  { 2048-4095 are reserved for customers. }
  { }
  { begin_ntddk begin_wdm begin_nthal begin_ntifs }
  { }
  { Define the various device type values.  Note that values used by Microsoft }
  { Corporation are in the range 0-32767, and 32768-65535 are reserved for use }
  { by customers. }
  { }

  type
   DEVICE_TYPE = DWORD;
  const

    FILE_DEVICE_BEEP = $00000001;
    FILE_DEVICE_CD_ROM = $00000002;
    FILE_DEVICE_CD_ROM_FILE_SYSTEM = $00000003;
    FILE_DEVICE_CONTROLLER = $00000004;
    FILE_DEVICE_DATALINK = $00000005;
    FILE_DEVICE_DFS = $00000006;
    FILE_DEVICE_DISK = $00000007;
    FILE_DEVICE_DISK_FILE_SYSTEM = $00000008;
    FILE_DEVICE_FILE_SYSTEM = $00000009;
    FILE_DEVICE_INPORT_PORT = $0000000a;
    FILE_DEVICE_KEYBOARD = $0000000b;
    FILE_DEVICE_MAILSLOT = $0000000c;
    FILE_DEVICE_MIDI_IN = $0000000d;
    FILE_DEVICE_MIDI_OUT = $0000000e;
    FILE_DEVICE_MOUSE = $0000000f;
    FILE_DEVICE_MULTI_UNC_PROVIDER = $00000010;
    FILE_DEVICE_NAMED_PIPE = $00000011;
    FILE_DEVICE_NETWORK = $00000012;
    FILE_DEVICE_NETWORK_BROWSER = $00000013;
    FILE_DEVICE_NETWORK_FILE_SYSTEM = $00000014;
    FILE_DEVICE_NULL = $00000015;
    FILE_DEVICE_PARALLEL_PORT = $00000016;
    FILE_DEVICE_PHYSICAL_NETCARD = $00000017;
    FILE_DEVICE_PRINTER = $00000018;
    FILE_DEVICE_SCANNER = $00000019;
    FILE_DEVICE_SERIAL_MOUSE_PORT = $0000001a;
    FILE_DEVICE_SERIAL_PORT = $0000001b;
    FILE_DEVICE_SCREEN = $0000001c;
    FILE_DEVICE_SOUND = $0000001d;
    FILE_DEVICE_STREAMS = $0000001e;
    FILE_DEVICE_TAPE = $0000001f;
    FILE_DEVICE_TAPE_FILE_SYSTEM = $00000020;
    FILE_DEVICE_TRANSPORT = $00000021;
    FILE_DEVICE_UNKNOWN = $00000022;
    FILE_DEVICE_VIDEO = $00000023;
    FILE_DEVICE_VIRTUAL_DISK = $00000024;
    FILE_DEVICE_WAVE_IN = $00000025;
    FILE_DEVICE_WAVE_OUT = $00000026;
    FILE_DEVICE_8042_PORT = $00000027;
    FILE_DEVICE_NETWORK_REDIRECTOR = $00000028;
    FILE_DEVICE_BATTERY = $00000029;
    FILE_DEVICE_BUS_EXTENDER = $0000002a;
    FILE_DEVICE_MODEM = $0000002b;
    FILE_DEVICE_VDM = $0000002c;
    FILE_DEVICE_MASS_STORAGE = $0000002d;
    FILE_DEVICE_SMB = $0000002e;
    FILE_DEVICE_KS = $0000002f;
    FILE_DEVICE_CHANGER = $00000030;
    FILE_DEVICE_SMARTCARD = $00000031;
    FILE_DEVICE_ACPI = $00000032;
    FILE_DEVICE_DVD = $00000033;
    FILE_DEVICE_FULLSCREEN_VIDEO = $00000034;
    FILE_DEVICE_DFS_FILE_SYSTEM = $00000035;
    FILE_DEVICE_DFS_VOLUME = $00000036;
    FILE_DEVICE_SERENUM = $00000037;
    FILE_DEVICE_TERMSRV = $00000038;
    FILE_DEVICE_KSEC = $00000039;
    FILE_DEVICE_FIPS = $0000003A;
  { was #define dname(params) para_def_expr }
  { argument types are unknown }
  { return type might be wrong }

  function CTL_CODE(DeviceType,_Function,Method,Access : longint) : longint; inline;

  { }
  { Define the method codes for how buffers are passed for I/O and FS controls }
  { }
  const
    METHOD_BUFFERED = 0;
    METHOD_IN_DIRECT = 1;
    METHOD_OUT_DIRECT = 2;
    METHOD_NEITHER = 3;
    FDRAWCMD_VERSION = $0100010b;    { Compile-time version, for structures and definitions below }
  { Must be checked with run-time driver for compatibility }
  { was #define dname(params) para_def_expr }
  { argument types are unknown }
  { return type might be wrong }

  function FD_CTL_CODE(i,m : longint) : longint; inline;

  { If you're not using C/C++, use the IOCTL values below }
  { was #define dname def_expr }
  function IOCTL_FDRAWCMD_GET_VERSION : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_READ_TRACK : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_SPECIFY : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_SENSE_DRIVE_STATUS : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_WRITE_DATA : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_READ_DATA : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_RECALIBRATE : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_SENSE_INT_STATUS : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_WRITE_DELETED_DATA : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_READ_ID : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_READ_DELETED_DATA : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_FORMAT_TRACK : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_DUMPREG : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_SEEK : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_VERSION : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_SCAN_EQUAL : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_PERPENDICULAR_MODE : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_CONFIGURE : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_LOCK : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_VERIFY : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_POWERDOWN_MODE : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_PART_ID : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_SCAN_LOW_OR_EQUAL : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_SCAN_HIGH_OR_EQUAL : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_SAVE : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_OPTION : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_RESTORE : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_DRIVE_SPEC_CMD : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_RELATIVE_SEEK : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FDCMD_FORMAT_AND_WRITE : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_SCAN_TRACK : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_GET_RESULT : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_RESET : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_SET_MOTOR_TIMEOUT : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_SET_DATA_RATE : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_GET_FDC_INFO : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_GET_REMAIN_COUNT : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_SET_DISK_CHECK : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_SET_SHORT_WRITE : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_SET_SECTOR_OFFSET : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_SET_HEAD_SETTLE_TIME : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_LOCK_FDC : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_UNLOCK_FDC : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_MOTOR_ON : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_MOTOR_OFF : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_WAIT_INDEX : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_TIMED_SCAN_TRACK : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_RAW_READ_TRACK : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_CHECK_DISK : longint; { return type might be wrong }

  { was #define dname def_expr }
  function IOCTL_FD_GET_TRACK_TIME : longint; { return type might be wrong }

  {///////////////////////////////////////////////////////////////////////////// }
  { Command flags: multi-track, MFM, sector skip, relative seek direction, verify enable count }
  const
    FD_OPTION_MT = $80;
    FD_OPTION_MFM = $40;
    FD_OPTION_SK = $20;
    FD_OPTION_DIR = $40;
    FD_OPTION_EC = $01;
    FD_OPTION_FM = $00;
    FD_ENCODING_MASK = FD_OPTION_MFM;
  { Controller data rates, for use with IOCTL_FD_SET_DATA_RATE }
    FD_RATE_MASK = 3;
    FD_RATE_500K = 0;
    FD_RATE_300K = 1;
    FD_RATE_250K = 2;
    FD_RATE_1M = 3;
  { FD_FDC_INFO controller types }
    FDC_TYPE_UNKNOWN = 0;
    FDC_TYPE_UNKNOWN2 = 1;
    FDC_TYPE_NORMAL = 2;
    FDC_TYPE_ENHANCED = 3;
    FDC_TYPE_82077 = 4;
    FDC_TYPE_82077AA = 5;
    FDC_TYPE_82078_44 = 6;
    FDC_TYPE_82078_64 = 7;
    FDC_TYPE_NATIONAL = 8;
  { Bits representing supported data rates, for the FD_FDC_INFO structure below }
    FDC_SPEED_250K = $01;
    FDC_SPEED_300K = $02;
    FDC_SPEED_500K = $04;
    FDC_SPEED_1M = $08;
    FDC_SPEED_2M = $10;
(** unsupported pragma#pragma pack(push,1)*)
(** unsupported pragma#pragma warning(push)*)
(** unsupported pragma#pragma warning(disable:4200)           // allow zero-sized arrays*)

  type
    tagFD_ID_HEADER = record
        cyl : BYTE;
        head : BYTE;
        sector : BYTE;
        size : BYTE;
      end;
    FD_ID_HEADER = tagFD_ID_HEADER;
    PFD_ID_HEADER = ^tagFD_ID_HEADER;

    tagFD_SEEK_PARAMS = record
        cyl : BYTE;
        head : BYTE;
      end;
    FD_SEEK_PARAMS = tagFD_SEEK_PARAMS;
    PFD_SEEK_PARAMS = ^tagFD_SEEK_PARAMS;
  { DIR }

    tagFD_RELATIVE_SEEK_PARAMS = record
        flags : BYTE;
        head : BYTE;
        offset : BYTE;
      end;
    FD_RELATIVE_SEEK_PARAMS = tagFD_RELATIVE_SEEK_PARAMS;
    PFD_RELATIVE_SEEK_PARAMS = ^tagFD_RELATIVE_SEEK_PARAMS;
  { MT MFM SK }

    tagFD_READ_WRITE_PARAMS = record
        flags : BYTE;
        phead : BYTE;
        cyl : BYTE;
        head : BYTE;
        sector : BYTE;
        size : BYTE;
        eot : BYTE;
        gap : BYTE;
        datalen : BYTE;
      end;
    FD_READ_WRITE_PARAMS = tagFD_READ_WRITE_PARAMS;
    PFD_READ_WRITE_PARAMS = ^tagFD_READ_WRITE_PARAMS;

    tagFD_CMD_RESULT = record
        st0 : BYTE;
        st1 : BYTE;
        st2 : BYTE;
        cyl : BYTE;
        head : BYTE;
        sector : BYTE;
        size : BYTE;
      end;
    FD_CMD_RESULT = tagFD_CMD_RESULT;
    PFD_CMD_RESULT = ^tagFD_CMD_RESULT;
  { MFM }

    tagFD_FORMAT_PARAMS = record
        flags : BYTE;
        phead : BYTE;
        size : BYTE;
        sectors : BYTE;
        gap : BYTE;
        fill : BYTE;
        Header : ^FD_ID_HEADER;
      end;
    FD_FORMAT_PARAMS = tagFD_FORMAT_PARAMS;
    PFD_FORMAT_PARAMS = ^tagFD_FORMAT_PARAMS;
  { MFM }

    tagFD_READ_ID_PARAMS = record
        flags : BYTE;
        head : BYTE;
      end;
    FD_READ_ID_PARAMS = tagFD_READ_ID_PARAMS;
    PFD_READ_ID_PARAMS = ^tagFD_READ_ID_PARAMS;
  { b6 = enable implied seek, b5 = enable fifo, b4 = poll disable, b3-b0 = fifo threshold }
  { precompensation start track }

    tagFD_CONFIGURE_PARAMS = record
        eis_efifo_poll_fifothr : BYTE;
        pretrk : BYTE;
      end;
    FD_CONFIGURE_PARAMS = tagFD_CONFIGURE_PARAMS;
    PFD_CONFIGURE_PARAMS = ^tagFD_CONFIGURE_PARAMS;
  { b7-b4 = step rate, b3-b0 = head unload time }
  { b7-b1 = head load time, b0 = non-DMA flag (unsupported) }

    tagFD_SPECIFY_PARAMS = record
        srt_hut : BYTE;
        hlt_nd : BYTE;
      end;
    FD_SPECIFY_PARAMS = tagFD_SPECIFY_PARAMS;
    PFD_SPECIFY_PARAMS = ^tagFD_SPECIFY_PARAMS;

    tagFD_SENSE_PARAMS = record
        head : BYTE;
      end;
    FD_SENSE_PARAMS = tagFD_SENSE_PARAMS;
    PFD_SENSE_PARAMS = ^tagFD_SENSE_PARAMS;

    tagFD_DRIVE_STATUS = record
        st3 : BYTE;
      end;
    FD_DRIVE_STATUS = tagFD_DRIVE_STATUS;
    PFD_DRIVE_STATUS = ^tagFD_DRIVE_STATUS;
  { status register 0 }
  { present cylinder number }

    tagFD_INTERRUPT_STATUS = record
        st0 : BYTE;
        pcn : BYTE;
      end;
    FD_INTERRUPT_STATUS = tagFD_INTERRUPT_STATUS;
    PFD_INTERRUPT_STATUS = ^tagFD_INTERRUPT_STATUS;
  { b7 = OW, b6 = 0, b5-b2 = drive select, b1 = gap2, b0 = write gate pre-erase loads }

    tagFD_PERPENDICULAR_PARAMS = record
        ow_ds_gap_wgate : BYTE;
      end;
    FD_PERPENDICULAR_PARAMS = tagFD_PERPENDICULAR_PARAMS;
    PFD_PERPENDICULAR_PARAMS = ^tagFD_PERPENDICULAR_PARAMS;
  { b7 = lock }

    tagFD_LOCK_PARAMS = record
        lock : BYTE;
      end;
    FD_LOCK_PARAMS = tagFD_LOCK_PARAMS;
    PFD_LOCK_PARAMS = ^tagFD_LOCK_PARAMS;
  { b4 = lock }

    tagFD_LOCK_RESULT = record
        lock : BYTE;
      end;
    FD_LOCK_RESULT = tagFD_LOCK_RESULT;
    PFD_LOCK_RESULT = ^tagFD_LOCK_RESULT;
  { present cylinder numbers }
  { b7-4 = step rate, b3-0 = head unload time }
  { b7-1 = head load time, b0 = non-dma mode }
  { sector count / end of track }
  { b7 = setting lock, b5-2 = drive selects, b1 = gap 2 (perpendicular), b0 = write gate }
  { b6 = implied seeks, b5 = fifo enable, b4 = poll disable, b3-0 = fifo threshold }
  { pre-comp start track }

    tagFD_DUMPREG_RESULT = record
        pcn0 : BYTE;
        pcn1 : BYTE;
        pcn2 : BYTE;
        pcn3 : BYTE;
        srt_hut : BYTE;
        hlt_nd : BYTE;
        sceot : BYTE;
        lock_d0123_gap_wgate : BYTE;
        eis_efifo_poll_fifothr : BYTE;
        pretrk : BYTE;
      end;
    FD_DUMPREG_RESULT = tagFD_DUMPREG_RESULT;
    PFD_DUMPREG_RESULT = ^tagFD_DUMPREG_RESULT;
  { number of sectors to skip after index }

    tagFD_SECTOR_OFFSET_PARAMS = record
        sectors : BYTE;
      end;
    FD_SECTOR_OFFSET_PARAMS = tagFD_SECTOR_OFFSET_PARAMS;
    PFD_SECTOR_OFFSET_PARAMS = ^tagFD_SECTOR_OFFSET_PARAMS;
  { length to write before interrupting }
  { finetune delay in microseconds }

    tagFD_SHORT_WRITE_PARAMS = record
        length : DWORD;
        finetune : DWORD;
      end;
    FD_SHORT_WRITE_PARAMS = tagFD_SHORT_WRITE_PARAMS;
    PFD_SHORT_WRITE_PARAMS = ^tagFD_SHORT_WRITE_PARAMS;
  { MFM }

    tagFD_SCAN_PARAMS = record
        flags : BYTE;
        head : BYTE;
      end;
    FD_SCAN_PARAMS = tagFD_SCAN_PARAMS;
    PFD_SCAN_PARAMS = ^tagFD_SCAN_PARAMS;
  { count of returned headers }
  { array of 'count' id fields }

    tagFD_SCAN_RESULT = record
        count : BYTE;
        Header : ^FD_ID_HEADER;
      end;
    FD_SCAN_RESULT = tagFD_SCAN_RESULT;
    PFD_SCAN_RESULT = ^tagFD_SCAN_RESULT;
  { time relative to index (in microseconds) }

    tagFD_TIMED_ID_HEADER = record
        reltime : DWORD;
        cyl : BYTE;
        head : BYTE;
        sector : BYTE;
        size : BYTE;
      end;
    FD_TIMED_ID_HEADER = tagFD_TIMED_ID_HEADER;
    PFD_TIMED_ID_HEADER = ^tagFD_TIMED_ID_HEADER;
  { count of returned headers }
  { offset of first sector detected }
  { total time for track (in microseconds) }
  { array of 'count' id fields }

    tagFD_TIMED_SCAN_RESULT = record
        count : BYTE;
        firstseen : BYTE;
        tracktime : DWORD;
        Header : ^FD_TIMED_ID_HEADER;
      end;
    FD_TIMED_SCAN_RESULT = tagFD_TIMED_SCAN_RESULT;
    PFD_TIMED_SCAN_RESULT = ^tagFD_TIMED_SCAN_RESULT;
  { FDC_TYPE_* }
  { FDC_SPEED_* values ORed together }

    tagFD_FDC_INFO = record
        ControllerType : BYTE;
        SpeedsAvailable : BYTE;
        BusType : BYTE;
        BusNumber : DWORD;
        ControllerNumber : DWORD;
        PeripheralNumber : DWORD;
      end;
    FD_FDC_INFO = tagFD_FDC_INFO;
    PFD_FDC_INFO = ^tagFD_FDC_INFO;
  { MFM }

    tagFD_RAW_READ_PARAMS = record
        flags : BYTE;
        head : BYTE;
        size : BYTE;
      end;
    FD_RAW_READ_PARAMS = tagFD_RAW_READ_PARAMS;
    PFD_RAW_READ_PARAMS = ^tagFD_RAW_READ_PARAMS;
(** unsupported pragma#pragma warning(pop)*)
(** unsupported pragma#pragma pack(pop)*)

implementation

  { was #define dname(params) para_def_expr }
  { argument types are unknown }
  { return type might be wrong }
  function CTL_CODE(DeviceType,_Function,Method,Access : longint) : longint;
  begin
    CTL_CODE:=(((DeviceType shl 16) or (Access shl 14)) or (_Function shl 2)) or Method;
  end;

  { was #define dname(params) para_def_expr }
  { argument types are unknown }
  { return type might be wrong }
  function FD_CTL_CODE(i,m : longint) : longint;
  begin
    FD_CTL_CODE:=CTL_CODE(FILE_DEVICE_UNKNOWN,i,m,FILE_READ_DATA or FILE_WRITE_DATA);
  end;

  { was #define dname def_expr }
  function IOCTL_FDRAWCMD_GET_VERSION : longint; { return type might be wrong }
    begin
      IOCTL_FDRAWCMD_GET_VERSION:=FD_CTL_CODE($888,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_READ_TRACK : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_READ_TRACK:=FD_CTL_CODE($802,METHOD_OUT_DIRECT);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_SPECIFY : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_SPECIFY:=FD_CTL_CODE($803,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_SENSE_DRIVE_STATUS : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_SENSE_DRIVE_STATUS:=FD_CTL_CODE($804,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_WRITE_DATA : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_WRITE_DATA:=FD_CTL_CODE($805,METHOD_IN_DIRECT);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_READ_DATA : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_READ_DATA:=FD_CTL_CODE($806,METHOD_OUT_DIRECT);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_RECALIBRATE : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_RECALIBRATE:=FD_CTL_CODE($807,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_SENSE_INT_STATUS : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_SENSE_INT_STATUS:=FD_CTL_CODE($808,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_WRITE_DELETED_DATA : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_WRITE_DELETED_DATA:=FD_CTL_CODE($809,METHOD_IN_DIRECT);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_READ_ID : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_READ_ID:=FD_CTL_CODE($80a,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_READ_DELETED_DATA : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_READ_DELETED_DATA:=FD_CTL_CODE($80c,METHOD_OUT_DIRECT);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_FORMAT_TRACK : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_FORMAT_TRACK:=FD_CTL_CODE($80d,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_DUMPREG : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_DUMPREG:=FD_CTL_CODE($80e,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_SEEK : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_SEEK:=FD_CTL_CODE($80f,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_VERSION : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_VERSION:=FD_CTL_CODE($810,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_SCAN_EQUAL : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_SCAN_EQUAL:=FD_CTL_CODE($811,METHOD_IN_DIRECT);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_PERPENDICULAR_MODE : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_PERPENDICULAR_MODE:=FD_CTL_CODE($812,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_CONFIGURE : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_CONFIGURE:=FD_CTL_CODE($813,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_LOCK : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_LOCK:=FD_CTL_CODE($814,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_VERIFY : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_VERIFY:=FD_CTL_CODE($816,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_POWERDOWN_MODE : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_POWERDOWN_MODE:=FD_CTL_CODE($817,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_PART_ID : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_PART_ID:=FD_CTL_CODE($818,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_SCAN_LOW_OR_EQUAL : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_SCAN_LOW_OR_EQUAL:=FD_CTL_CODE($819,METHOD_IN_DIRECT);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_SCAN_HIGH_OR_EQUAL : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_SCAN_HIGH_OR_EQUAL:=FD_CTL_CODE($81d,METHOD_IN_DIRECT);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_SAVE : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_SAVE:=FD_CTL_CODE($82e,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_OPTION : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_OPTION:=FD_CTL_CODE($833,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_RESTORE : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_RESTORE:=FD_CTL_CODE($84e,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_DRIVE_SPEC_CMD : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_DRIVE_SPEC_CMD:=FD_CTL_CODE($88e,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_RELATIVE_SEEK : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_RELATIVE_SEEK:=FD_CTL_CODE($88f,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FDCMD_FORMAT_AND_WRITE : longint; { return type might be wrong }
    begin
      IOCTL_FDCMD_FORMAT_AND_WRITE:=FD_CTL_CODE($8ef,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_SCAN_TRACK : longint; { return type might be wrong }
    begin
      IOCTL_FD_SCAN_TRACK:=FD_CTL_CODE($900,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_GET_RESULT : longint; { return type might be wrong }
    begin
      IOCTL_FD_GET_RESULT:=FD_CTL_CODE($901,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_RESET : longint; { return type might be wrong }
    begin
      IOCTL_FD_RESET:=FD_CTL_CODE($902,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_SET_MOTOR_TIMEOUT : longint; { return type might be wrong }
    begin
      IOCTL_FD_SET_MOTOR_TIMEOUT:=FD_CTL_CODE($903,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_SET_DATA_RATE : longint; { return type might be wrong }
    begin
      IOCTL_FD_SET_DATA_RATE:=FD_CTL_CODE($904,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_GET_FDC_INFO : longint; { return type might be wrong }
    begin
      IOCTL_FD_GET_FDC_INFO:=FD_CTL_CODE($905,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_GET_REMAIN_COUNT : longint; { return type might be wrong }
    begin
      IOCTL_FD_GET_REMAIN_COUNT:=FD_CTL_CODE($906,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_SET_DISK_CHECK : longint; { return type might be wrong }
    begin
      IOCTL_FD_SET_DISK_CHECK:=FD_CTL_CODE($908,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_SET_SHORT_WRITE : longint; { return type might be wrong }
    begin
      IOCTL_FD_SET_SHORT_WRITE:=FD_CTL_CODE($909,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_SET_SECTOR_OFFSET : longint; { return type might be wrong }
    begin
      IOCTL_FD_SET_SECTOR_OFFSET:=FD_CTL_CODE($90a,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_SET_HEAD_SETTLE_TIME : longint; { return type might be wrong }
    begin
      IOCTL_FD_SET_HEAD_SETTLE_TIME:=FD_CTL_CODE($90b,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_LOCK_FDC : longint; { return type might be wrong }
    begin
      IOCTL_FD_LOCK_FDC:=FD_CTL_CODE($910,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_UNLOCK_FDC : longint; { return type might be wrong }
    begin
      IOCTL_FD_UNLOCK_FDC:=FD_CTL_CODE($911,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_MOTOR_ON : longint; { return type might be wrong }
    begin
      IOCTL_FD_MOTOR_ON:=FD_CTL_CODE($912,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_MOTOR_OFF : longint; { return type might be wrong }
    begin
      IOCTL_FD_MOTOR_OFF:=FD_CTL_CODE($913,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_WAIT_INDEX : longint; { return type might be wrong }
    begin
      IOCTL_FD_WAIT_INDEX:=FD_CTL_CODE($914,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_TIMED_SCAN_TRACK : longint; { return type might be wrong }
    begin
      IOCTL_FD_TIMED_SCAN_TRACK:=FD_CTL_CODE($915,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_RAW_READ_TRACK : longint; { return type might be wrong }
    begin
      IOCTL_FD_RAW_READ_TRACK:=FD_CTL_CODE($916,METHOD_OUT_DIRECT);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_CHECK_DISK : longint; { return type might be wrong }
    begin
      IOCTL_FD_CHECK_DISK:=FD_CTL_CODE($917,METHOD_BUFFERED);
    end;

  { was #define dname def_expr }
  function IOCTL_FD_GET_TRACK_TIME : longint; { return type might be wrong }
    begin
      IOCTL_FD_GET_TRACK_TIME:=FD_CTL_CODE($918,METHOD_BUFFERED);
    end;


end.
