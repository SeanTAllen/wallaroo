
# Usage notes, tips, etc.

This doc assumes that the Wallaroo source repo is at `$HOME/wallaroo`
and that your login shell is either the Bourne shell or the Bash
shell.

## Build prerequisites

```
make -C ../../../.. \
    PONYCFLAGS="--verbose=1 -d -Dresilience -Dtrace -Dcheckpoint_trace -Didentify_routing_ids" \
    build-examples-pony-aloc_passthrough build-testing-tools-external_sender \
    build-utils-cluster_shrinker
```

## Basic command use

### Stop all Wallaroo-related processes and delete all state files

```
reset.sh
```

### Prerequisite: Start Wallaroo's sink

```
export PYTHONPATH=$HOME/wallaroo/machida/lib
~/wallaroo/testing/correctness/tests/aloc_sink/aloc_sink /tmp/sink-out/output /tmp/sink-out/abort 7200 > /tmp/sink-out/stdout-stderr 2>&1 &
```

### Start a 1-worker Wallaroo cluster

NOTE: The `poll-ready.sh` script will fail if the sink process is not
already running.

```
. ./sample-env-vars.sh
./start-initializer.sh -n 1
poll-ready.sh -v -a
```

### Start an N-worker Wallaroo cluster

The naming convention for the workers is:

- 1st: `initializer`
- 2nd: `worker1`
- 3rd: `worker2`
- ...etc...

WARNING: DO NOT USE THE `start-worker.sh` script to start
non-`initializer` workers for the first time.

The `sleep` commands are recommended: Wallaroo isn't 100% robust to
a worker joining very close in time to another worker's start.

Let's start a 4-worker cluster by first starting `initializer` and
then starting `worker1` through `worker3`.

```
DESIRED=4
. ./sample-env-vars.sh
./start-initializer.sh -n $DESIRED
sleep 1
DESIRED_1=`expr $DESIRED - 1`
for i in `seq 1 $DESIRED_1`; do ./start-worker.sh -n $DESIRED $i; sleep 1; done
./poll-ready.sh -v -a
```

### Join a worker to an existing Wallaroo cluster

NOTE: You are specifying which worker to join by name.  Because you
can't join or shrink the `initializer` worker, it isn't eligible to be
started by this script.  Thus specifying `4` as the argument will
start `worker4` and join it to the already-running `initializer`
worker.

Let's join `worker4`.

```
. ./sample-env-vars.sh
./join-worker.sh -n 1 4
sleep 1
./poll-ready.sh -v -a
```

### Join N workers to an existing Wallaroo cluster

NOTE: See note in "Join a worker to an existing Wallaroo cluster"
above.

WARNING: DO NOT USE THE `join-worker.sh` script to start
non-`initializer` workers for the first time.

The `sleep` commands are recommended: Wallaroo isn't 100% robust to
a worker joining very close in time to another worker's join.

Let's start 4 workers: `worker5` through `worker8`.

```
. ./sample-env-vars.sh
for i in `seq 5 8`; do ./join-worker.sh -n 4 $i; sleep 1; done
./poll-ready.sh -v -a
```

### Shrink the cluster by 1 worker

NOTE: This is a helper script that wraps invocation of the
`cluster_shrinker` utility.  It uses the same argument-to-name
convention as the `start-worker.sh` and `join-worker.sh` scripts: if
you specify `6`, then it will shrink away the `worker6` worker.

Let's shrink `worker6`.

```
. ./sample-env-vars.sh
./shrink-worker.sh 6
sleep 1
./poll-ready.sh -v -a
```

### Crash worker `N`

NOTE: This script extends the naming scheme to allow the argument `0`
to mean the `initializer` worker.

Let's crash `initializer`.

```
. ./sample-env-vars.sh
./crash-worker.sh 0
sleep 1
./poll-ready.sh -v -a
```

### Restart the `initializer` after a crash

```
. ./sample-env-vars.sh
./start-initializer.sh
```

### Restart worker `N` instead of `initializer` after a crash

Let's restart 1 worker, `worker5`.

```
. ./sample-env-vars.sh
./start-worker.sh -n 1 5
```


