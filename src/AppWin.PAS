{************************************************}
{                                                }
{ Copyright (C) 1997 Michael Radchenko           }
{ Portions Copyright (C) 2009-2018 MarinovSoft   }
{                                                }
{************************************************}
{*$X+,G+,D-,L-,S-,R-}

{$ifdef fpc}
{$A1, H-}
{$endif}

unit AppWin;

interface

Uses Objects, GrowView, Dialogs, Views, Drivers, App;

const

  {InfoWindow's palette}
  CInfoWinPalette = #8#9#10#11#12#13#14#15+#8#9#10#13+#32#30#26#31;

  {constants for TStringBuf}
  MaxLinesCount   = 200;
  MaxLineLength   = 100;

  cmSetConfig  = 1000;
  cmSaveConfig = 1001;

Type

  PProgressDialog = ^TProgressDialog;
  TProgressDialog = Object(TDialog)
    CurrentText : PStaticText;
    TotalText   : PStaticText;
    constructor Init(var GV1{, GV2} : PGrowView; ATitle : String);
    destructor  Done; virtual;
    procedure   SetCurrentText(AText : String);
    procedure   SetTotalText(AText : String);
  end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

  PStringBuf = ^TStringBuf;
  TStringBuf = Array [1..MaxLinesCount] of String[MaxLineLength];

  PColorText = ^TColorText;
  TColorText = Object(TScroller)
    LinesCount  : Integer;
    StrBuf      : TStringBuf;
    Color       : Integer;
    FirstLine   : Integer;

    constructor Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar);

    function    GetPalette: PPalette; virtual;
    procedure   CalcBounds(var Bounds: TRect; D: TPoint); virtual;
    procedure   Draw; virtual;

    procedure   FillBuf(S : String; var Buf : TDrawBuffer);
    procedure   WriteLineAt(LineNumber : Integer; S: String); virtual;
    procedure   WriteLine(S: String); virtual;
    procedure   LogWriteLineAt(LineNumber : Integer; S: String; var  LogFile : Text);
    procedure   LogWriteLine(S: String; var LogFile : Text); virtual;

    function    ReadPureLine(LineNumber : Integer) : String; virtual;
  end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
  PInfoWindow = ^TInfoWindow;
  TInfoWindow = Object(TWindow)

    ScreenText  : PColorText;

    constructor Init(SFileName:String);
    destructor  Done; virtual;

    procedure   Draw; virtual;

    function    GetLinesCount : Integer;
    procedure   WriteLineAt(LineNumber : Integer; S: String); virtual;
    procedure   WriteLine(S: String); virtual;
    procedure   LogWriteLineAt(LineNumber : Integer; S: String; var LogFile : Text);
    procedure   LogWriteLine(S: String; var LogFile : Text);

    procedure   SaveResults(var F: Text); virtual;
  end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
implementation

Uses Service;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
constructor TProgressDialog.Init(var GV1{, GV2} : PGrowView; ATitle : String);
var
  R       : TRect;
  B       : PButton;
  T       : PStaticText;
begin
{  R.Assign( 0, 0, 40, 11 );}
  R.Assign( 0, 0, 40, 9 );
  inherited Init( R, ATitle );
  Options := Options or ofCentered;

  R.Assign(2,2,38,3);
  New(T, Init(R, '     Current operation progress       '));
  Insert(T);
  CurrentText := T;
{  R.Assign( 2, 3, 38, 4 );}
  R.Assign( 2, 4, 38, 5 );
  GV1 := New( PGrowView, Init( R, 100 ));
  Insert( GV1 );

{  R.Assign(2,5,38,6);
  New(T, Init(R, '           Total progress             '));
  Insert(T);
  TotalText := T;
  R.Assign( 2, 6, 38, 7 );
  GV2 := New( PGrowView, Init( R, 100 ));
  Insert( GV2 );}

