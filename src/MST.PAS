{************************************************}
{                                                }
{  Программа для работы с дисками CP/M-80 и      }
{  МикроДос                                      }
{  Back to MST                                   }
{                                                }
{  Version 1.0                                   }
{  Copyright (C) MarinovSoft 2013-2014           }
{                                                }
{  From Kuzbass (Siberia) with Love              }
{                                                }
{  http://marinovsoft.narod.ru                   }
{  mailto:super386@rambler.ru                    }
{                                                }
{************************************************}

{$ifdef fpc}
{$A1}
{$R-}
{$endif}

Uses App, Objects, Views, Menus, Drivers, Stddlg,
  Msgbox, GrowView, AppWin, Mstconst, MSTDisk, AppWinEx, MstDlg, DosDlg, FV_Const, SysUtils
{$ifdef fpc}
{$ifndef win32}
, Go32
{$endif}
{$else}
, Service
{$endif}
;

{.$define linktime}

{$ifdef linktime}
{$I LinkDate.inc}
{$endif}

Type
  PMSTApplication = ^TMSTApplication;
  TMSTApplication = Object(TApplication)
{    MSTDisk:PMSTDisk;}
    Frec : TFormRec;
  {
  Const
    Frec : TFormRec = (
      Ssize :3;
      Gap1  :0;
      Gap2  :0;
      SCount:5;
      TCount:80;
      Side  :0;
      Track :0;
      Sect  :0;
      Interl:1
    );
  }
    {$ifdef fpc}
    FileName:ShortString;
    DiskName:ShortString;
    {$else}
    FileName:String;
    DiskName:String;
    {$endif}
  { 0=500Kbps (HD), 1=300Kbps (DD 5.25"), 2=250Kbps (DD 3.5"), 3=1Mbps (ED) }
    FDRate:(FD_RATE_500K=0,FD_RATE_300K=1,FD_RATE_250K=2,FD_RATE_1M=3);
    Dbt:Array[0..9] Of Byte;
    LeftWindow:PMSTShortWindow;
    RightWindow:PDOSShortWindow;
    Constructor Init;
    Destructor Done;Virtual;
    Procedure HandleEvent(Var Event:TEvent);Virtual;
    Procedure InitMenuBar; Virtual;
    Procedure InitStatusLine;Virtual;
    Procedure Idle;Virtual;
    Procedure DoAboutBox;
    Procedure FormatDisk;
    Procedure ReadDisk;
    Procedure WriteDisk;
    Procedure SelectDriveImage;
    Procedure ListDisk;
  End;

Procedure TMSTApplication.DoAboutBox;
Begin
  MessageBox(#3'Программа работы с дисками'#13#3'CP/M версия 1.0'
  {$ifdef linktime}
  + ' (' + linkdate + ')'
  {$endif}
    + #13 +
    #3'Copyright (C) 2013-2014'#13#3'Маринов Георгий aka MarinovSoft'
  , Nil, mfInformation Or mfOKButton);
End;

Procedure TMSTApplication.InitMenuBar;
Var
  R: TRect;
Begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~F~ile', hcNoContext, NewMenu(
    StdFileMenuItems(Nil)),
    NewSubMenu('~D~isc', hcNoContext, NewMenu(
    NewItem('~R~ead', '', kbNoKey, cmReadDisc, hcNoContext,
    NewItem('~W~rite', '', kbNoKey, cmWriteDisc, hcNoContext,
    NewItem('~F~ormat', '', kbNoKey, cmFormatDisc, hcNoContext,
    NewItem('~L~ist disk', '', kbNoKey, cmListDisk, hcNoContext,
    Nil))))),
    NewSubMenu('~O~ptions', hcNoContext, NewMenu(
    NewSubMenu('~D~rive', hcNoContext, NewMenu(
    NewSubMenu('Drive ~A~', hcNoContext, NewMenu(
    NewItem('~3~''5', '', kbNoKey, cmSelectDriveA3, hcNoContext,
    NewItem('~5~''25', '', kbNoKey, cmSelectDriveA5, hcNoContext,
    Nil))),
    NewSubMenu('Drive ~B~', hcNoContext, NewMenu(
    NewItem('~3~''5', '', kbNoKey, cmSelectDriveB3, hcNoContext,
    NewItem('~5~''25', '', kbNoKey, cmSelectDriveB5, hcNoContext,
    Nil))),
    NewItem('File ~i~mage', '', kbNoKey, cmSelectDriveImage, hcNoContext,
    Nil)))),
//    NewItem('Floppy setup', '', kbNoKey, cmOptions, hcNoContext,
//    Nil))),
    Nil)),
    NewSubMenu('~W~indow', hcNoContext, NewMenu(
    StdWindowMenuItems(Nil)),
    NewSubMenu('~H~elp', hcNoContext, NewMenu(
    NewItem('~A~bout...', 'F1', kbF1, cmAbout, hcNoContext,
    Nil)),
    Nil))))))));
