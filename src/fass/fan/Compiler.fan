//
// Copyright (c) 2022, Andy Frank
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
  ** Construct new compiler for given AST.
  new make(Def root)
  {
    this.root = root
  }

  ** Compile AST to native CSS on given outstream.
  Void compile(OutStream out)
  {
    flatten.each |d| { compileDef(d, out) }
  }

  ** Flatten all RulesetDefs.
  private Def[] flatten()
  {
    flat := Def[,]
    root.children.each |d|
    {
      // TODO: Ruleset probably needs to be required
      //       at the root level; but allow for now
      if (d is RulesetDef) flattenRuleset(d, "", flat)
      else flat.add(d)
    }
    return flat
  }

  ** Flatten given ruleset and add to accumlator list.
  private Void flattenRuleset(RulesetDef r, Str prefix, Def[] acc)
  {
    // create a flattened def for each selector
    r.selectors.each |s|
    {
      // append selector to qualified selector prefix
      qs := StrBuf().add(prefix).join(s, " ").toStr

      f := RulesetDef {
        it.selectors = [qs.toStr]
        it.children  = r.children.findAll |k| { k isnot RulesetDef }
      }
      acc.add(f)

      // walk child rulesets
      r.children.findType(RulesetDef#).each |k|
      {
        flattenRuleset(k, qs, acc)
      }
    }

  }

  ** Compile Def node to CSS.
  private Void compileDef(Def def, OutStream out)
  {
    switch (def.typeof)
    {
      case RulesetDef#:
        RulesetDef r := def
        decls := r.children.findType(DeclarationDef#)
        // do not render rule if no declarations
        if (decls.isEmpty) return
        out.print(r.selectors.join(" ")).printLine(" {")
        decls.each |k| { compileDef(k, out) }
        out.printLine("}")

      case DeclarationDef#:
        DeclarationDef d := def
        out.print("  ").print(d.prop).print(": ").print(d.val)
        out.printLine(";")

      default: throw ArgErr("Unexpected node '${def.typeof}'")
    }
  }

  private Def root    // AST root
}