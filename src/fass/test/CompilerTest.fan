//
// Copyright (c) 2022, Novant LLC
// Licensed under the MIT License
//
// History:
//   21 Jun 2022  Andy Frank  Creation
//

@Js class CompilerTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Empty
//////////////////////////////////////////////////////////////////////////

  Void testEmpty()
  {
    // empty content is ok
    verifyCss("", "")
  }

  Void testBasics()
  {
    verifyCss(
      "p { }",
      "")

    verifyCss(
      "p { color: #fff }",
      "p {
         color: #fff;
       }
       ")

    verifyCss(
      "  h2   div#foo p   {
         color:    #fff
            font-weight:  bold
       }",
      "h2 div#foo p {
         color: #fff;
         font-weight: bold;
       }
       ")

    verifyCss(
      "a.foo, p.bar { color: #fff }",
      "a.foo, p.bar {
         color: #fff;
       }
       ")
  }

//////////////////////////////////////////////////////////////////////////
// Selectors
//////////////////////////////////////////////////////////////////////////

  Void testSelectors()
  {
    verifyCss(
      "ul li:nth-child(2) { color: #567 }",
      "ul li:nth-child(2) {
         color: #567;
       }
       ")
  }

//////////////////////////////////////////////////////////////////////////
// Declarations
//////////////////////////////////////////////////////////////////////////

  Void testDeclare()
  {
    verifyCss(
      "div { color: #567 }",
      "div {
         color: #567;
       }
       ")

    verifyCss(
      "div { border: 1px solid #f00 }",
      "div {
         border: 1px solid #f00;
       }
       ")

    verifyCss(
      "div { height: calc(100% - 25px) }",
      "div {
         height: calc(100% - 25px);
       }
       ")

// TODO FIXIT: collapse whitespace?
    verifyCss(
      "div { color: hsl(212, 73%, 59%) }",
      "div {
         color: hsl(212 , 73% , 59%);
       }
       ")

    verifyCss(
      "@font-face {
         src: url('x.woff2') format('woff2'),
              url('x.woff') format('woff')
       }",
      "@font-face {
         src: url('x.woff2') format('woff2') , url('x.woff') format('woff');
       }
       ")

// TODO FIXIT
    // // prop declare outside ruleset
    // verifyErr(FassCompilerErr#) { "font-weight: bold" }
  }

//////////////////////////////////////////////////////////////////////////
// Nested
//////////////////////////////////////////////////////////////////////////

  Void testNested()
  {
    verifyCss(
     "div {
        p {
          span {
            color: #123
          }
        }
      }",
     "div p span {
        color: #123;
      }
      ")

    verifyCss(
     "div { p { span { color: #123 }}}",
     "div p span {
        color: #123;
      }
      ")

    verifyCss(
     "div {
        color: #00f
        font-weight: bold
        p {
          color: #333
        }
      }",
     "div {
        color: #00f;
        font-weight: bold;
      }
      div p {
        color: #333;
      }
      ")

    verifyCss(
     "div,h3 {
        color: #00f
        font-weight: bold
        p,ul {
          color: #333
        }
      }",
     "div, h3 {
        color: #00f;
        font-weight: bold;
      }
      div p, div ul, h3 p, h3 ul {
        color: #333;
      }
      ")

    verifyCss(
     "div {
        color: #00f
        p {
          opacity: 0.5
          span {
            display: block
          }
        }
      }",
     "div {
        color: #00f;
      }
      div p {
        opacity: 0.5;
      }
      div p span {
        display: block;
      }
      ")
  }

//////////////////////////////////////////////////////////////////////////
// Self
//////////////////////////////////////////////////////////////////////////

  Void testSelf()
  {
    verifyCss(
      "div.foo {
         color: #00f
         & { font-weight: bold }
         &:hover { background: red }
       }",
      "div.foo {
         color: #00f;
       }
       div.foo {
         font-weight: bold;
       }
       div.foo:hover {
         background: red;
       }
       ")

    verifyCss(
      "div.foo {
         h1 {
           span.bar {
             &:hover { color: green }
           }
         }
         & p { padding: 1em }
       }",
       "div.foo h1 span.bar:hover {
          color: green;
        }
        div.foo p {
          padding: 1em;
        }
        ")

    verifyCss(
      "div.foo {
         h1 {
           span.bar {
             &:hover { color: green }
           }
         }
         &:hover p { padding: 1em }
       }",
       "div.foo h1 span.bar:hover {
          color: green;
        }
        div.foo:hover p {
          padding: 1em;
        }
        ")

    // cannot use self at root
    verifyErr(FassCompileErr#) { Fass.compileStr("& { color: red }") }
  }

