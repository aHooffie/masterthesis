/******************************************************************************
 * Hanabi test run
 *
 * File 	      	runHanabi.rsc
 * Package			lang::crds
 * Brief       		Runs Hanabi
 * Contributor	 	Andrea van den Hooff - UvA
 * Date        		August 2019
 ******************************************************************************/

module lang::crds::runhanabi

import lang::crds::analysis;
import lang::crds::ast;
import lang::crds::grammar;
import lang::crds::helper;

import util::Math;
import util::Prompt;

import IO;
import List;
import Map;
import Set;
import String;
import Type;

data Decks 
 = decks(map[str name, list[str] cards] cardsets,
 		 map[str name, list[str] visibility] view,
 		 map[str name, list[str] attrs] cards,
 		 map[str name, list[tuple [str cat, str val]] cnd] conditions);
 
data Tokens
 = tokens(map[str name, int max] max,
 		  map[str name, int current] current);
 
data Players
 = players(map[str name, str handLoc] owners);
 
/******************************************************************************
 * Run a Hanabi game.
 ******************************************************************************/
void runGame() {
	CRDSII ast = createTree(|project://masterthesis/src/lang/samples/hanabisim1.crds|);

	// First collect all the data.
	Decks deck = 	decks((), (), (), ());
	Players ps =	players(());
	Tokens ts =		tokens((), ());
		
	visit(ast) {
		case deck(ID name, list[Card] cards, _, list[Prop] props, list[Condition] cdns):
																	{ deck.cardsets += (name.name : getCards(cards));
																	  deck.view += (name.name : getVis(props));
																	  deck.conditions += (name.name : getConditions(cdns));} 
		case card(var(ID name), list[Exp] attrs):					{ deck.cards += ( name.name : getAttrs(attrs)); }
		case token(ID name, real current, real max, _, _):			{ ts.max += (name.name : toInt(max));
															 		  ts.current += (name.name : toInt(current)); }
		case hands(str player, ID location):						{ ps.owners += (player : location.name); }
	}
	
	println("----------- Starting game -----------"); 
	
	// Loop over stages to run the game.
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
// Run a stage where the turns consists of each player playing in sequence. 
tuple [Decks d, Tokens t] runStage(stage(ID name, list[Condition] cdns, turns(), list[Turn] turns), Decks deck, Tokens ts, Players ps) {
	while (true) {
		for (player <- ps.owners) {
			// Pretty print information.
			println("------- It is player <player>\'s turn -------");
			printViewableDecks(deck, ps, player);
			
			// Run turns of players if conditions allow them.
			for (turn <- turns) {
				for (cdn <- cdns) if (eval(cdn, deck, ts) == false) return <deck, ts>;			
				if (checkPlay(turn, ts, deck) == false) {
					println("Cannot run current turn. Please take a look at stage <name> and fix this issue.");
					return <deck, ts>;
				}
				
				tuple [Decks d, Tokens t] objects = runAction(turn, deck, ts, ps, player);
				deck = objects.d;
				ts = objects.t;
			}
		}
	}

 	return <deck, ts>;
}

tuple [Decks d, Tokens t] runStage(basic(ID name, turns(), list[Turn] turns), Decks deck, Tokens ts, Players ps) {
	for (player <- ps.owners) {
		// Pretty print information.
		println("------- It is player <player>\'s turn -------");
		printViewableDecks(deck, ps, player);
		
		// Run turns of players.
		for (turn <- turns) {
			if (checkPlay(turn, ts, deck) == false) {
				println("Cannot run current turn. Please take a look at stage <name> and fix this issue.");
				return <deck, ts>;
			}
			
			tuple [Decks d, Tokens t] objects = runAction(turn, deck, ps, ts, player);
			deck = objects.d;
			ts = objects.t;
		}
	}

 	return <deck, ts>;
}


 // Take a card in hand from specific pile.
tuple [Decks d, Tokens t] runAction(takeCard(ID from, list[ID] to), Decks deck, Tokens ts, Players ps, str currentPlayer) {
	deck = takeCard(deck, from.name, [t.name | t <- to, ps.owners[currentPlayer] == t.name || "allCards" == t.name]);
	return <deck, ts> ;
}

// Player takes a card from a specified pile.
Decks takeCard(Decks deck, str from, list[str] to) {
	for (int i <- [0 .. size(to)]) {
		tuple [str newCard, list[str] newFrom] t = pop(deck.cardsets[from]);
		deck.cardsets[from] = t.newFrom;
		deck.cardsets[to[i]] += t.newCard;
		println("------- player took a card from <from> -------");
	}
	
	return deck;
}

// Players use and return tokens.
// TO DO: FIX CHECKPLAY
tuple [Decks d, Tokens t] runAction(useToken(ID object), Decks deck, Tokens ts, Players ps, str currentPlayer){
	if (ts.current[object.name] == 0) { println("CAN NOT USE TOKEN <object.name>. THERE ARE 0."); return <deck, ts>; }

	ts.current[object.name] -= 1;
	println("-------  <currentPlayer> used a token <object.name>. There are now <ts.current[object.name]> left. ------- ");
	return <deck, ts> ;
}

tuple [Decks d, Tokens t] runAction(returnToken(ID object), Decks deck, Tokens ts, Players ps, str currentPlayer){
	if (ts.current[object.name] == ts.max[object.name]) { println("CAN NOT RETURN TOKEN <object.name>, ALREADY MAX"); return <deck, ts>; }

	println("------- <currentPlayer> returned a token <object.name> ------- ");
	ts.current[object.name] += 1;
	return <deck, ts> ;
}

 // Communicate a hint to another player. 
 // TO DO: LESS HARDCODED.
tuple [Decks d, Tokens t] runAction(communicate(list[ID] locations, Exp e), Decks deck, Tokens ts, Players ps, str currentPlayer) {	
	list[str] names = [ player | player <- ps.owners.name, player != currentPlayer];
	println("BLA");
	println(stringify(names));
	str target = "";
	do {
		target = prompt("Please pick a player\'s hand to give a hint to: <stringify(names)>");
	} while (target notin names);			
	
	str cat = "";
	list[str] opts = ["red", "white", "green", "yellow", "blue", "1", "2", "3", "4", "5", "R", "W", "G", "Y", "B"];
	
	do {
		cat =  prompt("Player <target>\'s hand consists of the following cards: \n <deck.cardsets[ps.owners[target]]>.\n Give hint about which color or value?");
	} while (cat notin opts);
	
	list[int] cardsWithAttr =  getCardPositions(deck.cardsets[ps.owners[target]], cat);	
	if (isEmpty(cardsWithAttr)) { 
		println("There are no cards with this attribute. Please retry to give a hint");
		runAction(communicate(locations, e), deck, ts, ps, currentPlayer);
	} else println("<target>\'s cards at position(s) <cardsWithAttr> have the attribute \"<cat>\"");
	
	return <deck, ts>;
}

/******************************************************************************
 * Dealer actions. // Not implemented: changing turn order.
 ******************************************************************************/
 // Run dealer turn with conditions 
tuple [Decks d, Tokens t] runStage(stage(ID name, list[Condition] cdns, dealer(), list[Turn] turns), Decks deck, Tokens ts, Players ps) {	
	while (true) {	
		for (turn <- turns) {
			for (cdn <- cdns) if (eval(cdn, deck, ts) == false) return <deck, ts>;
			
			if (checkPlay(turn, ts, deck) == false) {
				println("Cannot run current turn. Please take a look at stage <name> and fix this issue.");
				return <deck, ts>;
			}
			deck = runAction(turn, deck);
		}
	}
	
	return <deck, ts>;
}

// Run dealer turn with no conditions
tuple [Decks d, Tokens t] runStage(basic(ID name, dealer(), list[Turn] turns), Decks deck, Tokens ts, Players ps) {
	for (turn <- turns) {
		println(turn);
		if (checkPlay(turn, ts, deck) == false) {
			println("Cannot run current turn. Please take a look at stage <name> and fix this issue.");
			return <deck, ts>;
		}
		
		deck = runAction(turn, deck);	
	}
				
	return <deck, ts>;
}

// Dealer actions by partial functions.
Decks runAction( req(distributeCards(real r, ID from, list[ID] locations)), Decks deck) {	
	println("--------- Distributing cards ---------");
	
	list[str] to =  [ location.name | location <- locations];
	for (int i <- [0 .. toInt(r)]) {
	 	for (int j <- [0 .. size(to)]) {
			tuple [str card, list[str] newFrom] t = pop(deck.cardsets[from.name]);
			deck.cardsets[from.name] = t.newFrom;
			deck.cardsets[to[j]] += t.card;
		}
	}
	 	
	return deck;
}

// Dealer actions by partial functions.
Decks runAction(req(shuffleDeck(ID name)), Decks deck) {
	println("--------- Shuffling deck ---------");	// permutations(list) takes too long. (50!)
	newList = [];
	
	for (int n <- [0 .. size(deck.cardsets[name.name])]) 
		newList += takeOneFrom(deck.cardsets[name.name])[0];

	deck.cardsets[name.name] = newList;
	return deck;
}

// Dealer actions by partial functions.
Decks runAction( req(calculateScore(list[ID] objects)), Decks deck) {
	println("--------- Calculating score ---------");
	
	int totalScore = 0;
	list[str] names = [ obj.name | obj <- objects];
	
	for ( name <- names) totalScore += size(deck.cardsets[name]);
		
	println("------- Your total score is <totalScore> ------- ");
	
	return deck;
}
/******************************************************************************
 * FUNCTIONS: X of the following actions 
 ******************************************************************************/
 // TO DO: 
tuple [Decks d, Tokens t] runAction(choice(real r, list[Action] actions), Decks deck, Tokens ts, Players ps, str currentPlayer) {
	actions = [ a | a <- actions, checkPlay(a, ts, deck) == true];	
	list[str] options = [ addOption(a) | a <- actions ];
	int n = 0; 
	
	for (int j <- [1 .. size(options) + 1]) 
		options[j - 1] = toString(j) + ": " + options[j - 1]; 

	for (int i <- [0 .. toInt(r)]) {
		do {
			n = promptForInt("You have the following actions available.\n Please choose the number of the following options: \n  <stringifyNL(options)>"); // errorprone
		} while (n > size(options) || n < 1);
	}
	
	return runAction(actions[n - 1], deck, ts, ps, currentPlayer);
}

//list[str] getActions(list[Action] actions) {
//	list[str] options = [];
//		
//	for (a <- actions) {
//		options += addOption(a);
//	}
//
//	list[str] options = [ addOption(a) | a <- actions ];
//	return options;	
//}	

 // Move a card from A to B.
tuple [Decks d, Tokens t] runAction(moveCard(Exp e, list[ID] fromList, list[ID] to), Decks deck, Tokens ts, Players ps, str currentPlayer) {
	str from = [f.name | f <- fromList, ps.owners[currentPlayer] == f.name || "allCards" == f.name][0];
	list[str] t = [t.name | t <- to];
	str movedCard;	
	int indexCard;
	int handSize = size(deck.cardsets[from]);
		
	// Get the correct card to move.
	if (val(real r) := e) movedCard = deck.cardsets[from][toInt(r)];
    else if (l(LIST l) := e && l(real min, real max) := l) { 
		do {
			indexCard = promptForInt("Please pick a card to move from your hand [1, 2, 3, 4, 5]");
			movedCard = deck.cardsets[from][toInt(indexCard)];
		} while (indexCard > handSize || indexCard < 1); // HANABI SPECIFIC!! 
	}
		
	// DISCARDPILE is special case. 
	if (t == ["discardPile"]) <deck, ts> = moveCardToDiscard(movedCard, from, deck, ts, ps, currentPlayer);

	// Check if card can be played. 
	else if (checkPlay(movedCard, t, deck) == true) {
		str correctPile = findCorrectPile(deck.cards[movedCard], t, deck);
		
		deck.cardsets[from] = delete(deck.cardsets[from], indexOf(deck.cardsets[from], movedCard));
		deck.cardsets[correctPile] += movedCard; // addCard
		println("-------- player moved card <movedCard> from <from> to <correctPile>");
	} else { // Else, move card to discardpile and lose life.
		deck.cardsets[from] = delete(deck.cardsets[from], indexOf(deck.cardsets[from], movedCard));
		deck.cardsets["discardPile"] += movedCard;
		ts.current["lives"] -= 1;
		
		println("--------- <currentPlayer> tried to move card <movedCard>, but it failed.");
		println("--------- <movedCard> is now moved to the discard pile.");		
		println("--------- <currentPlayer> lost a life: <ts.current["lives"]> left.");
	}
	
	// TAKE NEW CARD FROM DECK 
	
	
	<deck, ts> = runAction(takeCard(id("discardPile"), [id("currentPlayer")]), deck, ts, ps, currentPlayer);
	
			
	return <deck, ts>;
}

// Requires no checks -- can merge when conditions are checked 
tuple [Decks d, Tokens t] moveCardToDiscard(str movedCard, str from, Decks deck, Tokens ts, Players ps, str currentPlayer) {
	// move card to discardpile
	deck.cardsets[from] = delete(deck.cardsets[from], indexOf(deck.cardsets[from], movedCard));
	deck.cardsets["discardPile"] += movedCard; 
	
	println("--------- <currentPlayer> moved card <movedCard> from <from> to discardPile.");
	
	// return a hint token
	return runAction(returnToken(id("hints")), deck, ts, ps, currentPlayer);
}


/******************************************************************************
 * FUNCTIONS TO CHECK CORRECT PLAYS
 ******************************************************************************/
 // TO DO: add more eval options -- now only checks [deck / token ] != [value]
 bool eval(stageCondition(neq(Exp e1, Exp e2)), Decks ds, Tokens ts) {
	list[str] currentDeck = [];
	int currentToken = 0;
	int wantedSize = 0;
	
	if (empty() := e2) { wantedSize = 0; } 
	else if (val(real r) := e2) { wantedSize = toInt(r); }	
	
	if (var(ID name) := e1) {
		if (name.name in ds.cardsets) {		
			currentDeck = ds.cardsets[name.name];
			return size(currentDeck) != wantedSize;
		} else {	
			currentToken = ts.current[name.name];
			return currentToken != wantedSize;
		}
	}
}

 // TO DO: add more eval options -- now only checks [deck / token ] == [value]
bool eval(stageCondition(eq(Exp e1, Exp e2)), Decks deck, Tokens ts) {  // only checks [deck / token] == [value]
	list[str] currentDeck = [];
	int wantedSize = 0;	
	
	if (empty() := e2) { wantedSize = 0; } 
	else if (val(real r) := e2) { wantedSize = r; }
	
	if (var(ID name) := e1) {
		if (name.name in deck.cardsets) {
			currentDeck = deck.cardsets[name.name];
			return size(currentDeck) == wantedSize;
		} else {
			currentToken = ts.current[name.name];
			return currentToken == wantedSize;
		}
	} 	
}


// Check if a card can be moved from A to one of loc [B].
bool checkPlay(str card, list[str] deck, Decks ds) {
 	str correctPile = findCorrectPile(ds.cards[card], deck, ds);
 	if (correctPile == "") return false; 
	if (toString(size(ds.cardsets[correctPile] + 1)) notin ds.cards[card]) return false;
	
	return true;
}

/******************************************************************************
 * Small helper functions
 ******************************************************************************/
// Returns a list of cards that have the given attribute CAT
list[int] getCardPositions(list[str] cards, str cat) {
	list[int] l = [];	
	for (card <- cards) {
		switch (cat){
			case "white": 	if (startsWith(card, "W")) l += indexOf(cards, card) + 1;
			case "W": 		if (startsWith(card, "W")) l += indexOf(cards, card) + 1;
			case "green": 	if (startsWith(card, "G")) l += indexOf(cards, card) + 1; 
			case "G": 		if (startsWith(card, "G")) l += indexOf(cards, card) + 1; 
			case "yellow":	if (startsWith(card, "Y")) l += indexOf(cards, card) + 1;
			case "Y":		if (startsWith(card, "Y")) l += indexOf(cards, card) + 1;
			case "blue": 	if (startsWith(card, "B")) l += indexOf(cards, card) + 1;
			case "B": 		if (startsWith(card, "B")) l += indexOf(cards, card) + 1;
			case "red": 	if (startsWith(card, "R")) l += indexOf(cards, card) + 1;
			case "R": 		if (startsWith(card, "R")) l += indexOf(cards, card) + 1;
			case "1": if (stringChar(charAt(card, 1)) == "1") l += indexOf(cards, card) + 1;
			case "2": if (stringChar(charAt(card, 1)) == "2") l += indexOf(cards, card) + 1;
			case "3": if (stringChar(charAt(card, 1)) == "3") l += indexOf(cards, card) + 1;
			case "4": if (stringChar(charAt(card, 1)) == "4") l += indexOf(cards, card) + 1;
			case "5": if (stringChar(charAt(card, 1)) == "5") l += indexOf(cards, card) + 1;
		}
	}
	
	return l;
}
