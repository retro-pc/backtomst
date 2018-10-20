Unit Part3Msx;

Interface

Uses Objects;

Type
  PBasFile = ^TBasFile;
  TBasFile = Object
    Fl: PStream;
    Constructor Init(AStream: PStream; AFileName: String);
    Procedure WriteBASFile(NewFileName:String);
  protected
    Function Byte2Hex(B:Byte):String;virtual;
    Function Word2OCT(W:Word):String;virtual;
    Function ReadLine:String;virtual;
  End;

Implementation

Uses Msbin, SysUtils, FViewer;

Constructor TBasFile.Init(AStream: PStream; AFileName: String);
Begin
  Fl := AStream;
  if  (AFileName = '') and (Fl = nil) then
    Exit;
  {$I-}
  if Fl = nil then
    Fl := New(PHandleDosStream, Init(AFileName, stOpenRead, fmOpenRead or fmShareDenyNone))
//    Fl:=New(PDosStream, Init(AFileName, stOpenRead))
  else if Fl^.Status = stOK then

  {$I+}
End;

Procedure TBasFile.WriteBASFile(NewFileName:String);
Var
   BASStream:PDOSStream;
Var
  Nor:Word;
  S:ShortString;
  LineNumber:Word;
  Size:LongInt;
Begin
  Nor:=0;
  Size:=Fl^.GetSize;
  Fl^.Seek(0);
  BASStream:= New(PHandleDosStream, init(NewFileName, stCreate, fmOpenWrite or fmShareDenyNone));
  FL^.Read(Nor, 1);
  If Nor <> $FF Then
    Fl^.Seek(Fl^.Position - 1);
  Repeat
    Fl^.Read(Nor,2);
    If Nor=$0000 Then Break;
    FL^.Read(LineNumber, 2);
    S:=IntToStr(LineNumber);
    S:=S + ' ' + ReadLine + #13#10;
    BASStream^.Write(S[1], Length(S));
  Until fl^.Position >= Size;
  BASStream^.Done;
End;

