# --- Enumeration Macros and Symbols
# Sets symbols r0...r31, f0...f31, p0...p31 register names; and lt, gt, eq, cr.* names
# .macro hasva,  x, va:vararg;
# └── .macro str.hexp,  i, va:vararg;
#     └── .macro enum.debug,  value, name;
#         └── .macro enumf,  e=enum, i=1, p, s, name, va:vararg;
#             ├── .macro enum,  base=enum, incr=1, va:vararg;
#             ├── .macro enumbool,  base=enumbool, va:vararg;
#             └── .macro genmask,  va:vararg;

.ifndef def
.macro ifdef,     sym; .altmacro; ifdef.alt \sym; .noaltmacro; .endm; def=0
.macro ifdef.alt, sym; def=0; .ifdef sym; def=1; .endif; ndef=def^1; .endm
.endif; /*ifdef provides alternative to .ifdef directive, to avoid errors*/


# --- hasva
# - standalone utility -- checks vararg without committing to mutation
.ifndef hasva
.macro hasva, x, va:vararg; hasva=0; .ifnb \x; hasva=1; .endif; .endm
.endif

# --- str.hexp
# - uses 'hasva' module
.ifndef str.hexp.prefix
.macro str.hexp, i, va:vararg
  .ifb \i; str.hexp.params \va
  .else;
    str.hexp.bit=32
    .altmacro
    .if str.hexp.prefix & (str.hexp.sign & (\i < 0) ==0)
      str.hexp.va <0x>,,, <(\i)>, \va
    .elseif str.hexp.sign & (\i < 0)
      str.hexp.va <-0x>,,, <-(\i)>, \va
    .else
      str.hexp.va <>,,, <(\i)>, \va
    .endif
  .endif
.endm; str.hexp.trim=1; str.hexp.prefix=1; str.hexp.sign=0; str.hexp.case=1; str.hexp.quote=0
 /*- defaults params*/
/*opening function conditionally calls .params and sets up a prefix based on options*/

.macro str.hexp.params, p, i, va:vararg
  .ifb \p; .error "'str.hexp,' found no usable params"; .abort; .endif
  str.hexp.mask=1;
  .irpc c, "\p";/*for each char in argument p ...*/
    .rept 1;   /*.exitm will exit just this .rept block -- since .elseifc is not a thing*/
      .ifc \c, +; str.hexp.mask   = 1;                 .exitm; .endif
      .ifc \c, -; str.hexp.mask   = 0;                 .exitm; .endif
      .ifc \c, t; str.hexp.trim   = str.hexp.mask;     .exitm; .endif
      .ifc \c, s; str.hexp.sign   = str.hexp.mask;     .exitm; .endif
      .ifc \c, p; str.hexp.prefix = str.hexp.mask;     .exitm; .endif
      .ifc \c, l; str.hexp.case   = str.hexp.mask ^ 1; .exitm; .endif
      .ifc \c, c; str.hexp.case   = str.hexp.mask ^ 1; .exitm; .endif
      .ifc \c, C; str.hexp.case   = str.hexp.mask;     .exitm; .endif
      .ifc \c, u; str.hexp.case   = str.hexp.mask;     .exitm; .endif
      .ifc \c, U; str.hexp.case   = str.hexp.mask;     .exitm; .endif
      .ifc \c, q; str.hexp.quote  = str.hexp.mask;     .exitm; .endif
      .error "'str.hexp,' found invalid params in '\p' "
    .endr;
  .endr; .ifnb \i; str.hexp \i \va; .endif
.endm;  /*.params allows calls to str.hexp, (with a ',' prefix) to specify format paramters*/

.macro str.hexp.va, p, s, o, i, m, va:vararg; LOCAL oct, ascii, nib, trimming #
  str.hexp.bit = str.hexp.bit - 4
  .ifge str.hexp.bit;
    nib      = \i >> (str.hexp.bit) & 0xF      /*extract nth nibble from input expression*/
    ascii    = nib + 0x30 + ((nib > 9) & (7 + (32 & (str.hexp.case==0))))/*ascii math*/
    trimming = (str.hexp.trim != 0) & (nib == 0) & (str.hexp.bit > 0)   /*trim logic*/
    .ifnb \o;  trimming = 0;  .endif       /*only trim if all conditions evaluate > 0*/
    oct =       (ascii >> 6 & 7) * 100   /*3-digit oct escape code, in dec literals*/
    oct = oct + (ascii >> 3 & 7) * 10
    oct = oct + (ascii >> 0 & 7) * 1
    .if trimming
      str.hexp.va <\p>, <\s>,, \i, \m, \va
    .else;
      .ifb \o;  str.hexp.va <\p>, <\s>,   %oct, \i, \m, \va
      .else;    str.hexp.va <\p>, <\s\\o>, %oct, \i, \m, \va
      .endif;     /*evaluate %oct as numeric (decimal) literals, and append after evaluation*/
    .endif;
  .else;
    .ifnb \o; str.hexp.va <\p\s\\o >,,,, \m, \va
      /*when we run out of digits, concat last octal with string and given prefix*/
    .else; .noaltmacro
      str.hexp.continue \m, \p, \va
    .endif   /*pass resulting string to macro \m as first argument*/
  .endif;
