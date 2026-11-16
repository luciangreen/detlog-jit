:- module(cases, [title/1, case/3]).
:- use_module('../prolog/detlog_jit').
:- use_module(engine).
title('detlog-jit').
pool_g(X) :- rnd_int(0, 4, N), length(L, N), maplist([E]>>rnd_pick([a, b, 1, 2], E), L),
    rnd_int(-5, 9, I), rnd_pick([L, I, red, blue, green, f(x), []], X).
pred_g(P) :- rnd_pick([len, classify, member_of, colour], P).
case(solve, [P, In], solve) :- pred_g(P), pool_g(In).
case(specialise, [P, Os], specialise) :- pred_g(P), rnd_int(1, 5, N), length(Os, N), maplist(pool_g, Os).
case(run_jit, [P, T, In], run_jit) :- pred_g(P), rnd_int(1, 4, N), length(Os, N), maplist(pool_g, Os), specialise(P, Os, T), pool_g(In).
case(matching, [P, In], matching) :- pred_g(P), pool_g(In).
case(deterministic_shapes, [T], deterministic_shapes) :- pred_g(P), rnd_int(1, 5, N), length(Os, N), maplist(pool_g, Os), specialise(P, Os, T).
