MODULE Test;  (*AP 13.12.24*)
  IMPORT Texts, Oberon;

  TYPE R = RECORD a: INTEGER END ;
    R0 = RECORD (R) b: INTEGER END ;
    R1 = RECORD (R) b: REAL END ;
    R2 = RECORD (R) b: SET END ;
    R3 = RECORD (R2) c: SET END ;
    P = POINTER TO R;
    P0 = POINTER TO R0;
    P1 = POINTER TO R1;
    P2 = POINTER TO R2;
    P3 = POINTER TO R3;

  VAR W: Texts.Writer;
    p, q: P; p0: P0; p1: P1; p2: P2; p3: P3;

  PROCEDURE CaseNum*;
    VAR S: Texts.Scanner; i, j: INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Int THEN i := S.i; j := 9;
      CASE i OF
         2..5  : j := 11                    (*lower case label limit = 2*)
        |8 .. 10 : j := 22
        |13 .. 15: j := 33
        |28 .. 30, 18 .. 22: j := 44
        |33 .. 36, 24: j := 55              (*higher case label limit = 36*)
      (*ELSE j := 66*)
      END  ;
      Texts.WriteInt(W, j, 4)
    ELSE Texts.WriteString(W, " usage: Test.CaseNum number")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END CaseNum;

  PROCEDURE CaseChar*;
    VAR S: Texts.Scanner; ch: CHAR; j: INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Name) OR (S.class = Texts.String) THEN ch := S.s[0]; j := 0;
      CASE ch OF
        "D" .. "F" : j := 22                (*lower case label limit = ORD("D") = 68*)
        |"J" .. "M" : j := 33
        |"f" .. "h", "b" .. "c" : j := 44
        |"r" .. "u", "e", "m"   : j := 55   (*higher case label limit = ORD("u") = 117*)
      (*ELSE j := 66*)
      END  ;
      Texts.WriteInt(W, j, 4)
    ELSE Texts.WriteString(W, " usage: Test.CaseChar char")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END CaseChar;

  PROCEDURE CaseType*;
    VAR S: Texts.Scanner; i, j: INTEGER; pp: P;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Int THEN i := S.i; j := 0; p := q;
      IF i = 0 THEN p := p0
      ELSIF i = 1 THEN p := p1
      ELSIF i = 2 THEN p := p2
      ELSIF i = 3 THEN p := p3
      END ;
      pp := p;
      CASE pp OF
         P0: j := 22
       | P1: j := 33
       | P3: j := 55  (*P3 is an extension of P2, not P -> test P3 first*)
       | P2: j := 44
       (*ELSE j := 66*)
      END ;
      Texts.WriteInt(W, j, 4)
    ELSE Texts.WriteString(W, " usage: Test.CaseType extension (-1 = no extension)")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END CaseType;

BEGIN Texts.OpenWriter(W); NEW(p); NEW(q); NEW(p0); NEW(p1); NEW(p2); NEW(p3)
END Test.

ORP.Compile ORG.Mod/s ORP.Mod/s ~  # compile the new compiler
System.Free ORP ORG ORB ORS ~      # unload the old one

ORP.Compile Test.Mod/s ~
System.Free Test ~

ORTool.DecObj Test.rsc ~

THE FOLLOWING ARE THE RESULTS FOR THE DEFAULT VERSION (ORG.Mod and ORP.Mod):
============================================================================
  
----------------- CaseNum (numeric selector) ---------------

Test.CaseNum 0     Test.CaseNum 1       # TRAP --> outside the case label ranges  (result becomes 66 if the ELSE clause is uncommented)
Test.CaseNum 2     Test.CaseNum 5       # 11   --> range 2..5
Test.CaseNum  8    Test.CaseNum 10      # 22   --> range  8..10
Test.CaseNum 13    Test.CaseNum 15      # 33   --> range 13..15
Test.CaseNum 18    Test.CaseNum 22      # 44   --> range 18..22
Test.CaseNum 33    Test.CaseNum 36      # 55   --> range 33..36

Test.CaseNum 11    Test.CaseNum 17      # TRAP --> outside the case label ranges  (result becomes 66 if the ELSE clause is uncommented)
Test.CaseNum 23    Test.CaseNum 32      # TRAP --> outside the case label ranges  (result becomes 66 if the ELSE clause is uncommented)
Test.CaseNum 99    Test.CaseNum 255     # TRAP --> outside the case label ranges  (result becomes 66 if the ELSE clause is uncommented)

Test.CaseNum -99   Test.CaseNum -1      # TRAP --> outside the case label ranges  (result becomes 66 if the ELSE clause is uncommented)
Test.CaseNum 256   Test.CaseNum 1000    # TRAP --> outside the case label ranges  (result becomes 66 if the ELSE clause is uncommented)

----------------- ChaseChar (char selector) ---------------

Test.CaseChar A    Test.CaseChar C      # TRAP --> outside the case label ranges  (result becomes 66 if the ELSE clause is uncommented)
Test.CaseChar D    Test.CaseChar F      # 22   --> range D..F
Test.CaseChar J    Test.CaseChar M      # 33   --> range J..M
Test.CaseChar f    Test.CaseChar h      # 44   --> range f..h
Test.CaseChar b    Test.CaseChar c      # 44   --> range b..c
Test.CaseChar r    Test.CaseChar u      # 55   --> range r..u
Test.CaseChar e    Test.CaseChar m      # 55   --> range e, x

Test.CaseChar H    Test.CaseChar Y      # TRAP --> outside the case label ranges  (result becomes 66 if the ELSE clause is uncommented)
Test.CaseChar "["  Test.CaseChar "^"    # TRAP --> outside the case label ranges  (result becomes 66 if the ELSE clause is uncommented)
Test.CaseChar a    Test.CaseChar p      # TRAP --> outside the case label ranges  (result becomes 66 if the ELSE clause is uncommented)
Test.CaseChar v    Test.CaseChar z      # TRAP --> outside the case label ranges  (result becomes 66 if the ELSE clause is uncommented)

----------------- CaseType (type selector) ---------------

Test.CaseType -1       #  0   --> no extension  (result becomes 66 if the ELSE clause is uncommented)
Test.CaseType  0       # 22   --> P0
Test.CaseType  1       # 33   --> P1
Test.CaseType  2       # 44   --> P2
Test.CaseType  3       # 55   --> P3
Test.CaseType  4       #  0   --> no extension  (result 66 if the ELSE clause is uncommented)
