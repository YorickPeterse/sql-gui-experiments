# SQL GUI Experiments

A GTK 3 GUI for running SQL queries, written in various languages as an
experiment.

None of the code in this repository is production ready. In fact, most of it is
put together hastly as I just wanted to see how things would work out.

Most code uses hardcoded credentials. The implementations only support
PostgreSQL unless stated otherwise.

## Used Languages

* D: only supports MySQL at the moment as I originally wrote it on a laptop that
  didn't have PostgreSQL set up.
* Ruby

## Scrapped Languages

* Go: I tried two different GTK bindings (<https://github.com/mattn/go-gtk> and
  <https://github.com/conformal/gotk3>) but neither work with Go 1.3 at the time
  of writing. The error handling and the utterly broken build/dependency
  management system pissed me off so much that I decided to not write a Go
  implementation myself. At least I now know for sure that all the Go hipsters
  really have no idea what they're doing.

## License

All source code in this repository is licensed under the MIT license unless
specified otherwise. A copy of this license can be found in the file "LICENSE"
in the root directory of this repository.
