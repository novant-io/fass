//
// Copyright (c) 2022, Novant LLC
// All Rights Reserved
//
// History:
//   7 Jul 2022  Andy Frank  Creation
//

*************************************************************************
** TokenType
*************************************************************************

@Js internal enum class TokenType
{
  openBrace,
  closeBrace,
  comma,
  colon,
  semicolon,
  atRule,
  selector,
  property,
  expr,
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

  Bool isOpenBrace()  { type == TokenType.openBrace  }
  Bool isCloseBrace() { type == TokenType.closeBrace }
  Bool isComma()      { type == TokenType.comma      }
  Bool isColon()      { type == TokenType.colon      }
  Bool isAtRule()     { type == TokenType.atRule     }
  Bool isSemicolon()  { type == TokenType.semicolon  }
  Bool isSelector()   { type == TokenType.selector   }
  Bool isProperty()   { type == TokenType.property   }
  Bool isExpr()       { type == TokenType.expr       }
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

      // process next token
      parent := stack.last
      switch (token.type)
      {
        // semicolon
        case TokenType.semicolon: noBreakIsStoopid := 0

        // var assign
        case TokenType.var:
          var := VarDef { it.name=token.val }
          nextToken(TokenType.colon)
          token = nextToken
          expr := LiteralDef { it.val=token.val }
          def  := VarAssignDef { it.var=var; it.expr=expr }
          parent.children.add(def)

        // selectors/at-rules
        case TokenType.atRule:
        case TokenType.selector:
          // read ahead to check for additional selectors
          sels := [token.val]
          while (true)
          {
            token = nextToken
            if (token.isComma)
            {
              token = nextToken(TokenType.selector)
              sels.add(token.val)
              continue
            }
            if (token.isOpenBrace) break
            throw unexpectedToken(token)
          }
          def := RulesetDef { it.selectors=sels }
          parent.children.add(def)
          stack.push(def)

        // props
        case TokenType.property:
          prop := token.val
          nextToken(TokenType.colon)
          Def? expr
          token = nextToken
          if (token.isExpr) expr = LiteralDef { it.val=token.val }
          else if (token.isVar) expr = VarDef { it.name=token.val }
          else throw unexpectedToken(token)
          def := DeclarationDef
          {
            it.prop = prop
            it.expr = expr
          }
          parent.children.add(def)

        // close brace
        case TokenType.closeBrace: stack.pop

        // err
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
    // read next token
    token := readNextToken

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

    // eos
    if (ch == null) return null

    // eat block comment
    if (ch == '/' && peek == '*')
    {
      ch = read
      ch = read
      while (true)
      {
        if (ch == null) throw unexpectedChar(null)
        if (ch == '*' && peek == '/') { read; break }
        ch = read
      }
      // eat trailing / and recurse
      return readNextToken
    }

    // eat line comment
    if (ch == '/' && peek == '/')
    {
      // read till end of line and recurse
      while (peek != null && peek != '\n') read
      return readNextToken
    }

    // exact matches
    if (ch == '{') return Token(TokenType.openBrace,  "{")
    if (ch == '}') return Token(TokenType.closeBrace, "}")
    if (ch == ',') return Token(TokenType.comma,      ",")
    if (ch == ':') return Token(TokenType.colon,      ":")
    if (ch == ';') return Token(TokenType.semicolon,  ";")

    // var
    if (ch == '\$')
    {
      ch = read
      if (!ch.isAlpha) throw unexpectedChar(ch)
      buf.addChar(ch)
      while (peek != null && isVarChar(peek)) buf.addChar(read)

      // eat leading whitespace and check for ':' for assign cx
      while (peek.isSpace) ch = read
      if (peek == ':') cx = 1
      else cx = 0
      return Token(TokenType.var, buf.toStr.trim)
    }

    // at-rule
    if (ch == '@')
    {
      buf.addChar(ch)
      while (peek != null && isSelectorChar(peek)) buf.addChar(read)
      return Token(TokenType.atRule, buf.toStr.trim)
    }

    // check context to see expected token
    if (cx == 0)
    {
      // selector or property
      if (!ch.isAlpha)throw unexpectedChar(ch)
      buf.addChar(ch)
      while (peek != null && (isSelectorChar(peek) || isPropertyChar(peek)))
      {
        buf.addChar(read)
      }

      // eat leading whitespace, but retain in buf in
      // case we need to pushback (filter out later)
      while (peek.isSpace) buf.addChar(ch = read)

      // check next char for selector vs prop
      if (peek == '{' || peek == ',')
      {
        // set cx, re-validate as selector, fitler excess whitespace
        cx = 0
        temp := buf.toStr.trim.split.join(" ")
        temp.each |x| { if (!isSelectorChar(x)) throw unexpectedChar(x) }
        return Token(TokenType.selector, temp)
      }
      else
      {
        // valid selectors can include ':' so we need to check
        // if we consumed and pushback onto instream
        temp   := buf.toStr
        offset := temp.index(":")
        if (offset != null)
        {
          (temp.size - offset).times |p| { in.unreadChar(temp[-(p+1)]) }
          temp = temp[0..<offset]
        }

        // set cx, re-validate as property, filter excess whitepsace
        cx = 2
        temp = temp.trim.split.join(" ")
        temp.each |x| { if (!isPropertyChar(x)) throw unexpectedChar(x) }
        return Token(TokenType.property, temp)
      }
    }
    else
    {
      // expr
      while (true)
      {
        // if we hit a comma, allow a newline
        if (ch == ',')
        {
          buf.addChar(ch)
          while (peek != null && peek.isSpace) ch = read
        }

        // hit a comment
        if (ch == '/' && peek == '*') break
        if (ch == '/' && peek == '/') break

        // check line ending or keep going
        if (ch == null || ch == ';' || ch == '\n' || ch == '}') break
        else if (isExprChar(ch)) { buf.addChar(ch); ch = read }
        else throw unexpectedChar(ch)
      }

      // pushback last char and reset cx state
      if (ch != null) unread(ch)
      cx = 0
      return Token(TokenType.expr, buf.toStr.trim)
    }
  }

