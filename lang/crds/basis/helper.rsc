/******************************************************************************
 * Helper functions
 *
 * File 	      	helper.rsc
 * Package			lang::crds::basis
 * Brief       		Runs Hanabi
 * Contributor	 	Andrea van den Hooff - UvA
 * Date        		August 2019
 ******************************************************************************/


module lang::crds::basis::helper

import lang::crds::basis::ast;
import lang::crds::basis::grammar;
import lang::crds::hanabi::runhanabi;

import util::Math;

import IO;
import List;
import Map;
import Set;
import String;

/******************************************************************************
 * General 
 ******************************************************************************/
// Run a required action.
public tuple [Decks d, Tokens t] runTurn(req(Action action), Decks deck, Tokens ts, Players ps, str currentPlayer) {
	return runAction(action, deck, ts, ps, currentPlayer);
}

// Run a sequence of actions.
public tuple [Decks d, Tokens t] runAction(sequence(Action first, Action second), Decks deck, Tokens ts, Players ps, str currentPlayer) {
	tuple [Decks d, Tokens t] result = runAction(first, deck, ts, ps, currentPlayer);	
							  result = runAction(second, result.d, result.t, ps, currentPlayer);
	return <result.d, result.t>;
}

// Finds the pile the card with attrs should go onto.
public str findCorrectPile(list[str ] attrs, list[str] piles, Decks ds) {
	for (p <- piles) {
		for (val <- ds.conditions[p].val) {
			if (val in attrs) 
				return p;
		}
	}
		
	return "";
}

// Get all the card ID's
public list[str ] getCards(list[Card] cards) {
	list[str ] allCards = [];
	for (card <- cards) {
		if (card(var(ID n), list[Exp] attrs) := card)
			allCards += n.name; 
	}
	
	return allCards;
}


// Returns the list of properties of a set -- incomplete list 
public list[str]getVis(list[Prop] props) { 
	list[str]allVis = [];
	for (prop <- props) {
		if 		(visibility(allcards()) := prop) allVis += "all";
		else if (visibility(none()) := prop) allVis += "none";
		else if (visibility(top()) := prop) allVis += "top";
		else if (visibility(everyone()) := prop) allVis += "everyone";
		else if (visibility(hanabi()) := prop) allVis += "hanabi";
	}
	
	return allVis;
}

public list[str]getAttrs(list[Exp] exprs) {
	list[str]allAttrs = [];
	for (e <- exprs) {
		if (var(ID name) := e) 
			allAttrs += name.name;
		else if (val(real r) := e) 
			allAttrs += toString(toInt(r));
	}
	
	return allAttrs;
}

public list[tuple [str cat, str val]] getConditions(list[Condition] cdns) {
	list[tuple [str cat, str val] cdns] conditions = [];
	for (cdn <- cdns) 
		conditions += getCdn(cdn);
	return conditions;
}

/******************************************************************************
 * Functions to check valid plays.
 ******************************************************************************/
// Check if a sequence can be done
public bool checkPlay(sequence(Action first, Action second), Tokens ts, Decks ds) {
	return (checkPlay(first, ts, ds) && checkPlay(second, ts, ds));
}

// Check if token can be used
public bool checkPlay(useToken(ID object), Tokens ts, Decks ds) {
	if (ts.current[object.name] > 0) 
		return true;
	return false;
}

// Check if token can be returned
public bool checkPlay(returnToken(ID object), Tokens ts, Decks ds) {
	if (ts.current[object.name] < ts.max[object.name]) 
		return true;
	return false;
}

// Check if deck may be shuffled.
public bool checkPlay(shuffleDeck(ID name), Tokens ts, Decks ds) {
	println("SHUFFLE");
	if (size(deck.cardsets[name.name]) >= 0) 
		return true;
	return false;	
}

// Check if there are enough cards in name.
public bool checkPlay(distributeCards(real r, ID name, list[ID] locations), Tokens ts, Decks ds) {
	if (ds.cardsets[name.name] >= size(locations) * r)
		return true;
	return false;
}

// Check if a card can be taken from the pile.
public bool checkPlay(takeCard(ID f, list[ID] to), Tokens ts, Decks ds) {
	if (size(ds.cardsets[f.name]) >= 1) 
		return true;
	return false;
}

// Below are always allowed.
public bool checkPlay(calculateScore(list[ID] objects), Tokens ts, Decks ds) {
	return true;
}

public bool checkPlay(endGame(), Tokens ts, Decks ds) {
	return true;
}

public bool checkPlay(changeTurnorder(Turnorder order), Tokens ts, Decks ds) {
	return true; // not used in Hanabi
}

