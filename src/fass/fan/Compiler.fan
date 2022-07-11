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
  Void compile(OutStream out, |Str name->Def| onUse)
  {
    flatten.each |d| { compileDef(d, out, onUse) }
  }

  ** Flatten all RulesetDefs.
  private Def[] flatten()
  {
    flat := Def[,]
    root.children.each |d|
    {
      switch (d.typeof)
      {
        case AtRuleDef#: flat.add(d)

        case VarAssignDef#:
          VarAssignDef v := d
          varmap[v.var.name] = v.expr.val

        case RulesetDef#:
          flattenRuleset(d, "", flat)

        default:
          throw Err("Unexpected node '${d.typeof}'")
      }
    }
    return flat
  }

  ** Flatten given ruleset and add to accumlator list.
  private Void flattenRuleset(RulesetDef r, Str prefix, Def[] acc)
  {
    // create a flattened def for each selector
    r.selectors.each |s|
    {
      qs := ""
      if (s.startsWith("&"))
      {
        // cannot use self at root
        if (prefix.isEmpty) throw Err("Cannot reference & at root level")

        // if self reference use prefix as-is
        qs = s.replace("&", prefix)
      }
      else
      {
        // otherwise append selector to qualified selector prefix
        qs = StrBuf().add(prefix).join(s, " ").toStr
      }

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
  private Void compileDef(Def def, OutStream out, |Str name->Def| onUse)
  {
    switch (def.typeof)
    {
      case AtRuleDef#:
        AtRuleDef a := def
        if (a.rule != "@use") throw Err("Unsupported rule '${a.rule}'")
        if (a.expr isnot LiteralDef) throw Err("Unsupported @use expr")
        _def := onUse(a.filename)
        _def.children.each |k|
        {
          // inject vars into parent context
          if (k is VarAssignDef)
          {
            VarAssignDef v := k
            varmap[v.var.name] = v.expr.val
          }
        }
        Compiler(_def).compile(out, onUse)

      case RulesetDef#:
        RulesetDef r := def
        decls := r.children.findType(DeclarationDef#)
        // do not render rule if no declarations
        if (decls.isEmpty) return
        out.print(r.selectors.join(" ")).printLine(" {")
        decls.each |k| { compileDef(k, out, onUse) }
        out.printLine("}")

      case DeclarationDef#:
        DeclarationDef d := def
        out.print("  ").print(d.prop).print(": ")
        if (d.expr is VarDef)
        {
          n := d.expr->name
          v := varmap[n] ?: throw ArgErr("Unknown var '\$${n}'")
          out.print(v)
        }
        else
        {
          out.print(d.expr->val)
        }
        out.printLine(";")

      case VarDef#:
        // vardef does not compile to CSS
        x := 5

      default: throw ArgErr("Unexpected node '${def.typeof}'")
    }
  }

  private Def root                // AST root
  private Str:Str varmap := [:]   // cache of VarAssignDef name:vals
}