Function TBasFile.Byte2Hex(B:Byte):String;
Const HEXStr:Array[$0..$F] Of Char=('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Var
  tmpStr:String[2];
Begin
  tmpStr:=HEXStr[B ShR 4]+HEXStr[B And $0F];
  Byte2Hex:=tmpStr;
End;

Function TBasFile.Word2OCT(W:Word):String;
Const OCTStr:Array[1..8] Of Char=('0','1','2','3','4','5','6','7');
Var
  tmpStr:String;
Begin
  tmpStr:='';
  If W=0 Then tmpStr:=OCTStr[1];
  While W>0 Do
  Begin
    tmpStr:=OCTStr[(W Mod 8)+1]+tmpStr;
    W:=W Div 8;
  End;
  Word2OCT:=tmpStr;
End;

Function TBasFile.ReadLine:String;
Var
  I,J:Byte;
  Inquote:Boolean;
  tmpWord:Word;
  tmpInteger:Integer;
  tmpByte1,tmpByte2:Byte;

  tmpSngl:Single;
  tmpSngl_:Array[1..4] Of Byte Absolute tmpSngl;

  tmpDbl:Double;
  tmpDbl_:Array[1..8] Of Byte Absolute tmpDbl;

  S:String;
  Goon:Boolean;
  Forwarded:Byte;
Begin
  S:='';
  Goon:=True;Forwarded:=0;
  While Goon{J1<=W} Do
  Begin
    If Forwarded<>0 Then
    Begin
      I:=Forwarded;
      Forwarded:=0;
    End Else Fl^.Read(I,SizeOf(I));
    Case I Of
      $00: Begin
        Goon:=False;
        Break;
      End;
      $11..$1B:S:=S+IntToStr(I-$11);
      $3A: Begin
        Fl^.Read(J,SizeOf(J));
        Case J Of
          $A2:
          Begin
            S:=S+'ELSE';
            Continue;
          End;
          $00:
          Begin
            S:=S+':';
            Goon:=False;
            Break;
          End
            Else
            Begin
              S:=S+':';
              Forwarded:=J;
              Continue;
            End;
        End;
      End;
      $8F: Begin                      { Встретился REM - читаем сырые }
        S:=S+'REM';
        Repeat
          Fl^.Read(J,SizeOf(J));
          If J=0 Then Begin Goon:=False;Break;End;
          S:=S+Chr(J);
        Until False;
      End;
      $84: Begin                 { Встретился оператор DATA - читаем сырые }
        S:=S+'DATA';
        Inquote:=False;
        Repeat
          Fl^.Read(J,SizeOf(J));
          If J=0 Then
          Begin
            Goon:=False;
            Break;
          End;
          If ((J=Byte(':')) And (Not Inquote)) Then
          Begin
            Forwarded:=J;
            Continue;
          End;
          S:=S+Chr(J);
          If Chr(J)='"'Then Inquote:=Not Inquote;
        Until False;
      End;
      $0D,$0E: Begin                  { Встретился unsigned integer }
        Fl^.Read(tmpWord,SizeOf(tmpWord));
        S:=S+IntToStr(tmpWord);
      End;
      $0F: Begin
        Fl^.Read(J,SizeOf(J));
        S:=S+IntToStr(J);
      End;
      $0B: Begin                  { Встретился unsigned integer }
        S:=S+'&O';         { в 8-ричной записи           }
        Fl^.Read(tmpWord,SizeOf(tmpWord));
        S:=S+Word2OCT(tmpWord);
      End;
      $1C:Begin                   { Встретился signed Integer   }
        Fl^.Read(tmpInteger,SizeOf(tmpInteger));
        S:=S+IntToStr(tmpInteger);
      End;
      $0C:Begin                   { Встретился unsigned Integer }
        S:=S+'&H';       { в 16-ричной записи          }
        Fl^.Read(tmpByte1,SizeOf(tmpByte1));
        Fl^.Read(tmpByte2,SizeOf(tmpByte2));
        If tmpByte2<>0 Then S:=S+Byte2Hex(tmpByte2);
        S:=S+Byte2Hex(tmpByte1);
      End;

      $1D:Begin                    { Встретилось число с плав.точкой   }
        Fl^.Read(tmpSngl,SizeOf(tmpSngl));
        tmpSngl:=_Fmsbintoieee(tmpSngl);
        If Frac(tmpSngl)=0.0 Then
          S:=S+FloatToStrF(tmpSngl,ffGeneral,0,0)+'!'
        Else
          S:=S+FloatToStrF(tmpSngl,ffGeneral,0,7);
      End;
      $1F:Begin
        Fl^.Read(tmpDbl,SizeOf(tmpDbl));
        tmpDbl:=_Dmsbintoieee(tmpDbl);
        S:=S+FloatToStrF(tmpDbl,ffGeneral,0,16);
      End;

      Byte('"'):Begin                   { Встретилась открывающаяся кавычка }
        S:=S+'"';
        Repeat
          Fl^.Read(J,SizeOf(J));
          If J=0 Then Begin Goon:=False;Break;End;
          S:=S+Chr(J);
        Until (J=Byte('"'));    { Пока кавычка не закроется читать сырые }
      End;

      $81: S:=S+('END');
      $82: S:=S+('FOR');
      $83: S:=S+('NEXT');
      $85: S:=S+('INPUT');
      $86: S:=S+('DIM');
      $87: S:=S+('READ');
      $88: S:=S+('LET');
      $89: S:=S+('GOTO');
      $8A: S:=S+('RUN');              { Добавлено 22.11.08 }
      $8B: S:=S+('IF');
      $8C: S:=S+('RESTORE');
      $8D: S:=S+('GOSUB');
      $8E: S:=S+('RETURN');

      $90: S:=S+('STOP');
      $91: S:=S+('PRINT');
      $92: S:=S+('CLEAR');
      $93: S:=S+('LIST');             { Добавлено 25.02.09 }
      $94: S:=S+('NEW');              { Добавлено 18.03.09 }
      $95: S:=S+('ON');               { Добавлено 22.11.08 }
      $96: S:=S+('$');
 //     $97: S:=S+('COM');
      $98: S:=S+('DEF');
      $99: S:=S+('POKE');             { Добавлено 22.11.08 }
      $9A: S:=S+('CONT');             { Добавлено 19.03.09 }
      $9D: S:=S+('MOTOR');            { Добавлено 25.02.09 }
      $9E: S:=S+('LPRINT');           { Добавлено 14.03.08 }
      $9F: S:=S+('LLIST');            { Добавлено 19.03.09 }

      $A1: S:=S+('WIDTH');            { Добавлено 22.11.08 }
      $A2: S:=S+('ELSE');             { Добавлено 14.03.09 }
      $A3: S:=S+('TRON');             { Добавлено 25.02.09 }
      $A4: S:=S+('TROFF');            { Добавлено 25.02.09 }
      $A5: S:=S+('SWAP');             { Добавлено 25.02.09 }
      $A6: S:=S+('ERASE');            { Добавлено 14.03.09 }
      $A7: S:=S+('EDIT');             { Добавлено 19.03.09 }
      $A8: S:=S+('ERROR');            { Добавлено 25.02.09 }
      $A9: S:=S+('RESUME');           { Добавлено 18.03.09 }
      $Aa: S:=S+('DELETE');           { Добавлено 19.03.09 }
      $Ab: S:=S+('AUTO');             { Добавлено 19.03.09 }
      $Ac: S:=S+('RENUM');            { Добавлено 25.02.09 }
      $Ad: S:=S+('DEFSTR');
      $Ae: S:=S+('DEFINT');
      $Af: S:=S+('DEFSNG');           { Добавлено 25.02.09 }

      $B0: S:=S+('DEFDBL');
      $B1: S:=S+('LINE');
 //     $B2: S:=S+('SPEED');
      $Bb: S:=S+('RANDOMIZE');        { Добавлено 18.03.09 }
      $Bc: S:=S+('BEEP');             { Добавлено 22.11.08 }
      $Bd: S:=S+('SYSTEM');           { Добавлено 19.03.09 }
      $Bf: S:=S+('OPEN');             { Добавлено 18.03.09 }

      $C3: S:=S+('CLOSE');            { Добавлено 18.03.09 }
      $C4: S:=S+('LOAD');             { Добавлено 19.03.09 }
      $C5: S:=S+('MERGE');            { Добавлено 19.03.09 }
      $C6: S:=S+('FILES');            { Добавлено 18.03.09 }
      $C7: S:=S+('NAME');             { Добавлено 19.03.09 }
      $C8: S:=S+('KILL');             { Добавлено 19.03.09 }
      $Cb: S:=S+('SAVE');             { Добавлено 19.03.09 }
      $Cd: S:=S+('LFILES');           { Добавлено 19.03.09 }
      $Ce: S:=S+('CLS');
      $Cf: S:=S+('PCLS');             { Добавлено 14.03.09 }

      $D0: S:=S+('COLOR');            { Добавлено 22.11.08 }
      $D1: S:=S+('CIRCLE');
      $D2: S:=S+('DRAW');             { Добавлено 14.03.09 }
      $D3: S:=S+('PAINT');
      $D4: S:=S+('PSET');
      $D5: S:=S+('PRESET');
      $D6: S:=S+('LOCATE');
      $D7: S:=S+('SCREEN');        { Исправлено 22.11.08 }
      $D9: S:=S+('LUT');           { Добавлено 14.03.09 }
      $Da: S:=S+('RELOC');         { Добавлено 14.03.09 }
      $Dc: S:=S+('TO');
      $Dd: S:=S+('THEN');
      $De: S:=S+('TAB(');
      $Df: S:=S+('STEP');

      $E0: S:=S+('USR');              { Добавлено 19.12.08 }
      $E1: S:=S+('FN');
      $E2: S:=S+('SPC(');
      $E3: S:=S+('NOT');              { Добавлено 25.02.09 }
      $E4: S:=S+('ERL');              { Добавлено 25.02.09 }
      $E5: S:=S+('ERR');              { Добавлено 25.02.09 }
      $E6: S:=S+('STRING$');          { Добавлено 25.02.09 }
      $E7: S:=S+('USING');            { Добавлено 25.02.09 }
      $E8: S:=S+('INSTR');            { Добавлено 25.02.09 }
      $Ea: S:=S+('VARPTR');           { Добавлено 25.02.09 }
      $Eb: S:=S+('CSRLIN');           { Добавлено 25.02.09 }
      $Ec: S:=S+('OFF');              { Добавлено 22.11.08 }
      $Ed: S:=S+('INKEY$');           { Добавлено 22.11.08 }
      $Ee: S:=S+('POINT');
      $Ef: S:=S+('>');

      $F0: S:=S+('=');
      $F1: S:=S+('<');
      $F2: S:=S+('+');
      $F3: S:=S+('-');
      $F4: S:=S+('*');
      $F5: S:=S+('/');
      $F6: S:=S+('^');
      $F7: S:=S+('AND');
      $F8: S:=S+('OR');
      $F9: S:=S+('XOR');
      $Fa: S:=S+('EQV');
      $Fb: S:=S+('IMP');
      $Fc: S:=S+('MOD');
      $Fd: S:=S+('\');                { Добавлено 14.03.09 }

      $Ff: Begin                      { Двухбайтовые Токены }
        Fl^.Read(I,SizeOf(I));
        Case I Of
          $81:S:=S+('LEFT$');         { Добавлено 19.12.08 }
          $82:S:=S+('RIGHT$');        { Добавлено 19.12.08 }
          $83:S:=S+('MID$');          { Добавлено 25.02.09 }
          $84:S:=S+('SGN');           { Добавлено 22.11.08 }
          $85:S:=S+('INT');           { Добавлено 22.11.08 }
          $86:S:=S+('ABS');
          $87:S:=S+('SQR');
          $88:S:=S+('RND');           { Добавлено 22.11.08 }
          $89:S:=S+('SIN');
          $8A:S:=S+('LOG');
          $8B:S:=S+('EXP');           { Добавлено 25.02.09 }
          $8C:S:=S+('COS');
          $8D:S:=S+('TAN');
          $8E:S:=S+('ATN');
          $8F:S:=S+('FRE');           { Добавлено 25.02.09 }
          $90:S:=S+('BIN$');          { Добавлено 25.02.09 }
          $91:S:=S+('POS');           { Добавлено 25.02.09 }
          $92:S:=S+('LEN');           { Добавлено 25.02.09 }
          $93:S:=S+('STR$');          { Добавлено 19.12.08 }
          $94:S:=S+('VAL');           { Добавлено 19.12.08 }
          $95:S:=S+('ASC');           { Добавлено 25.02.09 }
          $96:S:=S+('CHR$');
          $97:S:=S+('PEEK');          { Добавлено 22.11.08 }
          $98:S:=S+('SPACE$');        { Добавлено 25.02.09 }
          $99:S:=S+('OCT$');          { Добавлено 25.02.09 }
          $9A:S:=S+('HEX$');          { Добавлено 23.11.08 }
          $9B:S:=S+('LPOS');          { Добавлено 19.03.09 }
          $9C:S:=S+('CINT');          { Добавлено 18.03.09 }
          $9D:S:=S+('CSNG');          { Добавлено 25.02.09 }
          $9E:S:=S+('CDBL');          { Добавлено 25.02.09 }
          $9F:S:=S+('FIX');           { Добавлено 25.02.09 }
          $Af:S:=S+('EOF');           { Добавлено 18.03.09 }
          Else
            S:=S+'ДВУХБАЙТОВЫЙ ТОКЕН '+Chr(I);
        End;
      End;
      Else
        S:=S+(Chr(I));
    End;
  End;
  ReadLine:=S;
End;

Begin
End.
