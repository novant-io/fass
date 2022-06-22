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
// Nested
//////////////////////////////////////////////////////////////////////////

  Void testNested()
  {
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
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  private Str c(Str fass)
  {
    css := Fass.compileStr(fass)
// echo(css)
    return css
  }

  private Void verifyCss(Str fass, Str css)
  {
    verifyEq(c(fass), css)
  }
}