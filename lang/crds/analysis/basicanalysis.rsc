/******************************************************************************
 * cardscript's abstract syntax 			
 *
 * File 	      	basicanalysis.rsc
 * Package			lang::crds::analysis
 * Brief       		Checks variable definitions and uses on correct usage.
 * Contributor	 	Andrea van den Hooff - UvA
 * Date        		August 2019
 ******************************************************************************/

module lang::crds::analysis::basicanalysis

import lang::crds::basis::ast;
import lang::crds::basis::grammar;

import util::Math;

import Prelude;
import List;
import ParseTree;
import String;
import Type;

int errorsFound = 0;

loc NULL_LOC = |null://null|(0,0,<0,0>,<0,0>);

data Scope
  = scope(str scopeName,
  		 loc l,
  		 map[str defName, loc l] defs,
  		 map[str defName, str nodeType] types,
  		 map[str def, list[loc l] uses] refs);


/******************************************************************************
 * Main function.
 ******************************************************************************/
 
void main(loc f) {
	// Parse and implode the game file.
	Tree parsedFile = parse(#CRDS, f);			
	CRDSII implodedFile = implode(#CRDSII, parsedFile);
	
	// Initiliase datatype.
	Scope lut = scope("global", NULL_LOC, (), (), ());
	
	// Add all ID definitions to the LUT and check all uses. 
	lut = addDefs(implodedFile, lut);
	println("++++++++");
	println(lut);
	iprintln("++++++++");
	
	if (errorsFound != 0) { println("Errors found. Please adjust your game description accordingly."); return; }	
	
	
	checkDefs(implodedFile, lut);
	if (errorsFound != 0) { println("Errors found. Please adjust your game description accordingly."); return; }
	
	iprintln("Checking uses to types of definitions to LUT");
	checkTypes(implodedFile, lut);
	if (errorsFound != 0) { println("Errors found. Please adjust your game description accordingly."); return; }
	
	iprintln("Adding references to LUT");
	// Add all uses to the right references..	
	lut = addRefs(implodedFile, lut);
	
	iprintToFile(|project://DSL/src/lang/crds/samples/refs|, lut.refs); // Check if this is correct !! 
	if (errorsFound != 0) { println("Errors found. Please adjust your game description accordingly."); return; }
}

/******************************************************************************
 * Loop over Tree to put all definitions in a LUT.
 ******************************************************************************/
public Scope addDefs(CRDSII c, Scope lut)
{
	visit(c) {
		case card(Exp exp, _): 							{ if (var(id(str a)) := exp) { lut = addDef(a, exp@location, "card", lut);}}
		case team(ID name, _):							{ lut = addDef(name.name, name@location, "team", lut);}
		case players(list[Hands] hands):				{ for (player <- hands) { lut = addDef(player.player, player@location, "player", lut); } }
		case deck(ID name, _, _, _):					{ lut = addDef(name.name, name@location, "deck", lut);}
		case game(ID name, _):							{ lut = addDef(name.name, name@location, "game", lut);}
		case typedef(ID name, list[Exp] values):		{ lut = addDef(name.name, name@location, "typedef", lut); lut = addAttrs(name, values, lut); } // FIX ATTR
		case stage(ID name, _, _, _): 					{ lut = addDef(name.name, name@location, "stage", lut);}	
		case basic(ID name, _, _):						{ lut = addDef(name.name, name@location, "stage", lut);}
		case token(ID name, _, _, _): 					{ lut = addDef(name.name, name@location, "token", lut);}
	}
	
  	return lut;
}

// Add constructor definition to LUT.
public Scope addDef(str name, loc l, str nodetype, Scope lut) {
	if (name in lut.defs) {
		println("Cannot define <name> as <nodetype>. Please use unique identifiers.");
		errorsFound += 1;
		return lut;
	} else {
		lut.defs += (name : l);
		lut.types += (name : nodetype);
		lut.refs += (name : [l]);
		return lut;
	}
}

// Special case: Attributes (in Card, Token & Typedef)
public Scope addAttrs(ID name, list[Exp] exps, Scope lut) {
	for (exp <- exps) {
		if (var(id(str a)) := exp) { lut = addDef(a, exp@location, name.name, lut); }
		else if (val(real r) := exp) { lut = addDef(toString(r), exp@location, name.name, lut); }
	}
	
	return lut;
}

// Loop over tree to add the references to defined variables.
public Scope addRefs(CRDSII c, Scope lut)
{	
	visit(c) {
		case deck(_, _, ID location, _):							{ lut = addRef(location, lut); }
		case team(_, list[ID] names): 								{ for (use <- names) { lut = addRef(use, lut); } }
		case turnorder(list[ID] names): 							{ for (use <- names) { lut = addRef(use, lut); } }
		case card(_, list[Exp] exps):								{ lut = addAttrRefs(exps, lut); }
		case token(_, _, ID location, _):							{ lut = addRef(location, lut); }
		case points(list[Scoring] scores):							{ lut = addScores(scores, lut); }
		case var(ID name):											{ lut = addRef(name, lut); }
		case obj(ID name, ID attr):									{ lut = addRef(name, lut); lut = addRef(attr, lut); }
		case hands(_, ID location):								{ lut = addRef(location, lut); }
		
		case shuffleDeck(ID name): 									{ lut = addRef(name, lut); }
		case distributeCards(_, ID name, list[ID] players): 		{ lut = addRef(name, lut); for (use <- players) { lut = addRef(use, lut); } }
		case moveCard(_, list[ID] from, list[ID] to):				{ for (use <- from) { lut = addRef(use, lut); }  for (use <- to) { lut = addRef(use, lut); } }
 		case moveToken(_, ID from, ID to):						 	{ lut = addRef(from, lut); lut = addRef(to, lut); }
		case useToken(ID object):									{ lut = addRef(object, lut); }
		case returnToken(ID object):								{ lut = addRef(object, lut); }
		case obtainKnowledge(ID name):								{ lut = addRef(name, lut); }
		case communicate(list[ID] locations, Exp e):				{ for (use <- locations) { lut = addRef(use, lut); } } // TODO: Exp e
		case calculateScore(list[ID] objects):						{ for (use <- objects) { lut = addRef(use, lut); } }
		
	}
	
	return lut;
}

// Add constructor referral to LUT.
public Scope addRef(ID use, Scope lut) {
	try {
		lut.refs[use.name] += use@location;	
	} catch NoSuchKey(): errorsFound += 1;

	return lut;
}

// Special case: Attributes (in Card, Token & Typedef)
public Scope addAttrRefs(list[Exp] exps, Scope lut) {
	for (exp <- exps) {
		if (var(id(str a)) := exp) {
			try {
				lut.refs[a] += exp@location;	
			} catch NoSuchKey(): errorsFound += 1;
		} else if (val(real r) := exp) {
			try {
				lut.refs[toString(r)] += exp@location;	
			} catch NoSuchKey(): errorsFound += 1;
		}
	}

	return lut;	
}

// Special case: Scores
public Scope addScores(list[Scoring] scores, Scope lut) {
	for (score <- scores) {
		try {
			if (s(str name, real r) := score) 
				lut.refs[name] += score@location;	
		} catch NoSuchKey(): errorsFound += 1;

		}
	return lut;
}

/******************************************************************************
 * Functions to check ID's on correct usage.
 ******************************************************************************/

public void checkDefs(CRDSII c, Scope lut)
{
	visit(c) {
		case id(str name): {
			if (name notin lut.defs) {
				println("ERROR: Could not find: <name>");
				errorsFound += 1;
			}
		}
	}		
  	return;
}


public void checkTypes(CRDSII c, Scope lut)
{
	println("Checking types");
	
	//visit(c) {
	//	case team(_, list[ID]names): 								{ for (name <- names) { compareTypes("player", lut.types[name.name]); } }
	//	case turnorder(list[ID]names): 								{ for (name <- names) { compareTypes("player", lut.types[name.name]); } }
	//	case shuffleDeck(ID name): 									{ compareTypes("deck", lut.types[name.name]); }
	//	case distributeCards(_, ID name, list[ID] players): 		{ compareTypes("deck", lut.types[name.name]); for (player <- players) { compareTypes("player", lut.types[player.name]); }}
	//	case moveCard(_, list[ID] from, list[ID] to):				{ for (f <- from) { compareTypes("deck", lut.types[f.name]); } for (t <- to) { compareTypes("deck", lut.types[t.name]); }}
 //		case moveToken(_, ID from, ID to):						 	{ compareTypes("location", lut.types[from.name]); compareTypes("location", lut.types[to.name]);}
	//	case useToken(ID object):									{ compareTypes("token", lut.types[object.name]); }
	//	case returnToken(ID object):								{ compareTypes("token", lut.types[object.name]); }
	//	case communicate(list[ID] locations, Exp e):				{ for (l <- locations) { compareTypes("Location", lut.types[l.name]) }; } // TO FIX
	//	case calculateScore(list[ID] objects):						{ for (object <- objects) { compareTypes("deck", lut.types[object.name]); }} // TO FIX
	//	case Loc(ID name):											{ compareTypes("location", lut.types[name.name]);}
	//	//case obtainKnowledge(ID name):							{ } // TO FIX		
	//	//case scoring(str name, _):									{ if (name != "each") compareTypes("card", lut.types[name]); } // only cards?
 //	//	case var(ID name):											{ } // TO FIX	
 //	//	case obj(ID name, ID attr): 								{ } // TO FIX	
	//}
	
	return;
}

/******************************************************************************
 * Helper functions.
 ******************************************************************************/

public str getLoc (str s) {
	return substring(s, findFirst(s, "|"), findLast(s, ","));	
}

public void compareTypes(str s, str t) {
	if (s != t) {
		println("<s> :: <t>");
	 	println("Found a type error");
		errorsFound += 1;
	}
	
	return;
	}