/////////////////////////////////////////////////////////////////////////
// Vars
//////////////////////////////////////////////////////////////////////////

  Void testVars()
  {
    verifyCss(
      "foo := 10px",
      "")

    verifyCss(
      "foo := 10px
       p { padding: \$foo }",
      "p {
         padding: 10px;
       }
       ")

    verifyCss(
      "foo := 10px
       bar := #f00
         p {
           padding: \$foo
           span { color: \$bar }
         }",
      "p {
         padding: 10px;
       }
       p span {
         color: #f00;
       }
       ")

   verifyCss(
      "foo := hsl(212, 73%, 59%)
       p { color: \$foo }",
      "p {
         color: hsl(212 , 73% , 59%);
       }
       ")

   verifyCss(
      "width := 480px
       @media only screen (max-width: \$width) { color: #f00 }",
      "@media only screen (max-width: 480px ) {
         color: #f00;
       }
       ")

    // var not found defined
    verifyErr(FassCompileErr#) {
      x := c("foo := 10px
              p { color: \$bar }")
    }

    // // var already defined
    // verifyErr(FassCompileErr#) {
    //   x := c("foo := 10px
    //           foo := #f00")
    // }
  }

//////////////////////////////////////////////////////////////////////////
// Comments
//////////////////////////////////////////////////////////////////////////

  Void testComments()
  {
    verifyCss(
      "h1 { color: #f00 }
       /*
       h2 { color: #0f0 }
       */
       h3 { color: #00f }",
      "h1 {
         color: #f00;
       }
       h3 {
         color: #00f;
       }
       ")

    verifyCss(
      "h1 { color: #f00 }
       // h2 { color: #0f0 }
       h3 { color: #00f }",
      "h1 {
         color: #f00;
       }
       h3 {
         color: #00f;
       }
       ")
  }

//////////////////////////////////////////////////////////////////////////
// Mixed Exprs
//////////////////////////////////////////////////////////////////////////

  Void testMixedExprs()
  {
    verifyCss(
     "foo := #f00
      div { border: 1px solid \$foo }",
     "div {
        border: 1px solid #f00;
      }
      ")

    verifyCss(
     "x := 25px
      div { height: calc(100% - \${x}) }",
     "div {
        height: calc(100% - 25px );
      }
      ")
    verifyCss(
     "x := 85%
      y := 20px
      div { height: calc(\${x} - \${y}) }",
     "div {
        height: calc( 85% - 20px );
      }
      ")
  }

//////////////////////////////////////////////////////////////////////////
// Use
//////////////////////////////////////////////////////////////////////////

  Void testUseSimple()
  {
    a := "p { color:#777 }"
    b := "ul { margin: 2em 0 }"
    u := |n->InStream|
    {
      if (n == "_a.fass") return a.in
      if (n == "_b.fass") return b.in
      throw Err("Not found '${n}'")
    }

    verifyCss(
      "@using _a
       h1 { color: #333 }",
      "p {
         color: #777;
       }
       h1 {
         color: #333;
       }
       ", u)

    verifyCss(
      "@using _a
       @using _b
       h1 { color: #333 }",
      "p {
         color: #777;
       }
       ul {
         margin: 2em 0;
       }
       h1 {
         color: #333;
       }
       ", u)
  }

  Void testUseVar()
  {
    a := "a1 := #777
          p { color: \${a1} }"
    b := "b1 := 2em 0
          ul { margin: \${b1} }"
    u := |n->InStream|
    {
      if (n == "_a.fass") return a.in
      if (n == "_b.fass") return b.in
      throw Err("Not found '${n}'")
    }

    verifyCss(
      "@using _a
       h1 {
        color: #333
        border-color: #444
       }
       ",
      "p {
         color: #777;
       }
       h1 {
         color: #333;
         border-color: #444;
       }
       ", u)

    verifyCss(
      "@using _a
       h1 {
        color: #333
        border-color: \${a1}
       }
       ",
      "p {
         color: #777;
       }
       h1 {
         color: #333;
         border-color: #777;
       }
       ", u)

    verifyCss(
      "@using _a
       @using _b
       h1 {
         color: #333
         border-color: \${a1}
         padding: \${b1}
       }",
      "p {
         color: #777;
       }
       ul {
         margin: 2em 0;
       }
       h1 {
         color: #333;
         border-color: #777;
         padding: 2em 0;
       }
       ", u)
  }

  Void testUseRecursive()
  {
    a := "a1 := #777
          a2 := 2em 0
          p { color: \$a1 }"
    b := "@using '_a.fass'
          ul { margin: \$a2 }"
    u := |n->InStream|
    {
      if (n == "_a.fass") return a.in
      if (n == "_b.fass") return b.in
      throw Err("Not found '${n}'")
    }

    verifyCss(
      "@using '_a.fass'
       @using '_b.fass'
       h1 {
        color: #333
        border-color: \$a1
       }
       ",
      "p {
         color: #777;
       }
       ul {
         margin: 2em 0;
       }
       h1 {
         color: #333;
         border-color: #777;
       }
       ", u)
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  private Str c(Str fass, Func? onUse := null)
  {
    css := ""
    if (onUse == null)
    {
      css = Fass.compileStr(fass)
    }
    else
    {
      buf := StrBuf()
      Fass.compile("test", fass.in, buf.out, onUse)
      css = buf.toStr
    }
// echo("-------------------------------")
// echo("# FASS >")
// echo("#-------")
// echo(fass)
// echo("# CSS >")
// echo("#------")
// echo(css)
    return css
  }

  private Void verifyCss(Str fass, Str css, Func? onUse := null)
  {
    verifyEq(c(fass, onUse), css)
  }
}