End;

Procedure TMSTApplication.InitStatusLine;
Var R:TRect;
Begin
  GetExtent(R);
  R.A.Y:=R.B.Y-1;
  New(StatusLine,Init(R,
    NewStatusDef(0,$2B00,
    NewStatusKey('~Alt-X~ Exit',kbAltX,cmQuit,
    NewStatusKey('~F3~ Open',kbF3,cmOpen,
    NewStatusKey('~F8~ Delete file', kbF8, cmDelete,
    NewStatusKey('~F5~ Copy file', kbNoKey, 0,
    StdStatusKeys(Nil))))),
    NewStatusDef(hcView, hcView,
    NewStatusKey('~F4~ Hex/Asc/Dmp', kbF4, cmHexMode,
    NewStatusKey('~Shift+F2~ Wrap', kbShiftF2, cmUnWrap,
    StdStatusKeys(nil))),  Nil))));
End;

Procedure TMSTApplication.HandleEvent(Var Event:TEvent);
Begin
  If Event.What = evCommand Then
  Begin
    Case Event.Command Of
      cmAbout:
      Begin
        DoAboutBox;
        ClearEvent(Event);
      End;
      cmWriteDisc:
      Begin
        WriteDisk; {переделать}
        ClearEvent(Event);
      End;
      cmReadDisc:
      Begin
        ReadDisk; {переделать}
        ClearEvent(Event);
      End;
      cmFormatDisc:
      Begin
        FormatDisk; {переделать}
        ClearEvent(Event);
      End;
      cmSelectDriveA3,cmSelectDriveA5:
      Begin
        DiskName:='A';
        If Event.Command = cmSelectDriveA3 Then
          FDRate:=FD_RATE_250K
        else
          FDRate:=FD_RATE_300K;
        ClearEvent(Event);
      End;
      cmSelectDriveB3,cmSelectDriveB5:
      Begin
        DiskName:='B';
        If Event.Command = cmSelectDriveB3 Then
          FDRate:=FD_RATE_250K
        else
          FDRate:=FD_RATE_300K;
        ClearEvent(Event);
      End;
      cmSelectDriveImage:
      Begin
        SelectDriveImage;
        ClearEvent(Event);
      End;
      cmListDisk:
      Begin
        ListDisk;
        ClearEvent(Event);
      End;
(*      cmCopyFileDOS:
      begin
         Message(LeftWindow, evCommand, cmCopyFileDOS, Event.InfoPtr);
         // ClearEvent(Event);
      end;
      cmCopyFileMST:
      begin
         Message(RightWindow, evCommand, cmCopyFileMST, Event.InfoPtr);
      end;*)
    End;

  End;
  If Event.What = evkeyDown Then
  Begin
    Case Event.KeyCode of
      kbTab:
      Begin
        Message(@Self, evCommand, cmNext, @Self);
      End;
    End;
  End;
  Inherited HandleEvent(Event);
End;

Procedure TMSTApplication.FormatDisk;
Var
  Track:Byte;
  Errc:Byte;
  Rslt:Word;
  D:PProgressDialog;
  R:TRect;
  Frm_Vec:TFrm_Vec;
  Catalog:TCatalog;
  K, I:Word;
  Buf:TBufType;

  MSTDisk:PMSTDisk;

Const
  GV1 : PGrowView = nil;
Procedure VerifyTrack(_Frec:TFormRec);
Var
  Sect:Byte;
  Buf:TBufType;
  K:Word;
