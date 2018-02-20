use_module(library(apply)).
use_module(library(random)).
use_module(library(tabling)).
%listing(subset).

table winner/3.
table score/3.
table is_tie/1.

players(x).
players(o).

other_player(x, o).
other_player(o, x).

valid_position(P) :- P >= 0, 2 >= P, !.
valid_position(P) :-
    format("Invalid position: ~w", [P]),
    nl,
    fail.

each(0).
each(1).
each(2).

winner(X, State) :- three_in_a_row(X, State), X \= empty.
winner(X, State) :- three_in_a_column(X, State), X \= empty.
winner(X, State) :- three_in_a_diagonal(X, State), X \= empty.

is_tie(State) :-
    flatten(State, FlatState),
    not(winner(_, State)),
    not(member(empty, FlatState)).

three_in_a_row(X, State) :- rows(State, [X, X, X]).

rows(State, R) :- nth0(0, State, R).
rows(State, R) :- nth0(1, State, R).
rows(State, R) :- nth0(2, State, R).

three_in_a_diagonal(X, State) :-
    nth0(0, State, R0),
    nth0(1, State, R1),
    nth0(2, State, R2),
    nth0(0, R0, X),
    nth0(1, R1, X),
    nth0(2, R2, X).

three_in_a_diagonal(X, State) :-
    nth0(0, State, R0),
    nth0(1, State, R1),
    nth0(2, State, R2),
    nth0(2, R0, X),
    nth0(1, R1, X),
    nth0(0, R2, X).

three_in_a_column(X, State) :-
    nth0(0, State, R0),
    nth0(1, State, R1),
    nth0(2, State, R2),
    each(I),
    nth0(I, R0, X),
    nth0(I, R1, X),
    nth0(I, R2, X).

possible_moves_list(_, 9, []).

possible_moves_list(State, I, T) :-
    R is I // 3,
    C is I mod 3,
    not(unoccupied(State, R, C)),
    Next is I + 1,
    possible_moves_list(State, Next, T),
    !.

possible_moves_list(State, I, [H|T]) :-
    R is I // 3,
    C is I mod 3,
    H = [R,C],
    Next is I + 1,
    possible_moves_list(State, Next, T),
    !.

possible_moves_list(S, M) :-
    possible_moves_list(S, 0, M).

score(State, Player, Score) :-
    players(OtherPlayer),
    OtherPlayer \= Player,
    winner(OtherPlayer, State),
    Score is -1,
    !.

score(State, Player, Score) :-
    winner(Player, State),
    players(Player),
    Score is 1.

score(State, _, Score) :-
    is_tie(State),
    Score is 0.

score(State, Player, Score) :-
    not(winner(_, State)),
    not(is_tie(State)),
    possible_moves_list(State, Moves),
    score_of_each(State, Player, ScoredMoves, Moves),
    pick_move(ScoredMoves, [Score, _, _]).

score_of_each(_, _, [], []).

score_of_each(State, Player, [[S,R,C]|L], [[R,C]|T]) :-
    get_or_modify(State, 0, R, C, Player, R0),
    get_or_modify(State, 1, R, C, Player, R1),
    get_or_modify(State, 2, R, C, Player, R2),
    N = [ R0, R1, R2],
    other_player(Player, OtherPlayer),
    score(N, OtherPlayer, S_other),
    S is -S_other,
    score_of_each(State, Player, L, T),
    !.

formatted_space(V, Formatted) :-
    V = x, Formatted = x.

formatted_space(V, Formatted) :-
    V = o, Formatted = o.

formatted_space(V, Formatted) :-
    V = empty, Formatted = ' '.

print_state(State) :-
    write("Game State:"),
    nl,
    rows(State, Row),
    print_row(Row),
    fail.

print_row(Row) :-
    nth0(0, Row, V0_raw), formatted_space(V0_raw, V0),
    nth0(1, Row, V1_raw), formatted_space(V1_raw, V1),
    nth0(2, Row, V2_raw), formatted_space(V2_raw, V2),
    format("~a | ~a | ~a", [V0, V1, V2]),
    nl.

