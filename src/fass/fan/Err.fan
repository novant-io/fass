//
// Copyright (c) 2022, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Aug 2022  Andy Frank  Creation
//

using util

*************************************************************************
** FassCompileErr
*************************************************************************

** Err for fass source compiler errors.
@Js const class FassCompileErr : Err
{
  ** Constructor.
  new make(Str msg, FileLoc? loc := null, Err? cause := null) : super(msg, cause)
  {
    this.loc = loc
  }

  ** File location for error, or 'null' if unavailable.
  const FileLoc? loc
}