begin
  Sect:=1;
  While Sect <= Frec.Scount Do
  Begin
    Frec.Sect:= Sect;
    Errc:=MSTDisk^.ReadSect(_Frec, Buf);
    If Errc = 0 Then

    else
    begin
      K:=_Frec.Track;
      If Integer(K) - Integer(SysTrk) < 0 Then
      else
      begin
        K:=((K-Systrk)*5+Sect-1) ShR 1;
        Frm_Vec[K]:=1;
      end;
    end;
    inc(Sect);
  End;
end;

Begin
  FillChar(Frm_Vec,512,0);
  If DiskName[0] = #0 Then
     SelectDriveImage;
  If DiskName[0] > #1 Then
     MSTDisk:= New(PMicroDOSDiskImage, Init(DiskName, Frec))
  Else If DiskName[0] > #0 Then
     MSTDisk:= New(PMicroDOSDisk, Init(DiskName[1], Frec, Byte(FDRate)))
  Else
     Exit;

  { Тут вам не Си! Злобный Паскаль ругается      }
  {
  For Frec.Track:=0 To (Frec.Tcount ShL 1)-1 Do
}
  R.Assign( 2, 4, 38, 5 );
  GV1 := New( PGrowView, Init( R, (Frec.TCount ShL 1)-1 ));

  D:=New(PDiskProgressDialog, Init(GV1, ''));
  Desktop^.Insert(D);
  D^.SetCurrentText('Format disk');

  Track:=0; Errc:=0;
  While Track <= (Frec.TCount ShL 1)-1 Do
  Begin
    Frec.Track:=Track;
    MSTDisk^.SeekTrack(Frec);
    Errc:=MSTDisk^.FormatTrack(Frec);
    GV1^.Update(Track);
    If Errc = 0 Then
      Inc(Track)
    Else
    Begin
      Rslt:= MessageBox(MSTDisk^.GetErrorDescription(Track, 0, Errc), Nil, mfError +
        mfYesNoCancel);
      If Rslt = cmYes Then
      Begin
        { Нажали Yes - повторим }
        MSTDisk^.ResetDisk;
        Continue;
      End;
      If Rslt = cmCancel Then
      Begin
        { Нажали отмена}
        Dispose(D,Done);
        Exit;
        {Break;}
      End;
      If Rslt = cmNo Then
      Begin
        { Нажали No - пропустим }
        { Проверить Track}
        VerifyTrack(Frec);
        Inc(Track);
        Continue;
      End;
    End;
    VerifyTrack(Frec);
    { Проверить Track}
  End;
  FillChar(Catalog,4096,$E5);
  I:=0;
  For K:=0 to BlockCount do
    If Frm_Vec[K]=1 Then
    begin
      FillChar(Catalog[I ShR 3].Fat[I And 7],16-(I And 7) ShL 1,0);
      Catalog[I ShR 3].Fat[I And 7]:=K;
      Catalog[I ShR 3].User:=$20;
      Catalog[I ShR 3].Exn:=I ShR 3;
      Inc(I);
      Catalog[I ShR 3].Recs:=(I And 7) ShL 4;
    end;

  With MSTDisk^ do
  Begin

    _Dpb:=Dpb;

    _Dpb.Systrk:=Systrk;

    MSTDisk^.WriteDir(Catalog);

{    _Dpb.Dsize:=BlockCount-1;}
    _Dpb.Dsize:=BlockCount;
    _Dpb.TCount:=Frec.TCount;
    _Dpb.Crc:=$66;
    For I:=0 To 30 Do
      {$ifndef fpc}
      Inc(Mem[Seg(_Dpb):Ofs(_Dpb)+31],Mem[Seg(_Dpb):Ofs(_Dpb)+I]);
      {$else}
      Inc(_Dpb.Crc, PByteArray(@_Dpb)^[I]);
      {$endif}
    FillChar(Buf, 1024, $E5);
    Move(_Dpb, Buf, 32);
  End;
  Frec.Sect:=1;
  Frec.Track:=0;
  Errc:=MSTDisk^.WriteSect(Frec,Buf);
  Dispose(MSTDisk, Done);
  Dispose(D,Done);
End;

