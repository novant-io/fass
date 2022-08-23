//
// Copyright (c) 2022, Novant LLC
// Licensed under the MIT License
//
// History:
//   20 Jun 2022  Andy Frank  Creation
//

@Js class ParserTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testEmpty()
  {
    // empty content is ok
    d := p("")
    verifyEq(d.children.size, 0)
  }

  Void testBasics()
  {
    d := p("foo := #f00")
    verifyAssign(d, [0], "foo", ["#f00"])

    d = p("div {}")
    verifyEq(d.children.size, 1)
    verifyRuleset(d, [0], ["div"])

    d = p("div { color: green }")
    verifyRuleset(d, [0],   ["div"])
    verifyDeclare(d, [0,0], "color", ["green"])

    d = p("div { color:green }")
    verifyRuleset(d, [0],   ["div"])
    verifyDeclare(d, [0,0], "color", ["green"])

    d = p("@using _vars.fass")
    verifyUsing(d, [0], "_vars.fass")
  }

//////////////////////////////////////////////////////////////////////////
// Assign
//////////////////////////////////////////////////////////////////////////

  Void testAssign()
  {
    d := p("foo := #f00")
    verifyAssign(d, [0], "foo", ["#f00"])

    d = p("foo := 1px solid #f00")
    verifyAssign(d, [0], "foo", ["1px", "solid", "#f00"])

    d = p("foo := 'Comic Sans'")
    verifyAssign(d, [0], "foo", ["'Comic Sans'"])

    d = p("foo := #f00; bar := 10px")
    verifyAssign(d, [0], "foo", ["#f00"])
    verifyAssign(d, [1], "bar", ["10px"])
  }

