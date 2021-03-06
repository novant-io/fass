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

    d = p("a,p {}")
    verifyChildSize(d, [,], 1)
    verifySelectors(d, [0], ["a", "p"])

    d = p(" a#foo ,  p.bar,input { } ")
    verifyChildSize(d, [,], 1)
    verifySelectors(d, [0], ["a#foo", "p.bar", "input"])

    d = p("li:first-child {}")
    verifyChildSize(d, [,], 1)
    verifySelectors(d, [0], ["li:first-child"])

    d = p("ul li:nth-child(2) {}")
    verifyChildSize(d, [,], 1)
    verifySelectors(d, [0], ["ul li:nth-child(2)"])

    d = p("div:first-child, ul li:nth-child(even) {}")
    verifyChildSize(d, [,], 1)
    verifySelectors(d, [0], ["div:first-child", "ul li:nth-child(even)"])

    d = p("h2 {}")
    verifyChildSize(d, [,], 1)
    verifySelectors(d, [0], ["h2"])

    d = p("#goo {}")
    verifyChildSize(d, [,], 1)
    verifySelectors(d, [0], ["#goo"])
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
    verifyDeclaration(d, [0,0], "color", ["#f00"])

    d = p("a { color: #f00; }")
    verifyChildSize(  d, [,], 1)
    verifySelectors(  d, [0], ["a"])
    verifyChildSize(  d, [0], 1)
    verifyDeclaration(d, [0,0], "color", ["#f00"])

    d = p("h2 {
             color: #5d2
           }")
    verifyChildSize(  d, [,], 1)
    verifySelectors(  d, [0], ["h2"])
    verifyChildSize(  d, [0], 1)
    verifyDeclaration(d, [0,0], "color", ["#5d2"])

    d = p("div {
             color: #00f
             font-weight: bold
           }")
    verifyChildSize(  d, [,], 1)
    verifySelectors(  d, [0], ["div"])
    verifyChildSize(  d, [0], 2)
    verifyDeclaration(d, [0,0], "color",       ["#00f"])
    verifyDeclaration(d, [0,1], "font-weight", ["bold"])

    d = p("div { color: #00f; font-weight: bold; }")
    verifyChildSize(  d, [,], 1)
    verifySelectors(  d, [0], ["div"])
    verifyChildSize(  d, [0], 2)
    verifyDeclaration(d, [0,0], "color",       ["#00f"])
    verifyDeclaration(d, [0,1], "font-weight", ["bold"])

    d = p("@font-face {
             font-family: 'Inter'
             font-style:  normal
             font-weight: 400
             src: url('../font/Inter-Regular.woff2') format('woff2')
           }")
    verifyChildSize(  d, [,], 1)
    verifySelectors(  d, [0], ["@font-face"])
    verifyChildSize(  d, [0], 4)
    verifyDeclaration(d, [0,0], "font-family", ["'Inter'"])
    verifyDeclaration(d, [0,1], "font-style",  ["normal"])
    verifyDeclaration(d, [0,2], "font-weight", ["400"])
    verifyDeclaration(d, [0,3], "src", ["url('../font/Inter-Regular.woff2') format('woff2')"])

    // missing newline/semicolon
    verifyErr(ParseErr#) { x := p("div { color: #00f font-weight: bold }") }
  }

