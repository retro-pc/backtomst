{************************************************}
{                                                }
{ Copyright (C) 1997 Michael Radchenko           }
{ Portions Copyright (C) 2009 MarinovSoft        }
{                                                }
{************************************************}

{$X+,D-,S-,R-,V-}

{$ifdef fpc}
{$A1}
{$else}
{$G+,L-,N+}
{$endif}

unit Service;

interface

function  Separator(Title: String) : String;
function  Min(a,b : LongInt) : LongInt;
function  Max(a,b : LongInt) : LongInt;
function  IntToStr(I: LongInt): String;
function  RealToStr(R: Extended;A1,A2:Byte): String;
function  ChangeFileExt(const FileName, Extension: string): string;
function  GetFileExt(const FileName:String):String;
function  GetMSXFileName(const FileName:String):String;
function  strupr(S:String):String;

implementation

Uses Dos;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function Separator(Title: String) : String;
var
  S, S1 : String[76];
begin
  FillChar(S[1],76,196); S[0] := #76;
  S1 := '';
  If Title <> '' Then S1 := 'İ'+Title+'Ş';
  Move(S1[1], S[(Length(S)-Length(S1)) div 2], Length(S1));
  Separator := S;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function Max(a,b : LongInt) : LongInt;
begin
  If a > b Then Max := a
           Else Max := b;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function Min(a,b : LongInt) : LongInt;
begin
  If a < b Then Min := a
           Else Min := b;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function  ChangeFileExt(const FileName, Extension: string): string;
Var
    D : DirStr;
    N : NameStr;
    E : ExtStr;
Begin
 FSplit(FileName, D, N, E);
 ChangeFileExt:=D+N+'.'+Extension;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function IntToStr(I: LongInt): String;
var S : String[11];
begin
  Str(i, S);
  IntToStr := S;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function RealToStr(R: Extended;A1,A2:Byte): String;
var S : String[11];
begin
  Str(R:A1:A2,S);
  RealToStr := S;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function  GetFileExt(const FileName:String):String;
Var
    D : DirStr;
    N : NameStr;
    E : ExtStr;
Begin
 FSplit(FileName, D, N, E);
 GetFileExt:=E;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function  GetFileName(const FileName:String):String;
Var
    D : DirStr;
    N : NameStr;
    E : ExtStr;
Begin
 FSplit(FileName, D, N, E);
 GetFileName:=N;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function  GetMSXFileName(const FileName:String):String;
Var
   MSXFileName:String;
begin
   MSXFileName:=GetFileName(FileName);
   While Length(MSXFileName)<6 do MSXFileName:=MSXFileName+' ';
   While Length(MSXFileName)>6 do Delete(MSXFileName,Length(MSXFileName),1);
   GetMSXFileName:=MSXFileName;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function strupr(S:String):String;
Var
   i:Byte;
begin
  for i:=1 to Length(S) do
     S[i]:=UpCase(S[i]);
  strupr:=S;
end;
end.