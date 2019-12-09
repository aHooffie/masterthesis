/******************************************************************************
 * File 	      	generalmetrics.rsc
 * Package			lang::crds::analysis
 * Brief       		Checks rule definitions of prototype.
 * Contributor	 	Andrea van den Hooff - UvA
 * Date        		December 2019
 ******************************************************************************/

module lang::crds::analysis::generalmetrics

import lang::crds::analysis::grammaranalysis;
import lang::crds::basis::ast;
import util::Prompt;
import util::Math;


import Exception;
import IO;
import List;
import Set;

data ruleSet 
 = r(map[str def, list[Action] actions] rules);
 
data Stats
 = stats(int teams, int players, int minplayers, int maxplayers,
 		 int decks, int cards,
 		 int stages,
 		 int tokens,
 		 list[str] gameflow);
 		 
data InfoStages
 = is(map[str name, int n] req,
 	  map[str name, int n] opt,
 	  map[str name, int n] decisions);

/******************************************************************************
 * Main function to loop over tree created of the grammar.
 ******************************************************************************/
void analysePrototype(loc gamefile) {
	CRDSII AST = createTree(gamefile);
	
	list[str] knownTeams = [];
	list[str] knownPlayers = [];
	bool scoring = false;
	bool ii = false;
	int knownCards = 0;
	ruleSet r = r(());
	Stats s = stats(0, 0, 0, 0, 0, 0, 0, 0, []);
	InfoStages is = is((), (), ());
	
	println("------------------------------------------------------------\nPossible improvements based on general card game properties:");
	
	visit(AST) {
		// First count all statistics of general objects.
		case playerCount(int min, int max): 	{ s.minplayers = min; s.maxplayers = max; }
		case hands(str player, _):				{ if (player notin knownPlayers) { knownPlayers += player; s.players += 1;} }
		case team(_, list[ID] names):			{ knownTeams = checkTeam(knownTeams, names); s.teams += 1; }
		case deck(_, list[Card] cards, _, _, _):{ s.cards = countCards(s.cards, cards); s.decks += 1; }
		case token(_, real min, real max, _, _):{ checkTokens(min, max); s.tokens += 1; }
		
		case stage(ID name, _, _, list[Turn] turns): { s.gameflow += [name.name]; is = addStage(name.name, turns, is); }
		
		case s(_,_):							{ scoring = true; }
		case allcards(_): 						{ scoring = true; }
		case none():							{ ii = true; }
		case top():								{ ii = true; }
		case team():							{ ii = true; }
		case hand(): 							{ ii = true; }
		case hanabi():							{ ii = true; }
		
		// Compute details of turns in stages.										  
		case turnorder(list[ID] names): 		{ checkTurnorder(names); }
		case totalTurns(Exp e): 				{ checkTurncount(e); }
		
		// case stage(_, list[Condition] cdns,
		//	 _, list[Turn] turns): 				{ checkConditions(cdns); }
		// case Action a: 							{ r = addRule(r, a); }
	}	
			
	checkPlayers(s);
	
	if (scoring == false) println("There is no scoring principle. Please fix this if not intended.");
	if (ii == false) println("Everyone can see all objects in play. Please fix this if not intended.");
	
	println();
	printStats(s, is);
	
	if (ii == true) println("There is incomplete information with the current visibility settings.");
	
	
	//printRules(r); // Prints links out, but since so many rather on request
	
		
	return;
}

/******************************************************************************
 * Small helper functions to check simple rules on their validity. 
 ******************************************************************************/
// Player-related checks.
void checkPlayercount(Stats s) {
	int min = s.minplayers;
	int max = s.maxplayers;
	
	if (min < 2 || max < 2) { println("Amount of players cannot be less than 2. Please fix this."); }
	if (min > max) { println("Amount of players should be between a minimum and maximum. Please fix this."); }
	if (s.players < min || s.players > max) { println("Amount of players in game does not match amount of players in rules. Please fix this."); }
	return;
} 

list[str] checkTeam(list[str] knownTeams, list[ID] names) {
	for (name <- names) {
		if (name.name notin knownTeams) knownTeams += name.name;
		else println("Player <name.name> occurs in multiple teams. Please fix this if not intended.");
	}

	return knownTeams;
}

void checkPlayers(Stats s) {
	if (s.teams != 0 && s.teams != s.players) 
		println("Not all players are in a team. Please fix this if not intended.");
	return;
} 

void checkTurnorder(list[ID] names) {
	if (size(distribution(names).occurs) > 1) 
		println("Some players get more turns than others. Please fix this if not intended.");
	return;
}

// Stages-related checks.
void checkTurncount(Exp e) {
	if (val(real r) := e) {
		if (r < 1)
			println("The amount of turns cannot be negative. Please fix this rule."); 
	}
	return;
}

InfoStages addStage(str name, list[Turn] turns, InfoStages is) {
	for (turn <- turns) {
		if (req(Action a) := turn) {
		
			// CHECK FOR BRANCHES
			println("<name>, required action");
			if (name in is.req) is.req[name] += 1;
			else is.req += (name : 1);
		} else if (opt(Action a) := turn) {
			// CHECK FOR BRANCHES
			println("<name>, opt action");
			if (name in is.opt) is.opt[name] += 1;
			else is.opt += (name : 1);
		}  else if (choice(real r, list[Action] actions) := turn) {
			// CHECK FOR BRANCHES
			println("<name>, choice action");
			if (name in is.req) { is.req[name] += toInt(r); }
			else is.req += (name : toInt(r));
		} 
	}
	
	return is;
}

// Card-related checks.
int countCards(int knownCards, list[Card] cards) {
	return knownCards += size(cards);
} 

// Check Tokens
void checkTokens(real min, real max) {
	if (min > max) println("Amount of tokens should be between a minimum and maximum. Please fix this.");
	if (min < 1 || max < 1) println("The amount of tokens cannot be negative. Please fix this rule.");
	return;
}
 /******************************************************************************
  * Print results.
  ******************************************************************************/
//void printRules(ruleSet r) {
//	str var = "";
//	do { var = prompt("We have found rules for the following variables:\n <r.rules.def>.\n For which variable would you like to see the actions?");
//		if (var in r.rules) {
//			println("\n------------------------------------------------------------------------");
//			println("For the following variable: <var>, the next rules have been found:");
//			println("------------------------------------------------------------------------");
//				
//			try {
//				for (rule <- r.rules[var]) {
//					println(readFile(rule@location));
//				}
//			} catch NoSuchKey(): return;
//		}
//	} while (var in r.rules);
//	
//	return;
// }

void printStats(Stats s, InfoStages is) {
	checkPlayercount(s);
	
	println("------------------------------------------------------------");
	println("The following stats have been calculated for this prototype:\n------------------------------------------------------------");
	println("Required # of players :: <s.minplayers> to <s.maxplayers>");
	println("Total # of players    :: <s.players>");
	println("Total # of teams      :: <s.teams>");
	println("Total # of cards      :: <s.cards>");
	println("Total # of decks      :: <s.decks>");
	println("Total # of token types:: <s.tokens>");
	println("Total # of stages     :: <size(s.gameflow)>");
	
	println("Actions per turn per stage ::");
	
	println(is);
	
	for (stagename <- s.gameflow) 
	{	
	    if (stagename in is.req)
	    	println("<stagename> has <is.req[stagename]> required action(s) in each turn.");
	    if (stagename in is.opt)
	    	println("<stagename> has <is.opt[stagename]> optional action(s) in each turn.");
	}
	
	
	return;
}