Procedure TMSTApplication.ReadDisk;
Var
  Track:Byte;
  Sect:Byte;
  Errc:Byte;
  F:File Of TBufType;
  Buf:TBufType;
  Rslt:Word;
  MSTDisk:PMSTDisk;
  FileDialog:PFileDialog;
  FileExt:ShortString;
  R:TRect;
  D:PProgressDialog;
const
  FDOptions: Word = fdOKButton {or fdOpenButton};
  GV1 : PGrowView = nil;
Begin
  FileName:= '*.kdi';
  New(FileDialog, Init(FileName, 'Save file', '~F~ile name', FDOptions, 1));
  if ExecuteDialog(FileDialog, @FileName) = cmCancel then
    Exit;
  FileExt:=ExtractFileExt(FileName);
  If (Length(FileExt) = 0) or (FileExt = '.') Then
    FileName:=ChangeFileExt(FileName, '.kdi');

  If FileExists(FileName) Then
  Begin
    Rslt:= MessageBox('File exists, overwrite?', Nil, mfError +
      mfOKCancel);
    If Rslt = cmCancel Then
      Exit;
  End;

  If DiskName[0] = #0 Then
     SelectDriveImage;
  If DiskName[0] > #1 Then
     MSTDisk:= New(PMicroDOSDiskImage, Init(DiskName, Frec))
  Else If DiskName[0] > #0 Then
     MSTDisk:= New(PMicroDOSDisk, Init(DiskName[1], Frec, Byte(FDRate)))
  Else
     Exit;

  MSTDisk^.ReadDPB;

  Assign(F, FileName);
  ReWrite(F);

  R.Assign( 2, 4, 38, 5 );
//  GV1 := New( PGrowView, Init( R, (Frec.TCount ShL 1)-1 )); // Количество секторов нужно брать из dpb
  GV1 := New( PGrowView, Init( R, (MSTDisk^._dpb.TCount ShL 1)-1 ));

  D:=New(PDiskProgressDialog, Init(GV1, ''));
  Desktop^.Insert(D);
  D^.SetCurrentText('Read disk');

//  For Track:=0 To (Frec.TCount ShL 1)-1 Do       // Количество секторов нужно брать из dpb
  For Track:=0 To (MSTDisk^._dpb.TCount ShL 1)-1 Do
  Begin
    Frec.Track:=Track;
    MSTDisk^.SeekTrack(Frec);
    GV1^.Update(Track);
    Sect:=1;
    While Sect <= Frec.SCount Do
    Begin
      Frec.Sect:= Sect;
      { rsect(sct,trk,buf,flag,errc);}
      FillChar(Buf,SizeOf(Buf),0);
      Errc:=MSTDisk^.ReadSect(Frec, Buf);
      If Errc = 0 Then
      Begin
        Inc(Sect);
        Write(F,Buf)
      End
      Else
      Begin
        { Rslt:=MessageBox('Disk read error! Retry?', Nil, mfError +
          mfYesNoCancel); }
        Rslt:= MessageBox(MSTDisk^.GetErrorDescription(Track, Sect, Errc), Nil, mfError +
          mfYesNoCancel);

        If Rslt = cmYes Then
        Begin
          { Нажали Yes - повторим }
          MSTDisk^.ResetDisk;
        End;
        FillChar(Buf,SizeOf(Buf),0);
        If Rslt = cmNo Then
        Begin
          { Нажали No - пропустим, записав нули }
          Inc(Sect);
          Write(F,Buf);
        End;
        If Rslt = cmCancel Then
        Begin
          { Нажали отмена - закроем файл без записи }
          Dispose(MSTDisk, Done);
          Dispose(D,Done);
          Close(F);
          Exit;
        End;
      End;
    End;
  End;
  Dispose(MSTDisk, Done);
  Dispose(D,Done);
  Close(F);
End;

Procedure TMSTApplication.WriteDisk;
Var
  Track:Byte;
  Sect:Byte;
  Errc:Byte;
  F:File Of TBufType;
  Buf:TBufType;
  Rslt:Word;
  MSTDisk:PMSTDisk;
  FileDialog:PFileDialog;
{  FileExt:ShortString; }
  R:TRect;
  D:PProgressDialog;
const
  FDOptions: Word = fdOKButton {or fdOpenButton};
  GV1 : PGrowView = nil;
