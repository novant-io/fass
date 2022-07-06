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
  Def[] exprs

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.print(prop).print(": ")
    exprs.each |e,i|
    {
      if (i > 0) out.print(", ")
      e.dump(out, 0)
    }
    out.printLine("")
  }
}

*************************************************************************
** VarAssignDef
*************************************************************************

@Js internal class VarAssignDef : Def
{
  new make(|This| f) { f(this) }

  VarDef var
  LiteralDef val

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    var.dump(out, 0)
    out.print(": ")
    val.dump(out, 0)
    out.printLine("")
  }
}

*************************************************************************
** VarDef
*************************************************************************

@Js internal class VarDef : Def
{
  new make(|This| f) { f(this) }

  const Str name

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.print("\$").print(name)
  }
}

*************************************************************************
** LiteralDef
*************************************************************************

@Js internal class LiteralDef : Def
{
  new make(|This| f) { f(this) }

  const Str val

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.print(val)
  }
}
