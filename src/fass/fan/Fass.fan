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
  ** results to 'out'. If the source contains '@use' at-rules then
  ** 'onUse' is required to resolve the filename to an 'InStream'
  ** for referenced fass content.
  static Void compile(InStream in, OutStream out, |Str name->InStream|? onUse := null)
  {
    def := Parser(in).parse
    use := |Str n->Def|
    {
      if (onUse == null) throw Err("Missing @use resolver func")
      return Parser(onUse(n)).parse
    }
    Compiler().compile(def, out, use)
  }

  ** Compile the fass source into native CSS and return as 'Str'.
  static Str compileStr(Str fass)
  {
    buf := StrBuf()
    Fass.compile(fass.in, buf.out)
    return buf.toStr
  }
}