{  R.Assign(0,8,12,10);}
  R.Assign(0,6,12,8);
  New(B, Init(R, '~C~ancel', cmCancel, 1));
  B^.Options := B^.Options or ofCenterX;
  Insert(B);

  {Bar1 := @GV1; Bar2 := @GV2;}
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure TProgressDialog.SetCurrentText(AText : String);
begin
  If (CurrentText^.Text) <> nil Then
    DisposeStr(CurrentText^.Text);
  CurrentText^.Text := NewStr(#3+AText);
  CurrentText^.Draw;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure TProgressDialog.SetTotalText(AText : String);
begin
  If (TotalText^.Text) <> nil Then
    DisposeStr(TotalText^.Text);
  TotalText^.Text := NewStr(#3+AText);
  TotalText^.Draw;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
destructor TProgressDialog.Done;
begin
  inherited Done;
{  Bar1^ := Nil; Bar2^ := Nil;}
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
                         TInfoWindow's Methods
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
constructor TInfoWindow.Init(SFileName:String);
var
  Bounds : TRect;
  ScrollBar : PScrollBar;
begin
  {If ScreenMode and smFont8x8 = 0             }
  {Then begin Size.X := 80; Size.Y := 23; end  }
  {Else begin Size.X := 80; Size.Y := 49;; end;}
  Desktop^.GetExtent(Bounds);

  inherited Init(Bounds, 'Reading file '+SFileName, wnNoNumber);
  Flags := Flags and (not wfZoom) and (not wfGrow) and (not wfMove);
  ScrollBar := StandardScrollBar(sbVertical or sbHandleKeyboard);
  ScrollBar^.Options := ScrollBar^.Options or ofPostProcess;
  Insert(ScrollBar);

  Inc(Bounds.A.X,2); Inc(Bounds.A.Y); Dec(Bounds.B.X); Dec(Bounds.B.Y);
  New(ScreenText, Init(Bounds, Nil, ScrollBar));
  Insert(ScreenText);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
destructor  TInfoWindow.Done;
begin
  inherited Done;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TInfoWindow.Draw;
begin
  inherited Draw;
  ScreenText^.Draw;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function   TInfoWindow.GetLinesCount : Integer;
begin
  GetLinesCount := ScreenText^.LinesCount;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TInfoWindow.WriteLineAt(LineNumber : Integer; S: String);
begin
  ScreenText^.WriteLineAt(LineNumber, S);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TInfoWindow.WriteLine(S: String);
begin
  ScreenText^.WriteLine(S);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TInfoWindow.LogWriteLineAt(LineNumber : Integer; S: String; var LogFile : Text);
begin
  ScreenText^.LogWriteLineAt(LineNumber, S, LogFile);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TInfoWindow.LogWriteLine(S: String; var LogFile : Text);
begin
  ScreenText^.LogWriteLine(S, LogFile);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TInfoWindow.SaveResults(var F: Text);
var
  I : Integer;
{  S : String; }
begin
  System.WriteLn(F, Separator('MXSCAS log file'));
  for I := 1 to ScreenText^.LinesCount do
    System.WriteLn(F, ScreenText^.ReadPureLine(I));
end;
{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
                         TColorText's Methods
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
constructor TColorText.Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar);
begin
  inherited Init(Bounds, AHScrollBar, AVScrollBar);
  Color := 23;
  LinesCount := 0; FirstLine := 1;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�}
procedure TColorText.FillBuf(S : String; var Buf : TDrawBuffer);
var
  Len   : Byte absolute S;
  i, j,
  B,
  OldColor : Byte;
  S1    : String;
{$IFNDEF VIRTUALPASCAL}
  C     : Integer;
{$ELSE}
  C     : LongInt;
{$ENDIF}
  XPos  : Byte;
begin
  MoveChar(Buf, ' ', Color, Size.X);       { fill buffer with spaces }
  XPos := 0;
  OldColor := Color;
  i := 0;
  While i < Len do
  begin
    Inc(i);
    j := i; S1[0] := #0;
    While (S[j] <> '|')and(j <= Len) do Inc(j);
    Move(S[i],S1[1],j-i); S1[0] := Char(j-i);
    MoveStr(Buf[XPos], S1, Color);
    Inc(XPos, j-i);
    i := j+1; j := i;
    While (S[j] <> '|')and(j <= Len) do Inc(j);
    Move(S[i],S1[1],j-i); S1[0] := Char(j-i);
    i := j;
    If J < Len Then
    begin
      If S1[0] = #0
        Then begin MoveStr(Buf[XPos], '|', Color); Inc(XPos); end
        Else begin
          Val(S1, B, C);
          If C = 0 Then Color := B;
        end;
    end;
  end;
  Color := OldColor;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TColorText.Draw;
var
  StartLine,
  Value,
  I            : Integer;
  Buf          : TDrawBuffer;

begin
  Value := VScrollBar^.Value;
  StartLine := Max(1, Value-Size.Y+1);
  FirstLine := StartLine;

  for i := 0 to Size.Y-1 do
  begin
    FillBuf(StrBuf[FirstLine+i], Buf);
    WriteBuf(0, i, Size.X, 1, Buf);
  end;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TColorText.WriteLineAt(LineNumber : Integer; S: String);
var
  i, Value, StartLine : Integer;
  Buf                 : TDrawBuffer;
begin
  If LineNumber = -1 Then LineNumber := LinesCount;
  StrBuf[LineNumber] := S;
  If LineNumber > LinesCount Then
  begin
    for i := LinesCount+1 to LineNumber-1 do StrBuf[i] := '';
    LinesCount := LineNumber;
  end;
  VScrollBar^.SetParams(LineNumber, 1, LinesCount, Size.Y, 1);
  Draw;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TColorText.WriteLine(S: String);
var
  i : Integer;
begin
  If LinesCount >= MaxLinesCount Then
  begin
    for i := 2 to MaxLinesCount do StrBuf[i-1] := StrBuf[i];
    StrBuf[MaxLinesCount] := S;
    Draw;
    Exit;
  end;
  Inc(LinesCount);
  WriteLineAt(LinesCount, S);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TColorText.LogWriteLineAt(LineNumber : Integer; S: String; var  LogFile : Text);
begin
  WriteLineAt(LineNumber, S);
  If LineNumber = -1 Then LineNumber := LinesCount;
  {$I-}
  System.WriteLn(LogFile, ReadPureLine(LineNumber));
  {$I+}
  If IOResult <> 0 Then;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TColorText.LogWriteLine(S: String; var  LogFile : Text);
begin
  WriteLine(S);
  {$I-}
  System.WriteLn(LogFile, ReadPureLine(LinesCount));
  {$I+}
  If IOResult <> 0 Then;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TColorText.GetPalette: PPalette;
const
  P: String[Length(CInfoWinPalette)] = CInfoWinPalette;
begin
  GetPalette := @P;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure TColorText.CalcBounds(var Bounds: TRect; D: TPoint);
begin
  Size.X := Size.X+D.X;
  Size.Y := Size.Y+D.Y;
  inherited CalcBounds(Bounds, D);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function   TColorText.ReadPureLine(LineNumber : Integer) : String;
var
  S, S1 : String;
  Len  : Byte absolute S;
  i, j : Byte;
begin
  S := StrBuf[LineNumber]; S1 := '';
  i := 0;
  While i < Len do
  begin
    Inc(i);
    j := i;
    While (S[j] <> '|')and(j <= Len) do Inc(j);
    S1 := S1+Copy(S, i, j-i);
    i := j+1; j := i;
    While (S[j] <> '|')and(j <= Len) do Inc(j);
    If (J < Len) and (j = i) Then S1 := S1+'|';
    i := j;
  end;
  ReadPureLine := S1;
end;

end.
