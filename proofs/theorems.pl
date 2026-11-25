% Theorems about detlog-jit, proved by exhaustion. Run: swipl -g main -t halt proofs/theorems.pl
:- module(theorems, [main/0]).
:- use_module('../prolog/detlog_jit').
:- use_module(prove).
:- discontiguous theorem/1.
:- use_module(library(lists)).
:- use_module(library(apply)).
main :- prove_all(theorems).

% Domain: every predicate; inputs from a pool of every shape (several of each); every set of up to 3 observed inputs.
pool([[], [a], [a,b], [1,2,3], 0, 5, -2, red, blue, green, f(x)]).
observed(Os) :- pool(P), between(0, 3, N), length(Os, N), maplist([X]>>member(X, P), Os).

% 1. On every input of a seen shape, observed or not, the specialised run gives exactly the general
%    solutions, in the same order.
theorem(specialised_equals_general_on_seen_shapes) :-
    forall(( pred(P, _), observed(Os), specialise(P, Os, T), pool(Pl), member(In, Pl), shape(In, Sh), memberchk(Sh-_, T) ),
           ( run_jit(P, T, In, S1), solve(P, In, S2), S1 == S2 )).

% 2. Unseen shapes fall back to the general run.
theorem(unseen_shapes_fall_back) :-
    forall(( pred(P, _), observed(Os), specialise(P, Os, T), pool(Pl), member(In, Pl), shape(In, Sh), \+ memberchk(Sh-_, T) ),
           ( run_jit(P, T, In, S1), solve(P, In, S2), S1 == S2 )).

% 3. The table lists exactly the clauses whose heads can match each seen shape, in clause order.
theorem(table_is_the_fitting_clauses) :-
    forall(( pred(P, Cs), observed(Os), specialise(P, Os, T), member(Sh-Is, T) ),
           ( findall(I, ( nth1(I, Cs, H-_), detlog_jit:head_fits(H, Sh) ), Is) )).

% 4. A shape with one clause in the table gives at most as many solutions as that clause alone (no choicepoints added).
theorem(one_clause_shapes_are_single_clause) :-
    forall(( pred(P, _), observed(Os), specialise(P, Os, T), member(Sh-[I], T), member(In, Os), shape(In, Sh) ),
           ( run_jit(P, T, In, S), detlog_jit:solve_with(P, [I], In, S2), S == S2 )).
