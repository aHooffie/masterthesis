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
 		 int gamesize,
 		 list[str] gameflow);
 		 
data InfoStages
 = is(map[str name, int n] opt,
 	  map[str name, int n] maxreq,
 	  map[str name, int n] minreq,
 	  map[str name, int n] maxdecisions,
 	  map[str name, int n] mindecisions);

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
	Stats s = stats(0, 0, 0, 0, 0, 0, 0, 0, 0, []);
	s.gamesize = size(readFileLines(gamefile));
	InfoStages is = is((), (), (), (), ());
	
	println("------------------------------------------------------------\nPossible improvements based on general card game properties:");
	
	visit(AST) {
		// First count all statistics of general objects.
		case playerCount(int min, int max): 	{ s.minplayers = min; s.maxplayers = max; }
		case hands(str player, _):				{ if (player notin knownPlayers) { knownPlayers += player; s.players += 1;} }
		case team(_, list[ID] names):			{ knownTeams = checkTeam(knownTeams, names); s.teams += 1; }
		case deck(_, list[Card] cards, _, _, _):{ s.cards = countCards(s.cards, cards); s.decks += 1; }
		case token(_, real min, real max, _, _):{ checkTokens(min, max); s.tokens += 1; }
		
		case stage(ID name, list[Condition] cdns, _, list[Turn] turns): { 
												  s.gameflow += [name.name];
												  is = addStage(name.name, turns, is);
												  checkConditions(cdns); }
		case basic(ID name, _, _):				{ s.gameflow += [name.name]; }	
	
	
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
		case Action a: 							{ r = addRule(r, a); }
	}	
			
	checkPlayers(s, knownPlayers, knownTeams);
	
	if (scoring == false) println("There is no scoring principle. Please fix this if not intended.");
	if (ii == false) println("Everyone can see all objects in play. Please fix this if not intended.");
	
	println();
	printStats(s, is);	
	
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

void checkPlayers(Stats s, list[str] knownPlayers, list[str] knownTeams) {
	if (size(knownTeams) != 0 && knownTeams != knownPlayers)
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


// Check how many actions and decisions players need to make.
InfoStages addStage(str name, list[Turn] turns, InfoStages is) {
	int minActions = 1, maxActions = 1;
	int minDecisions = 0, maxDecisions = 0;
	for (turn <- turns) {
		firstCheck = true;
		if (req(Action a) := turn) {		
			// Check maximum actions.
			maxActions = collectBranches(b, minActions);
			if (name in is.maxreq) is.maxreq[name] = maxActions;
			else is.maxreq += (name : maxActions);
			if (name in is.minreq) is.minreq[name] += minActions;
			else is.minreq += (name : minActions);
			
			// check if decisions have to be made.
			minDecisions = checkMinDecisions(a, minDecisions);	
			maxDecisions = minMaxDecisions;
		} else if (opt(Action a) := turn) {
			if (name in is.opt) is.opt[name] += 1;
			else is.opt += (name : 1);
			minDecisions += 1;
			maxDecisions = checkMaxDecisions(a, maxDecisions + 1);	
		
		}  else if (choice(real r, list[Action] actions) := turn) {
			int startDecisions = minDecisions + toInt(r);
			int m = 100000000; 
			
			for (b <- actions) {
				n = collectBranches(b, 1);

				if (n > maxActions) maxActions = n; // If more actions in this turn can be done.
				else if (n < minActions || firstCheck == true) { minActions = n; firstCheck = false; } // If less actions in this turn can be done.
				
				maxDecisions = checkMaxDecisions(b, maxDecisions);
				minDecisions = checkMinDecisions(b, startDecisions);
				if (minDecisions < m) m = minDecisions;
			}
			
			if (name in is.maxreq) { is.maxreq[name] += maxActions; }
			else is.maxreq += (name :  maxActions);
			if (name in is.minreq) is.minreq[name] += minActions;
			else is.minreq += (name : minActions);
			
			minDecisions = startDecisions + m;
		} 
	}
	
	is.maxdecisions += (name : maxDecisions);
	is.mindecisions += (name : minDecisions);
	
	return is;
}

int collectBranches(Action a, int nActions) {
	if (sequence(Action first, Action then) := a) {
		nActions = collectBranches(first, nActions + 1);
		nActions = collectBranches(then, nActions);
	}
		
	return nActions;
}

int checkMaxDecisions(Action a, int decisions) {
	if (moveCard(Exp e, list[ID] from, list[ID] to) := a) decisions += 1;
	if (communicate(list[ID] locations, Exp e) := a) decisions += 2;
	if (sequence(Action first, Action then) := a) {
		decisions = checkMaxDecisions(first, decisions);
		decisions = checkMaxDecisions(then, decisions);
	}
	return decisions;
}

int checkMinDecisions(Action a, int decisions) {
	if (moveToken(real index, ID f, ID t) := a || useToken(ID object) := a ||
 	    returnToken(ID object) := a || changeTurnorder(Turnorder order) := a) 
 	    return decisions;
 	    
 	if (moveCard(Exp e, list[ID] from, list[ID] to) := a) return 1;
	if (communicate(list[ID] locations, Exp e) := a) return 2;
 	    
	if (sequence(Action first, Action then) := a) {
		decisions = checkMinDecisions(first, decisions);
		decisions = checkMinDecisions(then, decisions);
	}
	
	return decisions;
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
void printRules(ruleSet r) {
	str var = "";
	do { var = prompt("We have found rules for the following variables:\n <r.rules.def>.\n For which variable would you like to see the actions?");
		if (var in r.rules) {
			println("\n------------------------------------------------------------------------");
			println("For the following variable: <var>, the next rules have been found:");
			println("------------------------------------------------------------------------");
				
			try {
				for (rule <- r.rules[var]) {
					println(readFile(rule@location));
				}
			} catch NoSuchKey(): return;
		}
	} while (var in r.rules);
	
	return;
 }

void printStats(Stats s, InfoStages is) {
	checkPlayercount(s);
	
	println("------------------------------------------------------------");
	println("Your prototype was defined in <s.gamesize> lines of code.");
	println("The following stats have been calculated for this prototype:\n------------------------------------------------------------");
	println("Required # of players :: <s.minplayers> to <s.maxplayers>");
	println("Total # of players    :: <s.players>");
	println("Total # of teams      :: <s.teams>");
	println("Total # of cards      :: <s.cards>");
	println("Total # of decks      :: <s.decks>");
	println("Total # of token types:: <s.tokens>");
	println("Total # of stages     :: <size(s.gameflow)>");
	
	println("\nActions per turn per stage ::");
	
	for (stagename <- s.gameflow) 
	{	
	    if (stagename in is.maxreq)
	    	println("-    <stagename> has a minimum of <is.minreq[stagename]> and a maximum of <is.maxreq[stagename]> required action(s) in each turn.");
	    if (stagename in is.opt)
	    	println("-    <stagename> has <is.opt[stagename]> optional action(s) in each turn.");
	}
	
	println("\nDecisions per turn per stage ::");
	for (stagename <- s.gameflow) 	
		if (stagename in is.mindecisions)
	    	println("-    <stagename> has a minimum of <is.mindecisions[stagename]> and a maximum of <is.maxdecisions[stagename]> decisions to make in each turn.");	
	
	return;
}

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