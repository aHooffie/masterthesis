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
import util::Prompt;

import IO;
import List;
import Set;

data ruleSet 
 = r(map[str def, list[Action] actions] rules);

/******************************************************************************
 * Main function to loop over tree created of the grammar.
 ******************************************************************************/
void foo() {
	CRDSII AST = createTree(|project://masterthesis/src/lang/samples/hanabi.crds|);
	
	list[str] knownTeams = [];
	list[str] knownPlayers = [];
	bool scoring = false;
	int knownCards = 0;
	ruleSet r = r(());
	
	visit(AST) {
		case playerCount(int min, int max): 	{ checkPlayers(min, max); }
		case turnorder(list[ID] names): 		{ checkTurnorder(names); }
		case token(_, real r, _, _):			{ checkToken(r); }
		case deck(_, list[Card] cards, _, _): /*, _):*/	{ knownCards = countCards(knownCards, cards); }
		case team(_, list[ID] names):			{ knownTeams = checkTeam(knownTeams, names); }
		case hands(str player, _):				{ if (player notin knownPlayers) knownPlayers += player; }
		case s(_,_):							{ scoring = true; }
		case allcards(_): 						{ scoring = true; }
		case totalTurns(Exp e): 				{ checkTurncount(e); }
		case stage(_, list[Condition] cdns,
			 _, list[Turn] turns): 				{ checkConditions(cdns); }
		case Action a: 							{ r = addRule(r, a); }
	}	
	
	checkCards(knownCards);
	checkPlayers(knownPlayers, knownTeams);
	
	if (scoring == false) println("There is no scoring principle. Please double check and fix this rule.");
	
	//printRules(r); // Prints links out, but since so maany rather on request
		
	return;
}

/******************************************************************************
 * Functions to create the sets of rules.
 ******************************************************************************/

ruleSet addRule(ruleSet r, Action a) {
	visit (a) {
		case shuffleDeck(ID name): 									{ r = addAction(r, name.name, a); }
 		case returnToken(ID object):								{ r = addAction(r, object.name, a); }
 		case useToken(ID object): 									{ r = addAction(r, object.name, a); }
		case takeCard(ID f, list[ID] t):							{ r = addAction(r, f.name, a); 
																	  for (name <- t) r = addAction(r, name.name, a); }
 		case moveToken(real index, ID f, ID t):						{ r = addAction(r, f.name, a); r = addAction(r, t.name, a); }
		case distributeCards(_, ID name, list[ID] locations): 		{ r = addAction(r, name.name, a); 
 																	  for (l <- locations) r = addAction(r, l.name, a); }
		case moveCard(Exp e, list[ID] from, list[ID] to):  			{ for (name <- from) r = addAction(r, name.name, a); 
																	  for (name <- to) r = addAction(r, name.name, a); }
		case communicate(list[ID] locations, Exp e): 				{ for (name <- locations) r = addAction(r, name.name, a); }
 		case calculateScore(list[ID] objects): 						{ for (name <- objects) r = addAction(r, name.name, a); }
	 	//	case obtainKnowledge(ID name): {} 		// TO FIX. 
 		
	}
	
	return r;
}

ruleSet addAction(ruleSet r, str name, Action a) {
	if (name in r.rules.def) {
		r.rules[name] += a;
	} else {
		r.rules += (name : [a]);
	}
	
	return r;
}


void printRules(ruleSet r) {
	str boo = "";
	do { boo = prompt("We have found rules for the following variables:\n <r.rules.def>.\n For which variable would you like to see the actions?");
		if (boo in r.rules) {
			println("\n------------------------------------------------------------------------");
			println("For the following variable: <boo>, the next rules have been found:");
			println("------------------------------------------------------------------------");
				
			try {
				for (rule <- r.rules[boo]) {
					println(readFile(rule@location));
				}
			} catch NoSuchKey(): return;
		}
	} while (boo in r.rules);
	
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
		if (r < 1 )
			println("The amount of turns cannot be negative. Please fix this rule."); 
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

void checkConditions(list[Condition] cdns) {
	for (cdn <- cdns) {
		if (stageCondition(Exp e) := cdn) {
			if (gt(Exp e1, Exp e2) := e) { // CHECK INTEGER COMPARISONS
				if (val(real r1) := e1 && val(real r2) := e2 && r1 > r2) println("The condition [<r1> \> <r2>] is always true.");
				else if (val(real r1) := e1 && val(real r2) := e2 && r1 < r2) println("The condition [<r1> \> <r2>] is never true.");
			} else if ( ge(Exp e1, Exp e2) := e) {
				if (val(real r1) := e1 && val(real r2) := e2 && r1 > r2) println("The condition [<r1> \>= <r2>]is always true.");
				else if (val(real r1) := e1 && val(real r2) := e2 && r1 < r2) println("The condition [<r1> \>= <r2>]is never true.");
			} else if (lt(Exp e1, Exp e2) := e) {
				if (val(real r1) := e1 && val(real r2) := e2 && r1 < r2) println("The condition [<r1> \< <r2>]is always true.");
				else if (val(real r1) := e1 && val(real r2) := e2 && r1 > r2) println("The condition [<r1> \< <r2>]is never true.");
			} else if (le(Exp e1, Exp e2) := e) {
				if (val(real r1) := e1 && val(real r2) := e2 && r1 < r2) println("The condition [<r1> \<= <r2>]is always true.");
				else if (val(real r1) := e1 && val(real r2) := e2 && r1 > r2) println("The condition [<r1> \<= <r2>]is never true.");
			} else if (eq(Exp e1, Exp e2) := e) {
				if (val(real r1) := e1 && val(real r2) := e2 && r1 == r2) println("The condition [<r1> == <r2>]is always true.");
				else if (val(real r1) := e1 && val(real r2) := e2 && r1 != r2) println("The condition [<r1> == <r2>]is never true.");
			} else if (neq(Exp e1, Exp e2) := e) { 
				if (val(real r1) := e1 && val(real r2) := e2 && r1 != r2) println("The condition [<r1> != <r2>]is always true.");
				else if (val(real r1) := e1 && val(real r2) := e2 && r1 == r2) println("The condition [<r1> != <r2>]is never true.");
			}
		}
	}
	
	return;
}