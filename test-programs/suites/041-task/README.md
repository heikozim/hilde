Structured concurrency: tasks in scopes, joined handles, channels with two linear ends.

013: a span of a string literal -- region Static, so it cannot dangle -- handed to a task is refused all the same, H3002.

014 to 022: the lending scope.  014 one string read by two tasks at once through a `Lending` scope, the close waiting for both; 015 the scope carried out of its borrow through a variable declared before it (H3064, the region does not exist there), 016 through a variable of region Static (H3060) and 017 left open at the end of the borrow (H4002) -- the region rule the scope rests on; 018 a reference of another borrow (H3066), 019 a write reference (H3067), 020 an argument of a type variable's type (H3068) and 022 a second lending scope (H3069) handed to a task of a lending scope; 021 a lending scope handed to a task of a plain scope (H3070).

023 to 027: the tasks on N threads.  023 two tasks on two workers at the same time -- one spins until the other sets a cell, in up to 20 rounds, a round counting only when the spinner was never switched out; 024 eight producer-consumer pairs, capacities 0, 1 and 3, all at once on the runtime's own number of workers; 025 sixteen tasks of one lending scope reading one string at once on eight workers; 026 the deadlock of 004 with a task on four workers, the same message; 027 HILDE_TASK_THREADS=0 ignored with one line on standard error, the tasks run all the same.

The tests that assert the order of ONE thread -- 001, 002, 003, 006 and 014 -- name HILDE_TASK_THREADS=1 in an env.txt; the order is the first-in-first-out queue of the runtime, kept on one worker.  023, 025 and 026 name the number of workers they need, so that a machine with one processor still runs them on several.

030: with every descriptor of the process in use, openScope answers None, and with descriptors free again a task runs -- the task runtime's pipe cannot be made, and that is an answer, not a stop.

031 to 033: waiting on two channels at once, receiveEither, and asking one without waiting, tryReceive.  031 two producers and main, the values in turn when both channels hold some, a closed channel beside an open one; 032 the three answers of tryReceive; 033 four rounds of two producers and a consumer on four workers.

028 and 029: a task handed an arena of its own, `Standard.TaskArena.spawnWithArena`.  028 the task asks its arena for 100 values and hands it back, and an arena that cannot be made gives the argument back; 029 must not compile: a reference as the argument (H3002, through `spawn` inside).

034 to 038: timers, preemption and blocking calls, each on one worker.  034 receiveWithin: the time runs out on an empty channel, a value comes before a long limit, closed, and capacity 0; 035 sleepFor: main waits at least the time asked, alone without a deadlock, and of two sleeping tasks the one that sleeps less is taken first; 036 main computes in a loop that never waits and the task it started still runs; 037 a task waiting a second for a child process lets a task that sleeps 200 ms print first; 038 a task spawned before a child is forked starts after the fork, also on OpenBSD, where a new stack that began at the very end of its mapping would end the programme.

039: a read gives its worker back, on one worker: a task reads the output of a child that writes a line after two seconds, and main, which let the task run first, must run again within one second.  A read that held the worker would make main wait for the line.

040: every sleeping worker can be woken, on four workers: after one task the three other workers sleep, two wake-ups under one hold of the idle lock leave one of them marked asleep, and the two woken with nothing to do sleep again, marked.

041: deadlines fire while timed receives and the sends that wake them fall together, on four workers.  042: a write fifteen pages below a task's stack lands on a guard page and ends the programme.

043: a scope opened with openScopeWithStack gives its tasks a larger stack: a task recurses about 200 KiB deep, more than the 64 KiB of a task of openScope.

044: a lending scope opened with openLendingWithStack does the same for a task that reads a borrow.