public bool checkPlay(moveToken(real index, ID f, ID t), Tokens ts, Decks ds) {
	return true; // not used in Hanabi
}

public bool checkPlay(communicate(list[ID] locations, Exp e), Tokens ts, Decks ds) {
	return true; // Only not allowed when no hints, is checked elsewhere. 
}


public bool checkPlay(moveCard(Exp e, list[ID] from, list[ID] to), Tokens ts, Decks ds) {
	return true; // TO DO!!!!
}


public bool checkPlay(opt(Action action), Tokens ts, Decks ds) {
	return checkPlay(action, ts, ds);
}

public bool checkPlay(req(Action action), Tokens ts, Decks ds) {
	return checkPlay(action, ts, ds);
}

public bool checkPlay(choice(real r, list[Action] actions), Tokens ts, Decks ds) {
	actions = [ a | a <- actions, checkPlay(a, ts, ds) == true];
	if (size(actions) == 0) 
		return false;
	return true;
}

/******************************************************************************
 * Functions for pretty printing.
 ******************************************************************************/

public str stringify(list[str]src) {
	str result = "";
	for (s <- src) 
		result += s + ", ";
	
	result = result[0 .. -2];
	return result;
}

public str stringifyNL(list[str]src) {
	 str result = "";
	for (s <- src) 
		result += s + ",\n ";
	
	result = result[0 .. -3];
	return result;
}


// Print the state of the game / decks.
public void printViewableDecks(Decks deck, Players ps, str currentPlayer) {
	
	map[str name, list[str]cards] piles = ();
	map[str name, list[str]cards] hands = ();
	
	for (d <- deck.cardsets) {
		if (d in ps.owners.handLoc) 
			hands += ( d : deck.cardsets[d]);
		else 
			piles += ( d : deck.cardsets[d]);
	}
	println("----------------------------------------------\n----------------------------------------------");
	
	printPiles(piles, deck, ps, currentPlayer);
	printPiles(hands, deck, ps, currentPlayer);
	println("----------------------------------------------\n----------------------------------------------");

	return;
}

// Print the state of the game / decks. -- Missing team / hand 
public void printPiles(map[str name, list[str]cards] piles, Decks deck, Players ps, str currentPlayer) {
	for (p <- piles) {
		if (isEmpty(deck.cardsets[p])) {
			println("<p> has no cards.");
			continue;
		}
		
		if ("everyone" in deck.view[p]) {
			if ("top" in deck.view[p])
				println("<p> has the following cards on top: <last(deck.cardsets[p])>.");
			else if ("all" in deck.view[p])
				println("<p> consists currently of the following cards: <stringify(deck.cardsets[p])>.");
		} else if ("hanabi" in deck.view[p]) {		
			if (ps.owners[currentPlayer] != p)
				println("<p> has the following cards: <stringify(deck.cardsets[p])>.");
		}
	}

	return; 
}

public tuple [str cat, str val] getCdn(xhigher(real r)) {
	return <"value", toString(toInt(r)) + " higher">;
}	

public tuple [str cat, str val] getCdn(higher()) {
	return <"value", "higher">;
}


public tuple [str cat, str val] getCdn(lower()) {
	return <"value", "lower">;
}

public tuple [str cat, str val] getCdn(color(ID name)) {
	return <"color", name.name>;
}

public str addOption(shuffleDeck(ID name)) {
	return "shuffle <name>";
}

public str addOption(distributeCards(real r, ID name, list[ID] locations)) {
	return "distribute <r> cards to <stringify(locations)>";
}

public str addOption(takeCard(ID f, list[ID] to)) {
	return "take a card from your hand to <stringify([ t.name | t <- to])> ";
}

public str addOption(moveCard(Exp e, list[ID] from, list[ID] to)) {
	return "move a card from your hand to one of <stringify([ t.name | t <- to])>";
}

public str addOption(useToken(ID object)) {
	return "use a token <object.name>";
}

public str addOption(returnToken(ID object)) {
	return "return a token <object.name>";;
}

public str addOption(communicate(list[ID] locations, Exp e)) {
	return "give a hint";
}

public str addOption(sequence(Action first, Action second)) {
	return addOption(first);
}

public str addOption(Action a) {
	return "DEFAULT";
}

/******************************************************************************
 * Unused functions.
 ******************************************************************************/

 // Run an optional action.
public tuple [Decks d, Tokens t] runTurn(opt(Action action), Decks deck, Tokens ts, Players ps, str currentPlayer) {
	println("TO DO: Action in turns: opt");
	return <deck, ts>;
}