  ** Return 'true' if this ch is a valid selector char.
  private Bool isSelectorChar(Int ch)
  {
    if (ch.isAlphaNum) return true
    if (ch == ' ') return true
    if (ch == '#') return true
    if (ch == '.') return true
    if (ch == '-') return true
    if (ch == '[') return true
    if (ch == ']') return true
    if (ch == '=') return true
    if (ch == ':') return true
    return false
  }

  ** Return 'true' if this ch is a valid property char.
  private Bool isPropertyChar(Int ch)
  {
    if (ch.isAlpha) return true
    if (ch == '-')  return true
    return false
  }

  ** Return 'true' if this ch is a valid expr char.
  private Bool isExprChar(Int ch)
  {
    if (ch.isAlphaNum) return true
    if (ch == ' ') return true
    if (ch == '#') return true
    if (ch == '.') return true
    if (ch == '+') return true
    if (ch == '-') return true
    if (ch == '/') return true
    if (ch == '*') return true
    if (ch == '%') return true
    if (ch == ',') return true
    if (ch == '(') return true
    if (ch == ')') return true
    if (ch == '\'') return true
    if (ch == '\"') return true
    return false
  }

  ** Return 'true' if this ch is a valid var char.
  private Bool isVarChar(Int ch)
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

  //
  // Current context state:
  //
  //   0: root
  //   1: inside var assign
  //   2: inside prop declaration
  //
  private Int cx := 0

  private InStream in               // input stream
  private Int line := 1             // current line number
  private Def[] stack := [,]        // AST node stack
  private StrBuf buf := StrBuf()    // resuse buf in nextToken
  private Token[] pushback := [,]   // for unreadToken
}