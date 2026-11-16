% detlog-jit: watch which clauses actually match on real inputs, and build a dispatch table by
% input shape (nil, cons, an integer, an atom, a compound). Where one clause matches a shape,
% that call is deterministic, with no choicepoint; shapes never seen fall back to every clause.
% A predicate is a list of clauses Head-Body over one input and one output, where Head is the
% input pattern and Body is Out^Goal. Solutions are all Outs, in clause order.
%?- solve(len, [a,b], S).                           % S = [2]
%?- specialise(len, [[], [a], [a,b]], T).          % T = [cons-[2], nil-[1]]: each shape has one clause
%?- run_jit(len, [cons-[2], nil-[1]], [a,b,c], S). % S = [3], using only clause 2
:- module(detlog_jit, [pred/2, shape/2, solve/3, matching/3, specialise/3, run_jit/4, deterministic_shapes/2]).
:- use_module(library(lists)).
:- use_module(library(apply)).

% Example predicates, as data (Head-Out^Goal).
pred(len, [ []-(O^(O = 0)), [_|T]-(O^(length(T, N), O is N + 1)) ]).
pred(classify, [ X-(O^(integer(X), X < 0, O = negative)), X-(O^(integer(X), X >= 0, O = natural)), X-(O^(atom(X), O = name)), [_|_]-(O^(O = list)) ]).
pred(member_of, [ [X|_]-(O^(O = X)), [_|T]-(O^member(O, T)) ]).
pred(colour, [ red-(O^(O = warm)), blue-(O^(O = cool)), X-(O^(atom(X), O = other)) ]).

shape(X, var) :- var(X), !.
shape([], nil) :- !.
shape([_|_], cons) :- !.
shape(X, int) :- integer(X), !.
shape(X, atom) :- atom(X), !.
shape(_, compound).

% solve(+Pred, +Input, -Solutions): every solution, trying every clause (the slow, general way).
solve(P, In, S) :- pred(P, Cs), numlist_of(Cs, Is), solve_with(P, Is, In, S).
numlist_of(Cs, Is) :- length(Cs, N), numlist(1, N, Is).
solve_with(P, Is, In, S) :- pred(P, Cs), findall(O, ( member(I, Is), nth1(I, Cs, C), copy_term(C, H-(O^G)), H = In, call(G) ), S0), S = S0.

% matching(+Pred, +Input, -ClauseNumbers): the clauses that gave at least one solution.
matching(P, In, Is) :- pred(P, Cs), findall(I, ( nth1(I, Cs, C), copy_term(C, H-(_^G)), H = In, once(G) ), Is0), Is = Is0.

% specialise(+Pred, +ObservedInputs, -Table): for each shape seen, the clauses that matched any input
% of that shape (sorted Shape-Clauses pairs).
specialise(P, Ins, T) :- findall(Sh-I, ( member(In, Ins), shape(In, Sh), matching(P, In, Is), member(I, Is) ), Ps0),
    sort(Ps0, Ps), group(Ps, T0), T = T0.
group([], []).
group([K-V|Rest], [K-[V|Vs]|Gs]) :- take(K, Rest, Vs, Rest1), group(Rest1, Gs).
take(K, [K2-V|R], [V|Vs], R1) :- K == K2, !, take(K, R, Vs, R1).
take(_, R, [], R).

% run_jit(+Pred, +Table, +Input, -Solutions): only the clauses the table lists for this shape;
% an unseen shape tries every clause.
run_jit(P, T, In, S) :- shape(In, Sh), ( memberchk(Sh-Is, T) -> true ; pred(P, Cs), numlist_of(Cs, Is) ), solve_with(P, Is, In, S).

deterministic_shapes(T, Ds) :- findall(Sh, member(Sh-[_], T), Ds).