.endm;  /*recursively format hex literals, with format options*/
.macro str.hexp.continue, m, p, va:vararg
  hasva \va
  .if     (hasva) & (str.hexp.quote==0); \m \p, \va
  .elseif (hasva) & (str.hexp.quote!=0); \m "\p", \va
  .elseif str.hexp.quote==0; \m \p
  .elseif str.hexp.quote!=0; \m "\p"
  .endif  /*avoid using a comma if va is blank*/
.endm /*final step removes any qoutes that may have been given to \m*/
# Accepts constants, variables, or expressions that don't have any shifts in them
.endif
 ## # EXAMPLES:
 ## .macro m, s, ss; .error "\s \ss"; .endm;
 ## str.hexp 1-10*5, m   # <- error text = evaluated, formatted hex from given expression
 ## x'Var = 10+12>>2     # - expressions with shifts must be passed via symbols
 ## str.hexp x'Var,  m   # <- but they can still be evaluated
 ## str.hexp 1000+x'Var, m, "and then some more text"
 ## # macros will recieve the hex as the first argument, followed by any extra arguments given
 ##
 ## # you can also use a blank first argument to set basic format options in the second argument:
 ## str.hexp, -tsp, 150, m # - remove trim, sign, and prefix options
 ## str.hexp, +tsp, 150, m # - add trim, sign and prefix options
 ## str.hexp, -s,  -150, m # - sign can be used to summarize negatives
 ## str.hexp, sl,  -150, m # - options can be toggled on without a + sign
 ## str.hexp, -s+t,-150, m # - you can also mix multiple signs in one param string
 ## # t = trim   s = sign   p = prefix   l, c = lowercase   u, U, C = uppercase   q = quote result


.ifndef enum
.macro enum, base=enum, incr=1, va:vararg
  enumf \base, \incr,,, \va
.endm
# 'enum' can set a base value modified by an incrementor to multiple symbols in a sequence
#   if incrementor is set to 0, then all symbols recieve the same base value
#   else, each symbol gets last value + incrementor
# Sets 'enum' (self) property to next enumeration value
#   blank base will use self property by default
# ex: enum 0, 4, A B C D
#     .byte A, B, C, D
# >>> .byte 0, 4, 8, 12

.macro enumf, e=enum, i=1, p, s, name, va:vararg
  .ifnb \name; enumf.ichange=0; enumf.i=0
    .irpc c, "\name"; enumf.i=enumf.i+1

      .if enumf.i <=2; .ifc "\c", "(";  enumf.ichange=enumf.ichange+1; .endif
      .else; .exitm
      .endif
    .endr
    .if     enumf.ichange==1; enumf \e, \name, \p, \s, \va
    .elseif enumf.ichange==2; enumf \name, \i, \p, \s, \va
    .else
      \p\name\s=\e
      .ifne enum.debug; enum.debug, \p\name\s; .endif
      enumf \e+\i, \i, \p, \s, \va
    .endif
  .else; enum=\e
  .endif
.endm; enum=0; enum.debug=0; enumf.ichange=0; enumf.i=0
# 'enumf' can be used to set up specialized enum macros, with prefixes/suffixes
# Sets 'enum' property to next enumeration value
# ex: enumf 0, 4, x, , A B C D
#     .byte xA, xB, xC, xD
# >>> .byte 0, 4, 8, 12

.macro enum.debug, value, name
  .ifb \value;
    .ifdef str.hexp.prefix
      str.hexp, tsup, \name, enum.debug, \name
    .else
      .altmacro
      enum.debug %\name, \name
      .noaltmacro
      .exitm
    .endif
  .else; .error "\name = \value\()"
  .endif
.endm
# 'enum.debug' is automatically invoked by all uses of enum if the property enum.debug = 1
#  If true, then all enum calls will throw an error displaying the values created for each symbol
# - this may be invoked manually to test the evaluation of any given expression
#   - use a call with a comma, like:  enum.debug, mySymbol+5
# - if the str.hexp module is detected, evaluations are displayed in hexadecimal

.irpc c, rfp; enumf 0, 1, \c,, /*
*/   0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15/*
*/, 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31; .endr
lt=0;gt=1;eq=2;.irpc i, 01234567;.irp x, lt, gt, eq; cr\i\().\x=\x+\i<<2; .endr; .endr
# register symbols, for r- GPRs, f- FPRs, and p- paired singles
# cr symbols lt, gt, eq, and crN.* symbols

.macro enumbool, base=enumbool, va:vararg
  .ifge \base
    enumbool.mask \base, 1, \va
    enumf \base, 1, b,, \va
    enumbool=enum
  .else
    enumbool.mask -(\base), -1, \va
    enumf -(\base), -1, b,, \va
    enumbool=-(enum)
  .endif
.endm
.macro enumbool.mask, s, i, name, va:vararg
  .ifnb \name
    m\name= 1<<(31-(\s))
    enumbool.mask \s+\i, \i, \va
  .endif
