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
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  private Str c(Str fass)
  {
    css := Fass.compileStr(fass)
//echo(css)
    return css
  }

  private Void verifyCss(Str fass, Str css)
  {
    verifyEq(c(fass), css)
  }
}