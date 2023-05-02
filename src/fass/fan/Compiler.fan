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
          flattenSelectors(r).each |sel,i|
          {
            if (i > 0) out.print(", ")
            out.print(sel)
          }
          out.printLine(" {")
          decls.each |k| { compileDef(k, out) }
          out.printLine("}")
        }
        kids := r.children.findType(RulesetDef#)
        kids.each |k| { compileDef(k, out) }

      case SelectorDef#:
        SelectorDef s := def
        s.parts.each |p,i|
        {
          if (i > 0) out.print(" ")
          if (p is LiteralDef) compileDef(p, out)
          else if (p is VarDef) compileDef(p, out)
          else throw unexpectedDef(p)
        }

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
          if (k is LiteralDef) compileDef(k, buf.out)
          else if (k is VarDef) compileDef(k, buf.out)
          else throw unexpectedDef(k)
        }
        out.print(buf.toStr.split.join(" "))  // filter excess whitepsace

      case LiteralDef#:
        LiteralDef l := def
        out.print(l.val)

      case VarDef#:
        VarDef v := def
        ExprDef? x := def.var(v.name)
        if (x == null) throw err("Var not found '${v.name}'", v)
        compileDef(x, out)

      default: throw err("Unsupported node tyoe '${def.typeof}'", def)
    }
  }

  ** Explode a ruleset into a list of flattened compiled selectors.
  private Str[] flattenSelectors(RulesetDef r)
  {
    // walk parents to get ruleset path
    path := [r]
    def  := r.parent
    while (def is RulesetDef)
    {
      path.add(def)
      def = def.parent
    }

    // then flatten
    acc := Str[,]
    doFlatten(acc, path.reverse, 0, "")
    return acc
  }

  private Void doFlatten(Str[] acc, RulesetDef[] path, Int depth, Str prefix)
  {
    // create a flattened def for each selector
    def := path[depth]
    def.selectors.each |sel|
    {
      flat := StrBuf()

      // first compile selector list to Str#
      cbuf := StrBuf()
      sel.parts.each |p,i|
      {
        if (i > 0) cbuf.addChar(' ')
        compileDef(p, cbuf.out)
      }
      csel := cbuf.toStr

      if (csel.startsWith("&"))
      {
        // cannot use self at root
        if (depth == 0) throw err("Cannot reference & at root level", sel)

        // append pusedo-class directly to prefix
        flat.add(prefix)
        if (csel.size > 1) flat.add(csel[1..-1])
      }
      else
      {
        // otherwise append selector to qualified selector prefix
        flat.add(prefix).join(csel, " ")
      }

      if (depth == path.size-1)
      {
        // hit a leaf node, add flattened name
        acc.add(flat.toStr)
      }
      else
      {
        // else traverse path
        doFlatten(acc, path, depth+1, flat.toStr)
      }
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
