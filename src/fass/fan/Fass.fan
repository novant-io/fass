//
// Copyright (c) 2022, Novant LLC
// Licensed under the MIT License
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
  ** results to 'out'. If the source contains '@using' imports
  ** 'onUse' is required to resolve the filename to an 'InStream'
  ** for referenced fass content.
  static Void compile(Obj file, InStream in, OutStream out, |Str name->InStream|? onUse := null)
  {
    def := Parser(file, in).parse
    use := |Str n->Def|
    {
      if (onUse == null) throw Err("Missing @using resolver func")
      f := file is File ? ((file as File) + n.toUri).osPath : n
      return Parser(f, onUse(n)).parse
    }
    Compiler().compile(def, out, use)
  }

  ** Compile the fass source into native CSS and return as 'Str'.
  static Str compileStr(Str fass)
  {
    buf := StrBuf()
    Fass.compile("str", fass.in, buf.out)
    return buf.toStr
  }
}
