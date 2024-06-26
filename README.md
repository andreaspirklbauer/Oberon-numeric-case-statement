# Oberon-numeric-case-statement
Numeric CASE statement for the Oberon-07 programming language on Project Oberon 2013 and Extended Oberon.

Note: In this repository, the term "Project Oberon 2013" refers to a re-implementation of the original "Project Oberon" on an FPGA development board around 2013, as published at www.projectoberon.com.

**PREREQUISITES**: A current version of Project Oberon 2013 (see http://www.projectoberon.com). If you use Extended Oberon (see http://github.com/andreaspirklbauer/Oberon-extended), the functionality is already implemented.

------------------------------------------------------
The official Oberon-07 language report (www.inf.ethz.ch/personal/wirth/Oberon/Oberon07.Report.pdf, as of 3.5.2016) allows *numeric* CASE statements, which are however not implemented in the official release at www.projectoberon.com.

The modified Oberon-07 compiler provided in **this** repository brings the compiler in line with the language report, i.e. it also allows *numeric* CASE statements (CASE int|char OF), in addition to *type* CASE statements (CASE pointer|record OF).

Implemented syntax:

     CaseStatement = CASE expression OF case {"|" case} [ELSE StatementSequence] END.
     case          = [CaseLabelList ":" StatementSequence].
     CaseLabelList = LabelRange {"," LabelRange}. 
     LabelRange    = label [".." label].
     label         = integer | string | qualident.

The essential property of the numeric CASE statement is that - in contrast to a cascaded conditional statement - it represents a single, indexed branch, which selects a statement sequence from a set of cases according to an index value. Case statements are recommended only if the set of selectable statements is reasonably large.

Our implementation constructs a "jump table" of branch statements (containing the branch distances as operands) to the various component statements, leading to a *constant* number of instructions for any selection in a CASE statement.

Jump tables are located in the code section of a module. The selection ("switch") in a case statement is generated by procedure *CaseHead* in module *ORG*, which uses the jump table generated by procedure *CaseTail*.

The following rules and restrictions apply for **numeric** case statements:

* Case labels must have values between 0 and 255.
* If the value of the case expression does not correspond to any case label in the source text, the statement sequence following the symbol ELSE is selected, if there is one, otherwise the program is aborted (*if one wants to treat such events as “empty” actions, an empty ELSE clause can be used*).

The ELSE clause has been re-introduced even though it is not part of the Oberon-07 language definition. This was done mainly for backward compatibility reasons. In general, we recommend using the ELSE clause only in well-justified cases, for example if the index range far exceeds the label range. But even in that case, one should first try to find a representation using explicit case label ranges, as shown in the example below (which assumes an index range of 0..255).

     CASE i OF                                     CASE i OF
         1:  S1                                        1:  S1
       | 3:  S3                                      | 3:  S3
       | 7:  S7            is the same as            | 7:  S7           
       | 9:  S9                                      | 9:  S9
     ELSE S0                                         | 0, 2, 4..6, 8, 10..255:  S0    (*preferred*)
     END                                           END

The implementation cost of adding the numeric CASE statement is **~65** lines of source code (*ORG* ~25, *ORP* ~40).

**Implementations:**

Several variants were implemented and tested. We recommend version A (=implemented in Extended Oberon)

**A. Default version** (source files *ORG.Mod* and *ORP.Mod*) **= recommended variant**

* Jump tables are addressed relative to the program counter (PC), and the branch offset when selecting the component statement is computed at **compile** time.

* The average overhead of any selection in a CASE statement is **9** instructions.

* The ELSE clause is implemented (although it is recommended to use explicit case label ranges whenever possible).

* Case labels must have values between 0 and 255.

* The index expression can have any value (even values outside the range 0 .. 255).

* If the index value does not correspond to any case label, a trap is generated **unless** an ELSE clause is present.

In this variant, the index range for case expressions of integer type is MIN(INTEGER) .. MAX(INTEGER) and therefore far exceeds the case label range (0 .. 255). It is the only variant where using an ELSE clause *may* be justified. But as outlined above, even in that case one should first try to express a numeric case statement using explicit case label ranges.

**B. Alternative version B** (source files *ORG1.Mod* and *ORP1.Mod*):

* Jump tables are addressed relative to the program counter (PC), and the branch offset when selecting the component statement is computed at **compile** time.

* The average overhead of any selection in a CASE statement is **9** instructions.

* The ELSE clause is implemented (although superfluous).

* Case labels must have values between 0 and 255.

* The index expression must **also** have values between 0 and 255 **regardless** of whether an ELSE clause is present.

* If the index value is outside 0 .. 255, a trap is generated **even if** an ELSE clause is present.

* If the index value is inside 0 .. 255 and does not correspond to any case label, **no** trap is generated (i.e. such events are treated as "empty" actions).

In this variant, the index range and the case label range are the same (0 .. 255). This means, that the ELSE clause is actually superfluous, as it is always **easy** to find an expression using explicit case label ranges (as shown above).

We do not recommend restricting the index range in this way. If one wants to restrict the index range, CHAR selectors can be used. In addition, the creation of traps (no trap for values 0 .. 255, trap for values outside 0 .. 255) is inconsistent. 

**C. Alternative version C** (source files *ORG2.Mod* and *ORP2.Mod*):

* Jump tables are addressed relative to the program counter (PC), and the branch offset when selecting the component statement is computed at **run** time.

* The average overhead of any selection in a CASE statement is **9** instructions.

* The ELSE clause is **not** implemented.

* Case labels must have values between 0 and 255

* The index expression must have values between 0 and the highest case label range.

* If the index value is outside 0 .. *highest case label range*, a trap is generated.

* If the index value is inside 0 .. *highest case label range* and does not correspond to any case label, **no** trap is generated (i.e. such events are treated as "empty" actions).

In this case, the index range is even more restricted (to 0 .. highest case label range <= 255).

We do not recommend restricting the index range in this way. In addition, the creation of traps (no trap for values 0 .. highest case label range, trap for values outside 0 .. highest label range) is inconsistent. 

**D. Further optimized version** (not implemented):

* If the branch instruction of the form **B,cond  [Rn]** of the RISC processor, as defined on www.projectoberon.com, were adapted to be of the form **B,cond  PC, [Rn]** (where the target of the branch is computed by adding the contents of a register to the current *program counter*), then the average overhead of any selection in a CASE statement would be **6** instructions (see www.astrobe.com for an example of such a modification of RISC).

------------------------------------------------------
**Preparing your compiler to support the numeric CASE statement**

If *Extended Oberon* is used, the numeric case statement (default version) is already implemented on your system.

If *Project Oberon 2013* is used, follow the instructions below:

------------------------------------------------------

**STEP 1**: Build a slightly modified Oberon compiler on your Project Oberon 2013 system

Edit the file *ORG.Mod* on your original system and set the following constants to the indicated new values:

     CONST ...
       maxCode = 8800; maxStrx = 3200; ...

Then recompile the modified file of your Project Oberon 2013 compiler (and unload the old one):

     ORP.Compile ORG.Mod/s ~
     System.Free ORTool ORP ORG ~

This step is (unfortunately) necessary since the official Oberon-07 compiler has a tick too restrictive constants. To compile the new version of the Oberon-07 compiler, one needs slightly more space (in the compiler) for both *code* and *string constants*.

------------------------------------------------------

**STEP 2**: Download and import the files to implement the numeric case statement to your Project Oberon 2013 system

Download all files from the [**Sources**](Sources/) directory of this repository. Convert the *source* files to Oberon format (Oberon uses CR as line endings) using the command [**dos2oberon**](dos2oberon), also available in this repository (example shown for Linux or MacOS):

     for x in *.Mod ; do ./dos2oberon $x $x ; done

Import the files to your Oberon system. If you use an emulator, click on the *PCLink1.Run* link in the *System.Tool* viewer, copy the files to the emulator directory, and execute the following command on the command shell of your host system:

     cd oberon-risc-emu
     for x in *.Mod ; do ./pcreceive.sh $x ; sleep 0.5 ; done

------------------------------------------------------

**STEP 3:** Build the "new" Oberon-07 compiler (default version):

     ORP.Compile ORG.Mod/s ORP.Mod/s ~
     System.Free ORTool ORP ORG ORB ORS ~

------------------------------------------------------

**STEP 4 (optional):** You can at any time build any of the alternative version of the compiler as follows:

     ORP.Compile ORG1.Mod/s ORP1.Mod/s ~
     System.Free ORTool ORP ORG ORB ORS ~

or

     ORP.Compile ORG2.Mod/s ORP2.Mod/s ~
     System.Free ORTool ORP ORG ORB ORS ~

------------------------------------------------------
**Testing the modified CASE statement on your system**

     MODULE Test; (*AP 1.8.18  Test program for the modified CASE statement in Oberon-07 for RISC*)
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
         IF S.class = Texts.Int THEN i := S.i; j := 0;
           CASE i OF
              2..5  : j := 11                    (*lower case label limit = 2*)
             |8 .. 10 : j := 22
             |13 .. 15: j := 33
             |28 .. 30, 18 .. 22: j := 44
             |33 .. 36, 24: j := 55              (*higher case label limit = 36*)
           (*ELSE j := 66*)                      (*for the default version of the compiler*)
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
           (*ELSE j := 66*)                      (*for the default version of the compiler*)
           END  ;
           Texts.WriteInt(W, j, 4)
         ELSE Texts.WriteString(W, " usage: Test.CaseChar char")
         END ;
         Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
       END CaseChar;

       PROCEDURE CaseType*;
         VAR S: Texts.Scanner; i, j: INTEGER;
       BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
         IF S.class = Texts.Int THEN i := S.i; j := 0; p := q;
           IF i = 0 THEN p := p0
           ELSIF i = 1 THEN p := p1
           ELSIF i = 2 THEN p := p2
           ELSIF i = 3 THEN p := p3
           END ;
           CASE p OF
              P0: IF p IS P0 THEN j := 222 ELSE j := 999 END
            | P1: IF p IS P1 THEN j := 333 ELSE j := 999 END
            | P3: IF p IS P3 THEN j := 555 ELSE j := 999 END  (*P3 is an extension of P2, not P!*)
            | P2: IF p IS P2 THEN j := 444 ELSE j := 999 END
           (*ELSE j := 666*)                                  (*for the default version of the compiler*)
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

     Test.CaseNum 0     Test.CaseNum 1       # range 0..1    -->  0  (or 66 if the ELSE clause is uncommented)
     Test.CaseNum 2     Test.CaseNum 5       # range 2..5    --> 11
     Test.CaseNum  8    Test.CaseNum 10      # range  8..10  --> 22
     Test.CaseNum 13    Test.CaseNum 15      # range 13..15  --> 33
     Test.CaseNum 18    Test.CaseNum 22      # range 18..22  --> 44
     Test.CaseNum 33    Test.CaseNum 36      # range 33..36  --> 55

     Test.CaseNum 11    Test.CaseNum 17      # inside the case label limits  --> 0  (or 66 if the ELSE clause is uncommented)
     Test.CaseNum 23    Test.CaseNum 32      # inside the case label limits  --> 0  (or 66 if the ELSE clause is uncommented)
     Test.CaseNum 99    Test.CaseNum 255     # outside the case label limits  --> 0  (or 66 if the ELSE clause is uncommented)

     Test.CaseNum -99   Test.CaseNum -1      # outside the minimum case label limit 0 --> TRAP
     Test.CaseNum 256   Test.CaseNum 1000    # outside the maximum case label limit 256 --> TRAP

     ----------------- char ---------------

     Test.CaseChar D    Test.CaseChar F      # range D..F  --> 22
     Test.CaseChar J    Test.CaseChar M      # range J..M  --> 33
     Test.CaseChar f    Test.CaseChar h      # range f..h  --> 44
     Test.CaseChar b    Test.CaseChar c      # range b..c  --> 44
     Test.CaseChar r    Test.CaseChar u      # range r..u  --> 55
     Test.CaseChar e    Test.CaseChar m      # range e, x  --> 55

     Test.CaseChar H    Test.CaseChar Y      # inside the case label limits  --> 0  (or 66 if the ELSE clause is uncommented)
     Test.CaseChar "["  Test.CaseChar "^"    # inside the case label limits  --> 0  (or 66 if the ELSE clause is uncommented)
     Test.CaseChar a    Test.CaseChar p      # inside the case label limits  --> 0  (or 66 if the ELSE clause is uncommented)

     Test.CaseChar A    Test.CaseChar C      # outside the lower case label limit "D"   --> 0  (or 66 if the ELSE clause is uncommented)
     Test.CaseChar v    Test.CaseChar z      # outside the higher case label limit "u"  --> 0  (or 66 if the ELSE clause is uncommented)

     ----------------- type ---------------

     Test.CaseType -1         # no extension  -->   0  (or 666 if the ELSE clause is uncommented)
     Test.CaseType  0         # P0            --> 222
     Test.CaseType  1         # P1            --> 333
     Test.CaseType  2         # P2            --> 444
     Test.CaseType  3         # P3            --> 555
     Test.CaseType  4         # no extension  -->   0  (or 666 if the ELSE clause is uncommented)

------------------------------------------------------
**DIFFERENCES OF THE DEFAULT VERSION TO THE OFFICIAL OBERON-07 COMPILER**

In the output of the following Unix-style *diff* commands, lines that begin with "<" are the old lines (i.e. code from the official Oberon-07 compiler), while lines that begin with ">" are the modified lines (i.e. code from *this* repository).

**$ diff FPGAOberon2013/ORG.Mod OberonNumericCaseStatement/ORG.Mod**

*ORG.CONST:*

```diff
10c10
<     maxCode = 8000; maxStrx = 2400; maxTD = 160; C24 = 1000000H;
---
>     maxCode = 8800; maxStrx = 3200; maxTD = 160; C16 = 10000H; C24 = 1000000H; C28 = 10000000H; C30 = 40000000H;
19c19
<     MI = 0; PL = 8; EQ = 1; NE = 9; LT = 5; GE = 13; LE = 6; GT = 14;
---
>     MI = 0; PL = 8; EQ = 1; NE = 9; CS = 2; CC = 10; LT = 5; GE = 13; LE = 6; GT = 14;
```

*ORG.TYPE:*

```diff
26a27
>     LabelRange* = RECORD low*, high*, label*: INTEGER END ;
```

*ORG.fix1, ORG.FixLink, ORG.FixLinkWith, ORG.merged:*

```diff
120,131c121,136
<   PROCEDURE FixLink*(L: LONGINT);
<     VAR L1: LONGINT;
<   BEGIN
<     WHILE L # 0 DO L1 := code[L] MOD 40000H; fix(L, pc-L-1); L := L1 END
<   END FixLink;
< 
<   PROCEDURE FixLinkWith(L0, dst: LONGINT);
<     VAR L1: LONGINT;
<   BEGIN
<     WHILE L0 # 0 DO
<       L1 := code[L0] MOD C24;
<       code[L0] := code[L0] DIV C24 * C24 + ((dst - L0 - 1) MOD C24); L0 := L1
---
>   PROCEDURE fix1(at, with: LONGINT);
>     VAR v: LONGINT;
>   BEGIN (*fix format-1 instruction*)
>     IF with < 0 THEN v := C28 (*set v bit*) ELSE v := 0 END ;
>     code[at] := code[at] DIV C16 * C16 + (with MOD C16) + v
>   END fix1;
> 
>   PROCEDURE FixLinkWith(L, dst: LONGINT);
>     VAR L1, k: LONGINT;
>   BEGIN (*fix format-1 and branch instructions*)
>     WHILE L # 0 DO k := code[L] DIV C30 MOD 4;
>       IF k = 1 THEN L1 := code[L] MOD C16; fix1(L, (dst-L)*4)
>       ELSIF k = 3 THEN L1 := code[L] MOD 40000H; fix(L, dst-L-1)
>       ELSE ORS.Mark("fixup impossible"); L1 := 0
>       END ;
>       L := L1
134a140,143
>   PROCEDURE FixLink*(L: LONGINT);
>   BEGIN FixLinkWith(L, pc)
>   END FixLink;
> 
```

*ORG.CaseHead, ORG.CaseTail:*

```diff
816c825,851
> 
>   PROCEDURE CaseHead*(VAR x: Item; VAR L0: LONGINT);
>   BEGIN load(x); L0 := pc;
>     (*L0+0*) Put1(Cmp, RH, x.r, 0);  (*higher bound, fixed up in CaseTail*)
>     (*L0+1*) Put3(BC, CC, 0);  (*branch to else, fixed up in CaseTail*)
>     (*L0+2*) Put1(Add, x.r, x.r, 0);  (*index + offset from L0+4 to jump table, fixed up in CaseTail*)
>     (*L0+3*) Put1(Lsl, x.r, x.r, 2);
>     (*L0+4*) Put3(BL, 7, 0);  (*LNK := PC+1*)
>     Put0(Add, LNK, LNK, x.r); Put3(BR, 7, LNK); DEC(RH)
>   END CaseHead;
> 
>   PROCEDURE CaseTail*(L0, L1: LONGINT; n: INTEGER; VAR tab: ARRAY OF LabelRange);
>     VAR i, j: INTEGER;
>   BEGIN
>     IF n > 0 THEN fix1(L0, tab[n-1].high + 1) (*higher bound*) ELSIF L1 = 0 THEN ORS.Mark("empty case") END ;
>     IF L1 = 0 THEN L1 := pc; Trap(7, 1) END ;  (*create else unless it already exists*)
>     fix(L0+1, L1-L0-2);  (*branch to else*)
>     fix1(L0+2, pc-L0-5);  (*offset from L0+4 to jump table*)
>     j := 0;
>     FOR i := 0 TO n-1 DO  (*construct jump table*)
>       WHILE j < tab[i].low DO BJump(L1); INC(j) END ;  (*else*)
>       WHILE j <= tab[i].high DO BJump(tab[i].label); INC(j) END
>     END
>   END CaseTail;
```

**$ diff FPGAOberon2013/ORP.Mod OberonNumericCaseStatement/ORP.Mod**

*ORP.CONST:*

```diff
8a9,10
>   CONST NofCases = 256;
```

*ORP.CheckCase:*

```diff
75a78,82
>   PROCEDURE CheckCase(VAR x: ORG.Item);
>   BEGIN
>     IF ~(x.type.form IN {ORB.Int, ORB.Byte, ORB.Char}) THEN ORS.Mark("invalid type"); x.type := ORB.intType END
>   END CheckCase;
```

*ORP.StatSequence:*

```diff
465d471
<       orgtype: ORB.Type; (*original type of case var*)
     469,470c475,477
<     PROCEDURE TypeCase(obj: ORB.Object; VAR x: ORG.Item);
<       VAR typobj: ORB.Object;
---
>     PROCEDURE TypeCase(obj: ORB.Object; VAR L0: LONGINT);
>       VAR typobj: ORB.Object; x: ORG.Item;
>         orgtype: ORB.Type;  (*original type of case var*)
473c480
<         qualident(typobj); ORG.MakeItem(x, obj, level);
---
>         qualident(typobj); ORG.MakeItem(x, obj, level); orgtype := obj.type;
476,477c483,503
<         ORG.CFJump(x); Check(ORS.colon, ": expected"); StatSequence
<       ELSE ORG.CFJump(x); ORS.Mark("type id expected")
---
>         ORG.CFJump(x); Check(ORS.colon, ": expected"); StatSequence;
>         ORG.FJump(L0); ORG.Fixup(x); obj.type := orgtype
>       ELSE ORS.Mark("type id expected"); Check(ORS.colon, ": expected"); StatSequence
>       END
>     END TypeCase;
> 
>     PROCEDURE TypeCasePart;
>       VAR obj: ORB.Object; L0: LONGINT;
>     BEGIN qualident(obj); Check(ORS.of, "OF expected"); L0 := 0;
>       WHILE (sym < ORS.end) OR (sym = ORS.bar) DO
>         IF sym = ORS.bar THEN ORS.Get(sym) ELSE TypeCase(obj, L0) END
>       END ;
>       IF sym = ORS.else THEN ORS.Get(sym); StatSequence END ;
>       ORG.FixLink(L0)
>     END TypeCasePart;
> 
>     PROCEDURE CaseLabel(VAR x: ORG.Item);
>     BEGIN expression(x); CheckConst(x);
>       IF (x.type.form = ORB.String) & (x.b = 2) THEN ORG.StrToChar(x)
>       ELSIF ~(x.type.form IN {ORB.Int, ORB.Char}) OR (x.a < 0) OR (x.a > 255) THEN
>         ORS.Mark("invalid case label"); x.type := ORB.intType
479c505
<      END TypeCase;
---
>     END CaseLabel;
481,485c507,544
<     PROCEDURE SkipCase;
<     BEGIN 
<       WHILE sym # ORS.colon DO ORS.Get(sym) END ;
<       ORS.Get(sym); StatSequence
<     END SkipCase;
---
>     PROCEDURE NumericCase(LabelForm: INTEGER; VAR n: INTEGER; VAR tab: ARRAY OF ORG.LabelRange);
>       VAR x, y: ORG.Item; i: INTEGER; continue: BOOLEAN;
>     BEGIN
>       REPEAT CaseLabel(x);
>         IF x.type.form # LabelForm THEN ORS.Mark("invalid label form") END ;
>         IF sym = ORS.upto THEN ORS.Get(sym); CaseLabel(y);
>           IF (x.type.form # y.type.form) OR (x.a >= y.a) THEN ORS.Mark("invalid label range"); y := x END
>         ELSE y := x
>         END ;
>         IF n < NofCases THEN  (*enter label range into ordered table*)
>           i := n; continue := TRUE;
>           WHILE continue & (i > 0) DO
>             IF tab[i-1].low > y.a THEN tab[i] := tab[i-1]; DEC(i)
>             ELSE continue := FALSE;
>               IF tab[i-1].high >= x.a THEN ORS.Mark("overlapping case labels") END
>             END
>           END ;
>           tab[i].low := x.a; tab[i].high := y.a; tab[i].label := ORG.Here(); INC(n)
>         ELSE ORS.Mark("too many case labels")
>         END ;
>         IF sym = ORS.comma THEN ORS.Get(sym)
>         ELSIF (sym < ORS.comma) OR (sym = ORS.semicolon) THEN ORS.Mark("comma?")
>         END
>       UNTIL (sym > ORS.comma) & (sym # ORS.semicolon);
>       Check(ORS.colon, ": expected"); StatSequence
>     END NumericCase;
> 
>     PROCEDURE NumericCasePart;
>       VAR x: ORG.Item; L0, L1, L2: LONGINT; n, labelform: INTEGER;
>         tab: ARRAY NofCases OF ORG.LabelRange;  (*ordered table of label ranges*)
>     BEGIN expression(x); CheckCase(x); ORG.CaseHead(x, L0); labelform := x.type.form;
>       Check(ORS.of, "OF expected"); n := 0; L2 := 0;
>       WHILE (sym < ORS.end) OR (sym = ORS.bar) DO
>         IF sym = ORS.bar THEN ORS.Get(sym) ELSE NumericCase(labelform, n, tab); ORG.FJump(L2) END
>       END ;
>       IF sym = ORS.else THEN ORS.Get(sym); L1 := ORG.Here(); StatSequence; ORG.FJump(L2) ELSE L1 := 0 END ;
>       ORG.CaseTail(L0, L1, n, tab); ORG.FixLink(L2)
>     END NumericCasePart;
489,491c548,549
<       IF ~((sym >= ORS.ident)  & (sym <= ORS.for) OR (sym >= ORS.semicolon)) THEN
<         ORS.Mark("statement expected");
<         REPEAT ORS.Get(sym) UNTIL (sym >= ORS.ident)
---
>       IF ~((sym >= ORS.ident) & (sym <= ORS.for) OR (sym >= ORS.semicolon)) THEN ORS.Mark("statement expected");
>         REPEAT ORS.Get(sym) UNTIL sym >= ORS.ident
571,583c629,632
<         IF sym = ORS.ident THEN
<           qualident(obj); orgtype := obj.type;
<           IF (orgtype.form = ORB.Pointer) OR (orgtype.form = ORB.Record) & (obj.class = ORB.Par) THEN
<             Check(ORS.of, "OF expected"); TypeCase(obj, x); L0 := 0;
<             WHILE sym = ORS.bar DO
<               ORS.Get(sym); ORG.FJump(L0); ORG.Fixup(x); obj.type := orgtype; TypeCase(obj, x)
<             END ;
<             ORG.Fixup(x); ORG.FixLink(L0); obj.type := orgtype
<           ELSE ORS.Mark("numeric case not implemented");
<             Check(ORS.of, "OF expected"); SkipCase;
<             WHILE sym = ORS.bar DO SkipCase END
<           END
<         ELSE ORS.Mark("ident expected")
---
>         IF sym = ORS.ident THEN obj := ORB.thisObj() ELSE obj := NIL END ;
>         IF (obj # NIL) & (obj.type # NIL) &
>           ((obj.type.form = ORB.Pointer) OR (obj.type.form = ORB.Record) & (obj.class = ORB.Par)) THEN TypeCasePart
>         ELSE NumericCasePart
```