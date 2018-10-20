{*********************************************************}
{                                                         }
{ Microsoft Binary Format to IEEE binary format           }
{ conversion Unit                                         }
{ Version 1.0   10/11/2007                                }
{                                                         }
{ Copyright (C) MarinovSoft 2007                          }
{                                                         }
{*********************************************************}
{$R-,Q-}

Unit MSBin;
Interface
Function _Fmsbintoieee(Src4:Single):Single;
Function _Dmsbintoieee(Src8:Double):Double;
Implementation
Function _Fmsbintoieee(Src4:Single):Single;
Const
  Sign:Byte = $00;
  Ieee_Exp:Byte = $00;
Var
  Msbin:Array[0..3] Of Byte Absolute Src4;
  Ieee_:Single;
  Ieee :Array[0..3] Of Byte Absolute Ieee_;
  I:Byte;
Begin
  { MS Binary Format                         }
  { byte order =>    m3 | m2 | m1 | exponent }
  { m1 is most significant byte => sbbb|bbbb }
  { m3 is the least significant byte         }
  {      m = mantissa byte                   }
  {      s = sign bit                        }
  {      b = bit                             }

  Sign := Msbin[2] And $80;      { 1000|0000b  }

  { IEEE Single Precision Float Format       }
  {    m3        m2        m1     exponent   }
  { mmmm|mmmm mmmm|mmmm emmm|mmmm seee|eeee  }
  {          s = sign bit                    }
  {          e = exponent bit                }
  {          m = mantissa bit                }

  For I:=0 To 3 Do Ieee[I] := 0;

  { any msbin w/ exponent of zero = zero }
  If Msbin[3] = 0 Then
  Begin
    _Fmsbintoieee:=0.0;
    Exit;
  End;
  Ieee[3]:=Ieee[3] Or Sign;

  { MBF is bias 128 and IEEE is bias 127. ALSO, MBF places   }
  { the decimal point before the assumed bit, while          }
  { IEEE places the decimal point after the assumed bit.     }

  Ieee_Exp := Msbin[3] - 2;    { actually, msbin[3]-1-128+127 }

  { the first 7 bits of the exponent in ieee[3] }
  Ieee[3]:= Ieee[3] Or Ieee_Exp ShR 1;

  { the one remaining bit in first bin of ieee[2] }
  Ieee[2]:= Ieee[2] Or Ieee_Exp ShL 7;

  { 0111|1111b : mask out the msbin sign bit }
  Ieee[2]:= Ieee[2] Or Msbin[2] And $7F;

  Ieee[1]:= Msbin[1];
  Ieee[0]:= Msbin[0];
  _Fmsbintoieee:=Ieee_;
End;

Function _Dmsbintoieee(Src8:Double):Double;
Const
  Sign:Byte = $00;
  Ieee_Exp:Word = $0000;
Var
  Msbin:Array[0..7] Of Byte Absolute Src8;
  Ieee_:Double;
  Ieee:Array[0..7] Of Byte Absolute Ieee_;
  I:Byte;
Begin

  { MS Binary Format                                             }
  { byte order =>    m7 | m6 | m5 | m4 | m3 | m2 | m1 | exponent }
  { m1 is most significant byte => smmm|mmmm                     }
  { m7 is the least significant byte                             }
  {      m = mantissa byte                                       }
  {      s = sign bit                                            }
  {      b = bit                                                 }

  Sign := Msbin[6] And $80;      { 1000|0000b  }

  { IEEE Single Precision Float Format                           }
  {  byte 8    byte 7    byte 6    byte 5    byte 4    and so on }
  { seee|eeee eeee|mmmm mmmm|mmmm mmmm|mmmm mmmm|mmmm ...        }
  {          s = sign bit                                        }
  {          e = exponent bit                                    }
  {          m = mantissa bit                                    }

  For I:=0 To 7 Do Ieee[I] := 0;

  { any msbin w/ exponent of zero = zero }
  If Msbin[7] = 0 Then
  Begin
    _Dmsbintoieee:=0.0;
    Exit;
  End;

   Ieee[7]:= Ieee[7] Or Sign;

   { MBF is bias 128 and IEEE is bias 1023. ALSO, MBF places  }
   { the decimal point before the assumed bit, while          }
   { IEEE places the decimal point after the assumed bit.     }

   Ieee_Exp := Msbin[7] - 128 - 1 + 1023;

   { First 4 bits of the msbin exponent   }
   { go into the last 4 bits of ieee[7]   }
   Ieee[7]:= Ieee[7] Or Ieee_Exp ShR 4;

   { The last 4 bits of msbin exponent    }
   { go into the first 4 bits of ieee[6]  }
   Ieee[6]:= Ieee[6] Or Ieee_Exp ShL 4;

   { The msbin mantissa must be shifted to the right 1 bit.   }
   { Remember that the msbin number has its bytes reversed.   }
   For I:=6 Downto 1 Do
   Begin
     Msbin[I]:=Msbin[I] ShL 1;
     Msbin[I]:=Msbin[I] Or Msbin[I-1] ShR 7;
   End;
   Msbin[0]:= Msbin[0] ShL 1;

   { Now the mantissa is put into the ieee array starting in  }
   { the middle of the second to last byte.                   }

   For I:=6 Downto 1 Do
   Begin
     Ieee[I]:=Ieee[I] Or Msbin[I] ShR 4;
     Ieee[I-1]:=Ieee[I-1] Or Msbin[I] ShL 4;
   End;
   Ieee[0]:= Ieee[0] Or Msbin[0] ShR 4;
   _Dmsbintoieee:=Ieee_;

End;
end.
