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

void runGame() {
	CRDSII AST = createTree(|project://masterthesis/src/lang/samples/takeCard.crds|);
	Scope LUT = createLUT(|project://masterthesis/src/lang/samples/takeCard.crds|);
	
	// First create data.
	list [str] currentDeck = [];
	
	visit(AST) {
		case gameflow(_, list[Stage] stages): 		{ for (stage <- stages) runStage(stage); }
	}

	return;
}

list[str] getCards() {}


void runStage(Stage stage) {
	//iprintln(stage);
	//if (stage(ID name, list[Condition] cdns, Playerlist plist, list[Turn] turns) := stage) {
		//println(cdns);
	//}
	//if (condition == while)
	// WHILE 
	runTurn(actions);
	
	return;
}

void runTurn() {
	str action = prompt("Your options are distributeCards and Shuffle");
	if (action == "shuffle") shuffle(DECK);
	
	 if (action == "distributeCards") distributeCards(ncards, from, to);
	
	 //if (action == endGame) return;

	return;
}

tuple [list[str], list[str]] distributeCards(int ncards, list[str] from, list[str] to) {
	 for ( int i <- [1 .. ncards]) {
		 tuple [str newCard, list[str]] t = pop(from);
		 to = push(t[newCard], to);
	 }
	
	return <from, to>;
}

list[str] shuffleDeck(list[str] deck) {
	list[list[str]] perms = permutations(deck);
	
	return perms[arbInt(size(perms))];
}


void moveCard() {
	return;
}

