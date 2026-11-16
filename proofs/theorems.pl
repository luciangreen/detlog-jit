% Theorems about detlog-jit, proved by exhaustion. Run: swipl -g main -t halt proofs/theorems.pl
:- module(theorems, [main/0]).
:- use_module('../prolog/detlog_jit').
:- use_module(prove).
:- discontiguous theorem/1.
:- use_module(library(lists)).
:- use_module(library(apply)).
main :- prove_all(theorems).

% Domain: every predicate; inputs from a pool of every shape; every set of up to 3 observed inputs.
pool([[], [a], [a,b], [1,2,3], 0, 5, -2, red, blue, green, f(x)]).
observed(Os) :- pool(P), between(0, 3, N), length(Os, N), maplist([X]>>member(X, P), Os).

% 1. On every input whose shape was observed, the specialised run gives exactly the general solutions,
%    in the same order: when the observed inputs cover the input's clauses (the input itself was seen).
theorem(specialised_equals_general_on_seen_inputs) :-
    forall(( pred(P, _), observed(Os), member(In, Os), specialise(P, Os, T) ), ( run_jit(P, T, In, S1), solve(P, In, S2), S1 == S2 )).

% 2. Unseen shapes fall back to the general run.
theorem(unseen_shapes_fall_back) :-
    forall(( pred(P, _), observed(Os), specialise(P, Os, T), pool(Pl), member(In, Pl), shape(In, Sh), \+ memberchk(Sh-_, T) ),
           ( run_jit(P, T, In, S1), solve(P, In, S2), S1 == S2 )).

% 3. The table lists only clauses that matched: every clause it names matched some observed input of that shape.
theorem(table_is_justified) :-
    forall(( pred(P, _), observed(Os), specialise(P, Os, T), member(Sh-Is, T), member(I, Is) ),
           ( member(In, Os), shape(In, Sh), matching(P, In, M), memberchk(I, M) )).

% 4. A shape with one clause in the table gives at most as many solutions as that clause alone (no choicepoints added).
theorem(one_clause_shapes_are_single_clause) :-
    forall(( pred(P, _), observed(Os), specialise(P, Os, T), member(Sh-[I], T), member(In, Os), shape(In, Sh) ),
           ( run_jit(P, T, In, S), detlog_jit:solve_with(P, [I], In, S2), S == S2 )).
