MODULE Test;
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

ORP.Compile Test.Mod/s ~
System.Free Test ~

ORTool.DecObj Test.rsc ~

----------------- num ---------------

Test.CaseNum 0     Test.CaseNum 1       # outside the case label ranges  --> TRAP  (or 66 if the ELSE clause is uncommented)
Test.CaseNum 2     Test.CaseNum 5       # range 2..5    -->  11
Test.CaseNum  8    Test.CaseNum 10      # range  8..10  -->  22
Test.CaseNum 13    Test.CaseNum 15      # range 13..15  -->  33
Test.CaseNum 18    Test.CaseNum 22      # range 18..22  -->  44
Test.CaseNum 33    Test.CaseNum 36      # range 33..36  -->  55

Test.CaseNum 11    Test.CaseNum 17      # outside the case label ranges  --> TRAP  (or 66 if the ELSE clause is uncommented)
Test.CaseNum 23    Test.CaseNum 32      # outside the case label ranges  --> TRAP  (or 66 if the ELSE clause is uncommented)
Test.CaseNum 99    Test.CaseNum 255     # outside the case label ranges  --> TRAP  (or 66 if the ELSE clause is uncommented)

Test.CaseNum -99   Test.CaseNum -1      # outside the case label ranges  --> TRAP  (or 66 if the ELSE clause is uncommented)
Test.CaseNum 256   Test.CaseNum 1000    # outside the case label ranges  --> TRAP  (or 66 if the ELSE clause is uncommented)

----------------- char ---------------

Test.CaseChar A    Test.CaseChar C      # outside the case label ranges  --> TRAP  (or 66 if the ELSE clause is uncommented)
Test.CaseChar D    Test.CaseChar F      # range D..F  -->  22
Test.CaseChar J    Test.CaseChar M      # range J..M  -->  33
Test.CaseChar f    Test.CaseChar h      # range f..h  -->  44
Test.CaseChar b    Test.CaseChar c      # range b..c  -->  44
Test.CaseChar r    Test.CaseChar u      # range r..u  -->  55
Test.CaseChar e    Test.CaseChar m      # range e, x  -->  55

Test.CaseChar H    Test.CaseChar Y      # outside the case label ranges  --> TRAP  (or 66 if the ELSE clause is uncommented)
Test.CaseChar "["  Test.CaseChar "^"    # outside the case label ranges  --> TRAP  (or 66 if the ELSE clause is uncommented)
Test.CaseChar a    Test.CaseChar p      # outside the case label ranges  --> TRAP  (or 66 if the ELSE clause is uncommented)
Test.CaseChar v    Test.CaseChar z      # outside the case label ranges  --> TRAP  (or 66 if the ELSE clause is uncommented)

----------------- type ---------------

Test.CaseType -1       # no extension  -->   0  (or 66 if the ELSE clause is uncommented)
Test.CaseType  0       # P0            -->  22
Test.CaseType  1       # P1            -->  33
Test.CaseType  2       # P2            -->  44
Test.CaseType  3       # P3            -->  55
Test.CaseType  4       # no extension  -->   0  (or 66 if the ELSE clause is uncommented)
