//
// Copyright (c) 2022, Novant LLC
// Licensed under the MIT License
//
// History:
//   14 Jul 2022  Andy Frank  Creation
//

@Js class TokenizerTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
  {
    v := t("@using _vars.fass")
    verifyEq(v.size, 2)
    verifyToken(v[0], TokenType.term, "@using")
    verifyToken(v[1], TokenType.term, "_vars.fass")

    v = t("foo := #f00")
    verifyEq(v.size, 3)
    verifyToken(v[0], TokenType.term,   "foo")
    verifyToken(v[1], TokenType.assign, ":=")
    verifyToken(v[2], TokenType.term,   "#f00")

    v = t("div { color:green }")
    verifyEq(v.size, 4)
    verifyToken(v[0], TokenType.term,       "div")
    verifyToken(v[1], TokenType.openBrace,  "{")
    verifyToken(v[2], TokenType.term,       "color:green")
    verifyToken(v[3], TokenType.closeBrace, "}")

    v = t("div { color: green }")
    verifyEq(v.size, 5)
    verifyToken(v[0], TokenType.term,       "div")
    verifyToken(v[1], TokenType.openBrace,  "{")
    verifyToken(v[2], TokenType.term,       "color:")
    verifyToken(v[3], TokenType.term,       "green")
    verifyToken(v[4], TokenType.closeBrace, "}")

    v = t("p:nth-child(2) { padding : 10px }")
    verifyEq(v.size, 6)
    verifyToken(v[0], TokenType.term,       "p:nth-child(2)")
    verifyToken(v[1], TokenType.openBrace,  "{")
    verifyToken(v[2], TokenType.term,       "padding")
    verifyToken(v[3], TokenType.colon,      ":")
    verifyToken(v[4], TokenType.term,       "10px")
    verifyToken(v[5], TokenType.closeBrace, "}")

    v = t("div { color: \$foo }")
    verifyEq(v.size, 5)
    verifyToken(v[0], TokenType.term,       "div")
    verifyToken(v[1], TokenType.openBrace,  "{")
    verifyToken(v[2], TokenType.term,       "color:")
    verifyToken(v[3], TokenType.var,        "foo")
    verifyToken(v[4], TokenType.closeBrace, "}")

    v = t("div, p { color: #f00 }")
    verifyEq(v.size, 7)
    verifyToken(v[0], TokenType.term,       "div")
    verifyToken(v[1], TokenType.comma,      ",")
    verifyToken(v[2], TokenType.term,       "p")
    verifyToken(v[3], TokenType.openBrace,  "{")
    verifyToken(v[4], TokenType.term,       "color:")
    verifyToken(v[5], TokenType.term,       "#f00")
    verifyToken(v[6], TokenType.closeBrace, "}")
  }

//////////////////////////////////////////////////////////////////////////
// Quotes
//////////////////////////////////////////////////////////////////////////

  Void testQuotes()
  {
    v := t("span { font-family: 'Comic Sans' }")
    verifyEq(v.size, 5)
    verifyToken(v[0], TokenType.term,       "span")
    verifyToken(v[1], TokenType.openBrace,  "{")
    verifyToken(v[2], TokenType.term,       "font-family:")
    verifyToken(v[3], TokenType.term,       "'Comic Sans'")
    verifyToken(v[4], TokenType.closeBrace, "}")

    v = t("span { font-family: \"Comic Sans\" }")
    verifyEq(v.size, 5)
    verifyToken(v[0], TokenType.term,       "span")
    verifyToken(v[1], TokenType.openBrace,  "{")
    verifyToken(v[2], TokenType.term,       "font-family:")
    verifyToken(v[3], TokenType.term,       "\"Comic Sans\"")
    verifyToken(v[4], TokenType.closeBrace, "}")
  }

