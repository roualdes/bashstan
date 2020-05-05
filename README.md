# bashstan

Unofficial bash shim around [CmdStan](https://github.com/stan-dev/cmdstan).

# Installation

1. Copy the file `stan` to your path.  I use `/usr/local/bin/stan`.

2. If CmdStan is not located at `$HOME/cmdstan`, then change the line
   `cmdstan="$HOME/cmdstan"` in `stan` to point to your copy of
   CmdStan.

3. Copy `local` to the folder `make` within your copy of CmdStan.
   Edit this file if you need/want to.

# Examples

Suppose you have a directory with a model in it named `gaussian.stan`
and a JSON dataset `gaussian.json`.  From within this directory,
calling

```bash
$ stan gaussian
```

will compile your Stan model, create a new directory `gaussian_model`,
and copy appropriate files into it.  To sample run

```bash
$ stan sample [options] gaussian gaussian.json
```

This will create a directory named `gaussian_output` with the standard
CSV files in it.


# Notes

* As it stands, you need to look through the file `stan` to see the
list of options.

* No spaces in file names.
