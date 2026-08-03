* Loads data/mod3data.csv - the real four-group data used in the coding
* chapter. Written by hand rather than by setup/make_data.R, because this file
* is measured data rather than something the book simulates.
*
* Note f3: its four groups are coded 2, 3, 4, 5 - NOT 1 to 4. That is genuinely
* how the data arrived, and it is exactly the sort of thing worth checking
* before you build codes on top of it.
GET DATA /TYPE=TXT /FILE='data/mod3data.csv'
  /DELIMITERS=',' /QUALIFIER='"' /FIRSTCASE=2
  /VARIABLES=
    y1 F16.10
    y2 F16.10
    y3 F16.10
    y4 F16.10
    x1 F16.10
    x2 F16.10
    x3 F16.10
    x4 F16.10
    x5 F16.10
    x6 F16.10
    x7 F16.10
    f1 F8.0
    f2 F8.0
    f3 F8.0
    f4 F8.0
    f5 F8.0
    f6 F8.0
    f7 F8.0
    f8 F8.0.
