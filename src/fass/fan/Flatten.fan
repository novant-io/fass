//
// Copyright (c) 2022, Novant LLC
// Licensed under the MIT License
//
// History:
//   22 Aug 2022  Andy Frank  Creation
//

*************************************************************************
** Flatten
*************************************************************************

@Js internal class Flatten
{
  static Str[] flatten(RulesetDef[] path)
  {
    acc := Str[,]
    doFlatten(acc, path, 0, "")
    return acc
  }

  private static Void doFlatten(Str[] acc, RulesetDef[] path, Int depth, Str prefix)
  {
    // create a flattened def for each selector
    def := path[depth]
    def.selectors.each |sel|
    {
      flat := StrBuf()

      if (sel.startsWith("&"))
      {
        // cannot use self at root
        if (depth == 0) throw Err("Cannot reference & at root level")

        // append pusedo-class directly to prefix
        flat.add(prefix)
        if (sel.size > 1) flat.add(sel[1..-1])
      }
      else
      {
        // otherwise append selector to qualified selector prefix
        flat.add(prefix).join(sel, " ")
      }

      if (depth == path.size-1)
      {
        // hit a leaf node, add flattened name
        acc.add(flat.toStr)
      }
      else
      {
        // else traverse path
        doFlatten(acc, path, depth+1, flat.toStr)
      }
    }
  }
}
