//
// Copyright (c) 2022, Novant LLC
// All Rights Reserved
//
// History:
//   20 Jun 2022  Andy Frank  Creation
//

*************************************************************************
** Def
*************************************************************************

@Js internal class Def
{
  ** Child nodes for this AST node.
  Def[] children := [,]

  // TODO
  // Loc loc { file, line }

  ** Dump AST to given outsteam.
  virtual Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.printLine("def")
    children.each |k| { k.dump(out, indent+2) }
  }
}

*************************************************************************
** RulesetDef
*************************************************************************

@Js internal class RulesetDef : Def
{
  new make(|This| f) { f(this) }

  const Str[] selectors

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.print(selectors.join(", ")).printLine(" {")
    children.each |k| { k.dump(out, indent+2) }
    out.print(Str.spaces(indent)).printLine("}")
  }
}

*************************************************************************
** DeclarationDef
*************************************************************************

@Js internal class DeclarationDef : Def
{
  new make(|This| f) { f(this) }

  const Str prop
  const Str val

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.print(prop).print(": ").printLine(val)
  }
}