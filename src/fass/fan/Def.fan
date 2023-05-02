//
// Copyright (c) 2022, Novant LLC
// Licensed under the MIT License
//
// History:
//   20 Jun 2022  Andy Frank  Creation
//

using util

*************************************************************************
** Def
*************************************************************************

@Js internal class Def
{
  ** Parent def of 'null' for root.
  Def? parent := null

  ** Location where this node was defined.
  FileLoc loc := FileLoc.unknown

  ** Child nodes for this AST node.
  Def[] children := [,]

  ** Append node to 'children'
  This add(Def child)
  {
    child.parent = this
    children.add(child)
    return this
  }

  ** Get all var assingments for this def.
  AssignDef[] vars() { children.findType(AssignDef#) }

  ** Get expr value for given var.
  ExprDef? var(Str name)
  {
    a := vars.find |d| { d->name == name }
    if (a != null) return a->expr
    if (parent != null) return parent.var(name)
    return null
  }

  ** Dump AST to given outsteam.
  virtual Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.printLine("def [$loc]")
    children.each |k| { k.dump(out, indent+2) }
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
    out.print(Str.spaces(indent)).print(val)
  }
}

*************************************************************************
** LiteralDef
*************************************************************************

@Js internal class VarDef : Def
{
  new make(|This| f) { f(this) }

  const Str name

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent)).print("\$").print(name)
  }
}

*************************************************************************
** ExprDef
*************************************************************************

@Js internal class ExprDef : Def
{
  new make(|This| f)
  {
    f(this)
    this.defs.each |d| { d.parent = this }
  }

  Def[] defs

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    defs.each |d| { d.dump(out, 0) }
  }
}

*************************************************************************
** AssignDef
*************************************************************************

@Js internal class AssignDef : Def
{
  new make(|This| f)
  {
    f(this)
    this.expr.parent = this
  }

  const Str name
  ExprDef expr

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.print(name).print(" := ")
    expr.dump(out, 0)
    out.printLine(" [$loc]")
  }
}

*************************************************************************
** AtRuleDef
*************************************************************************

@Js internal class AtRuleDef : Def
{
  new make(|This| f)
  {
    f(this)
    this.conditions.each |c| { c.parent = this }
  }

  const Str identifier  // for now includes leading @
  Def[] conditions

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent)).print(identifier)
    conditions.each |c|
    {
      out.print(" ")
      c.dump(out, 0)
    }
    out.printLine(" { [$loc]")
    children.each |k| { k.dump(out, indent+2) }
    out.print(Str.spaces(indent)).printLine("}")
  }
}

*************************************************************************
** SelectorDef
*************************************************************************

@Js internal class SelectorDef : Def
{
  new make(|This| f) { f(this) }

  Def[] parts := Def[,]

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    parts.each |p,i|
    {
      if (i > 0) out.print(" ")
      p.dump(out, 0)
    }
  }
}

*************************************************************************
** RulesetDef
*************************************************************************

@Js internal class RulesetDef : Def
{
  new make(|This| f)
  {
    f(this)
    this.selectors.each |s| { s.parent = this }
  }

  SelectorDef[] selectors

  override Void dump(OutStream out, Int indent)
  {
    selectors.each |s,i|
    {
      if (i > 0) out.printLine(",")
      out.print(Str.spaces(indent))
      s.dump(out, 0)
    }
    out.printLine(" { [$loc]")
    children.each |k| { k.dump(out, indent+2) }
    out.print(Str.spaces(indent)).printLine("}")
  }
}

*************************************************************************
** DeclareDef
*************************************************************************

@Js internal class DeclareDef : Def
{
  new make(|This| f)
  {
    f(this)
    this.expr.parent = this
  }

  const Str prop
  ExprDef expr

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.print(prop).print(": ")
    expr.dump(out, 0)
    out.printLine(" [$loc]")
  }
}

*************************************************************************
** UsingDef
*************************************************************************

@Js internal class UsingDef : Def
{
  new make(|This| f) { f(this) }

  const Str ref

  // Str filename()
  // {
  //   if (expr isnot LiteralDef) throw ArgErr("Invalid expr '${expr}'")
  //   v := expr->val.toStr
  //   if (v.size >= 3)
  //   {
  //     if (v.startsWith("'"))  v = v[1..-2]
  //     if (v.startsWith("\"")) v = v[1..-2]
  //   }
  //   if (!v.endsWith(".fass")) v += ".fass"
  //   return v
  // }

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent)).print("@using ${ref}")
    out.printLine(" [$loc]")
  }
}
