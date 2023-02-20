# clidev
Bash functions for swift CLI coding work

The motivation for this work is to make more swift the business of
working on a large codebase working solely in the Bash shell.

## Use Case:

Find a file that contains a certain regex and then open it with vim.

```
[ddoxey@dev src]$ search 'expected =='
[1] table.cpp:715:            if (expected == matched
[2] table.cpp:732:            if (expected > 0 && expected == matched)
[3] table.cpp:794:            if (expected == matched
[4] table.cpp:802:            if (expected > 0 && expected == matched)
[5] table.cpp:850:            if (expected == matched
```
Refer to the numbered list to open the file with vim to the indicated line number.
```
[ddoxey@dev src]$ vim 4
```
Later, the Bash history will have the actual vim command executed.
```
[ddoxey@dev src]$ vim +802 table.cpp
```

This is designed to streamline the file search to vim operation in a CLI only environment. 


## Functions Defined

### num

The `num` function simply prepends the lines received on STDIN with the [n] line numbering
and updates the ~/.num database with the results for later reference. 

Number a list of anything.
```
[ddoxey@dev src]$ ls | num
[1] main.cpp
[2] table.cpp
[3] table.hpp
[4] test
```
Then open in `vim`.
```
[ddoxey@dev src]$ vim 3
```
Also use `num` to look up recently `num`bered files.
```
[ddoxey@dev src]$ num 3
table.hpp
```

### findf [<dir>] <pattern>

This is essentially shorthand for `find . -type f` which also filters out Binary files
as well as .swp and .pyc files which no one is likely to want to open in `vim`.

### search <pattern> [<ext>]

This is effectively similar to doing a recursive `grep` on text files. 
The difference being that the pattern is matched on text files (optionally filtered
by the given filename extension) and the results are `num`bered.