//////////////////////////////////////////////////////////////////////////
// Declaration
//////////////////////////////////////////////////////////////////////////

  Void testDeclaration()
  {
    d := p("a { color: #f00 }")
    verifyDeclaration(d, [0,0], "color", ["#f00"])

    d = p("a { font-family: 'comic sans' }")
    verifyDeclaration(d, [0,0], "font-family", ["'comic sans'"])

    d = p("a { font-family: \"comic sans\" }")
    verifyDeclaration(d, [0,0], "font-family", ["\"comic sans\""])

    d = p("a { height: calc(100% - 25px) }")
    verifyDeclaration(d, [0,0], "height", ["calc(100% - 25px)"])

    d = p("a { font-family: 'Inter' }")
    verifyDeclaration(d, [0,0], "font-family", ["'Inter'"])

    d = p("a { font-family: \"Inter\" }")
    verifyDeclaration(d, [0,0], "font-family", ["\"Inter\""])

    d = p("@font-face { src: url('x.woff2') format('woff2'), url('x.woff') format('woff') }")
    verifyDeclaration(d, [0,0], "src", ["url('x.woff2') format('woff2'), url('x.woff') format('woff')"])

    d = p("@font-face {
             src: url('x.woff2') format('woff2'), url('x.woff') format('woff')
           }")
    verifyDeclaration(d, [0,0], "src", ["url('x.woff2') format('woff2'), url('x.woff') format('woff')"])

    d = p("@font-face {
             src: url('x.woff2') format('woff2'),
                  url('x.woff') format('woff')
           }")
    verifyDeclaration(d, [0,0], "src", ["url('x.woff2') format('woff2'), url('x.woff') format('woff')"])
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
    verifyChildSize(  d, [,], 1)
    verifySelectors(  d, [0], ["div"])
    verifyChildSize(  d, [0], 3)
    verifyDeclaration(d, [0,0], "color",       ["#00f"])
    verifyDeclaration(d, [0,1], "font-weight", ["bold"])
    verifySelectors(  d, [0,2], ["p"])
    verifyDeclaration(d, [0,2,0], "color", ["#333"])
  }

  Void testSelf()
  {
    d := p("div {
              color: #00f
              & { font-weight: bold }
              &:hover { background: red }
            }")
    verifyChildSize(  d, [,], 1)
    verifySelectors(  d, [0], ["div"])
    verifyChildSize(  d, [0], 3)
    verifyDeclaration(d, [0,0], "color", ["#00f"])
    verifySelectors(  d, [0,1], ["&"])
    verifyDeclaration(d, [0,1,0], "font-weight", ["bold"])
    verifySelectors(  d, [0,2], ["&:hover"])
    verifyDeclaration(d, [0,2,0], "background", ["red"])
  }

