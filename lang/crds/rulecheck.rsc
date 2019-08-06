/******************************************************************************
 * check basic rules	
 *
 * File 	      	rulecheck.rsc
 * Package			lang::crds
 * Brief       		Checks variable definitions and uses on correct usage.
 * Contributor	 	Andrea van den Hooff - UvA
 * Date        		August 2019
 ******************************************************************************/

module lang::crds::rulecheck

import lang::crds::analysis;
import lang::crds::ast;

import IO;
import List;
import Set;


/******************************************************************************
 * Main function to loop over tree created of the grammar.
 ******************************************************************************/
void foo() {
	CRDSII AST = createTree(|project://masterthesis/src/lang/samples/hanabi.crds|);
	//Scope LUT = createLUT(|project://masterthesis/src/lang/samples/hanabi.crds|);
	
	list[str] knownTeams = [];
	list[str] knownPlayers = [];
	bool scoring = false;
	int knownCards = 0;
	
	visit(AST) {
		case playerCount(int min, int max): 	{ checkPlayers(min, max); }
		case turnorder(list[ID] names): 		{ checkTurnorder(names); }
		case token(_, real r, _, _):			{ checkToken(r); }
		case basic(_, _, list[Turn] turns): 	{ checkTurns(turns); }
		case deck(_, list[Card] cards, _, _):	{ knownCards = countCards(knownCards, cards); }
		case team(_, list[ID] names):			{ knownTeams = checkTeam(knownTeams, names); }
		case hands(str player, _):				{ if (player notin knownPlayers) knownPlayers += player; }
		case s(_,_):							{ scoring = true; }
		case allcards(_): 						{ scoring = true; }
		case totalTurns(Exp e): 				{ checkTurncount(e); }
		case stage(_, list[Condition] cdns, _, list[Turn] turns): {	checkConditions(cdns); checkTurns(turns); }
	}	
	
	checkCards(knownCards);
	checkPlayers(knownPlayers, knownTeams);
	
	if (scoring == false) println("There is no scoring principle. Please double check and fix this rule.");
	
	println(testtt);
	
	return;
}


/******************************************************************************
 * Small helper functions to check simple rules on their validity. 
 ******************************************************************************/

int countCards(int knownCards, list[Card] cards) {
	return knownCards += size(cards);
}

void checkPlayers(int min, int max) {
	if (min < 1 || max < 1) println("Amount of players cannot be negative. Please fix this rule.");
	if (min > max) println("Amount of players should be between a minimum and maximum. Please fix this rule.");
	if (min < 2 || max > 10) println("Amount of players is unusual. Please double check this rule.");
	return;
}

void checkToken(real r) {
	if (r < 1 ) println("The amount of tokens cannot be negative. Please fix this rule.");
	return;
}

void checkTurncount(Exp e) {
	if (val(real r) := e) {
		if (r < 2 )
			println("The amount of turns cannot be 1 or negative. Please fix this rule."); 
	}
	return;
}

void checkTurnorder(list[ID] names) {
	if (size(distribution(names).occurs) > 1) println("Some players get more turns than others. Please fix this rule.");
	return;
}

void checkCards(int cards) {
	if (cards < 10) println("There are very few cards in the game. Please fix this rule.");
	return;
}

void checkPlayers(list[str] knownPlayers, list[str] knownTeams) {
	if (size(knownTeams) != 0 && size(knownTeams) != size(knownPlayers)) 
		println("Not all players are in a team. Please fix this rule.");
}

list[str] checkTeam(list[str] knownTeams, list[ID] names) {
	for (name <- names) {
		if (name.name notin knownTeams) knownTeams += name.name;
		else println("Player <name.name> occurs in multiple teams. Please fix this rule.");
	}

	return knownTeams;
}

void checkTurns(list[Turn] turns) {
	println("TURNS");
	iprintln(turns);
	return;
}

void checkConditions(list[Condition] cdns) {
	println("CONDITIONS");
	iprintln(cdns);
	return;
}

