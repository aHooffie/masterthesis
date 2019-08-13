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
 = decks(map[str name, list[str] cards] cardsets,
 		 map[str name, list[str] visibility] view);
// 		 map[str name, list[str] cnds] conditions)
 
data Tokens
 = token(	map[str name, int max] max,
 			map[str name, int current] current);
 
data Players
 = players(map[str name, str handLoc] owners);

/******************************************************************************
 * Run a Hanabi game.
 ******************************************************************************/
void runGame() {
	CRDSII ast = createTree(|project://masterthesis/src/lang/samples/hanabi.crds|);
	
	// First collect all the data.
	Decks deck = 	decks((), (), ());
	Players ps =	players(());
	Tokens ts =		tokens((), ());
	
	visit(ast) {
		case deck(ID name, list[Card] cards, _, list[Prop] props, list[Condition] cdns):
																	{ deck.cardsets += (name.name : getCards(cards));
																	  deck.view += (name.name : getVis(props)); }
																	  //deck.conditions += (name.name : getCdns(cdns)); } 
		case token(ID name, real current, real max, _, _):			{ ts.max += (name.name : toInt(max));
															 		  ts.current += (name.name : toInt(current)); }
		case hands(str player, ID location):						{ ps.owners += (player : location.name); }
	}
	
	println("----------- Starting game -----------"); 
	
	// Loop over stages to run the game.-
	visit(ast) {
		case gameflow(_, list[Stage] stages): 			{ for (stage <- stages) { 
															tuple [Decks d, Tokens t] objects = runStage(stage, deck, ts, ps);
															deck = objects.d; 
															ts = objects.t; }
														}				 
	}
	
	println("----------- Game completed -----------"); 
	 
	return;
}

/******************************************************************************
 * Player round-robin turns.
 ******************************************************************************/
tuple [Decks d, Tokens t] runPlayerTurn(Turn turn, Decks deck, Players ps, Tokens ts, str currentPlayer, list[Condition] cdns) {
	println("It is <currentPlayer>\'s turn. Your cards are: <deck.cardsets[ps.owners[currentPlayer]]>");

	while (true) {
		// for (cdn <- cdns) if (eval(cdn, deck, ts) == false) return <deck, ts>;
		printViewableDecks(deck, ps, currentPlayer);
		tuple [Decks d, Tokens t] objects = runActions(turn, deck, ts, ps, currentPlayer);
		deck = objects.d;
		ts = objects.t;
	}
		
	return <objects.d, objects.t> ;
}
 
tuple [Decks d, Tokens t] runPlayerTurn(Turn turn, Decks deck, Players ps, Tokens ts, str currentPlayer) {
	println("It is <currentPlayer>\'s turn. Your cards are: <deck.cardsets[ps.owners[currentPlayer]]>");
	
	tuple [Decks d, Tokens t] objects = runActions(turn, deck, ts, ps, currentPlayer);
	return return <objects.d, objects.t>;
}

/******************************************************************************
 * Player actions.
 ******************************************************************************/
Decks moveCard(Decks deck, Exp e, list[str] f, list[str] t) {
	str movedCard;	
	list[str] from = f[0];
	list[str] to = t[0];
	
	if (val(real r) := action) { 
		movedCard = dec.cardsets[from][r];
		deck.cardsets[from] = delete(deck.cardsets[from], toInt(r) );
		deck.cardsets[to] += t.abc;
		println("-- player moved card <movedCard> from <from> to <to>");
	} else if (l(LIST l) := action && l(real min, real max) := l) { 
		do {
			int r = prompt("Please pick a card to move (<deck.cardsets[from]>), between index <min> to <max>") + 1;
		} while (r < min || r > max);
		
		movedCard = deck.cardsets[from][r];
		deck.cardsets[from] = delete(deck.cardsets[from], toInt(r) );
		deck.cardsets[to] += movedCard;
		println("-- player moved card <movedCard> from <from> to <to>");
	}
	
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
 
// else if (calculateScore(  // To add: turnorder?   // To add: calculate Score.
Decks runDealerTurn(Turn turn, Decks deck, Tokens ts, Players ps) {
	if (req(shuffleDeck(ID name)) := turn)
		deck.cardsets[name.name] = shuffleDeck(deck.cardsets[name.name]);
	else if (req(distributeCards(real r, ID from, list[ID] locations)) := turn)
		deck = distributeCards(deck, r, [from.name], [ location.name | location <- locations]);
	else if (req(calculateScore(list[ID] objects)) := turn)
		calculateScore([ obj.name | obj <- objects], deck);
	return deck;
}

Decks runDealerTurn(Turn turn, Decks deck, Tokens ts, Players ps, list[Condition] cdns) {
	while (true) {	
		for (cdn <- cdns) if (eval(cdn, deck, ts) == false) return <deck, ts>;
		
		if (req(shuffleDeck(ID name)) := turn)
			deck.cardsets[name.name] = shuffleDeck(deck.cardsets[name.name]);
		else if (req(distributeCards(real r, ID from, list[ID] locations)) := turn)
			deck = distributeCards(deck, r, [from.name], [ location.name | location <- locations]);
		// else if (calculateScore(  // To add: turnorder?   // To add: calculate Score.
		
	}
	return deck;
}

Decks distributeCards(Decks deck, real ncards, list[str] from, list[str] to) {	
	println("Distributing cards");
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

list[str] shuffleDeck(list[str] deck) {
	println("Shuffling deck");	// permutations(list) takes too long. (50!)
	newList = [];
	for (int n <- [0 .. size(deck)])  
		newList += takeOneFrom(deck)[0];

	return newList;
}

void calculateScore(list[str] decks, Decks ds) {
	println("Calculating score");
	int totalScore = 0;
	

	for (deck <- decks) 
		totalScore += size(ds.cardsets[deck]);
		
	println("Your total score is <totalScore>");
	
	return;
}

/******************************************************************************
 * Helper functions
 ******************************************************************************/
 void OneOf(real r, list[Action] action) { // TO DO
 	println("TO DO");
	return;
}

void printViewableDecks(Decks d, Players ps, str currentPlayer) {
	for (deck <- d.cardsets) {
		if ("everyone" in d.view[deck]) {
			if ("top" in d.view[deck]) {
				if (!isEmpty(d.cardsets[deck])) println("<deck> has the following cards on top: <last(d.cardsets[deck])>.");
				else println("<deck> has no cards.");
			} else if ("all" in d.view[deck]) {
				if (!isEmpty(d.cardsets[deck])) println("<deck> consists currently of the following cards: <d.cardsets[deck]>.");
				else println("<deck> has no cards.");
			}
		} else if ("hanabi" in d.view[deck]) {
			if (ps.owners[currentPlayer] != deck) {
				if (!isEmpty(d.cardsets[deck])) println("<deck> has the following cards: <d.cardsets[deck]>.");
				else println("<deck> has no cards.");
			}
		}
	}
}
 
list[str] getCards(list[Card] cards) {
	list[str] allCards = [];
		
	for (card <- cards) {
		if (card(var(ID n), list[Exp] attrs) := card)
			allCards += n.name;
	}
		
	return allCards;
}

list[str] getVis(list[Prop] props) {
	list[str] allVis = [];
	for (prop <- props) {
		if (visibility(allcards()) := prop) allVis += "all";
		 else if (visibility(none()) := prop) allVis += "none";
		 else if (visibility(top()) := prop) allVis += "top";
		 else if (visibility(everyone()) := prop) allVis += "everyone";
		 else if (visibility(hanabi()) := prop) allVis += "hanabi";
  		 //else if (visibility(team()) := prop) allVis += "team";		 
		 //else if (hand() := prop) allVis += "hand";
		 //else if (draw() := prop) allVis += "draw";
 		 //else if (discard() := prop) allVis += "discard";	 
	}
	
	return allVis;
}

list[str] getCdns(list[Condition] cdns) {
	list[str] allCdns = [];
	return allCdns;
}	

bool eval(neq(Exp e1, Exp e2), Decks ds, Tokens ts) { // only checks [deck / token ] != [value]
	list[str] currentDeck = [];
	int currentToken = 0;
	int wantedSize = 0;
	
	println("1");
	
	if (empty() := e2) { wantedSize = 0; } 
	else if (val(real r) := e2) { wantedSize = toInt(r); }
	
		println("2");
	
	
	if (var(ID name) := e1) {
		if (name.name in ds.cardsets) {
			println("3");
		
			currentDeck = ds.cardsets[name.name];
			return size(currentDeck) != wantedSize;
		} else {
			println("4");
		
			currentToken = ts.current[name.name];
			return currentToken != wantedSize;
		}
	}
}

bool eval(eq(Exp e1, Exp e2), Decks deck, Tokens token) {  // only checks [deck / token] == [value]
	list[str] currentDeck = [];
	int wantedSize = 0;
	
	println("1");
	
	
	if (empty() := e2) { wantedSize = 0; } 
	else if (val(real r) := e2) { wantedSize = r; }
	
	if (var(ID name) := e1) {
		if (name.name in deck.cardsets) {
			currentDeck = deck.cardsets[name.name];
			return size(currentDeck) == wantedSize;
		} else {
			currentToken = token.current[name.name];
			return currentToken == wantedSize;
		}
	} 	
}


// Check if a card can be moved from A to B. If not, move to discardPile and lose a life. 
// Check if a token can be used.
// Check if a token can be returned.
// Check if a hint can be given (color / number available).
//bool checkPlay() {
// 	bool b;
//	return b;
//}

/******************************************************************************
 * PARTIAL FUNCTIONS
 ******************************************************************************/
tuple [Decks d, Tokens t] runStage(stage(ID name, list[Condition] cdns, dealer(), list[Turn] turns), Decks deck, Tokens ts, Players ps) {
	println("TO DO: Running dealer turn with conditions");
	
	for (turn <- turns) deck = runDealerTurn(turn, deck, ts, ps, cdns);
	
	return <deck, ts >;
}

tuple [Decks d, Tokens t] runStage(basic(ID name, dealer(), list[Turn] turns), Decks deck, Tokens ts, Players ps) {
	println("Running dealer turn without conditions");
	
	for (turn <- turns) deck = runDealerTurn(turn, deck, ts, ps);
	
	return <deck, ts >;
}

tuple [Decks d, Tokens t] runStage(stage(ID name, list[Condition] cdns, turns(), list[Turn] turns), Decks deck, Tokens ts, Players ps) {
	println("Running player turns with conditions");
	for (player <- ps.owners) {
		for (turn <- turns) {
			tuple [Decks d, Tokens t] objects = runPlayerTurn(turn, deck, ps, ts, player, cdns);
			deck = objects.d;
			ts = objects.t;
		}
	}

 	return <objects.d, objects.t >;
}

tuple [Decks d, Tokens t] runStage(basic(ID name, turns(), list[Turn] turns), Decks deck, Tokens ts, Players ps) {
	println("Running player turns without conditions");
	tuple [Decks d, Tokens t] objects = < deck, ts >;
	
	for (player <- ps.owners) {
		for (turn <- turns) {
			tuple [Decks d, Tokens t] objects = runPlayerTurn(turn, deck, ps, ts, player);
			deck = objects.d;
			ts = objects.t;
		}
	}

 	return <objects.d, objects.t >;
}

tuple [Decks d, Tokens t]runActions(opt(Action action), Decks deck, Tokens ts, Players ps, str currentPlayer) {
	println("TO DO: Action in turns: opt");
	return <deck, ts>;
}

tuple [Decks d, Tokens t] runActions(req(Action action), Decks deck, Tokens ts, Players ps, str currentPlayer) {
	tuple [Decks d, Tokens t] objects = runAction(action, deck, ts, ps, currentPlayer);
	
	return <objects.d, objects.t >;
	
}

tuple [Decks d, Tokens t] runActions(choice(real r, list[Action] action), Decks deck, Tokens ts, Players ps, str currentPlayer) {
	println("TO DO: Action in turn: choice");
	return <deck, ts>;
}

tuple [Decks d, Tokens t] runAction(moveCard(Exp e, list[ID] from, list[ID] to), Decks deck, Tokens ts, Players ps, str currentPlayer) {
	deck = moveCard(deck, e, [f.name | f <- from, ps.owners[currentPlayer] == f.name || "allCards" == f.name],
							 [t.name | t <- to, ps.owners[currentPlayer] == t.name || "allCards" == t.name]);
	return <deck, ts> ;
}

tuple [Decks d, Tokens t] runAction(takeCard(ID from, list[ID] to), Decks deck, Tokens ts, Players ps, str currentPlayer) {
	deck = takeCard(deck, from.name, [t.name | t <- to, ps.owners[currentPlayer] == t.name || "allCards" == t.name]);
	return <deck, ts> ;
}

tuple [Decks d, Tokens t] runAction(useToken(ID object), Decks deck, Tokens ts, Players ps, str currentPlayer){
	if (ts.current[object.name] == 0) { println("KAN NIET <object.name> TOKEN USEN"); return <deck, ts>; }
	
	ts.current[object.name] -= 1;
	return <deck, ts> ;
}

tuple [Decks d, Tokens t] runAction(returnToken(ID object), Decks deck, Tokens ts, Players ps, str currentPlayer){
	if (ts.current[object.name] == ts.max[object.name]) { println("KAN NIET <object.name> TOKEN UPPEN"); return <deck, ts>; }
	
	ts.current[object.name] += 1;
	return <deck, ts> ;
}
/******************************************************************************
 * TO DO: All players can go at the same time && TEAM turn.
 ******************************************************************************/