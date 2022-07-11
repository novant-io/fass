//
// Copyright (c) 2022, Novant LLC
// All Rights Reserved
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
      "a.foo {
         color: #fff;
       }
       p.bar {
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

  Void testDeclarations()
  {
    verifyCss(
      "@font-face {
         src: url('x.woff2') format('woff2'),
              url('x.woff') format('woff')
       }",
      "@font-face {
         src: url('x.woff2') format('woff2'), url('x.woff') format('woff');
       }
       ")
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
     "div {
        color: #00f;
        font-weight: bold;
      }
      div p {
        color: #333;
      }
      div ul {
        color: #333;
      }
      h3 {
        color: #00f;
        font-weight: bold;
      }
      h3 p {
        color: #333;
      }
      h3 ul {
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

    // cannot use self at root
    verifyErr(Err#) { Fass.compileStr("& { color: red }") }
  }

/////////////////////////////////////////////////////////////////////////
// Vars
//////////////////////////////////////////////////////////////////////////

  Void testVars()
  {
    verifyCss(
      "\$foo: 10px",
      "")

    verifyCss(
      "\$foo: 10px
         p { padding: \$foo }",
      "p {
         padding: 10px;
       }
       ")

    verifyCss(
      "\$foo: 10px
       \$bar: #f00
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
// Use
//////////////////////////////////////////////////////////////////////////

  private Void testUse()
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
      "@use '_a.fass'
       h1 { color: #333 }",
      "p {
         color: #777;
       }
       h1 {
         color: #333;
       }
       ", u)

    verifyCss(
      "@use '_a.fass'
       @use '_b.fass'
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
      Fass.compile(fass.in, buf.out, onUse)
      css = buf.toStr
    }
// echo(css)
    return css
  }

  private Void verifyCss(Str fass, Str css, Func? onUse := null)
  {
    verifyEq(c(fass, onUse), css)
  }
}