//
// Copyright (c) 2022, Novant LLC
// All Rights Reserved
//
// History:
//   20 Jun 2022  Andy Frank  Creation
//

using concurrent

*************************************************************************
** Fass
*************************************************************************

@Js const class Fass
{
  ** Compile the fass source from 'in' into native CSS and write
  ** results to 'out'.
  static Void compile(InStream in, OutStream out)
  {
    def := Parser(in).parse
    Compiler(def).compile(out)
  }

  ** Compile the fass source into native CSS and return as 'Str'.
  static Str compileStr(Str fass)
  {
    buf := StrBuf()
    Fass.compile(fass.in, buf.out)
    return buf.toStr
  }
}