//////////////////////////////////////////////////////////////////////////
// Selectors
//////////////////////////////////////////////////////////////////////////

  Void testSelectors()
  {
    d := p("a {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["a"])

    d = p("   a    {   }  ")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["a"])

    d = p("h1 p {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["h1 p"])

    d = p(" h3.some-class   div#foo  #bar { }  ")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["h3.some-class div#foo #bar"])

    d = p("a,p {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["a", "p"])

    d = p(" a#foo ,  p.bar,input { } ")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["a#foo", "p.bar", "input"])

    d = p("li:first-child {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["li:first-child"])

    d = p("ul li:nth-child(2) {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["ul li:nth-child(2)"])

    d = p("div:first-child, ul li:nth-child(even) {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["div:first-child", "ul li:nth-child(even)"])

    d = p("h2 {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["h2"])

    d = p("#goo {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["#goo"])

    d = p("* {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["*"])

    d = p("*:nth-child(2) {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["*:nth-child(2)"])

    d = p("li > span {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["li > span"])

    // test sub-tokenize
    d = p("li:hover p span {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["li:hover p span"])

    // test sub-tokenize
    d = p("ul li:hover span {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["ul li:hover span"])

    d = p("div,
           p,
           a {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["div", "p", "a"])

    d = p("div,
           // h3
           p,
           a {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["div", "p", "a"])

    d = p("div,

           p,

           a {}")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["div", "p", "a"])
  }

//////////////////////////////////////////////////////////////////////////
// Ruleset
//////////////////////////////////////////////////////////////////////////

  Void testRuleset()
  {
    d := p("a { color: #f00 }")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["a"])
    verifyKidSize(d, [0], 1)
    verifyDeclare(d, [0,0], "color", ["#f00"])

    d = p("a { color: #f00; }")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["a"])
    verifyKidSize(d, [0], 1)
    verifyDeclare(d, [0,0], "color", ["#f00"])

    d = p("h2 {
             color: #5d2
           }")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["h2"])
    verifyKidSize(d, [0], 1)
    verifyDeclare(d, [0,0], "color", ["#5d2"])

    d = p("div {
             color: #00f
             font-weight: bold
           }")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["div"])
    verifyKidSize(d, [0], 2)
    verifyDeclare(d, [0,0], "color",       ["#00f"])
    verifyDeclare(d, [0,1], "font-weight", ["bold"])

    d = p("div { color: #00f; font-weight: bold; }")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["div"])
    verifyKidSize(d, [0], 2)
    verifyDeclare(d, [0,0], "color",       ["#00f"])
    verifyDeclare(d, [0,1], "font-weight", ["bold"])

    d = p("@font-face {
             font-family: 'Inter'
             font-style:  normal
             font-weight: 400
             src: url('../font/Inter-Regular.woff2') format('woff2')
           }")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["@font-face"])
    verifyKidSize(d, [0], 4)
    verifyDeclare(d, [0,0], "font-family", ["'Inter'"])
    verifyDeclare(d, [0,1], "font-style",  ["normal"])
    verifyDeclare(d, [0,2], "font-weight", ["400"])
    verifyDeclare(d, [0,3], "src", ["url('../font/Inter-Regular.woff2')", "format('woff2')"])

    // missing newline/semicolon
    verifyErr(FassCompileErr#) { x := p("div { color: #00f font-weight: bold }") }
  }

//////////////////////////////////////////////////////////////////////////
// Declarations
//////////////////////////////////////////////////////////////////////////

  Void testDeclare()
  {
    d := p("a { color: #f00 }")
    verifyDeclare(d, [0,0], "color", ["#f00"])

    d = p("a{color:#f00}")
    verifyDeclare(d, [0,0], "color", ["#f00"])

    d = p("a{color:#f00;}")
    verifyDeclare(d, [0,0], "color", ["#f00"])

    d = p("a { border-left: 1px solid #f00 }")
    verifyDeclare(d, [0,0], "border-left", ["1px", "solid", "#f00"])

    d = p("a { font-family: 'comic sans' }")
    verifyDeclare(d, [0,0], "font-family", ["'comic sans'"])

    d = p("a { font-family: \"comic sans\" }")
    verifyDeclare(d, [0,0], "font-family", ["\"comic sans\""])

    d = p("a { height: calc(100% - 25px) }")
    verifyDeclare(d, [0,0], "height", ["calc(100%", "-", "25px)"])

    d = p("a { font-family: 'Inter' }")
    verifyDeclare(d, [0,0], "font-family", ["'Inter'"])

    d = p("a { font-family: \"Inter\" }")
    verifyDeclare(d, [0,0], "font-family", ["\"Inter\""])

    d = p("@font-face { src: url('x.woff2') format('woff2'), url('x.woff') format('woff') }")
    verifyDeclare(d, [0,0], "src", ["url('x.woff2')", "format('woff2')", ",", "url('x.woff')", "format('woff')"])

    d = p("@font-face {
             src: url('x.woff2') format('woff2'), url('x.woff') format('woff')
           }")
    verifyDeclare(d, [0,0], "src", ["url('x.woff2')", "format('woff2')", ",", "url('x.woff')", "format('woff')"])

    d = p("@font-face {
             src: url('x.woff2') format('woff2'),
                  url('x.woff') format('woff')
           }")
    verifyDeclare(d, [0,0], "src", ["url('x.woff2')", "format('woff2')", ",", "url('x.woff')", "format('woff')"])

    d = p("@font-face {
             src: url('x.woff2') format('woff2'),

                  url('x.woff') format('woff')
           }")
    verifyDeclare(d, [0,0], "src", ["url('x.woff2')", "format('woff2')", ",", "url('x.woff')", "format('woff')"])


    d = p("@font-face {
             src: url('x.woff2') format('woff2'),
                  // xxx
                  url('x.woff') format('woff')
           }")
    verifyDeclare(d, [0,0], "src", ["url('x.woff2')", "format('woff2')", ",", "url('x.woff')", "format('woff')"])
  }

//////////////////////////////////////////////////////////////////////////
// Nested
//////////////////////////////////////////////////////////////////////////

  Void testNested()
  {
    d := p("div {
              color: #00f
              font-weight: bold
              p {
                color: #333
              }
            }")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["div"])
    verifyKidSize(d, [0], 3)
    verifyDeclare(d, [0,0], "color",       ["#00f"])
    verifyDeclare(d, [0,1], "font-weight", ["bold"])
    verifyRuleset(d, [0,2], ["p"])
    verifyDeclare(d, [0,2,0], "color", ["#333"])
  }

  Void testSelf()
  {
    d := p("div {
              color: #00f
              & { font-weight: bold }
              &:hover { background: red }
            }")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["div"])
    verifyKidSize(d, [0], 3)
    verifyDeclare(d, [0,0], "color", ["#00f"])
    verifyRuleset(d, [0,1], ["&"])
    verifyDeclare(d, [0,1,0], "font-weight", ["bold"])
    verifyRuleset(d, [0,2], ["&:hover"])
    verifyDeclare(d, [0,2,0], "background", ["red"])
  }

//////////////////////////////////////////////////////////////////////////
// Vars
//////////////////////////////////////////////////////////////////////////

  Void testVars()
  {
    d := p("p { color: \$foo }")
    verifyRuleset(d, [0],   ["p"])
    verifyDeclare(d, [0,0], "color", ["foo"])

    d = p("foo := #333
           bar := 1px solid \$foo")
    verifyAssign(d, [0], "foo", ["#333"])
    verifyAssign(d, [1], "bar", ["1px", "solid", "foo"])

    d = p("foo := 10px
           bar := #f00
           p {
             padding: \$foo
             span { color: \$bar }
           }")
    verifyAssign( d, [0], "foo", ["10px"])
    verifyAssign( d, [1], "bar", ["#f00"])
    verifyRuleset(d, [2], ["p"])
    verifyDeclare(d, [2,0], "padding", ["foo"])
    verifyRuleset(d, [2,1], ["span"])
    verifyDeclare(d, [2,1,0], "color", ["bar"])
  }

//////////////////////////////////////////////////////////////////////////
// Mixed Exprs
//////////////////////////////////////////////////////////////////////////

  Void testMixedExprs()
  {
    d := p("foo := #f00
            div { border: 1px solid \$foo }")
    verifyAssign( d, [0],   "foo", ["#f00"])
    verifyRuleset(d, [1],   ["div"])
    verifyDeclare(d, [1,0], "border", ["1px", "solid", "foo"])

    d = p("x := 25px
           div { height: calc(100% - \${x}) }")
    verifyAssign( d, [0],   "x", ["25px"])
    verifyRuleset(d, [1],   ["div"])
    verifyDeclare(d, [1,0], "height", ["calc(100%", "-", "x", ")"])

    d = p("x := 85%
           y := 20px
           div { height: calc(\${x} - \${y}) }")
    verifyAssign(d,  [0],   "x", ["85%"])
    verifyAssign(d,  [1],   "y", ["20px"])
    verifyRuleset(d, [2],   ["div"])
    verifyDeclare(d, [2,0], "height", ["calc(", "x", "-", "y", ")"])
  }


//////////////////////////////////////////////////////////////////////////
// Comments
//////////////////////////////////////////////////////////////////////////

  Void testBlockComments()
  {
    d := p("/**/")
    verifyEq(d.children.size, 0)

    d = p("/**//**/")
    verifyEq(d.children.size, 0)

    d = p("/**/
           /**/")
    verifyEq(d.children.size, 0)

    d = p("/* cool */")
    verifyEq(d.children.size, 0)

    d = p("/*
           h1 { color: #f00 }
           */")
    verifyEq(d.children.size, 0)

    d = p("h1 { color: #f00 }
           /*
           h2 { color: #0f0 }
           */
           h3 { color: #00f }")
    verifyKidSize(d, [,], 2)
    verifyRuleset(d, [0], ["h1"])
    verifyRuleset(d, [1], ["h3"])

    d = p("h1 { color: #f00 } /* color: #222 */
           h2 { color: #00f /* color: #333 */ }")
    verifyKidSize(d, [,], 2)
    verifyRuleset(d, [0], ["h1"])
    verifyRuleset(d, [1], ["h2"])
    verifyDeclare(d, [0,0], "color", ["#f00"])
    verifyDeclare(d, [1,0], "color", ["#00f"])

    d = p("h1 {
             color: #f00 /* color: #222 */
             background: #00f
           }")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["h1"])
    verifyDeclare(d, [0,0], "color",      ["#f00"])
    verifyDeclare(d, [0,1], "background", ["#00f"])

    // unmatched closing
    verifyErr(FassCompileErr#) { x := p("/*") }
    verifyErr(FassCompileErr#) { x := p("/* *") }
  }

  Void testLineComments()
  {
    d := p("//")
    verifyEq(d.children.size, 0)

    d = p("//
           //")
    verifyEq(d.children.size, 0)

    d = p("// cool")
    verifyEq(d.children.size, 0)

    d = p("// h1 { color: #f00 }")
    verifyEq(d.children.size, 0)

    d = p("h1 { color: #f00 }
           // h2 { color: #0f0 }
           h3 { color: #00f }")
    verifyKidSize(d, [,], 2)
    verifyRuleset(d, [0], ["h1"])
    verifyRuleset(d, [1], ["h3"])

    d = p("h1 { color: #f00 } // color: #222
           h2 { color: #00f }")
    verifyKidSize(d, [,], 2)
    verifyRuleset(d, [0], ["h1"])
    verifyRuleset(d, [1], ["h2"])

    d = p("h1 {
             color: #f00 // color: #222
             background: #00f
           }")
    verifyKidSize(d, [,], 1)
    verifyRuleset(d, [0], ["h1"])
    verifyDeclare(d, [0,0], "color",      ["#f00"])
    verifyDeclare(d, [0,1], "background", ["#00f"])
  }

//////////////////////////////////////////////////////////////////////////
// Use
//////////////////////////////////////////////////////////////////////////

  Void testUse()
  {
    // variations
    x := [
      "@using 'foo.fass'",
      "@using \"foo.fass\"",
      "@using foo.fass",
      "@using foo",
      "@using 'foo'",
      "@using \"foo\"",
    ]
    x.each |f| { verifyUsing(p(f), [0], "foo.fass") }

    // unmatched quotes
    verifyErr(FassCompileErr#) { p("@using 'foo.fass")   }
    verifyErr(FassCompileErr#) { p("@using \"foo.fass")  }
    verifyErr(FassCompileErr#) { p("@using 'foo.fass\"") }
    verifyErr(FassCompileErr#) { p("@using \"foo.fass'") }
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  private Def p(Str text)
  {
    buf := Buf().print(text).flip
    def := Parser("test", buf.in).parse
//    def.dump(Env.cur.out, 0)
    return def
  }

  private Void verifyKidSize(Def root, Int[] path, Int test)
  {
    d := descend(root, path)
    verifyEq(d.children.size, test)
  }

  private Void verifyUsing(Def root, Int[] path, Str ref)
  {
    d := descend(root, path)
    verifyEq(d.typeof, UsingDef#)
    verifyEq(d->ref, ref)
  }

  private Void verifyAssign(Def root, Int[] path, Str name, Str[] vals)
  {
    d := descend(root, path)
    verifyEq(d.typeof, AssignDef#)
    verifyEq(d->name, name)
    verifyExpr(d->expr, vals)
  }

  private Void verifyRuleset(Def root, Int[] path, Str[] selectors)
  {
    d := descend(root, path)
    verifyEq(d.typeof, RulesetDef#)
    verifyEq(d->selectors, selectors)
  }

  private Void verifyDeclare(Def root, Int[] path, Str prop, Str[] vals)
  {
    d := descend(root, path)
    verifyEq(d.typeof, DeclareDef#)
    verifyEq(d->prop, prop)
    verifyExpr(d->expr, vals)
  }

  private Void verifyExpr(ExprDef expr, Str[] vals)
  {
    verifyEq(expr.defs.size, vals.size)
    expr.defs.each |d,i|
    {
      v := vals[i]
      if (d is LiteralDef) verifyEq(d->val, v)
      else if (d is VarDef) verifyEq(d->name, v)
      else fail()
    }
  }

  private Def descend(Def root, Int[] path)
  {
    cur := root
    path.each |i| { cur = cur.children[i] }
    return cur
  }
}