/******************************************************************************
 * Hanabi test run
 *
 * File 	      	runHanabi.rsc
 * Package			lang::crds
 * Brief       		Runs Hanabi
 * Contributor	 	Andrea van den Hooff - UvA
 * Date        		August 2019
 ******************************************************************************/


module lang::crds::runHanabi

import lang::crds::analysis;
import lang::crds::ast;
import lang::crds::grammar;

import util::Math;
import IO;
import List;
import Map;
import String;

data Decks 
 = decks(map[str name, list[str] cards] cardsets);
 
data Tokens
 = tokens(map[str name, int amount] tokens);
 
data Players
 = players(map[str name, str handLoc] owners);

/******************************************************************************
 * Run a Hanabi game.
 ******************************************************************************/
void runGame() {
	println("1");
	CRDSII ast = createTree(|project://masterthesis/src/lang/samples/takeCard.crds|);
	
	// First collect all the data.
	Decks deck = decks(());
	Players ps = players(());
	Tokens ts = tokens(());
	
	println("2");
	visit(ast) {
		case deck(ID name, list[Card] cards, _, _): 	{ deck.cardsets += (name.name : getCards(cards)); } 
		case token(ID name, real r, _, _):				{ ts.tokens += ( name.name : r); }
		case hands(str player, ID location):			{ ps.owners += (player : location.name); }
		case gameflow(_, list[Stage] stages): 			{ for (stage <- stages) { deck = runStage(stage, deck, ps);} }
	}
	
	println("Game completed."); 
	 
	return;
}

// Loop over stages.
Decks runStage(Stage stage, Decks deck, Players ps) {
	if (stage(ID name, list[Condition] cdns, dealer(), list[Turn] turns) := stage) { // TO DO 
		for (turn <- turns) deck = runDealerTurn(turn, deck, ps);
	} else if (stage(ID name, list[Condition] cdns, turns(), list[Turn] turns) := stage) {	 
		for (player <- ps.owners) 
			for (turn <- turns) deck = runPlayerTurn(turn, deck, ps, player, cdns); 
	} else if (stage(ID name, list[Condition] cdns, allplayers(), list[Turn] turns) := stage) { // TO DO 
		for (turn <- turns) deck = runAllTurn(turn, deck, ps); 
	} else if (basic(ID name, dealer(), list[Turn] turns) := stage) {
		for (turn <- turns) deck = runDealerTurn(turn, deck, ps); 
	} else if (basic(ID name, turns(), list[Turn] turns) := stage) {  // TO DO 
		for (turn <- turns) deck = runPlayerTurn(turn, deck, ps); 
	} else if (basic(ID name, allplayers(), list[Turn] turns) := stage) {  // TO DO 
		for (turn <- turns) deck = runAllTurn(turn, deck, ps);
	}
	
	return deck;
}


/******************************************************************************
 * Player round-robin turns.
 ******************************************************************************/
// Loop over turns - Execute a player's turn.
Decks runPlayerTurn(Turn turn, Decks deck, Players ps, str currentPlayer, list[Condition] cdns) {
	while (true) {	
		for (cdn <- cdns) if (eval(cdn, deck) == false) return deck;
		println("Your cards are: <deck.cardsets[ps.owners[currentPlayer]]>");
		
		
		if (opt(Action action) := turn) {
			println("Turn - Opt");
		} else if (req(Action action) := turn) {
			println("Turn - Req");
			if (moveCard(Exp e, list[ID] from, list[ID] to) := action) { // filter not allowed decks
				deck = moveCard(deck, e, [f.name | f <- from, ps.owners[currentPlayer] == f.name || "allCards" == f.name],
										 [t.name | t <- to, ps.owners[currentPlayer] == t.name || "allCards" == t.name]);
			} else if (takeCard(ID from, list[ID] to) := action)
				deck = takeCard(deck, from.name, [t.name | t <- to, ps.owners[currentPlayer] == t.name || "allCards" == t.name]);
			else if (moveToken(real index, ID f, ID t) := action) println("bla");
			else if (useToken(ID object) := action) println("bla");
			else if (returnToken(ID object)	:= action) println("bla");
			
		} else if (choice(real r, list[Action] action) := turn) {
			println("Turn - 1 Of");
		}
	}
		
	return deck;
}

// Loop over turns - Execute a player's turn.
Decks runPlayerTurn(Turn turn, Decks deck, Players ps, str currentPlayer) {
	println("Your cards are: <deck.cardsets[currentPlayer]>");


	if (opt(Action action) := turn) {
		println("Turn - Opt");
	} else if (req(Action action) := turn) {
		println("Turn - Req");
		if (moveCard(Exp e, list[ID] from, list[ID] to) := action) { // filter not allowed decks
			deck = moveCard(deck, e, [f.name | f <- from, ps.owners[currentPlayer] == f.name || "allCards" == f.name],
									 [t.name | t <- to, ps.owners[currentPlayer] == t.name || "allCards" == t.name]);
		} else if (takeCard(ID from, list[ID] to) := action)
			deck = takeCard(deck, from.name, [t.name | t <- to, ps.owners[currentPlayer] == t.name || "allCards" == t.name]);
		else if (moveToken(real index, ID f, ID t) := action) println("bla");
		else if (useToken(ID object) := action) println("bla");
		else if (returnToken(ID object)	:= action) println("bla");
		
	} else if (choice(real r, list[Action] action) := turn) {
		println("Turn - 1 Of");
	}
		
	return deck;
}


/******************************************************************************
 * Player actions.
 ******************************************************************************/
 // decks(map[str name, list[str] cards] cardsets);
Decks moveCard(Decks deck, Exp e, list[str] from, list[str] to) {
	println("move <e> <from> to <to>");
	return deck;
}

Decks takeCard(Decks deck, str from, list[str] to) {
	for (int i <- [0 .. size(to)]) {
		tuple [str abc, list[str] newFrom] t = pop(deck.cardsets[from]);
		deck.cardsets[from] = t.newFrom;
		deck.cardsets[to[i]] += t.abc;
		println("-- player <to> took a card from <from>");
	}
	
	return deck;
}

/******************************************************************************
 * Dealer actions.
 ******************************************************************************/
Decks runDealerTurn(Turn turn, Decks deck, Players ps) {
	if (req(Action action) := turn) { // Dealers do not do opt actions, right?
		if (shuffleDeck(ID name) := action)
			deck.cardsets[name.name] = shuffleDeck(deck.cardsets[name.name]);
		else if (distributeCards(real r, ID from, list[ID] locations) := action) {	
			deck = distributeCards(deck, r, [from.name], [ location.name | location <- locations]);
		} // else if (calculateScore(  // To add: turnorder?   // To add: calculate Score.
	}

	return deck;
}


Decks distributeCards(Decks deck, real ncards, list[str] from, list[str] to) {	
	 for ( int i <- [0 .. toInt(ncards)]) {
	 	for (f <- from) {
 		 	for (int j <- [0 .. size(to)]) {
				tuple [str abc, list[str] newFrom] t = pop(deck.cardsets[f]);
				deck.cardsets[f] = t.newFrom;
				deck.cardsets[to[j]] += t.abc;
			}
		}
	 }
	 	
	return deck;
}

list[str] shuffleDeck(list[str] deck) {	// permutations(list) takes too long. (50!)
	newList = [];
	for (int n <- [0 .. size(deck)])  
		newList += takeOneFrom(deck)[0];

	return newList;
}

/******************************************************************************
 * Helper functions
 ******************************************************************************/
 void OneOf(real r, list[Action] action) { // TO DO
	return;
}
 
list[str] getCards(list[Card] cards) {
	list[str] allCards = [];
		
	for (card <- cards) {
		if (card(Exp name, list[Exp] attrs) := card)
			if (var(ID n) := name) allCards += n.name;
	}
		
	return allCards;
}


bool evalNEQ(neq(Exp e1, Exp e2), Decks deck) { // only checks [deck] != [value]
	list[str] currentDeck = [];
	int wantedSize = 0;
	
	if (var(ID name) := e1) {
		currentDeck = deck.cardsets[name.name];
	} 
	
	if (empty() := e2) { wantedSize = 0; } 
	else if (val(real r) := e2) { wantedSize = r; }
	
	return size(currentDeck) != wantedSize;
}


bool evalEQ(eq(Exp e1, Exp e2), Decks deck) {  // only checks [deck] == [value]
	list[str] currentDeck = [];
	int wantedSize = 0;
	
	if (var(ID name) := e1) {
		currentDeck = deck.cardsets[name.name];
	} 
	
	if (empty() := e2) { wantedSize = 0; } 
	else if (val(real r) := e2) { wantedSize = r; }
	
	return size(currentDeck) == wantedSize;
}

bool eval(stageCondition(Exp e), Decks deck) {
	bool b;
	if (neq(Exp e1, Exp e2) := e) b = evalNEQ(e, deck);
	else  if (eq(Exp e1, Exp e2) := e) b = evalEQ(e, deck);
	
	return b;
}

/******************************************************************************
 * All players can go at the same time && TEAM turns == TO DO. 
 ******************************************************************************/
// Loop over turns - All players can play.
void runAllTurn(Turn turn, Decks deck, Players ps) {
	if (opt(Action action) := turn) println("All - Opt");
	else if (req(Action action) := turn) println("All - Req");
	else if (choice(real r, list[Action] action) := turn) println("All - 1 Of");
	
	return;
}

void runTeamsTurn(Turn turn, Decks deck, Players ps) {
	if (opt(Action action) := turn) println("All - Opt");
	else if (req(Action action) := turn) println("All - Req");
	else if (choice(real r, list[Action] action) := turn) println("All - 1 Of");
	
	return;
}