Begin
  FileName:= '*.kdi';
  New(FileDialog, Init(FileName, 'Open file', '~F~ile name', FDOptions, 1));
  if ExecuteDialog(FileDialog, @FileName) = cmCancel then
    Exit;
{  FileExt:=ExtractFileExt(FileName);
  If (Length(FileExt) = 0) or (FileExt = '.') Then
    FileName:=ChangeFileExt(FileName, '.kdi');}
  If Not FileExists(FileName) Then
  begin
    MessageBox(#3'File not found!', nil, mfError and mfOKButton);
    Exit;
  End;
  If DiskName[0] = #0 Then
     SelectDriveImage;
  If DiskName[0] > #1 Then
     MSTDisk:= New(PMicroDOSDiskImage, Init(DiskName, Frec))
  Else If DiskName[0] > #0 Then
     MSTDisk:= New(PMicroDOSDisk, Init(DiskName[1], Frec, Byte(FDRate)))
  Else
     Exit;

  MSTDisk^._Dpb:=Dpb;

  Assign(F,FileName);
  Reset(F);

  R.Assign( 2, 4, 38, 5 );
//  GV1 := New( PGrowView, Init( R, (Frec.TCount ShL 1)-1 )); // Количество секторов нужно брать из dpb
  GV1 := New( PGrowView, Init( R, (MSTDisk^._dpb.TCount ShL 1)-1 ));

  D:=New(PDiskProgressDialog, Init(GV1, ''));
  Desktop^.Insert(D);
  D^.SetCurrentText('Write disk');

//  For Track:=0 To (Frec.Tcount ShL 1)-1 Do
  For Track:=0 To (MSTDisk^._dpb.TCount ShL 1)-1 Do
  Begin
    Frec.Track:=Track;
    MSTDisk^.SeekTrack(Frec);
    GV1^.Update(Track);
    Sect:=1;
    While Sect <= Frec.SCount Do
    Begin
      If (FileSize(F) - FilePos(F)) <= 0 Then
      Begin
        { Close(F);
         Exit; }
        Break;
      End;
      {$I-}
      Read(F,Buf);
      {$I+}
      Frec.Sect:= Sect;
      { rsect(sct,trk,buf,flag,errc);}
      Errc:=MSTDisk^.WriteSect(Frec, Buf);
      If Errc = 0 Then
      Begin
        Inc(Sect);
      End
      Else
      Begin
        Rslt:= MessageBox(MSTDisk^.GetErrorDescription(Track, Sect, Errc), Nil, mfError +
          mfYesNoCancel);

        If Rslt = cmYes Then
        Begin
          { Нажали Yes - повторим }
          MSTDisk^.ResetDisk;
        End;
        If Rslt = cmNo Then
        Begin
          { Нажали No - пропустим, записав нули }
          Inc(Sect);
        End;
        If Rslt = cmCancel Then
        Begin
          { Нажали отмена - закроем файл без записи }
          Dispose(MSTDisk, Done);
          Dispose(D,Done);
          Close(F);
          Exit;
        End;
      End;
    End;
  End;
  Dispose(MSTDisk, Done);
  Dispose(D,Done);
  Close(F);
End;

Constructor TMSTApplication.Init;
Var
  B:Byte;
  S:ShortString;
{$ifdef fpc}
{$ifndef win32}
  Seg, Ofs:Word;
{$endif}
{$endif}
{
Const
  defFrec : TFormRec = (
    Ssize :3;
    Gap1  :0;
    Gap2  :0;
    SCount:5;
    TCount:80;
    Side  :0;
    Track :0;
    Sect  :0;
    Interl:1
  );
}
Begin
  Inherited Init;
  DisableCommands([cmFileInfo, cmEditCategories]);
//  DiskName:='ESL_00.kdi';
  Frec.Ssize:=3;
  Frec.Gap1:=0;
  Frec.Gap2:=0;
  Frec.SCount:=5;
  Frec.TCount:=80;
  Frec.Side:=0;
  Frec.Track:=0;
  Frec.Interl:=1;
  {$ifdef fpc}
  {$ifndef win32}
  dosmemget(0, $7A, Seg, 2);
  dosmemget(0, $78, Ofs, 2);
  For B:=0 To 9 Do
    dosmemget(Seg, Ofs + B, Dbt[b], 1);
  B:=3;   dosmemput(Seg, Ofs + 3, B, 1);
  B:=5;   dosmemput(Seg, Ofs + 4, B, 1);
  B:=$E5; dosmemput(Seg, Ofs + 8, B, 1);
  {$endif}
  {$else}
  For B:=0 To 9 Do
    Dbt[B]:=Mem[MemW[0:$7A]:MemW[0:$78]+B];
  Mem[MemW[0:$7A]:MemW[0:$78]+3]:=3;
  Mem[MemW[0:$7A]:MemW[0:$78]+4]:=5;
  Mem[MemW[0:$7A]:MemW[0:$78]+8]:=$E5;
  {$endif}
  GetDir(0, S);
  RightWindow:=New(PDOSLongWindow, Init(S{'C:\'}, '*.*'));

  Desktop^.Insert(RightWindow);

  B:=ParamCount;
  While B > 0 do
  Begin
    If FileExists(ParamStr(B)) Then
    Begin
       DiskName:=ParamStr(B);
       ListDisk;
       Break;
    End;
    Dec(B)
  End;
End;

Procedure TMSTApplication.SelectDriveImage;
Var
{  R: TRect; }
  FileDialog: PFileDialog;
  TheFile: FNameStr;
Const
  fdOptions: Word = fdOkButton + fdOpenButton;
Begin
  TheFile := '*.KDI';
  FileDialog := New(PFileDialog, Init(TheFile, 'Open file', '~F~ile name',
    fdOptions, 1));
  If ExecuteDialog(FileDialog, @TheFile) <> cmCancel Then
  begin
    DiskName:=TheFile;
  end;
end;

Procedure TMSTApplication.ListDisk;
var
{   Catalog:TCatalog; }
   MSTDisk:PMSTDisk;
begin
  If DiskName[0] = #0 Then
     SelectDriveImage;
  If DiskName[0] > #1 Then
     MSTDisk:= New(PMicroDOSDiskImage, Init(DiskName, Frec))
  Else If DiskName[0] > #0 Then
     MSTDisk:= New(PMicroDOSDisk, Init(DiskName[1], Frec, Byte(FDRate)))
  Else
     Exit;
  { MSTDisk^.ReadDir(Catalog); }
  LeftWindow:=New(PMSTShortWindow, Init(MSTDisk));
  If LeftWindow^.LastError = 0 Then
    Desktop^.Insert(LeftWindow)
  Else
    Dispose(LeftWindow, Done);
{  Dispose(MSTDisk, Done);}
end;

Destructor TMSTApplication.Done;
{$ifdef fpc}
{$ifndef win32}
Var
  B:Byte;
  Ofs,Seg:Word;
{$endif}
{$else}
Var
  B:Byte;
{$endif}
Begin
  {$ifdef fpc}
  {$ifndef win32}
  dosmemget(0, $7A, Seg, 2);
  dosmemget(0, $78, Ofs, 2);
  For B:=0 To 9 Do
  begin
    dosmemput(Seg, Ofs + B, Dbt[b], 1);
  end;
  {$endif}
  {$else}
  For B:=0 To 9 Do
  begin
    Mem[MemW[0:$7A]:MemW[0:$78]+B]:=Dbt[B];
  end;
  {$endif}
  Inherited Done;
End;

Procedure TMSTApplication.Idle;
Begin
  Inherited Idle;
  If Message(Application, evBroadCast, cmMSTDiskOpen, nil) <> Nil Then
    DisableCommands([cmReadDisc,cmWriteDisc,cmListDisk,cmFormatDisc,cmSelectDriveA5,cmSelectDriveA3,cmSelectDriveB5,cmSelectDriveB3,cmSelectDriveImage])
  Else
    EnableCommands([cmReadDisc,cmWriteDisc,cmListDisk,cmFormatDisc,cmSelectDriveA5,cmSelectDriveA3,cmSelectDriveB5,cmSelectDriveB3,cmSelectDriveImage]);
End;

Var
  MSTApplication:PMSTApplication;
Begin
  New(MSTApplication, Init);
  MSTApplication^.Run;
  Dispose(MSTApplication, Done);
End.
