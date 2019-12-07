.ifndef blaba.included
blaba.included=1
.macro bla, a, b
  .ifb \b;lis r0, \a \@;ori r0, r0, \a \@;mtlr r0;blrl
  .else;  lis \a, \b \@;ori \a, \a, \b \@;mtlr \a;blrl
  .endif
.endm
.macro ba, a, b
  .ifb \b;lis r0, \a \@;ori r0, r0, \a \@;mtctr r0;bctr
  .else;  lis \a, \b \@;ori \a, \a, \b \@;mtctr \a;bctr
  .endif
.endm
.endif
