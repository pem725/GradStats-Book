* Loads data/knox.dat - Wright's Knox Cube Test responses: 35 children (rows)
* by 18 tapping items (columns), 1 = repeated the tapping pattern correctly.
*
* Two things about this file will bite you.
*
* Its columns are separated by a MIX of spaces and tabs, so both have to be
* listed as delimiters - and the delimiter below is a real tab character, not
* the two-character escape \t. Written as \t, PSPP takes it literally as a
* backslash and a letter, tabs stop separating anything, and the file still
* loads: no error, just the wrong numbers in the wrong columns. That is how
* this book briefly reported that 6 of 35 children passed item 3 when in fact
* all 35 did.
*
* And GET DATA wants a format after EVERY variable name; the "i1 TO i18"
* shorthand that works in DATA LIST is not available here, which is why all
* eighteen items are written out one at a time.
GET DATA /TYPE=TXT /FILE='data/knox.dat'
  /ARRANGEMENT=DELIMITED /DELIMITERS=' 	' /FIRSTCASE=2
  /VARIABLES=Name A10 sex A1 i1 F1.0 i2 F1.0 i3 F1.0 i4 F1.0 i5 F1.0 i6 F1.0 i7 F1.0 i8
             F1.0 i9 F1.0 i10 F1.0 i11 F1.0 i12 F1.0 i13 F1.0 i14 F1.0
             i15 F1.0 i16 F1.0 i17 F1.0 i18 F1.0.
