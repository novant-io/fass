//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   14 Jul 2022  Andy Frank  Creation
//

using util

*************************************************************************
** TokenType
*************************************************************************

@Js internal enum class TokenType
{
  newline,
  openBrace,
  closeBrace,
  colon,
  semicolon,
  comma,
  assign,
  // atRule,
  var,
  term,
  eos
}

*************************************************************************
** Token
*************************************************************************

@Js internal const class Token
{
  ** Ctor.
  new make(TokenType t, Str v, FileLoc l)
  {
    this.type = t
    this.val  = v
    this.loc  = l
  }

  ** Token type.
  const TokenType type

  ** Token literval val.
  const Str val

  ** Locaaton where this token occured in source.
  const FileLoc loc

  Bool isNewline()    { type == TokenType.newline    }
  Bool isOpenBrace()  { type == TokenType.openBrace  }
  Bool isCloseBrace() { type == TokenType.closeBrace }
  Bool isColon()      { type == TokenType.colon      }
  Bool isSemicolon()  { type == TokenType.semicolon  }
  Bool isAssign()     { type == TokenType.assign     }
  Bool isComma()      { type == TokenType.comma      }
  // Bool isAtRule()     { type == TokenType.atRule     }
  Bool isVar()        { type == TokenType.var        }
  Bool isTerm()       { type == TokenType.term       }
  Bool isEos()        { type == TokenType.eos        }

  Bool isDelim()
  {
    if (isNewline)    return true
    if (isSemicolon)  return true
    // if (isOpenBrace)  return true
    if (isCloseBrace) return true
    return false
  }

  override Str toStr() { "${type}='${val}'" } // [${loc.line}:${loc.col}]" }
}

*************************************************************************
** Tokenizer
*************************************************************************

@Js internal class Tokenizer
{
  ** Construct new Tokenizer for given 'InStream'.
  new make(Obj file, InStream in)
  {
    this.file = file
    this.in   = in
    this.line = 1
    this.col  = 1
    this.buf  = StrBuf()
  }

  ** Return the next token.
  Token next()
  {
    // first check pushback
    if (pushback.size > 0) return pushback.pop

    // stash pos for start for token
    loc := file is File
      ? FileLoc.makeFile(file, line, col)
      : FileLoc(file.toStr, line, col)

    // reset buffer and read next char
    buf.clear
    ch := read

    // consume leading whitespace
    while (ch == ' ' || ch == '\t') ch = read

    // eos
    if (ch == 0) return Token(TokenType.eos, "", loc)

    // line comment
    if (ch == '/' && peek == '/')
    {
      while (ch != '\n' && ch != 0) ch = read
      if (ch == 0) return Token(TokenType.eos, "", loc)
      else return Token(TokenType.newline, "\\n", loc)
    }

    // block comment
    if (ch == '/' && peek == '*')
    {
      ch = read  // /
      ch = read  // *
      while (true)
      {
        if (ch == 0) throw unexpectedChar(0, loc)
        if (ch == '*' && peek == '/') { read; break }
        ch = read
      }
      return next
    }

    // assign
    if (ch == ':' && peek == '=')
    {
      read
      return Token(TokenType.assign, ":=", loc)
    }

    // exact matches
    if (ch == '\n') return Token(TokenType.newline,  "\\n", loc)
    if (ch == '{')  return Token(TokenType.openBrace,  "{", loc)
    if (ch == '}')  return Token(TokenType.closeBrace, "}", loc)
    if (ch == ':')  return Token(TokenType.colon,      ":", loc)
    if (ch == ';')  return Token(TokenType.semicolon,  ";", loc)
    if (ch == ',')  return Token(TokenType.comma,      ",", loc)

    // var
    if (ch == '\$')
    {
      ch = read
      bracket := ch == '{'
      if (bracket) ch = read
      while (true)
      {
        if (bracket && ch == '}') break
        if (isDelim(ch)) { unread(ch); break }
        buf.addChar(ch)
        ch = read
      }
      return Token(TokenType.var, buf.toStr, loc)
    }

    // quoted term
    if (ch == '\'' || ch == '\"')
    {
      q := ch
      while (true)
      {
        buf.addChar(ch)
        ch = read
        if (ch == 0) break
        if (ch == q) { buf.addChar(ch); break }
      }
      return Token(TokenType.term, buf.toStr, loc)
    }

    // term
    while (true)
    {
      if (isDelim(ch)) { unread(ch); break }
      buf.addChar(ch)
      ch = read
    }

    return Token(TokenType.term, buf.toStr, loc)
  }

  ** Push token back onto tokenizer stack.
  Void push(Token token)
  {
    pushback.push(token)
  }

  ** Read next char in stream.
  private Int read()
  {
    ch := in.readChar
    if (ch == null) return 0
    if (ch == '\n') { line++; col=1 }
    else col++
    return ch
  }

  ** Peek next char in stream.
  private Int peek() { in.peekChar ?: 0 }

  ** Push char back on stream.
  private Void unread(Int ch)
  {
    in.unreadChar(ch)
    col--
    // TODO: col should reset to end of line someehow?
    if (col == 0) { line--; col=1 }
  }

  ** Return FassCompileErr
  private Err unexpectedChar(Int ch, FileLoc loc)
  {
    ch == 0
      ? parseErr("Unexpected end of stream", loc)
      : parseErr("Unexpected char: '$ch.toChar'", loc)
  }

  ** Return FassCompileErr
  private Err parseErr(Str msg, FileLoc loc)
  {
    FassCompileErr(msg, loc, null)
  }

  ** Return 'true' if char is a delimiter.
  private Bool isDelim(Int ch) { delims[ch] != null }
  private const Int:Int delims := [:].setList([
    0, ';', '\n', ' ',  ',', '{', '}', '\$',
  ])

  private const Obj file           // file name for FileLoc ref
  private InStream in              // source instream
  private Int line                 // cur line number for 'in'
  private Int col                  // cur col index for 'line'
  private StrBuf buf               // resuable str buf
  private Token[] pushback := [,]  // pushback buffer
}