Socketeer
=========

Socketeer is a set of messaging demos for Elixir. The demos are:

* broadcast (done)
* user to user (todo)
* asynchronous user to user (todo)
* user to user, where each user has multiple clients (todo)
* asynchronous multiclient user to user (todo)

To start socketeer, run:

```
mix deps.get
mix run --no-halt
open http://localhost:8080
```

Socketeer runs on the [Cowboy HTTP Server](https://github.com/ninenines/cowboy) and registers processes with [gproc](https://github.com/uwiger/gproc).

Feedback
========

If you have any feedback or ways to improve the code, let me know by opening an issue or [emailing me](mailto:alexander.max.shapiro@gmail.com).
