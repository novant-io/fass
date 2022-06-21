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
    root.children.each |d| { compileDef(d, out) }
  }

  ** Compile Def node to CSS.
  private Void compileDef(Def def, OutStream out)
  {
    switch (def.typeof)
    {
      case RulesetDef#:
        RulesetDef r := def
        out.print(r.selectors.join(" ")).printLine(" {")
        r.children.each |k| { compileDef(k, out) }
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