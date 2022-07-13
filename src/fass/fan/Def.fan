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

@Js internal abstract class Def
{
  ** Child nodes for this AST node.
  Def[] children := [,]

  // TODO
  // Loc loc { file, line }

  ** Dump AST to given outsteam.
  abstract Void dump(OutStream out, Int indent)
  // {
  //   out.print(Str.spaces(indent))
  //   out.printLine("def")
  //   children.each |k| { k.dump(out, indent+2) }
  // }
}

*************************************************************************
** ScopeDef
*************************************************************************

@Js internal class ScopeDef : Def
{
  ** Compiler hook to identiy this scope.
  Str cname := ""

  ** Compiled map of var:val for this scope
  Str:Str cvars := [:]

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent)).printLine("scope")
    cvars.each |v,k|
    {
      out.print(Str.spaces(indent+4)).printLine("${k}:${v}")
    }
    children.each |k| { k.dump(out, indent+2) }
  }
}

*************************************************************************
** AtRuleDef
*************************************************************************

@Js internal class AtRuleDef : Def
{
  new make(|This| f) { f(this) }

  const Str rule
  Def expr

  Str filename()
  {
    if (expr isnot LiteralDef) throw ArgErr("Invalid expr '${expr}'")
    v := expr->val.toStr
    if (v.size >= 3)
    {
      if (v.startsWith("'"))  v = v[1..-2]
      if (v.startsWith("\"")) v = v[1..-2]
    }
    if (!v.endsWith(".fass")) v += ".fass"
    return v
  }

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.print(rule).print(" ")
    expr.dump(out, 0)
    out.printLine("")
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
    exprs.each |e| { e.dump(out, 0) }
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
  LiteralDef expr

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    var.dump(out, 0)
    out.print(": ")
    expr.dump(out, 0)
    out.printLine("")
  }
}

*************************************************************************
** VarDef
*************************************************************************

@Js internal class VarDef : Def
{
  new make(|This| f) { f(this) }

  Str name

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

  Str val

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.print(val)
  }
}
