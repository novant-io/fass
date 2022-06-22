//
// Copyright (c) 2022, Novant LLC
// All Rights Reserved
//
// History:
//   20 Jun 2022  Andy Frank  Creation
//

*************************************************************************
** TokenType
*************************************************************************

@Js internal enum class TokenType
{
  identifier,
  openBrace,
  closeBrace,
  comma,
  colon,
  semicolon,
  eos
}

*************************************************************************
** Token
*************************************************************************

@Js internal const class Token
{
  ** Ctor.
  new make(TokenType t, Str v) { this.type=t; this.val=v }

  ** Token type.
  const TokenType type

  ** Token literval val.
  const Str val

  Bool isIdentifier() { type == TokenType.identifier }
  Bool isOpenBrace()  { type == TokenType.openBrace  }
  Bool isCloseBrace() { type == TokenType.closeBrace }
  Bool isComma()      { type == TokenType.comma      }
  Bool isColon()      { type == TokenType.colon      }
  Bool isSemicolon()  { type == TokenType.semicolon  }
  Bool isEos()        { type == TokenType.eos        }

  override Str toStr() { "${type}='${val}'" }
}

*************************************************************************
** Parser
*************************************************************************

@Js internal class Parser
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Ctor.
  new make(InStream in)
  {
    // TODO
    this.podName  = "<pod>"
    this.filename = "<file>"

    this.in = in
  }

  ** Parse input stream into AST tree.
  Def parse()
  {
    root := Def {}
    stack.add(root)
    Token? token

    while (true)
    {
      // read next token or break if eos
      token = nextToken
      if (token.isEos) break

      parent := stack.last
      switch (token.type)
      {
        case TokenType.identifier:
          start := token
          // first check if this is a declaration
          token = nextToken
          if (token.isColon)
          {
            token = nextToken(TokenType.identifier)
            def := DeclarationDef
            {
              it.prop = start.val
              it.val  = token.val
            }
            parent.children.add(def)

            // eat trailing semicolon if present
            token = nextToken
            if (!token.isSemicolon) unreadToken(token)
          }
          else
          {
            // else assume ruleset
            acc := [start.val]
            while (true)
            {
              if (token.isIdentifier) acc.add(token.val)
              else if (token.isOpenBrace) break
              else if (!token.isComma) throw unexpectedToken(token)
              token = nextToken
            }
            def := RulesetDef { it.selectors=acc }
            parent.children.add(def)
            stack.push(def)
          }

        case TokenType.closeBrace:
          last := stack.pop
          // if (last isnot IfDef) throw unmatchedDef(last)

        default: throw unexpectedToken(token)
      }
    }

    // check for unmatched braces
    if (stack.size > 1) throw parseErr("Missing closing '}'")

    return root
  }

//////////////////////////////////////////////////////////////////////////
// Tokenizer
//////////////////////////////////////////////////////////////////////////

  ** Read next token from stream.  If 'type' is non-null
  ** and does match read token, throw ParseErr.
  private Token nextToken(TokenType? type := null)
  {
    // read next non-comment token
    token := readNextToken
//    while (token?.isComment == true) token = readNextToken

    // wrap in eos if hit end of file
    if (token == null) token = Token(TokenType.eos, "")

    // check match
    if (type != null && token?.type != type) throw unexpectedToken(token)

    return token
  }

  ** Unread given token.
  private Void unreadToken(Token token)
  {
    pushback.push(token)
  }

  ** Read next token from stream or 'null' if EOS.
  private Token? readNextToken()
  {
    // first check pushback
    if (pushback.size > 0) return pushback.pop

    buf.clear

    // read next char (eat leading whitespace)
    ch := read
    while (ch != null && ch.isSpace) ch = read
    if (ch == null) return null

    // exact matches
    if (ch == '{') return Token(TokenType.openBrace,  "{")
    if (ch == '}') return Token(TokenType.closeBrace, "}")
    if (ch == ',') return Token(TokenType.comma,      ",")
    if (ch == ':') return Token(TokenType.colon,      ":")
    if (ch == ';') return Token(TokenType.semicolon,  ";")

    // identifier
    if (!isValidIdentiferChar(ch)) throw unexpectedChar(ch)
    buf.addChar(ch)
    while (isValidIdentiferChar(peek)) buf.addChar(read)
    while (peek.isSpace) ch = read // eat trailing space
    // trim whitespace around selectors
    return Token(TokenType.identifier, buf.toStr.split.join(" "))
  }

  ** Return 'true' if ch is a valid identifier char
  private Bool isValidIdentiferChar(Int ch)
  {
    if (ch.isAlphaNum) return true
    if (ch == '-') return true
    if (ch == '_') return true
    if (ch == '.') return true
    if (ch == '#') return true
    if (ch == ' ') return true
    return false
  }

  ** Read next char in stream.
  private Int? read()
  {
    ch := in.readChar
    if (ch == '\n') line++
    return ch
  }

  ** Peek next char in stream.
  private Int? peek() { in.peekChar }

  ** Throw ParseErr
  private Err parseErr(Str msg)
  {
    ParseErr("${msg} [${filename}:${line}]")
  }

  ** Throw ParseErr
  private Err unexpectedChar(Int? ch)
  {
    ch == null
      ? parseErr("Unexpected end of stream")
      : parseErr("Unexpected char: '$ch.toChar'")
  }

  ** Throw ParseErr
  private Err unexpectedToken(Token token)
  {
    token.isEos
      ? parseErr("Unexpected end of stream")
      : parseErr("Unexpected token: '$token.val'")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const Str podName         // podName
  private const Str filename        // name of file to parse
  private InStream in               // input
  private Int line := 1             // current line
  private Def[] stack := [,]        // AST node stack
  private Int commentDepth := 0     // track comment {{!-- depth
  private StrBuf buf := StrBuf()    // resuse buf in nextToken
  private Token[] pushback := [,]   // for unreadToken
}