//////////////////////////////////////////////////////////////////////////
// Vars
//////////////////////////////////////////////////////////////////////////

  Void testVars()
  {
    v := t("a { color: \$foo }")
    verifyEq(v.size, 5)
    verifyToken(v[0], TokenType.term,       "a")
    verifyToken(v[1], TokenType.openBrace,  "{")
    verifyToken(v[2], TokenType.term,       "color:")
    verifyToken(v[3], TokenType.var,        "foo")
    verifyToken(v[4], TokenType.closeBrace, "}")

    v = t("a { color: \${foo} }")
    verifyEq(v.size, 5)
    verifyToken(v[0], TokenType.term,       "a")
    verifyToken(v[1], TokenType.openBrace,  "{")
    verifyToken(v[2], TokenType.term,       "color:")
    verifyToken(v[3], TokenType.var,        "foo")
    verifyToken(v[4], TokenType.closeBrace, "}")

    v = t("a { foo: 1px \$x ('foo') \$y }")
    verifyEq(v.size, 8)
    verifyToken(v[0], TokenType.term,       "a")
    verifyToken(v[1], TokenType.openBrace,  "{")
    verifyToken(v[2], TokenType.term,       "foo:")
    verifyToken(v[3], TokenType.term,       "1px")
    verifyToken(v[4], TokenType.var,        "x")
    verifyToken(v[5], TokenType.term,       "('foo')")
    verifyToken(v[6], TokenType.var,        "y")
    verifyToken(v[7], TokenType.closeBrace, "}")

    v = t("a { foo: bar-\${foo}-zar }")
    verifyEq(v.size, 7)
    verifyToken(v[0], TokenType.term,       "a")
    verifyToken(v[1], TokenType.openBrace,  "{")
    verifyToken(v[2], TokenType.term,       "foo:")
    verifyToken(v[3], TokenType.term,       "bar-")
    verifyToken(v[4], TokenType.var,        "foo")
    verifyToken(v[5], TokenType.term,       "-zar")
    verifyToken(v[6], TokenType.closeBrace, "}")

    v = t("a { foo: url('/foo/\${bar}.svg') }")
    verifyEq(v.size, 7)
    verifyToken(v[0], TokenType.term,       "a")
    verifyToken(v[1], TokenType.openBrace,  "{")
    verifyToken(v[2], TokenType.term,       "foo:")
    verifyToken(v[3], TokenType.term,       "url('/foo/")
    verifyToken(v[4], TokenType.var,        "bar")
    verifyToken(v[5], TokenType.term,       ".svg')")
    verifyToken(v[6], TokenType.closeBrace, "}")

    v = t("a { font-family: 'Inter-\${bar}' }")
    verifyEq(v.size, 5)
    verifyToken(v[0], TokenType.term,       "a")
    verifyToken(v[1], TokenType.openBrace,  "{")
    verifyToken(v[2], TokenType.term,       "font-family:")
    verifyToken(v[3], TokenType.term,       "'Inter-\${bar}'")
    verifyToken(v[4], TokenType.closeBrace, "}")
  }

//////////////////////////////////////////////////////////////////////////
// Assign
//////////////////////////////////////////////////////////////////////////

  Void testAssign()
  {
    v := t("foo := 25px")
    verifyEq(v.size, 3)
    verifyToken(v[0], TokenType.term,   "foo")
    verifyToken(v[1], TokenType.assign, ":=")
    verifyToken(v[2], TokenType.term,   "25px")

    v = t("foo := 1px solid #555")
    verifyEq(v.size, 5)
    verifyToken(v[0], TokenType.term,   "foo")
    verifyToken(v[1], TokenType.assign, ":=")
    verifyToken(v[2], TokenType.term,   "1px")
    verifyToken(v[3], TokenType.term,   "solid")
    verifyToken(v[4], TokenType.term,   "#555")

    v = t("foo := 1px solid \$bar")
    verifyEq(v.size, 5)
    verifyToken(v[0], TokenType.term,   "foo")
    verifyToken(v[1], TokenType.assign, ":=")
    verifyToken(v[2], TokenType.term,   "1px")
    verifyToken(v[3], TokenType.term,   "solid")
    verifyToken(v[4], TokenType.var,    "bar")
  }

