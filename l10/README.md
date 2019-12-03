Lab 10
======

Submit the solution to [Asynchronous shell](#asynchronous-shell)
according to the [Submitting instructions](#submitting)
before Wednesday Dec 9 23:59:59.

*If your solution also solves the [bonus](#bonus-job-control), state it clearly
in the pull request message.*

Asynchronous shell
-------------------

Create a simple "asynchronous shell": it reads commands from stdin and executes
them.  Immediately after starting a process (command) it will return back to
reading another command.  When a process (command) finishes, it will
immediately print it's commandline and return code.

*Note: this means that the output might "intermix" with a commandline
that is just being typed. This is acceptable behaviour, you don't
have to make it "nicer" (i.e. by reprinting the commandline etc.).*

The shell shall display `>` as a prompt when waiting for a command.

The commands are of the form:

    command [arg1 [arg2 ...]]

where command and its arguments are separated by whitespace (space or tab
characters, there is no quoting to include whitespace in arguments) and the
whole line is terminated by a newline character.

You can assume that no command line will be longer then 255 characters (bytes)
and that there will be at most 10 separate arguments (including the command).

For each command (except the special commands below) a message of the form

    = started [N] PID COMMAND

should be show when it is started and another one of the form

    = finished [N] PID COMMAND EXIT_STATUS

should be shown when it finishes. In both messages, N is a sequential
number assigned to the commands, PID is the pid of that process, COMMAND is
the started command (only the first argument / command name) and EXIT_STATUS
is the exit status of the process.

The shell should recognize a couple of special commands:

- `exit`: the shell finishes (it is undefined what should happen with running
  commands),

- `jobs`: lists active (running) commands with their pids. For each currently
  running process print a line of the form

      = running [N] PID COMMAND

- empty command: does nothing, just reprints the prompt.

Note: you don't have to use the low level `read` and `write` calls in this
assignment (i.e. you can use c FILE streams or c++ iostreams), however,
you might have to use them anyway depending on how you handle asynchrony.

The provided `shell.c` contains a simple example that reads a command,
executes it and (synchronously) waits for it to finish before reading the
next one. It's plain C, but if you want to use C++, just rename it to `shell.cpp`
(your commit needs to remote the old `.c` file so there is only one of them in git).

### Example

```
> sleep 10
= started [1] 432 sleep
> echo Hi
= started [2] 435 echo
Hi
= finished [2] 435 echo
> jobs
= running [1] 432 sleep
... 10 seconds later ...
= finished [1] 432 sleep
> exit
```

Note: the prompt ('>') before the `jobs` and `exit` commands will be actually
interleaved with the other output, so it will more probably look like:

```
...
= started [2] 435 echo
> Hi
= finished [2] 435 echo
jobs
= running [1] 432 sleep
> = finished [1] 432 sleep
exit
```

There are two basic ways to implement this task: threads or signals. The
threaded approach is slightly easier to understand and maybe implement, but
less efficient.

#### Threaded implementation

In this approach we spawn a new thread for each command, basically running
`run_command` in it. Note that the original code however reuses (and modifies)
the buffer containing the commmandline!

Because the `jobs` command has to keep track (a list?) of running processes and
processes need to be removed from that list (from corresponding threads), you
will most probably need to synchronize access to this list. Also remember that
you need to clean up the threads (call `pthread_join` or `pthread_tryjoin_np`)
eventually, though it's OK to do that every time the user enters a new command.

As an optimisation, you could also re-use threads instead of finishing / starting
new ones, though the management and  passing new jobs to threads etc will get a
bit more complicated, and you will need to "grow" the number of threads dynamically
anyway when there are too many simultaneous jobs.

Note: you can use the "higher level" C++
[thread support library](https://en.cppreference.com/w/cpp/thread)
in this task if you switch your solution to C++.

#### Signals based implementation

In this approach, we use the `SIGCHLD` signal to get a notification about a
child process finishing. We need to setup a signal handler for SIGCHLD
and call `wait`/`waitpid` when the signal is delivered. Note that instead of
handling it in the handler itself, it's much easier to just call `waitpid`
inside the normal code, because the (blocking) read on `stdin` will be
interrupted by the signal (returns -1 with `errno` == `EINTR` if we set up the
handler without the `SA_RESTART` flag, see `man sigaction`): thus the steps would be:

- Set up the interrupt handler (without the `SA_RESTART` flag, the handler can
  be actually empty).
- The input handling needs to be rewritten, because the `read` command will be
  interrupted when a child finishes.
- When a child finishes (and `read` is interrupted) we need to call `waitpid`
  **without blocking** to check for any finished children (i.e. with `pid`
  argument of -1 and `WNOHANG` as options, see `man waitpid`) and then resume
  reading the input command.

The simplest way to rewrite input handling might be to read into a buffer,
check the children (`waitpid`) every time after read finishes, and check the
buffer for newlines.. (note that one read call could actually read multiple
lines).

And again, you need to make sure that you correctly handle strings.

```c++
void handler(int sig)
{
	// we don't really need to do anything here
}

...
struct sigaction action;

action.sa_handler = &handler;
sigemptyset (&new_action.sa_mask);
action.sa_flags = 0;
sigaction (SIGCHLD, &action, NULL);
...

while (not whole line read) {
	ssize_t ret = read(...);
	if (ret == -1) {
		if (errno == EINTR) {
			// we received a signal, maybe it was SIGCHLD
			int status;
			pid_t pid;
			while ((pid = waitpid(-1, &status, WNOHANG)) > 0) {
				// a child finished
				...
			}
		}
	}
}
```

Bonus: Job control
-------------------

*If you implement this bonus, state it clearly in the pull request message,
otherwise you might not get the bonus points.*

Implement "job control" for your shell. This includes two additional special
commands:

- `stop N`: "pauses" (sends SIGSTOP to) the job number N,
- `cont N`: "resumes" (sends SIGCONT to) the job number N.

When the `stop` command is issued a message of the form

    = stopped [N] PID COMMAND

should be displayed. Similarly when `cont` is issued a message of the form

    = running [N] PID COMMAND

should be displayed. The output of the `jobs` command should be adjusted
accordingly to show the correct state of the job.

Note: for the basic bonus, you don't have to correctly track stop / continue
changes issued from outside your shell (i.e. you don't have to check the real
status of the process in case someone else sent it a SIGSTOP or SIGCONT).
However doing so might gain you another bonus points (please state it clearly
in the pull request, if you do so). See the `WUNTRACED` and `WCONTINUED`
options in `man waitpid`.

Submitting
----------

Submit your solution by modifying and committing required files (`shell.c`, if
you want to use C++ just rename it to `shell.cpp`) under the directory `l10`
and creating a pull request against the `l10` branch.

If you split your solution into multiple files, modify appropriately the
dependencies of the `shell` target in the Makefile

A correctly created pull request should appear in the
[list of PRs for `l10`](https://github.com/pulls?utf8=%E2%9C%93&q=is%3Aopen+is%3Apr+user%3AFMFI-UK-2-AIN-118+base%3Al10).