unoccupied(State, Row, Col) :-
    nth0(Row, State, RowValue),
    nth0(Col, RowValue, Spot),
    Spot = empty.

start_state(State) :-
    State = [[empty,empty,empty], [empty,empty,empty], [empty,empty,empty]].

print_each_move(_, []) :- fail.

print_each_move(Player, [[R,C]|T]) :-
    format("~a's valid positions (row, col): ~d, ~d", [Player, R, C]),
    nl,
    print_each_move(Player, T).

extract_first([], []).

extract_first([A|B], [A_first|B_extracted]) :-
    nth0(0, A, A_first),
    extract_first(B, B_extracted).

begins_with(B, L) :- nth0(0, L, B).

pick_move(ScoredMoves, [S, R, C]) :-
    msort(ScoredMoves, SortedScoredMoves),
    extract_first(SortedScoredMoves, SortedScores),
    max_list(SortedScores, MaxScore),
    include(call(begins_with, MaxScore), ScoredMoves, FilteredMoves),
    random_member([S, R, C], FilteredMoves).

take_turn(State, _, _) :-
    print_state(State).

take_turn(State, P, _) :-
    possible_moves_list(State, Moves),
    print_each_move(P, Moves).

take_turn(State, CurrentPlayer, NextState) :-
    CurrentPlayer = o,
    possible_moves_list(State, Moves),
    score_of_each(State, CurrentPlayer, ScoredMoves, Moves),
    pick_move(ScoredMoves, [_, R,C]),
    take_turn(State, CurrentPlayer, R, C, NextState).

take_turn(State, CurrentPlayer, NextState) :-
    CurrentPlayer = x,
    format("Enter row for player ~a", [CurrentPlayer]),
	read(Row),
    format("Enter col for player ~a", [CurrentPlayer]),
    read(Col),
    valid_position(Row),
    valid_position(Col),
    unoccupied(State, Row, Col),
    take_turn(State, CurrentPlayer, Row, Col, NextState).

take_turn(State, CurrentPlayer, Row, Col, NextState) :-
    get_or_modify(State, 0, Row, Col, CurrentPlayer, R0),
    get_or_modify(State, 1, Row, Col, CurrentPlayer, R1),
    get_or_modify(State, 2, Row, Col, CurrentPlayer, R2),
    NextState = [ R0, R1, R2].

get_or_modify(State, Row, DesiredChangeRow, _, _, RowOut) :-
    Row \= DesiredChangeRow,
    nth0(Row, State, RowOut).

get_or_modify(State, Row, DesiredChangeRow, Col, Player, RowOut) :-
    Row = DesiredChangeRow,
    Col = 0,
    nth0(Row, State, RowStateOut),
    nth0(1, RowStateOut, C1),
    nth0(2, RowStateOut, C2),
    RowOut = [Player, C1, C2].

get_or_modify(State, Row, DesiredChangeRow, Col, Player, RowOut) :-
    Row = DesiredChangeRow,
    Col = 1,
    nth0(Row, State, RowStateOut),
    nth0(0, RowStateOut, C0),
    nth0(2, RowStateOut, C2),
    RowOut = [C0, Player, C2].

get_or_modify(State, Row, DesiredChangeRow, Col, Player, RowOut) :-
    Row = DesiredChangeRow,
    Col = 2,
    nth0(Row, State, RowStateOut),
    nth0(0, RowStateOut, C0),
    nth0(1, RowStateOut, C1),
    RowOut = [C0, C1, Player].

take_turns(State, _) :-
    winner(_, State),
    print_state(State).

take_turns(State, _) :-
    winner(P, State),
    format("Player ~a won!", [P]).
    %halt.

take_turns(State, _) :-
    is_tie(State),
    format("Both players tied!").

take_turns(State, Player) :-
  Player = x,
  take_turn(State, Player, NextState),
  take_turns(NextState, o).

take_turns(State, Player) :-
    Player = o,
    take_turn(State, Player, NextState),
    take_turns(NextState, x).

% :- initialization(main).
main :-
    start_state(State),
    take_turns(State, x).
