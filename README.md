# Command Sequence Unoriginal Format

A simplistic file format, meant for read only data.

## Example:

```csuf
.new

Hi <name>

.new 8
.something back 6

Bye <name> loozer
```

## Syntax

Command:

    .<token> <token ...>

Information:

    <token> <token ...>

If first token is to be an information line, then it must be escaped by using ``\``.
All entries are reset given a specific command, default: ``new``.