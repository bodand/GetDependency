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

include(GetGit)
include(GetSVN)

include(Utils)

# Checks the system for all a dependency and if not found,
# will install them for the project
# Supported repositories are 'Git' and 'SVN' as deduced from the URL
# GetDependency(
#    <DEPENDENCY_TO_SEARCH>
#    REPOSITORY_URL <URL_OF_<GIT|SVN>_REPOSITORY>
#    VERSION <GIT_TAG|SVN_REVISION>
#    [REMOTE_ONLY]
#    [COMPONENTS <LIST_OF_COMPONENTS...>]
#    [FALLBACK <DEPENDENCY_LIBRARY_NAME>
#    [FALLBACK_COMPONENTS <LIST_OF_COMPONENTS_OF_FALLBACK_DEPENDENCY...>]]
# )
function(GetDependency)
    ## Helpers
    macro(EMIT_ERROR MSG)
        message(FATAL_ERROR "GetDependency was not passed the appropriate arguments:\
        ${MSG}")
    endmacro()
    set(REPO_GIT_NAME GIT)
    set(REPO_GIT_REVISION GIT_TAG)
    set(REPO_SVN_NAME SVN)
    set(REPO_SVN_REVISION SVN_REVISION)

    ## ARGUMENT HANDLING BEGIN #################################################
    cmake_parse_arguments(PARSE_ARGV 0 GET_DEP
                          "REMOTE_ONLY"
                          "REPOSITORY_URL;VERSION;FALLBACK"
                          "COMPONENTS;FALLBACK_COMPONENTS"
                          )

    ## Check incomplete arguments
    if (GET_DEP_KEYWORDS_MISSING_VALUES)
        EMIT_ERROR("Values for the option(s): '${GEP_DEP_KEYWORDS_MISSING_VALUES}' were not defined.")
    endif ()

    ## Remote only
    if (DEFINED GET_DEP_REMOTE_ONLY)
        set(RemoteOnly 1)
    else ()
        set(RemoteOnly 2)
    endif ()

    ## Library
    list(LENGTH GET_DEP_UNPARSED_ARGUMENTS GET_DEP_UNPARSED_ARGUMENTS_LEN)
    if (GET_DEP_UNPARSED_ARGUMENTS_LEN EQUAL 0)
        EMIT_ERROR("Dependency name to check/install must be provided")
    elseif (GET_DEP_UNPARSED_ARGUMENTS_LEN GREATER 1)
        EMIT_ERROR("Dependency name to check/install must be specified exactly once")
    endif ()
    list(GET GET_DEP_UNPARSED_ARGUMENTS 0 Library)

    ## If checking the system
    ## We care about components and fallbacks
    ## otherwise if REMOTE_ONLY is set we just ignore them
    if (NOT RemoteOnly)
        ## Components
        if (DEFINED GET_DEP_COMPONENTS)
            set(Components ${GET_DEP_COMPONENTS})
        else ()
            set(Components)
        endif ()

        ## HasFallback / FallbackLibrary
        if (DEFINED GET_DEP_FALLBACK)
            set(HasFallback TRUE)
            set(FallbackLibrary ${GET_DEP_FALLBACK})
        else ()
            set(HasFallback FALSE)
            set(FallbackLibrary ${GET_DEP_FALLBACK})
        endif ()

        ## FallbackComponents
        if (DEFINED GET_DEP_FALLBACK_COMPONENTS)
            if (NOT HasFallback)
                EMIT_ERROR("FALLBACK_COMPONENTS must only be specified if FALLBACK is specified")
            endif ()
            set(FallbackComponents ${GET_DEP_FALLBACK_COMPONENTS})
        else ()
            set(FallbackComponents)
        endif ()
    endif ()

    ## URL
    if (NOT DEFINED GET_DEP_REPOSITORY_URL)
        EMIT_ERROR("REPOSITORY_URL must be passed")
    endif ()
    set(URL "${GET_DEP_REPOSITORY_URL}")

    ## RepoType/RepoTagType
    GetRepoTypeFromURL("${URL}" DEDUCED_REPO_TYPE)
    set(RepoType "${REPO_${DEDUCED_REPO_TYPE}_NAME}")
    set(RepoTagType "${REPO_${DEDUCED_REPO_TYPE}_REVISION}")

    ## Version
    if (NOT DEFINED GET_DEP_VERSION)
        EMIT_ERROR("VERSION must be passed")
    endif ()
    set(Version "${GET_DEP_VERSION}")

    ##### Variables set
    # # All list vars have a <LIST_NAME>_LEN set about their length
    #
    # Library            : The main library to check
    # RemoteOnly         : Whether to skip checking the system for the library
    # Components         : The components to search for with Library [LIST]
    # HasFallback        : Whether fallback's provided
    # FallbackLibrary    : The fallback library to check
    # FallbackComponents : The components to search for with FallbackLib [LIST]
    # RepoType           : Type of the repository - GIT or SVN
    # RepoTagType        : Type of the repository's versioning thing: GIT_TAG/SVN_REVISION
    # URL                : The git/SVN repo URL to install from if not found
    # Version            : The git tag/SVN revision to install if not found
    ## ARGUMENT HANDLING END ###################################################

    ## Main library
    if (Components_LEN EQUAL 0)
        find_package("${Library}" QUIET)
    else ()
        find_package("${Library}" COMPONENTS ${Components} QUIET)
    endif ()

    if ("${${Library}_FOUND}")
        message(STATUS "Loaded dependency from system: '${Library}'")
        set("${Library}_LINK_AS" ${Library})
        return()
    endif ()

    ## Fallback library
    if (HasFallback)
        if (FallbackComponents_LEN EQUAL 0)
            find_package("${FallbackLibrary}" QUIET)
        else ()
            find_package("${FallbackLibrary}" COMPONENTS ${FallbackComponents} QUIET)
        endif ()

        if ("${${FallbackLibrary}_FOUND}")
            message(STATUS "Loaded fallback dependency from system: '${FallbackLibrary}' "
                    "for dependency: '${Library}'")
            set("${Library}_LINK_AS" ${FallbackLibrary})
            return()
        endif ()
    endif ()

    ## Install
    message(STATUS "Could not load dependency from system: '${Library}' - Installing")
    FetchContent_Declare(
            "${Library}"
            "${RepoType}_REPOSITORY" "${URL}"
            "${RepoTagType}" "${Version}"
    )
    FetchContent_MakeAvailable("${Library}")
endfunction()
