module lang::crds::checkhypotheses

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

data Playerhistory 
 = history(map[str player, list[str] cards] memory);
 
data Checkedhypotheses
 = hyps(list[str] booleans);
 
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
 
data Administration 
 = results(Decks ds, Tokens ts, Players ps, Playerhistory ph, Checkedhypotheses ch, int rounds, int turncount); 
 
/******************************************************************************
 * Run a Hanabi game.
 ******************************************************************************/
void runhypotheses() {	
	// First collect all the data.
	Decks deck = 	decks((), (), (), ());
	Players ps =	players(());
	Tokens ts =		tokens((), ());
	Playerhistory ph = history(());
	Checkedhypotheses ch = hyps([]);
	Administration as = results(deck, ts, ps, ph, ch, 0, 0); // THIS IS A CONFUSED DATA TYPE.
	CRDSII ast;
	list[str] toa;
	
	int n = 5;
	//for (int n <- [1 .. 4]) {	
		switch (n) {
		case 1: { ast = createTree(|project://masterthesis/src/lang/samples/sim1.crds|);
				  toa = readFileLines(|project://masterthesis/src/lang/samples/toa1|); }
		case 2: { ast = createTree(|project://masterthesis/src/lang/samples/sim2.crds|);
		 		  toa = readFileLines(|project://masterthesis/src/lang/samples/toa2|); }
		case 3: { ast = createTree(|project://masterthesis/src/lang/samples/sim3.crds|);
				  toa = readFileLines(|project://masterthesis/src/lang/samples/toa3|); }
		case 4: { ast = createTree(|project://masterthesis/src/lang/samples/sim4.crds|);
				  toa = readFileLines(|project://masterthesis/src/lang/samples/toa4|); }
	  	case 5: { ast = createTree(|project://masterthesis/src/lang/samples/sim5.crds|);
	 	 		  toa = readFileLines(|project://masterthesis/src/lang/samples/toa5|); }
		}
		
		
		// Add data of current game.
		visit(ast) {
			case deck(ID name, list[Card] cards, _, list[Prop] props, list[Condition] cdns):
																		{ as.ds.cardsets += (name.name : getCards(cards));
																		  as.ds.view += (name.name : getVis(props));
																		  as.ds.conditions += (name.name : getConditions(cdns));} 
			case card(var(ID name), list[Exp] attrs):					{ as.ds.cards += ( name.name : getAttrs(attrs)); }
			case token(ID name, real current, real max, _, _):			{ as.ts.max += (name.name : toInt(max));
																 		  as.ts.current += (name.name : toInt(current)); }
			case hands(str player, ID location):						{ as.ps.owners += (player : location.name); }
		}
	
		// Loop over stages to run the game.
		visit(ast) {
			case gameflow(_, list[Stage] stages): 			{ for (stage <- stages) as = runStage(stage, as, toa); } 
		}
		
	//}	
	
	printStatistics(as.ch); 	
	return;
}

/******************************************************************************
 * Player round-robin turns.
 ******************************************************************************/
// Run a stage where the turns consists of each player playing in sequence. 
Administration runStage(stage(ID name, list[Condition] cdns, turns(), list[Turn] turns), Administration as, list[str] toa) {
	for (int n <- [as.turncount .. size(toa)]) {	
		list[str] currentTurn = split(" ", toa[n]);
		str player = currentTurn[0];		
				
		// Run turns of players if conditions allow them.
		for (turn <- turns) {
			// First check the conditions of the stage.
			for (cdn <- cdns) {
				if (eval(cdn, as) == false)	 {
					 as.rounds = 0;
					 return as;
				}
			}
			
			// Pretty print information.
			println("--------------- It is <player>\'s turn ---------------");
			printViewableDecks(as.ds, as.ps, player);
			println("Turn: <as.turncount> of <size(toa) - 1>"); // Bug fixing
			println("<currentTurn>"); 						// Bug fixing 
			
			
			// Check if the actions can be done with current game state.
			if (checkPlay(turn, as.ts, as.ds) == false) {
				println("Cannot run current turn. Please take a look at stage <name> and fix this issue.");
				return as;
			}
			
			// Run the turn.
			as = runAction(turn, as, player, currentTurn);	
		}
		
		as.turncount += 1; // Current player finished turn.	
	}

 	return as;
}

Administration runStage(basic(ID name, turns(), list[Turn] turns), Administration as, list[str] toa) {
	for (int n <- [as.turncount .. size(toa)]) {	
		list[str] currentTurn = split(" ", toa[n]);
		str player = currentTurn[0];		
		
		// Run turns of players.
		for (turn <- turns) {
			if (checkPlay(turn, as.ts, as.ds) == false) {
				println("Cannot run current turn. Please take a look at stage <name> and fix this issue.");
				return as;
			}
			
			// Pretty print information.
			println("--------------- It is <player>\'s turn ---------------");
			printViewableDecks(as.ds, as.ps, player);
			println("Turn: <as.turncount> of <size(toa) - 1>"); // Bug fixing
			println("<currentTurn>"); 						// Bug fixing 
			
			as = runAction(turn, as, player, currentTurn);
		}
		
		as.turncount += 1; // Current player finished turn.
	}

 	return as;
}


 // Take a card in hand from specific pile.
Administration runAction(takeCard(ID from, list[ID] to), Administration as, str currentPlayer) {
	list [str] targets = [target.name | target <- to, currentPlayer == target.name];
	str src = from.name;
	
			
	for (int i <- [0 .. size(targets)]) {
		tuple [str newCard, list[str] newFrom] result = pop(as.ds.cardsets[src]);
		as.ds.cardsets[src] = result.newFrom;
		as.ds.cardsets[as.ps.owners[targets[i]]] += result.newCard;			
		println("<targets[i]> took a new card from the drawpile.");
	}
	
	return as;
}

// Players use and return tokens.
Administration runAction(useToken(ID object), Administration as, str currentPlayer) {
	if (as.ts.current[object.name] == 0) {
		println("CAN NOT USE TOKEN <object.name>. THERE ARE 0.");
		return as;
	}

	as.ts.current[object.name] -= 1;
	println("-------  <currentPlayer> used a token <object.name>, <as.ts.current[object.name]> left. ------- ");
	return as;
}

Administration runAction(returnToken(ID object), Administration as, str currentPlayer) {
	if (as.ts.current[object.name] == as.ts.max[object.name]) {
		println("CAN NOT RETURN TOKEN <object.name>, ALREADY MAX");
		return as;
	}
	
	if (as.ts.current[object.name] < 2 && "A player gave another player more options to execute in the turn" notin as.ch.booleans)
		as.ch.booleans += ["A player gave another player more options to execute in the turn"];

	println("------- <currentPlayer> returned a token <object.name> ------- ");
	as.ts.current[object.name] += 1;
	
	return as;
}

 // Communicate a hint to another player. 
Administration runAction(communicate(list[ID] locations, Exp e), Administration as, str currentPlayer, list[str] currentTurn) {	
	str cat = currentTurn[2];
	str target = currentTurn[4];

	list[int] cardsWithAttr = getCardPositions(as.ds.cardsets[as.ps.owners[target]], cat);	
	if (isEmpty(cardsWithAttr)) { // bug fixing
		println(as.ds.cardsets[as.ps.owners[target]]);
		println(cat); 
		println("There are no cards with this attribute. Please fix your trace of actions");
		return;
	}
	
	println("<target>\'s cards at position(s) <cardsWithAttr> have the attribute \"<cat>\"");
	
	if (target in as.ph.memory)
		as.ph.memory[target] = as.ph.memory[target] + getCardlist(as.ds.cardsets[as.ps.owners[target]], cat); 
	else 
		as.ph.memory[target] = getCardlist(as.ds.cardsets[as.ps.owners[target]], cat);
 
	// Use token.	
	return runAction(useToken(id("hints")), as, currentPlayer);
}

/******************************************************************************
 * Dealer actions. // Not implemented: changing turn order.
 ******************************************************************************/
 // Run dealer turn with conditions 
Administration runStage(stage(ID name, list[Condition] cdns, dealer(), list[Turn] turns), Administration as, list[str] toa) {	
	while (true) {	
		for (turn <- turns) {
		
			// First check the conditions of the stage.
			for (cdn <- cdns) if (eval(cdn, as) == false) {
				as.rounds = 0;
				return as;
			}
			
			// Check if the actions can be done with current game state.
			if (checkPlay(turn, as.ts, as.ds) == false) {
				println("Cannot run current turn. Please take a look at stage <name> and fix this issue.");
				return as;
			}
			
			// Run the turn.			
			as = runAction(turn, as);	
		}
		
		as.turncount += 1; // Current player finished turn.	
	}
}

// Run dealer turn with no conditions
Administration runStage(basic(ID name, dealer(), list[Turn] turns), Administration as, list[str] toa) {
	for (turn <- turns) {
		if (checkPlay(turn, as.ts, as.ds) == false) {
			println("Cannot run current turn. Please take a look at stage <name> and fix this issue.");
			return as;
		}
		
		as = runAction(turn, as);	
	}

	return as;
}

// Dealer actions by partial functions.
Administration runAction( req(distributeCards(real r, ID from, list[ID] locations)), Administration as) {	
	println("--------- Distributing cards ---------");
	list[str] targets = [ location.name | location <- locations];
	
	for (int i <- [0 .. toInt(r)]) {
	 	for (int j <- [0 .. size(targets)]) {
			tuple [str card, list[str] newFrom] result = pop(as.ds.cardsets[from.name]);
			as.ds.cardsets[from.name] = result.newFrom;
			as.ds.cardsets[targets[j]] += result.card;
		}
	}
	 	
	return as;
}

// Dealer actions by partial functions.
Administration runAction(req(shuffleDeck(ID name)), Administration as) {
	println("--------- Shuffling deck ---------");	// permutations(list) takes too long. (50!)
	newList = [];
	
	for (int n <- [0 .. size(as.ds.cardsets[name.name])]) 
		newList += takeOneFrom(as.ds.cardsets[name.name])[0];

	as.ds.cardsets[name.name] = newList;
	
	return as;
}

// Dealer actions by partial functions.
Administration runAction( req(calculateScore(list[ID] objects)), Administration as) {
	println("----------------------------------------------\n------------- Calculating score --------------");
	
	int totalScore = 0;
	list[str] names = [ obj.name | obj <- objects];
	
	for ( name <- names) totalScore += size(as.ds.cardsets[name]);
		
	println("-------------- Total score: <totalScore> --------------- ");
	
	return as;
}
/******************************************************************************
 * FUNCTIONS: X of the following actions 
 ******************************************************************************/
Administration runAction(choice(real r, list[Action] actions), Administration as, str currentPlayer, list[str] currentTurn) {	
	list[str] options = [ addOption(a) | a <- [ a | a <- actions, checkPlay(a, as.ts, as.ds) == true]];
	println("You have the following actions available: \n <stringifyNL(options)>"); // errorprone
	println("----------------------------------------------\n----------------------------------------------");
	
	// Check if multiple cards hinted can be played.
	if (currentPlayer in as.ph.memory) {	
		list[str] knownCards = [ card | card <- as.ds.cardsets[as.ps.owners[currentPlayer]], card in as.ph.memory[currentPlayer]];
		list[str] possiblePlays = [ card | card <- knownCards,
			checkPlay(card, ["bluePile", "yellowPile", "whitePile", "greenPile", "redPile"])];
			
		if (size(possiblePlay) > 1 && "A player knows he can play multiple cards." notin as.ch.booleans)
			as.ch.booleans += ["A player knows he can play multiple cards."];
	}
	
	list[Action] actiontorun;
	
	// UGLY HARDCODED 
	if ("hints" in currentTurn) {
		actiontorun = [ communicate(locations, e) | a <- actions, sequence(communicate(list[ID] locations, Exp e),_) := a];	
		return runAction(actiontorun[0], as, currentPlayer, currentTurn);
	} else if ("plays" in currentTurn) {
		if (size(as.ds.cardsets["allCards"]) == 0)  {// hacky fix
			actiontorun = [ moveCard(e, from, to) | a <- actions, moveCard(Exp e, list[ID] from, list[ID] to) := a];
			return runAction(actiontorun[0], as, currentPlayer, currentTurn);
		} else  {
		 	actiontorun = [ moveCard(e, from, to) | a <- actions, sequence(moveCard(Exp e, list[ID] from, list[ID] to), _) := a];
			return runAction(actiontorun[0], as, currentPlayer, currentTurn);
		}
	} else if ("discards" in currentTurn) {
		if (size(as.ds.cardsets["allCards"]) == 0) {  // hacky fix
			actiontorun = [ moveCard(e, from, to) | a <- actions, sequence(moveCard(Exp e, list[ID] from, list[ID] to), _) := a];
			return runAction(actiontorun[0], deck, as, currentTurn);
		} else {
			actiontorun = [ moveCard(e, from, to) | a <- actions, sequence(sequence(moveCard(Exp e, list[ID] from, list[ID] to), _),_) := a];
			return runAction(actiontorun[0], as, currentPlayer, currentTurn);
		}
	} else
		println("ERROR: Could not understand the action <currentTurn>. Please look at TOA.");
	
	return as;
}

 // Move a card from A to B.
Administration runAction(moveCard(Exp e, list[ID] fromList, list[ID] to), Administration as, str currentPlayer, list[str] currentTurn) {	
	str src = [f.name | f <- fromList, as.ps.owners[currentPlayer] == f.name || "allCards" == f.name][0];
	list[str] targets = [target.name | target <- to];
	str movedCard = currentTurn[2];	
	
	// Check hypotheses
	if (movedCard in as.ph.memory[currentPlayer] && "A player successfully used information obtained thanks to a teammate\'s communication." notin as.ch.booleans)
		as.ch.booleans += ["A player successfully used information obtained thanks to a teammate\'s communication."];
					
	// DISCARDPILE is special case. 
	if (targets == ["discardPile"])
		as = moveCardToDiscard(movedCard, src, as, currentPlayer);

	// Check if card can be played. 
	else if (checkPlay(movedCard, targets, as) == true) {
		str correctPile = findCorrectPile(as.ds.cards[movedCard], targets, as.ds);
		as.ds.cardsets[src] = delete(as.ds.cardsets[src], indexOf(as.ds.cardsets[src], movedCard));
		as.ds.cardsets[correctPile] += movedCard; // addCard
		println("--- Card <movedCard> moved from <src> to <correctPile> ---");
		
		// ADD TOKEN IF FIVE WAS REACHED
		if (size(as.ds.cardsets[correctPile]) == 5) 
			as = runAction(returnToken(id("hints")), as, currentPlayer);
			
	} else { // Else, move card to discardpile and lose life.
		as.ds.cardsets[src] = delete(as.ds.cardsets[src], indexOf(as.ds.cardsets[src], movedCard));
		as.ds.cardsets["discardPile"] += movedCard;
		as.ts.current["lives"] -= 1;
		
		if (movedCard in as.ph.memory[currentPlayer] && "A player misunderstood the information obtained thanks to a teammate\'s communication." notin as.ch.booleans) {
			as.ch.booleans += ["A player misunderstood the information obtained thanks to a teammate\'s communication."];
		}
		
		println("--------- <currentPlayer> tried to play <movedCard>, but it failed.");
		println("--------- <movedCard> is now moved to the discard pile.");		
		println("--------- <currentPlayer> lost a life: <as.ts.current["lives"]> left.");
	}
		

	// TAKE NEW CARD FROM DECK 
	if (size(as.ds.cardsets["allCards"]) != 0)
		return runAction(takeCard(id("allCards"), [id(currentPlayer)]), as, currentPlayer);

	return as;
	
}

// Requires no checks -- can merge when conditions are checked 
Administration moveCardToDiscard(str movedCard, str src, Administration as, str currentPlayer) {
	as.ds.cardsets[src] = delete(as.ds.cardsets[src], indexOf(as.ds.cardsets[src], movedCard));
	as.ds.cardsets["discardPile"] += movedCard; 

	println("--------- <currentPlayer> moved card <movedCard> from <src> to discardPile.");
	
	// return a hint token
	return runAction(returnToken(id("hints")), as, currentPlayer);
}


/******************************************************************************
 * FUNCTIONS TO CHECK CORRECT PLAYS
 ******************************************************************************/
 // TO DO: add more eval options -- now only checks [deck / token ] != [value]
 bool eval(stageCondition(neq(Exp e1, Exp e2)), Administration as) {
	list[str] currentDeck = [];
	int currentToken = 0;
	int wantedSize = 0;
	
	if (empty() := e2) { wantedSize = 0; } 
	else if (val(real r) := e2) { wantedSize = toInt(r); }	
	
	if (var(ID name) := e1) {
		if (name.name in as.ds.cardsets) {		
			currentDeck = as.ds.cardsets[name.name];
			return size(currentDeck) != wantedSize;
		} else {	
			currentToken = as.ts.current[name.name];
			return currentToken != wantedSize;
		}
	}
}

bool eval(totalTurns(Exp e), Administration as) {
	if (val(real r) := e) 
		println("MAX TURNS: <toInt(r)>");
	return true;
}

 // TO DO: add more eval options -- now only checks [deck / token ] == [value]
bool eval(stageCondition(eq(Exp e1, Exp e2)), Administration as) {  // only checks [deck / token] == [value]
	list[str] currentDeck = [];
	int wantedSize = 0;	
	
	if (empty() := e2) { wantedSize = 0; } 
	else if (val(real r) := e2) { wantedSize = r; }
	
	if (var(ID name) := e1) {
		if (name.name in as.ds.cardsets) {
			currentDeck = as.ds.cardsets[name.name];
			return size(currentDeck) == wantedSize;
		} else {
			currentToken = as.ts.current[name.name];
			return currentToken == wantedSize;
		}
	} 	
}


// Check if a card can be moved from A to one of loc [B].
bool checkPlay(str card, list[str] deck, Administration as) {
 	str correctPile = findCorrectPile(as.ds.cards[card], deck, as.ds);
 	if (correctPile == "") return false; 
	if (toString(size(as.ds.cardsets[correctPile] + 1)) notin as.ds.cards[card]) return false;
	
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

list[str] getCardlist(list[str] cards, str cat) {
	list[str] l = [];	
	for (card <- cards) {
		switch (cat){
			case "white": 	if (startsWith(card, "W")) l += card;
			case "W": 		if (startsWith(card, "W")) l += card;
			case "green": 	if (startsWith(card, "G")) l += card;
			case "G": 		if (startsWith(card, "G")) l += card;
			case "yellow":	if (startsWith(card, "Y")) l += card;
			case "Y":		if (startsWith(card, "Y")) l += card;
			case "blue": 	if (startsWith(card, "B")) l += card;
			case "B": 		if (startsWith(card, "B")) l += card;
			case "red": 	if (startsWith(card, "R")) l += card;
			case "R": 		if (startsWith(card, "R")) l += card;
			case "1": if (stringChar(charAt(card, 1)) == "1") l += card;
			case "2": if (stringChar(charAt(card, 1)) == "2") l += card;
			case "3": if (stringChar(charAt(card, 1)) == "3") l += card;
			case "4": if (stringChar(charAt(card, 1)) == "4") l += card;
			case "5": if (stringChar(charAt(card, 1)) == "5") l += card;
		}
	}
	return l;
}

/******************************************************************************
 * Check collaborations
 ******************************************************************************/
 
bool checkCollaboration() {
	bool b = false;
	println("TO DO checkCollaboration");
	return b;
}

void printStatistics(Checkedhypotheses ch) {
	println("\n\nThe following hypotheses have been checked and appeared in this simulated game:\n");
	for (h <- ch.booleans) {
		print(" - ");
		println(h);
	}
}