{.$DEFINE DEB}
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

Uses App, Objects, Views, Menus, Drivers, Dialogs, Stddlg,
  Msgbox, GrowView, AppWin, Service, Mstconst, MSTDisk, AppWinEx, MstDlg, DosDlg, FV_Const, SysUtils
{$ifdef fpc}
{$ifndef win32}
, Go32
{$endif}
{$endif}
;

Type
  PMSTApplication = ^TMSTApplication;
  TMSTApplication = Object(TApplication)
{    MSTDisk:PMSTDisk;}
    Frec : TFormRec;
    {$ifdef fpc}
    FileName:ShortString;
    DiskName:ShortString;
    {$else}
    FileName:String;
    DiskName:String;
    {$endif}
    Dbt:Array[0..9] Of Byte;
    LeftWindow:PMSTShortWindow;
    RightWindow:PDOSShortWindow;
    Constructor Init;
    Destructor Done;Virtual;
    Procedure HandleEvent(Var Event:TEvent);Virtual;
    Procedure InitMenuBar; Virtual;
    Procedure InitStatusLine;Virtual;
    Procedure DoAboutBox;
    Procedure FormatDisk;
    Procedure ReadDisk;
    Procedure WriteDisk;
    Procedure SelectDriveImage;
    Procedure ListDisk;
  End;

Procedure TMSTApplication.DoAboutBox;
Begin
  MessageBox(#3'Программа работы с дисками'#13#3'МикроДос версия 1.0'#13 +
    #3'Copyright (C) 2013-2014'#13#3'Маринов Георгий aka MarinovSoft',
    Nil, mfInformation Or mfOKButton);
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
    NewItem('~R~ead', '', kbNoKey, Cmreaddisc, hcNoContext,
    NewItem('~W~rite', '', kbNoKey, Cmwritedisc, hcNoContext,
    NewItem('~F~ormat', '', kbNoKey, Cmformatdisc, hcNoContext,
    NewItem('~L~ist disk', '', kbNoKey, cmListDisk, hcNoContext,
    Nil))))),
    NewSubMenu('~O~ptions', hcNoContext, NewMenu(
    NewSubMenu('~D~rive', hcNoContext, NewMenu(
    NewItem('A:', '', kbNoKey, cmSelectDriveA, hcNoContext,
    NewItem('B:', '', kbNoKey, cmSelectDriveB, hcNoContext,
    NewItem('File image', '', kbNoKey, cmSelectDriveImage, hcNoContext,
    Nil)))),
    NewItem('Floppy setup', '', kbNoKey, cmOptions, hcNoContext,
    Nil))),
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
    StdStatusKeys(nil)),  Nil))));
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
      cmSelectDriveA:
      Begin
        DiskName:='A';
        ClearEvent(Event);
      End;
      cmSelectDriveB:
      Begin
        DiskName:='B';
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
      cmCopyFileDOS:
      begin
         Message(LeftWindow, evCommand, cmCopyFileDOS, Event.InfoPtr);
         // ClearEvent(Event);
      end;
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

  If DiskName[0] > #1 Then
     MSTDisk:= New(PMicroDOSDiskImage, Init(DiskName, Frec))
  else
     MSTDisk:= New(PMicroDOSDisk, Init(DiskName[1], Frec));

  { Тут вам не Си! Злобный Паскаль ругается      }
  {
  For Frec.Track:=0 To (Frec.Tcount ShL 1)-1 Do
}
  R.Assign( 2, 4, 38, 5 );
  GV1 := New( PGrowView, Init( R, (Frec.Tcount ShL 1)-1 ));

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
  MSTDisk^.WriteDir(Catalog);

  Dpb.Systrk:=Systrk;
  Dpb.Dsize:=BlockCount-1;
  Dpb.TCount:=Frec.Tcount;
  Dpb.Crc:=$66;
  For I:=0 To 30 Do
    {$ifndef fpc}
    Inc(Mem[Seg(Dpb):Ofs(Dpb)+31],Mem[Seg(Dpb):Ofs(Dpb)+I]);
    {$else}
    Inc(Dpb.Crc, PByteArray(@Dpb)^[I]);
    {$endif}
  FillChar(Buf,1024,$E5);
  Move(Dpb,Buf,32);
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
const
  FDOptions: Word = fdOKButton {or fdOpenButton};
Begin
  FileName:= '*.kdi';
  New(FileDialog, Init(FileName, 'Save file', '~F~ile name', FDOptions, 1));
  if ExecuteDialog(FileDialog, @FileName) = cmCancel then
    Exit;
  FileExt:=ExtractFileExt(FileName);
  If (Length(FileExt) = 0) or (FileExt = '.') Then
    FileName:=ChangeFileExt(FileName, '.kdi');
  Assign(F,FileName);
  ReWrite(F);
  If DiskName[0] > #1 Then
     MSTDisk:= New(PMicroDOSDiskImage, Init(DiskName, Frec))
  else
     MSTDisk:= New(PMicroDOSDisk, Init(DiskName[1], Frec));
  For Track:=0 To (Frec.Tcount ShL 1)-1 Do
  Begin
    Frec.Track:=Track;
    MSTDisk^.SeekTrack(Frec);
    Sect:=1;
    While Sect <= Frec.Scount Do
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
          Close(F);
          Exit;
        End;
      End;
    End;
  End;
  Dispose(MSTDisk, Done);
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
  FileExt:ShortString;
const
  FDOptions: Word = fdOKButton {or fdOpenButton};
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
  Assign(F,FileName);
  Reset(F);
  If DiskName[0] > #1 Then
     MSTDisk:= New(PMicroDOSDiskImage, Init(DiskName, Frec))
  else
     MSTDisk:= New(PMicroDOSDisk, Init(DiskName[1], Frec));
  For Track:=0 To (Frec.Tcount ShL 1)-1 Do
  Begin
    Frec.Track:=Track;
    Sect:=1;
    While Sect <= Frec.Scount Do
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
          Close(F);
          Exit;
        End;
      End;
    End;
  End;
  Dispose(MSTDisk, Done);
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
Begin
  Inherited Init;
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
End;

Procedure TMSTApplication.SelectDriveImage;
Var
  R: TRect;
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
   Catalog:TCatalog;
{$IFDEF DEB}
   _F:File;
{$ENDIF}
   MSTDisk:PMSTDisk;
begin
  If DiskName[0] > #1 Then
     MSTDisk:= New(PMicroDOSDiskImage, Init(DiskName, Frec))
  else
     MSTDisk:= New(PMicroDOSDisk, Init(DiskName[1], Frec));

  { MSTDisk^.ReadDir(Catalog); }
  {$IFDEF DEB}
  Assign(_F,'1.DEB');
  Rewrite(_F,1);
  BlockWrite(_F,Catalog,SizeOf(Catalog));
  Close(_F);
  {$ENDIF}

  LeftWindow:=New(PMSTShortWindow, Init(MSTDisk));

  Desktop^.Insert(LeftWindow);
{  Dispose(MSTDisk, Done);}
end;

Destructor TMSTApplication.Done;
Var
  B:Byte;
{$ifdef fpc}
{$ifndef win32}
  Ofs,Seg:Word;
{$endif}
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

Var
  MSTApplication:PMSTApplication;
Begin
  New(MSTApplication, Init);
  MSTApplication^.Run;
  Dispose(MSTApplication, Done);
End.