//////////////////////////////////////////////////////////////////////////
// Vars
//////////////////////////////////////////////////////////////////////////

  Void testVars()
  {
    d := p("\$foo: 10px")
    verifyVarAssign(d, [0], "foo", "10px")

    d = p("\$foo: 10px;")
    verifyVarAssign(d, [0], "foo", "10px")

    d = p(" \$foo:10px ;  \$bar : 3em")
    verifyVarAssign(d, [0], "foo", "10px")
    verifyVarAssign(d, [1], "bar", "3em")

    d = p("\$foo: 10px
           \$bar: 3em")
    verifyVarAssign(d, [0], "foo", "10px")
    verifyVarAssign(d, [1], "bar", "3em")

    d = p("\$foo: 10px
           p { padding: \$foo }")
    verifyVarAssign(d, [0], "foo", "10px")
    verifySelectors(  d, [1], ["p"])
    verifyDeclaration(d, [1,0], "padding", ["foo"])

    d = p("\$foo: 10px
           \$bar: #f00
           p {
             padding: \$foo
             span { color: \$bar }
           }")
    verifyVarAssign(d,   [0], "foo", "10px")
    verifyVarAssign(d,   [1], "bar", "#f00")
    verifySelectors(d,   [2], ["p"])
    verifyDeclaration(d, [2,0], "padding", ["foo"])
    verifySelectors(d,   [2,1], ["span"])
    verifyDeclaration(d, [2,1,0], "color", ["bar"])
  }

//////////////////////////////////////////////////////////////////////////
// Mixed Exprs
//////////////////////////////////////////////////////////////////////////

  Void testMixedExprs()
  {
    d := p("\$foo: #f00
            div { border: 1px solid \$foo }")
    verifyVarAssign(d,   [0],   "foo", "#f00")
    verifySelectors(d,   [1],   ["div"])
    verifyDeclaration(d, [1,0], "border", ["1px solid ", "foo"])

    d = p("\$x: 25px
           div { height: calc(100% - \$x) }")
    verifyVarAssign(d,   [0],   "x", "25px")
    verifySelectors(d,   [1],   ["div"])
    verifyDeclaration(d, [1,0], "height", ["calc(100% - ", "x", ")"])

// TODO FIXIT: need to maintain leading space in expr list
    // d = p("\$x: 85%
    //        \$y: 20px
    //        div { height: calc(\$x - \$y) }")
    // verifyVarAssign(d,   [0],   "x", "85%")
    // verifyVarAssign(d,   [1],   "y", "20px")
    // verifySelectors(d,   [2],   ["div"])
    // verifyDeclaration(d, [2,0], "height", ["calc(", "x", " - ", "y", ")"])
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
    verifyChildSize(d, [,], 2)
    verifySelectors(d, [0], ["h1"])
    verifySelectors(d, [1], ["h3"])

    d = p("h1 { color: #f00 } /* color: #222 */
           h2 { color: #00f /* color: #333 */ }")
    verifyChildSize(d, [,], 2)
    verifySelectors(d, [0], ["h1"])
    verifySelectors(d, [1], ["h2"])
    verifyDeclaration(d, [0,0], "color", ["#f00"])
    verifyDeclaration(d, [1,0], "color", ["#00f"])

    d = p("h1 {
             color: #f00 /* color: #222 */
             background: #00f
           }")
    verifyChildSize(d,   [,], 1)
    verifySelectors(d,   [0], ["h1"])
    verifyDeclaration(d, [0,0], "color",      ["#f00"])
    verifyDeclaration(d, [0,1], "background", ["#00f"])

    // unmatched closing
    verifyErr(ParseErr#) { x := p("/*") }
    verifyErr(ParseErr#) { x := p("/* *") }
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
    verifyChildSize(d, [,], 2)
    verifySelectors(d, [0], ["h1"])
    verifySelectors(d, [1], ["h3"])

    d = p("h1 { color: #f00 } // color: #222
           h2 { color: #00f }")
    verifyChildSize(d, [,], 2)
    verifySelectors(d, [0], ["h1"])
    verifySelectors(d, [1], ["h2"])

    d = p("h1 {
             color: #f00 // color: #222
             background: #00f
           }")
    verifyChildSize(d,   [,], 1)
    verifySelectors(d,   [0], ["h1"])
    verifyDeclaration(d, [0,0], "color",      ["#f00"])
    verifyDeclaration(d, [0,1], "background", ["#00f"])
  }

//////////////////////////////////////////////////////////////////////////
// Use
//////////////////////////////////////////////////////////////////////////

  Void testUse()
  {
    d := p("@use 'foo.fass'
            p {}")
    verifyChildSize(d, [,], 2)
    verifyAtRule(d,    [0], "@use", "'foo.fass'")
    verifySelectors(d, [1], ["p"])

    d = p("@use \"foo.fass\"
           p {}")
    verifyChildSize(d, [,], 2)
    verifyAtRule(d,    [0], "@use", "\"foo.fass\"")
    verifySelectors(d, [1], ["p"])
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

  private Void verifyAtRule(Def root, Int[] path, Str rule, Str val)
  {
    d := descend(root, path)
    verifyEq(d.typeof, AtRuleDef#)
    verifyEq(d->rule, rule)
    e := d->expr
    t := e is LiteralDef ? e->val : e->name
    verifyEq(t, val)
  }

  private Void verifySelectors(Def root, Int[] path, Str[] selectors)
  {
    d := descend(root, path)
    verifyEq(d.typeof, RulesetDef#)
    verifyEq(d->selectors, selectors)
  }

  private Void verifyDeclaration(Def root, Int[] path, Str prop, Str[] vals)
  {
    d := descend(root, path)
    verifyEq(d.typeof, DeclarationDef#)
    verifyEq(d->prop, prop)
    verifyEq(d->exprs->size, vals.size)
    vals.each |v,i|
    {
      e := d->exprs->get(i)
      t := e is LiteralDef ? e->val : e->name
      verifyEq(t, v)
    }
  }

  private Void verifyVarAssign(Def root, Int[] path, Str name, Str val)
  {
    d := descend(root, path)
    verifyEq(d.typeof, VarAssignDef#)
    verifyEq(d->var->name, name)
    verifyEq(d->expr->val, val)
  }

  private Def descend(Def root, Int[] path)
  {
    cur := root
    path.each |i| { cur = cur.children[i] }
    return cur
  }
}