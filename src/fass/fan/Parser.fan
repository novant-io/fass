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
  comment,
  directive,
  identifier,
  openBrace,
  closeBrace,
  comma,
  colon,
  semicolon,
  var,
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

  Bool isComment()    { type == TokenType.comment    }
  Bool isDirective()  { type == TokenType.directive  }
  Bool isIdentifier() { type == TokenType.identifier }
  Bool isOpenBrace()  { type == TokenType.openBrace  }
  Bool isCloseBrace() { type == TokenType.closeBrace }
  Bool isComma()      { type == TokenType.comma      }
  Bool isColon()      { type == TokenType.colon      }
  Bool isSemicolon()  { type == TokenType.semicolon  }
  Bool isVar()        { type == TokenType.var        }
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
            exprs := Def[,]
            Token? last
            while (true)
            {
              canAdd := last == null || last.isComma
              token = nextToken
              if (last == null || last.isComma)
              {
                if (token.isIdentifier) exprs.add(LiteralDef { it.val=token.val })
                else if (token.isVar)   exprs.add(VarDef { it.name=token.val })
                else throw unexpectedToken(token)
              }
              else if (!token.isComma)
              {
                unreadToken(token)
                break
              }
              last = token
            }
            def := DeclarationDef
            {
              it.prop  = start.val
              it.exprs = exprs
            }
            consumeSemicolon
            parent.children.add(def)
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

        case TokenType.var:
          var := VarDef { it.name = token.val }
          nextToken(TokenType.colon)
          token = nextToken(TokenType.identifier)
          val := LiteralDef { it.val = token.val }
          consumeSemicolon
          def := VarAssignDef { it.var=var; it.val=val }
          parent.children.add(def)

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

  ** Eat trailing semicolon if present.
  private Void consumeSemicolon()
  {
    token := nextToken
    if (!token.isSemicolon) unreadToken(token)
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
    while (token?.isComment == true) token = readNextToken

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

    // comment
    if (ch == '/' && peek == '*')
    {
      read
      ch = read
      while (true)
      {
        if (ch == '*' && peek == '/') { read; break }
        buf.addChar(ch)
        ch = read
      }
      return Token(TokenType.comment, buf.toStr)
    }

    // exact matches
    if (ch == '{') return Token(TokenType.openBrace,  "{")
    if (ch == '}') return Token(TokenType.closeBrace, "}")
    if (ch == ',') return Token(TokenType.comma,      ",")
    if (ch == ':') return Token(TokenType.colon,      ":")
    if (ch == ';') return Token(TokenType.semicolon,  ";")

    // directive
    if (ch == '@')
    {
      while (peek.isAlpha) buf.addChar(read)
      if (isDirective(buf.toStr))
        return Token(TokenType.directive, buf.toStr)
      else
      {
        // push back onto stream
        i := buf.size-1
        while (i >= 0) unread(buf[i--])
      }
      buf.clear
    }

    // var
    if (ch == '\$')
    {
      if (!peek.isAlpha) throw unexpectedChar(ch)
      while (isValidVarChar(peek)) buf.addChar(read)
      return Token(TokenType.var, buf.toStr)
    }

    // identifier
    if (!isValidIdentiferChar(ch)) throw unexpectedChar(ch)
    buf.addChar(ch)
    while (peek != null && isValidIdentiferChar(peek)) buf.addChar(read)
    // trim whitespace around selectors
    return Token(TokenType.identifier, buf.toStr.split.join(" "))
  }

  ** Return 'true' if str is a fass directive.
  private Bool isDirective(Str s)
  {
    if (s == "use") return true
    return false
  }

  ** Return 'true' if ch is a valid identifier char
  private Bool isValidIdentiferChar(Int ch)
  {
    if (ch == '{') return false
    if (ch == '}') return false
    if (ch == ',') return false
    if (ch == ':') return false
    if (ch == ';') return false
    if (ch == '\n') return false
    return true
  }

  ** Return 'true' if ch is a valid variable char
  private Bool isValidVarChar(Int ch)
  {
    if (ch.isAlphaNum) return true
    if (ch == '_') return true
    return false
  }

  ** Read next char in stream.
  private Int? read()
  {
    ch := in.readChar
    if (ch == '\n') line++
    return ch
  }

  ** Push char back on stream.
  private Void unread(Int ch) { in.unreadChar(ch) }

  ** Peek next char in stream.
  private Int? peek() { in.peekChar }

  ** Throw ParseErr
  private Err parseErr(Str msg)
  {
    ParseErr("${msg} [line:${line}]")
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

  private InStream in               // input
  private Int line := 1             // current line
  private Def[] stack := [,]        // AST node stack
  private Int commentDepth := 0     // track comment {{!-- depth
  private StrBuf buf := StrBuf()    // resuse buf in nextToken
  private Token[] pushback := [,]   // for unreadToken
}