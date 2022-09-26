//
// Copyright (c) 2022, Novant LLC
// Licensed under the MIT License
//
// History:
//   14 Jul 2022  Andy Frank  Creation
//

*************************************************************************
** Parser
*************************************************************************

@Js internal class Parser
{
  ** Construcor.
  new make(Obj file, InStream in)
  {
    this.tokenizer = Tokenizer(file, in)
  }

  ** Parse input stream into AST tree.
  Def parse()
  {
    root  := Def()
    scope := [root]
    token := tokenizer.next

    while (!token.isEos)
    {
      pre := scope.last  // scope before we parse next token
      Def? post          // scope after we parse next token

      // parse
      switch (token.type)
      {
        case TokenType.term:       post = parseTerm(pre, token)
        case TokenType.closeBrace: scope.pop
        case TokenType.newline:    x := 10   // no-op
        case TokenType.semicolon:  x := 10   // no-op
        default: throw unexpectedToken(token)
      }

      // check if we need to push new scope
      if (post != null && pre != post) scope.push(post)

      // advance
      token = tokenizer.next
    }

    return root
  }

  ** Parse a term and return new scope.
  private Def parseTerm(Def cur, Token token)
  {
    orig := token

    // check for @using
    if (token.val == "@using")
    {
      ref := tokenizer.next
      if (!token.isTerm) throw unexpectedToken(token)
      cur.add(UsingDef { it.loc=orig.loc; it.ref= normRef(ref) })
      return cur
    }

    // read next token to check
    token = tokenizer.next
    if (token.isAssign)
    {
      defs := Def[,]
      token = tokenizer.next
      while (token.isTerm || token.isVar || token.isComma)
      {
        defs.add(parseExprDef(token))
        token = tokenizer.next
      }
      tokenizer.push(token)
      expr := ExprDef   { it.loc=defs.first.loc; it.defs=defs }
      cur.add(AssignDef { it.loc=orig.loc; it.name=orig.val; it.expr=expr })
      return cur
    }

    // read-ahead to identify selector list or prop declare
    acc := [orig]
    while (token.isTerm || token.isVar || token.isComma)
    {
      acc.add(token)
      token = tokenizer.next
      // eat trailing newlines after a comma
      while (token.isNewline && acc.last.isComma) token = tokenizer.next
    }

    if (token.isOpenBrace)
    {
      // parse as ruleset selector list
      sels := Str[,]
      acc.each |t,i|
      {
        if (t.isComma) sels.add("")
        else if (i == 0) sels.add(t.val)
        else sels[-1] = "${sels[-1]} ${t.val}".trim
      }
      ruleset := RulesetDef { it.loc=orig.loc; it.selectors=sels }
      cur.add(ruleset)
      return ruleset
    }
    else if (token.isDelim)
    {
      // push delim back onto stack
      tokenizer.push(token)

      // parse as prop declartion
      // tokenizer leaves ':' in place; so split first term
      temp := acc.first.val
      i := temp.index(":")
      if (i == null) throw err(orig, "Unexpected token '${token}")
      x := temp[0..<i]
      y := temp[i+1..-1].trimToNull

      // insert split terms back into read-ahead acc
      acc[0] = Token(TokenType.term, x, orig.loc)
      if (y != null) acc.insert(1, Token(TokenType.term, y, orig.loc))

      // validate enough params
      if (acc.size < 2) throw err(orig, "Expecting declaration expr")

      prop := acc.first.val
      defs := Def[,]
      acc.eachRange(1..-1) |t|
      {
        if (t.isNewline) return
        if (t.val.contains(":")) throw err(t, "Unexpected char ':'")
        defs.add(parseExprDef(t))
      }
      expr := ExprDef    { it.loc=defs.first.loc; it.defs=defs }
      def  := DeclareDef { it.loc=orig.loc; it.prop=prop; it.expr=expr }
      cur.add(def)
      return cur
    }

    // invalid syntax if we get here
    throw unexpectedToken(token)
  }

  ** Normalize ref format.
  private Str normRef(Token token)
  {
    // remove quotes if specified
    s := token.val
    q := s[0]
    if (q == '\'' || q == '\"')
    {
      if (s[-1] != q) throw err(token, "Unmatched closing quote: ${token.val}")
      s = s[1..-2]
    }

    // append .fass ext if missing
    if (!s.endsWith(".fass")) s += ".fass"

    return s
  }

  ** Parsed an token inside an expression.
  private Def parseExprDef(Token token)
  {
    if (token.isTerm || token.isComma) return LiteralDef { it.loc=token.loc; it.val=token.val }
    if (token.isVar)  return VarDef { it.loc=token.loc; it.name=token.val }
    throw unexpectedToken(token)
  }

  ** Err for unexpected token.
  private Err unexpectedToken(Token token)
  {
    err(token, token.isEos
      ? "Unexpected end of stream"
      : "Unexpected token: '${token.val}'")
  }

  ** Err error with location.
  private FassCompileErr err(Token token, Str msg)
  {
    FassCompileErr(msg, token.loc)
  }

  private Tokenizer tokenizer
}