//////////////////////////////////////////////////////////////////////////
// Whitespace
//////////////////////////////////////////////////////////////////////////

  Void testWhitespace()
  {
    opts := [
      "div { color: green }",
      "div{color: green}",
      "  div {color: green}  ",
      "div {
        color: green
       }"
    ]

    opts.each |s|
    {
      v := t(s).findAll |x| { !x.isNewline }
      verifyEq(v.size, 5)
      verifyToken(v[0], TokenType.term,       "div")
      verifyToken(v[1], TokenType.openBrace,  "{")
      verifyToken(v[2], TokenType.term,       "color:")
      verifyToken(v[3], TokenType.term,       "green")
      verifyToken(v[4], TokenType.closeBrace, "}")
    }

    opts = [
      "div { color: green; padding: 10px }",
      "div{color: green; padding: 10px}",
      "  div {color: green;   padding:   10px}  ",
      "div {
        color: green;
        padding: 10px
       }"
    ]

    opts.each |s|
    {
      v := t(s).findAll |x| { !x.isNewline }
      verifyEq(v.size, 8)
      verifyToken(v[0], TokenType.term,       "div")
      verifyToken(v[1], TokenType.openBrace,  "{")
      verifyToken(v[2], TokenType.term,       "color:")
      verifyToken(v[3], TokenType.term,       "green")
      verifyToken(v[4], TokenType.semicolon,  ";")
      verifyToken(v[5], TokenType.term,       "padding:")
      verifyToken(v[6], TokenType.term,       "10px")
      verifyToken(v[7], TokenType.closeBrace, "}")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Nested
//////////////////////////////////////////////////////////////////////////

  Void testNested()
  {
    v := t("div {
              color: green
              span {
                color: red
                b:first-child {
                  font-style: \$foo_bar
                }
              }
            }")

    verifyEq(v.size, 23)
    verifyToken(v[0],  TokenType.term,       "div")
    verifyToken(v[1],  TokenType.openBrace,  "{")
    verifyToken(v[2],  TokenType.newline,    "\\n")
    verifyToken(v[3],  TokenType.term,       "color:")
    verifyToken(v[4],  TokenType.term,       "green")
    verifyToken(v[5],  TokenType.newline,    "\\n")
    verifyToken(v[6],  TokenType.term,       "span")
    verifyToken(v[7],  TokenType.openBrace,  "{")
    verifyToken(v[8],  TokenType.newline,    "\\n")
    verifyToken(v[9],  TokenType.term,       "color:")
    verifyToken(v[10], TokenType.term,       "red")
    verifyToken(v[11], TokenType.newline,    "\\n")
    verifyToken(v[12], TokenType.term,       "b:first-child")
    verifyToken(v[13], TokenType.openBrace,  "{")
    verifyToken(v[14], TokenType.newline,    "\\n")
    verifyToken(v[15], TokenType.term,       "font-style:")
    verifyToken(v[16], TokenType.var,        "foo_bar")
    verifyToken(v[17], TokenType.newline,    "\\n")
    verifyToken(v[18], TokenType.closeBrace, "}")
    verifyToken(v[19], TokenType.newline,    "\\n")
    verifyToken(v[20], TokenType.closeBrace, "}")
    verifyToken(v[21], TokenType.newline,    "\\n")
    verifyToken(v[22], TokenType.closeBrace, "}")

    v = t( "div.foo {
              h1 {
                span.bar {
                  &:hover { color: green }
                }
              }
              & p { padding: 1em }
            }")

    verifyEq(v.size, 27)
    verifyToken(v[0],  TokenType.term,       "div.foo")
    verifyToken(v[1],  TokenType.openBrace,  "{")
    verifyToken(v[2],  TokenType.newline,    "\\n")
    verifyToken(v[3],  TokenType.term,       "h1")
    verifyToken(v[4],  TokenType.openBrace,  "{")
    verifyToken(v[5],  TokenType.newline,    "\\n")
    verifyToken(v[6],  TokenType.term,       "span.bar")
    verifyToken(v[7],  TokenType.openBrace,  "{")
    verifyToken(v[8],  TokenType.newline,    "\\n")
    verifyToken(v[9],  TokenType.term,       "&:hover")
    verifyToken(v[10], TokenType.openBrace,  "{")
    verifyToken(v[11], TokenType.term,       "color:")
    verifyToken(v[12], TokenType.term,       "green")
    verifyToken(v[13], TokenType.closeBrace, "}")
    verifyToken(v[14], TokenType.newline,    "\\n")
    verifyToken(v[15], TokenType.closeBrace, "}")
    verifyToken(v[16], TokenType.newline,    "\\n")
    verifyToken(v[17], TokenType.closeBrace, "}")
    verifyToken(v[18], TokenType.newline,    "\\n")
    verifyToken(v[19], TokenType.term,       "&")
    verifyToken(v[20], TokenType.term,       "p")
    verifyToken(v[21], TokenType.openBrace,  "{")
    verifyToken(v[22], TokenType.term,       "padding:")
    verifyToken(v[23], TokenType.term,       "1em")
    verifyToken(v[24], TokenType.closeBrace, "}")
    verifyToken(v[25], TokenType.newline,    "\\n")
    verifyToken(v[26], TokenType.closeBrace, "}")
  }

//////////////////////////////////////////////////////////////////////////
// Comments
//////////////////////////////////////////////////////////////////////////

  Void testLineComments()
  {
    v := t("// hey dude!")
    verifyEq(v.size, 0)

    v = t("// p { color: red }")
    verifyEq(v.size, 0)

    v = t("p { color: blue // red }
           }")
    verifyEq(v.size, 6)
    verifyToken(v[0], TokenType.term,       "p")
    verifyToken(v[1], TokenType.openBrace,  "{")
    verifyToken(v[2], TokenType.term,       "color:")
    verifyToken(v[3], TokenType.term,       "blue")
    verifyToken(v[4], TokenType.newline,    "\\n")
    verifyToken(v[5], TokenType.closeBrace, "}")

    v = t("h1 { color: yellow }
           // h2 { color: red }
           h3 { color: blue }")
    verifyEq(v.size, 12)
    verifyToken(v[0],  TokenType.term,       "h1")
    verifyToken(v[1],  TokenType.openBrace,  "{")
    verifyToken(v[2],  TokenType.term,       "color:")
    verifyToken(v[3],  TokenType.term,       "yellow")
    verifyToken(v[4],  TokenType.closeBrace, "}")
    verifyToken(v[5],  TokenType.newline,    "\\n")
    verifyToken(v[6],  TokenType.newline,    "\\n")
    verifyToken(v[7],  TokenType.term,       "h3")
    verifyToken(v[8],  TokenType.openBrace,  "{")
    verifyToken(v[9],  TokenType.term,       "color:")
    verifyToken(v[10], TokenType.term,       "blue")
    verifyToken(v[11], TokenType.closeBrace, "}")
  }

  Void testBlockComments()
  {
    v := t("/* hey dude! */")
    verifyEq(v.size, 0)

    v = t("/*
                p { color: red }

              */")
    verifyEq(v.size, 0)

    v = t("p { color: /*blue*/ red }")
    verifyEq(v.size, 5)
    verifyToken(v[0], TokenType.term,       "p")
    verifyToken(v[1], TokenType.openBrace,  "{")
    verifyToken(v[2], TokenType.term,       "color:")
    verifyToken(v[3], TokenType.term,       "red")
    verifyToken(v[4], TokenType.closeBrace, "}")

    v = t("h1 { color: yellow }
           /* h2 { color: red } */
           h3 { color: blue }")
    verifyEq(v.size, 12)
    verifyToken(v[0],  TokenType.term,       "h1")
    verifyToken(v[1],  TokenType.openBrace,  "{")
    verifyToken(v[2],  TokenType.term,       "color:")
    verifyToken(v[3],  TokenType.term,       "yellow")
    verifyToken(v[4],  TokenType.closeBrace, "}")
    verifyToken(v[5],  TokenType.newline,    "\\n")
    verifyToken(v[6],  TokenType.newline,    "\\n")
    verifyToken(v[7],  TokenType.term,       "h3")
    verifyToken(v[8],  TokenType.openBrace,  "{")
    verifyToken(v[9],  TokenType.term,       "color:")
    verifyToken(v[10], TokenType.term,       "blue")
    verifyToken(v[11], TokenType.closeBrace, "}")
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  private Token[] t(Str fass)
  {
    tokens := Token[,]
    tokenizer := Tokenizer("test", fass.in)
    while (true)
    {
      t := tokenizer.next
// echo("> $t")
      if (t.isEos) break
      tokens.add(t)
    }
    return tokens
  }

  private Void verifyToken(Token token, TokenType testType, Str testVal)
  {
    verifyEq(token.val,  testVal)
    verifyEq(token.type, testType)
  }
}