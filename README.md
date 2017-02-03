# Command Sequence Unoriginal Format

A simplistic file format, meant for read only data.

Sister format for [chunked binary data](https://github.com/rikkimax/cubf).

## Example:

```csuf
.new

Hi <name>

.new 8
.something back 6

Bye <name> loozer

.new

some value

..command for value
.set global
..another command for value
```

## Syntax

Command:

    .<token> <token ...>

Information:

    <token> <token ...>

Information Command:

    ..<token> <token ...>

You may escape the first token, for information use ``\.`` to get ``.``. For a command use ``.\\.`` to get a command that starts with a 
``.``.
Information commands assign a command specifically to a single information entry.
All entries are reset given a specific command, default: ``new``.
