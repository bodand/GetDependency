## BSD-0 License
# Copyright (c) 2020 bodand
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

## Count(List Value oReturnVal)
##
## Counts how many occurrences of `Value` are in
## `List` and returns it through `oReturnVal`
function(Count List Value oReturnVal)
    set(_SUM 0)
    foreach (elem IN LISTS List)
        if ((Value STREQUAL elem)
             || (Value EQUAL elem))
            math(EXPR _SUM "${_SUM} + 1")
        endif ()
    endforeach ()
    set("${oReturnVal}" ${_SUM} PARENT_SCOPE)
endfunction()

## GetRepoTypeFromURL(RepoURL oRepoType)
##
## Deduces the VCS from the repository's clone URL
## Currently supported are Git and SVN
## Note that this is a crappy algorithm:
##  checks if the url ends in .git, in which case it is a Git repo
##  in any other case it is just SVN. Have fun
function(GetRepoTypeFromURL RepoURL oRepoType)
    string(LENGTH "${RepoURL}" RepoURL_LEN)
    math(EXPR RepoURL_GIT_BEGIN "${RepoURL_LEN} - 4")
    string(SUBSTRING "${RepoURL}" ${RepoURL_GIT_BEGIN} 4 RepoURL_LAST4)
    if (RepoURL_LAST4 STREQUAL ".git")
        set("${oRepoType}" GIT PARENT_SCOPE)
    else ()
        set("${oRepoType}" SVN PARENT_SCOPE)
    endif ()
endfunction()
