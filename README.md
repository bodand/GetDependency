# GetDependency

The CMake-only dependency manager. 

## Motivation

Many people use CMake. Most of them also misuse it, by the way, which makes most people think CMake is horrendous.
While CMake is not the best thing since sliced bread, it is a good piece of software for project management.

The problem comes from dependencies.  
It aways does in C++, doesn't it?
There are a few attempts to make a C++ dependency manager, including JFrog's `conan` and Microsoft's `vcpkg`.
Also, there was a CMake project manager `Hunter` if anyone remembers it.
So, dear bodand, why not use any of those to manage my dependencies?
I don't know, but I do know why I don't. They are as follows.

### Conan

Conan relies on Python to do the heavy lifting of the system. This is bad because 1) I don't like Python; 
and 2) users need to have Python installed to work with your projects.
Also having to use another executable to work with projects is slightly inconvenient:

 1) `conan` to install the dependencies
 2) `cmake` to configure the project
 3) `make`/`ninja`/etc to build the project

While the first two can be merged to be done by CMake, what do we gain from not doing it in CMake completely?
Nothing much.

## vcpkg

The most obvious problem: it has `vc` in its name. /s?

It installs everything system-wide. What if I didn't want to have all these installed, because I'm just trying
to build this one project? 

The other problem is that it provides, according to my knowledge, no file-based dependency listing to automatically
install. You can integrate it with CMake, but then it also means that you need to somehow install it first, which involves building an executable,
which means we are back with the problem of too many tools, but instead of Python we now need the vcpkg executable.
Slightly better, but still not the greatest.

## Hunter

Hunter is cool, cold rather. Literally. It's [dead](https://github.com/ruslo/hunter).

There exists a [fork](https://github.com/cpp-pm/hunter), however, so disregard my futile attempt at humor.

The problem with Hunter is it's trying to solve a problem old CMake is not really capable of doing,
which means the whole codebase is rather large and complex. 
While I do like CMake, this much of it is juts a tad too much to completely understand quickly.
It feels exactly like when Boost.MPL implemented variadic templates in C++98.

Even then, it supports much more than this library, so
I have to give them that. For example, Autotools projects
can be used as dependencies with it as well, then it relies on `ExternalProject_Add` to add them to the project.

It, however, feels a bit clunky to use in my opinion, making me do this:

```cmake
hunter_add_package(Something)
find_package(Something CONFIG REQUIRED)
```

That's one more command than ideal. If you can live with that, be their guest.

### What then?

Most CMake users don't actually know `CMake 3.11+` contains a dependency manager, albeit a 
relatively low-level one.
It's contained in a module `FetchContent` which configuration-time pulls the dependencies from 
the provided sources, and adds them as subprojects, which allows to link with them using 
`target_link_libraries` without polluting your system.

GetDependency literally just wraps that interface, with the extra feature that it checks the system 
by default before mindlessly downloading stuff.

It also allows components to be installed standalone, if the components support it, for exmaple:
Boost.Hana is a self-contained library which relies on nothing, but is part of Boost.
You most likely don't want to rely on the whole of Boost just because you wanted Boost.Hana, now
do you?
GetDependency allows you to, in order,
 1) check the system for Hana; if failed to find it
 2) check the system for Boost; if failed to find it
 3) install Hana, and Hana only.

As far as I know, Hunter cannot do this.

## CMake support

The dependency manager is just a wrapper around `find_package` and `FetchContent` calls.
Because the latter is provided after `CMake 3.11` the project requires that as a minimum 
CMake version.

## Installation & Usage

Installation can be done any way you wish, the only requirement is that the repo's 
`add_subdirectory`'d into the project.
You can just copy the whole thing and add it to your repo if you wish, or use a Git submodule
to get it.  
If you ask me, I use it with `FetchContent`:  
Have a `dependencies.cmake` file which is laid out like so, with example dependencies:

```cmake
## - Insert License notice -

## Install GetDependency
include(FetchContent)
FetchContent_Declare(
    GetDependency
    GIT_REPOSITORY https://github.com/isbodand/GetDependency.git
    GIT_TAG v1.0.2
)
FetchContent_MakeAvailable(GetDependency)

## Build dependencies
# {fmt}
GetDependency(
    fmt
    REPOSITORY_URL https://github.com/fmtlib/fmt.git
    VERSION 6.2.1
)

## Test Dependencies
if (${PROJECT_NAME}_BUILD_TESTS)
    # Catch2
    GetDependency(
        Catch2
        REPOSITORY_URL https://github.com/catchorg/Catch2.git
        VERSION v2.12.1
    )
endif ()

```
Then include it in your main `CMakeLists.txt`.

## The GetDependency command

### Synopsis
```cmake
GetDependency(
   <DEPENDENCY_TO_SEARCH: STRING>
   REPOSITORY_URL <URL: STRING>
   VERSION <GIT_TAG|SVN_REVISION: STRING>
   [REMOTE_ONLY]
   [COMPONENTS <COMPONENTS: STRING...>]
   [FALLBACK <LIBRARY_NAME: STRING>
   [FALLBACK_COMPONENTS <COMPONENTS: STRING...>]]
)
```

Required parameters:

 - `<DEPENDENCY_TO_SEARCH: STRING>` - The name of the dependency to search for on the system. 
  If it's not found it is used as the identifier to `FetchContent_Declare` which can optimize 
  out calls to install the same dependency, so using a common name to refer to a project is advised.

 - `REPOSITORY_URL <URL: STRING>` - The URL of the git or SVN repository to clone the sources from.
  Git repositories are to end with `.git`, so it's not the GitHub repo homepage. If it does not end 
  with `.git` it will be understood as a SVN repo.

 - `VERSION <GIT_TAG|SVN_REVISION: STRING>` - The git tag, or the SVN revision, to check out.

Optional parameters:
 - `REMOTE_ONLY` - If provided the checking the system for the dependency is skipped and the 
  dependency will be downloaded even if the system already has it installed.
  If this is provided all options documented after this, as they relate to finding the
  system's install, are ignored silently.

 - `COMPONENTS <COMPONENTS: STRING...>` - When searching the system for the dependency also
  check if these components are present.

 - `FALLBACK <LIBRARY_NAME: STRING>` - If the main library  was not found check this library
  as well. Useful if you are trying to get a part of Boost, for example, and first you search
  for that part only, then tell GetDependency that a complete Boost install also works. 

 - `FALLBACK_COMPONENTS <COMPONENTS: STRING...>` - When searching the system for the fallback
  dependency also check if these components are present. If `FALLBACK` is not specified this option aborts configuration.

## License

Contrary to my other projects, GetDependency is licensed under BSD-0.
Anybody is free to do anything they wish, how they wish, and when they wish.
For more information see the provided *LICENSE* file.