.endm; enumbool=-31
# 'enumbool' macro creates a b- boolean index symbol and a m- mask symbol for each given name.
#   The incrementor assumes -1 or +1 from the sign of the given starting base.
#   The base corresponds with the b- symbol value, and is equal to the bit's big-endian index.
#   May be used to streamline mask data generation with 'genmask' macro
# Sets 'enumbool' (self) property to next enumeration value
# ex: enumbool -31, A B C D
#     bf- bC, 0f;  rlwimi r0, r0, bA-bC, mC;     0:
# >>> bf- 29, 0f;  rlwimi r0, r0, 2, 0x00000004; 0:

.macro genmask, va:vararg
  genmask=0
  genmask.crf=0
  genmask.i=0
  genmask.va \va
.endm
.macro genmask.va, name, va:vararg
  .ifnb \name
    ifdef m\name
    .if def
      .if \name
        genmask=genmask|m\name
      .endif
    .else
      genmask=genmask|\name
    .endif
    genmask.va \va
  .else
    .rept 8
      .if (genmask & (0xF<<(genmask.i<<2)))
        genmask.crf=genmask.crf|(1<<genmask.i)
      .endif
      genmask.i=genmask.i+1
    .endr
  .endif
.endm; genmask=0; genmask.crf=0
# 'genmask' macro compiles a mask int and a crf byte for loading in cr bits
# Sets 'genamsk' (self) property to the generated int value.
# Sets 'genmask.crf' property to the generated crf mask for using the mtcrf PPC instruction.
# ex: enumbool -31, A B C D
#     A=1;  B=1;  C=0;  D=1
#     genmask A B C D
#     li r0, genmask;  mtcrf genmask.crf, r0;  bf- bC, 0f;  rlwimi r0, r0, bA-bC, mC;     0:
# >>> li r0, 0xB;      mtcrf 0x01, r0;         bf- 29, 0f;  rlwimi r0, r0, 2, 0x00000004; 0:


## # More Examples:
## enum,, A B C D E F G H
## .byte A, B, C, D, E, F, G, H
## # >>> 00010203 04050607
## # enum can be used to create named index places
## # - blank base on first call defaults to 0
## # - blank increment size defaults to +1
## enum 1, 0, A B C D E F G H
## .byte A, B, C, D, E, F, G, H
## # >>> 01010101 01010101
## # enum can set multiple variables to the same value
## # - commas optional
##
## enum 1, 0, A, (1), B, (2), C, (3), D, (1), E F G H
## .byte A, B, C, D, E, F, G, H
## # >>> 01010204 0708090A
## # enum can also change its increment size using parentheses (n)
## # - commas required before and after each pair of parentheses
##
## enum, 1, I J K L
## .byte I, J, K, L, 0, 0, 0, 0
## # >>> 0B0C0D0E
## # - blank base will default to last enum placement
##
## enum 0, 0, A C D E F G H, ((1)), B
## .byte A, B, C, D, E, F, G, H
## # >>> 00010000 00000000
## # - double parentheses ((n)) will set a new absolute base
##
## enumbool -31, A B C D E F G H
## # enumbool can be used to create (b-) boolean index and (m-) mask names
## # 20...31 are for interpreting ints as bool fields without saving CR
## #  0...31 may be used fully if CR has been saved
## # - enumbool summarizes initial incrementor as +/- 1 using sign of 'base' argument
## # - since they were defined as -31, the index descends to make little-endian masks
##
## Options= mA|mE|mF
## .long Options
## # >>> 00000031
## # Options int represents a compressed configuration of options A, E, F = TRUE
## # - the m- prefix stands for 'Mask'
## #   - these can be used to construct ints without shifts
##
## lwz r0, 0x0(r3)
## mtcrf 0x03, r0
## bt+ bE, _myLabel
## bf- bF, 0x100
## # bt (branch if true) and bf (branch if false) use options E and F bools in CR
## # - the b- prefix stands for 'Boolean'
## #   - these can be used to match the CR index of corresponding m- 'Mask' values
##
## rlwinm r3, r0, 0, bE, bE
## # >>> rlwinm r3, r0, 0, 24, 24
## rlwimi r0, r0, bA-bC, mC
## # >>> rlwimi r0, r0, 2, 0x00000004
## # both m- and b- symbols may be used in different types of rotate syntaxes
## # - 4 arg uses a contiguous mask value;  5 arg uses a bit index range to define mask instead
## # - subtraction can be used to transpose bits from one index to another in rotation arg
##
## A=1
## B=1
## C=0
## E=1
## # user settings; true or false
##
## genmask A B C D E F G H
## .long genmask
## .long genmask.crf
## # >>> 00000013 00000003
## # genmask compiles int from all of the symbol info generated by enumbool + user settings
## # - genmask.crf can be used to mask which cr fields are used in mtcrf instructions
##
##
## _myLabel:
## lis r0, genmask@h
## ori r3, r0, genmask@l
## # genmask properties can be used in expressions to generate immediates from option settings
##
## mtcrf genmask.crf, r3
## cmpwi cr1, r3, 0
## bt+ bD, _myLabel
## cror eq, cr1.eq, bC
## beq- 0x100
## # generated symbols can be used in cr-based instructions


.endif
