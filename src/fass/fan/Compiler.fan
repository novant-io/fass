//
// Copyright (c) 2022, Novant LLC
// Licensed under the MIT License
//
// History:
//   21 Jun 2022  Andy Frank  Creation
//

*************************************************************************
** Compiler
*************************************************************************

@Js internal class Compiler
{
  ** Compile AST to native CSS on given outstream.
  Void compile(Def root, OutStream out, |Str name->Def| onUse)
  {
    this.onUse = onUse
    this.useMap.clear
    compileDef(root, out)
  }

  ** Compile Def node to CSS.
  private Void compileDef(Def def, OutStream out)
  {
    switch (def.typeof)
    {
      case Def#:
        def.children.each |k| { compileDef(k, out) }

      case UsingDef#:
        UsingDef u := def
        Def k := onUse(u.ref)
        // only render using once
        if (!useMap.containsKey(u.ref))
        {
          useMap[u.ref] = true
          compileDef(k, out)
        }
        // copy root var scope to parent scope
        k.vars.each |v| { def.parent.add(v) }

      case AssignDef#:
        AssignDef a := def
        // verify var not already defined
        test := a.parent.var(a.name)
// TODO FIXIT: disable to get @using work; but need to fix
        // if (test != null && test.parent != a)
        //   throw err("Variable arleady defined '${a.name}'", a)

      case RulesetDef#:
        RulesetDef r := def
        decls := r.children.findType(DeclareDef#)
        // only render rule if declares props
        if (decls.size > 0)
        {
          Str[]? fsel
          try { fsel=r.flattenSels }
          catch (Err e) throw err(e.msg, r)
          out.print(fsel.join(", ")).printLine(" {")
          decls.each |k| { compileDef(k, out) }
          out.printLine("}")
        }
        kids := r.children.findType(RulesetDef#)
        kids.each |k| { compileDef(k, out) }

      case DeclareDef#:
        DeclareDef d := def
        out.print("  ").print(d.prop).print(": ")
        compileDef(d.expr, out)
        out.printLine(";")

      case ExprDef#:
        ExprDef e := def
        buf := StrBuf()
        e.defs.each |k,i|
        {
          if (i > 0) buf.addChar(' ')
          if (k is LiteralDef)
          {
            LiteralDef l := k
            buf.add(l.val)
          }
          else if (k is VarDef)
          {
            VarDef v := k
            ExprDef? x := e.var(v.name)
            if (x == null) throw err("Var not found '${v.name}'", k)
            compileDef(x, buf.out)
          }
          else throw unexpectedDef(k)
        }
        out.print(buf.toStr.split.join(" "))  // filter excess whitepsace

      default: throw err("Unsupported node tyoe '${def.typeof}'", def)
    }
  }

 ** Err for unexpected def.
  private Err unexpectedDef(Def def)
  {
    err("Unexpected node '${def.typeof}'", def)
  }

  ** Err error with location.
  private FassCompileErr err(Str msg, Def def)
  {
    FassCompileErr(msg, def.loc)
  }

  private Func? onUse              // callback to resolve @using refs
  private Str:Bool useMap := [:]   // mark UsingDef.ref as processed
}
