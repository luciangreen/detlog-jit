# detlog-jit

watch which clauses actually match on real inputs, and build a dispatch table by input shape (nil, cons, an integer, an atom, a compound). Where one clause matches a shape, that call is deterministic, with no choicepoint; shapes never seen fall back to every clause. A predicate is a list of clauses Head-Body over one input and one output, where Head is the input pattern and Body is Out^Goal. Solutions are all Outs, in clause order.

## Use

```prolog
?- use_module(prolog/detlog_jit).
?- solve(len, [a,b], S).                           % S = [2]
?- specialise(len, [[], [a], [a,b]], T).          % T = [cons-[2], nil-[1]]: each shape has one clause
?- run_jit(len, [cons-[2], nil-[1]], [a,b,c], S). % S = [3], using only clause 2
```

## Proofs

`proofs/theorems.pl` proves 4 theorems by exhaustion: each one is checked for every case in a finite domain that covers every branch of the definitions. every predicate; inputs from a pool of every shape; every set of up to 3 observed inputs.

1. On every input whose shape was observed, the specialised run gives exactly the general solutions, in the same order: when the observed inputs cover the input's clauses (the input itself was seen).
2. Unseen shapes fall back to the general run.
3. The table lists only clauses that matched: every clause it names matched some observed input of that shape.
4. A shape with one clause in the table gives at most as many solutions as that clause alone (no choicepoints added).

```sh
swipl -g main -t halt proofs/theorems.pl
```

## 200 inputs and outputs

`io/ios.txt` lists 200 inputs and outputs from real runs, and `io/ios.pl` has the same as Prolog facts. The inputs come from a fixed seed (`io/cases.pl`). `swipl -g check -t halt io/run.pl` runs them again. It fails if any output changes, or if a predicate doesn't confirm its own recorded output, which checks steadfastness. GitHub Actions runs the proofs and the examples on every push, and records the examples on the first push.

Licence: BSD-3-Clause.
