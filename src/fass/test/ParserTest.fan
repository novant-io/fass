//
// Copyright (c) 2022, Novant LLC
// All Rights Reserved
//
// History:
//   20 Jun 2022  Andy Frank  Creation
//

@Js class ParserTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Empty
//////////////////////////////////////////////////////////////////////////

  Void testEmpty()
  {
    // empty content is ok
    d := p("")
    verifyEq(d.children.size, 0)
  }

//////////////////////////////////////////////////////////////////////////
// Selectors
//////////////////////////////////////////////////////////////////////////

  Void testSelectors()
  {
    d := p("a {}")
    verifyChildSize(d, [,], 1)
    verifySelectors(d, [0], ["a"])

    d = p("   a    {   }  ")
    verifyChildSize(d, [,], 1)
    verifySelectors(d, [0], ["a"])

    d = p("h1 p {}")
    verifyChildSize(d, [,], 1)
    verifySelectors(d, [0], ["h1 p"])

    d = p(" h3.some-class   div#foo  #bar { }  ")
    verifyChildSize(d, [,], 1)
    verifySelectors(d, [0], ["h3.some-class div#foo #bar"])
  }

//////////////////////////////////////////////////////////////////////////
// Ruleset
//////////////////////////////////////////////////////////////////////////

  Void testRuleset()
  {
    d := p("a { color: #f00 }")
    verifyChildSize(  d, [,], 1)
    verifySelectors(  d, [0], ["a"])
    verifyChildSize(  d, [0], 1)
    verifyDeclaration(d, [0,0], "color", "#f00")

    d = p("a { color: #f00; }")
    verifyChildSize(  d, [,], 1)
    verifySelectors(  d, [0], ["a"])
    verifyChildSize(  d, [0], 1)
    verifyDeclaration(d, [0,0], "color", "#f00")

    d = p("h2 {
             color: #5d2
           }")
    verifyChildSize(  d, [,], 1)
    verifySelectors(  d, [0], ["h2"])
    verifyChildSize(  d, [0], 1)
    verifyDeclaration(d, [0,0], "color", "#5d2")

    d = p("div {
             color: #00f
             font-weight: bold
           }")
    verifyChildSize(  d, [,], 1)
    verifySelectors(  d, [0], ["div"])
    verifyChildSize(  d, [0], 2)
    verifyDeclaration(d, [0,0], "color",       "#00f")
    verifyDeclaration(d, [0,1], "font-weight", "bold")

    d = p("div { color: #00f; font-weight: bold; }")
    verifyChildSize(  d, [,], 1)
    verifySelectors(  d, [0], ["div"])
    verifyChildSize(  d, [0], 2)
    verifyDeclaration(d, [0,0], "color",       "#00f")
    verifyDeclaration(d, [0,1], "font-weight", "bold")

    // missing newline/semicolon
    verifyErr(ParseErr#) { x := p("div { color: #00f font-weight: bold }") }
  }

//////////////////////////////////////////////////////////////////////////
// Nested
//////////////////////////////////////////////////////////////////////////

  Void testNested()
  {
    // TODO
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  private Def p(Str text)
  {
    buf := Buf().print(text).flip
    def := Parser(buf.in).parse
//    def.dump(Env.cur.out, 0)
    return def
  }

  private Void verifyChildSize(Def root, Int[] path, Int test)
  {
    d := descend(root, path)
    verifyEq(d.children.size, test)
  }

  private Void verifySelectors(Def root, Int[] path, Str[] selectors)
  {
    d := descend(root, path)
    verifyEq(d.typeof, RulesetDef#)
    verifyEq(d->selectors, selectors)
  }

  private Void verifyDeclaration(Def root, Int[] path, Str prop, Str val)
  {
    d := descend(root, path)
    verifyEq(d.typeof, DeclarationDef#)
    verifyEq(d->prop, prop)
    verifyEq(d->val,  val)
  }

  private Def descend(Def root, Int[] path)
  {
    cur := root
    path.each |i| { cur = cur.children[i] }
    return cur
  }
}