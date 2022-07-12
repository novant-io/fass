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
  ** Compile AST to native CSS on given outstream.
  Void compile(ScopeDef scope, OutStream out, |Str name->Def| onUse)
  {
    f := flatten(null, scope, onUse)
    compileDef(f, f, out)
  }

  ** Flatten all RulesetDefs while resolving VarAssignDef
  ** and AtRuleDef includes, which get filtered out of the
  ** flattened list.
  private ScopeDef flatten(ScopeDef? parent, ScopeDef orig, |Str name->Def| onUse)
  {
    flat := ScopeDef {}
    orig.children.each |d|
    {
      switch (d.typeof)
      {
        case AtRuleDef#:
          AtRuleDef a := d
          if (a.rule != "@use") throw Err("Unsupported rule '${a.rule}'")
          if (a.expr isnot LiteralDef) throw Err("Unsupported @use expr")
          u := onUse(a.filename)
          f := flatten(flat, u, onUse)
          f.cname = a.filename
          if (scopeMap[f.cname] == null) scopeMap[f.cname] = f
          else
          {
            // this def already exists, so prune children to avoid
            // rendereing duplicates; but keep cvar map for scoping
            f.children.clear
          }
          flat.children.add(f)

        case VarAssignDef#:
          VarAssignDef v := d
          n := v.var.name
          if (flat.cvars[n] != null) throw Err("Variable already defined '${n}'")
          flat.cvars.add(v.var.name, v.expr.val)

        case RulesetDef#:
          flattenRuleset(d, "", flat.children)

        default:
          throw Err("Unexpected node '${d.typeof}'")
      }
    }

    // merge vars into parent if non-null
    if (parent != null)
    {
      flat.cvars.each |v,n|
      {
        // value may already exist from a previous @use import
        // so only throw if the value does not match
        pv := parent.cvars[n]
        if (pv != null && pv != v) throw Err("Variable already defined '${n}'")
        parent.cvars[n] = v
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
  private Void compileDef(ScopeDef scope, Def def, OutStream out)
  {
    switch (def.typeof)
    {
      case ScopeDef#:
        ScopeDef s := def
        s.children.each |k| { compileDef(s, k, out) }

      case RulesetDef#:
        RulesetDef r := def
        decls := r.children.findType(DeclarationDef#)
        // do not render rule if no declarations
        if (decls.isEmpty) return
        out.print(r.selectors.join(" ")).printLine(" {")
        decls.each |k| { compileDef(scope, k, out) }
        out.printLine("}")

      case DeclarationDef#:
        DeclarationDef d := def
        out.print("  ").print(d.prop).print(": ")
        if (d.expr is VarDef)
        {
          // TODO FIXIT: include [file:line#] in err
          n := d.expr->name
          v := scope.cvars[n] ?: throw ArgErr("Undefined var '\$${n}'")
          out.print(v)
        }
        else
        {
          out.print(d.expr->val)
        }
        out.printLine(";")

      default: throw ArgErr("Unexpected node '${def.typeof}'")
    }
  }

  // map to track if a scope has already been rendered
  private Str:ScopeDef scopeMap := [:]
}