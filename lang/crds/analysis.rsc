/******************************************************************************
 * Checks designer's correct usage of the grammar in a designed game.
 *
 * File 	      	analysis.rsc
 * Package			lang::crds
 * Brief       		Checks variable definitions and uses on correct usage.
 * Contributor	 	Andrea van den Hooff - UvA
 * Date        		August 2019
 ******************************************************************************/

module lang::crds::analysis

import lang::crds::ast;
import lang::crds::grammar;

import util::Math;

import Prelude;
import List;
import ParseTree;
import String;
import Type;

int errorsFound = 0;

loc NULL_LOC = |null://null|(0,0,<0,0>,<0,0>);

data LUT
  = lut(str scopeName,
  		 loc l,
  		 map[str defName, loc l] defs,
  		 map[str defName, str nodeType] types,
  		 map[str def, list[loc l] uses] refs);

// TO DO
data CRDStype 
  = player() | team() | deck() ;

/******************************************************************************
 * Main function.
 ******************************************************************************/
CRDSII createTree(loc f) {
	Tree parsedFile = parse(#CRDS, f);			
	return implode(#CRDSII, parsedFile);
}

LUT createLUT(loc f) {
	// Parse and implode the game file.
	CRDSII implodedFile = createTree(f);
	
	// Initiliase datatype.
	LUT lut = lut("global", NULL_LOC, (), (), ());
	
	// Add all ID definitions to the LUT and check all uses.
	lut = addDefs(implodedFile, lut);
	if (errorsFound != 0) { println("Errors found during definition adding. Please adjust your game description accordingly."); return; }	
	
	// Check if all ID's in grammar are defined somewhere. 
	checkDefs(implodedFile, lut);
	if (errorsFound != 0) { println("Errors found during definition checking. Please adjust your game description accordingly."); return; }
	
	// Check if all ID's have the correct type. 
	checkTypes(implodedFile, lut);
	if (errorsFound != 0) { println("Errors found during type checking. Please adjust your game description accordingly."); return; }
	
	// Add all referrals to the right definitions..	
	lut = addRefs(implodedFile, lut);
	if (errorsFound != 0) { println("Errors found during referral adding. Please adjust your game description accordingly."); return; }

	return lut;
}

/******************************************************************************
 * Loop over Tree to put all definitions in a LUT.
 ******************************************************************************/
LUT addDefs(CRDSII c, LUT lut)
{
	visit(c) {
		case card(Exp exp, _): 							{ if (var(id(str a)) := exp) { lut = addDef(a, exp@location, "card", lut);}}
		case team(ID name, _):							{ lut = addDef(name.name, name@location, "team", lut);}
		case players(list[Hands] hands):				{ for (player <- hands) { lut = addDef(player.player, player@location, "player", lut); } }
		case deck(ID name, _, _, _, _):					{ lut = addDef(name.name, name@location, "deck", lut);}
		case game(ID name, _):							{ lut = addDef(name.name, name@location, "game", lut);}
		case typedef(ID name, list[Exp] values):		{ lut = addDef(name.name, name@location, "typedef", lut);
														  lut = addAttrs(name, values, lut); }
		case stage(ID name, _, _, _): 					{ lut = addDef(name.name, name@location, "stage", lut);}	
		case basic(ID name, _, _):						{ lut = addDef(name.name, name@location, "stage", lut);}
		case token(ID name, _, _, _): 					{ lut = addDef(name.name, name@location, "token", lut);}
	}
	
  	return lut;
}

// Add constructor definition to LUT.
LUT addDef(str name, loc l, str nodetype, LUT lut) {
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
LUT addAttrs(ID name, list[Exp] exps, LUT lut) {
	for (exp <- exps) {
		if (var(id(str a)) := exp) { lut = addDef(a, exp@location, name.name, lut); }
		else if (val(real r) := exp) { lut = addDef(toString(r), exp@location, name.name, lut); }
	}
	
	return lut;
}

// Loop over tree to add the references to defined variables.
LUT addRefs(CRDSII c, LUT lut)
{	
	visit(c) {
		case deck(_, _, ID location, _, _):							{ lut = addRef(location, lut); }
		case team(_, list[ID] names): 								{ for (use <- names) { lut = addRef(use, lut); } }
		case turnorder(list[ID] names): 							{ for (use <- names) { lut = addRef(use, lut); } }
		case communicate(list[ID] locations, Exp e):				{ for (use <- locations) { lut = addRef(use, lut); } } // TODO: Exp e
		case calculateScore(list[ID] objects):						{ for (use <- objects) { lut = addRef(use, lut); } }
		case token(_, _, ID location, _):							{ lut = addRef(location, lut); }
		case points(list[Scoring] scores):							{ lut = addScores(scores, lut); }
		case var(ID name):											{ lut = addRef(name, lut); }
		case obj(ID name, ID attr):									{ lut = addRef(name, lut); 
																	  lut = addRef(attr, lut); }
		case hands(_, ID location):									{ lut = addRef(location, lut); }
		
		case shuffleDeck(ID name): 									{ lut = addRef(name, lut); }
		case distributeCards(_, ID name, list[ID] locations): 		{ lut = addRef(name, lut);
																	  for (use <- locations) { lut = addRef(use, lut); } }
		case moveCard(_, list[ID] from, list[ID] to):				{ for (use <- from) { lut = addRef(use, lut); }  
																	  for (use <- to) { lut = addRef(use, lut); } }
		case takeCard(ID from, list[ID] to):						{ lut = addRef(from, lut);  
																	  for (use <- to) { lut = addRef(use, lut); } }
 		case moveToken(_, ID from, ID to):						 	{ lut = addRef(from, lut);
 																	  lut = addRef(to, lut); }
		case useToken(ID object):									{ lut = addRef(object, lut); }
		case returnToken(ID object):								{ lut = addRef(object, lut); }
		case obtainKnowledge(ID name):								{ lut = addRef(name, lut); }		
	}
	
	return lut;
}

// Add constructor referral to LUT.
LUT addRef(ID use, LUT lut) {
	try {
		if (use@location notin lut.refs[use.name]) {
			lut.refs[use.name] += use@location;	
		}
	} catch NoSuchKey(): errorsFound += 1;

	return lut;
}

// Special case: Attributes (in Card, Token & Typedef)
LUT addAttrRefs(list[Exp] exps, LUT lut) {
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
LUT addScores(list[Scoring] scores, LUT lut) {
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

void checkDefs(CRDSII c, LUT lut)
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

// Compare types of referrals to definitions. TO DO: Attributes.
void checkTypes(CRDSII c, LUT lut)
{
	println("Checking types");
	
	visit(c) {
		case team(_, list[ID] names): 								{ for (use <- names) { lut = checkRef(use, "player", lut); } }
		case turnorder(list[ID] names): 							{ for (use <- names) { lut = checkRef(use, "player", lut); } }
		case moveCard(_, list[ID] from, list[ID] to):				{ for (use <- from) { lut = checkRef(use, "deck", lut); }
																	  for (use <- to) { lut = checkRef(use, "deck", lut); } }
	 	case communicate(list[ID] locations, Exp e):				{ for (use <- locations) { lut = checkRef(use, "deck", lut); } } // TODO: Exp e
		
		case shuffleDeck(ID name): 									{ lut = checkRef(name, "deck", lut); }
		case distributeCards(_, ID name, list[ID] locations): 		{ lut = checkRef(name, "deck", lut);
																	  for (use <- locations) { lut = checkRef(use, "deck", lut); } }
 		case moveToken(_, ID from, ID to):						 	{ lut = checkRef(from, "token", lut);
 																	  lut = checkRef(to, "token", lut); }
		case useToken(ID object):									{ lut = checkRef(object, "token", lut); }
		case returnToken(ID object):								{ lut = checkRef(object, "token", lut); }
		case hands(_, ID location):									{ lut = checkRef(location, "deck", lut); }
		case deck(_, _, ID location, _, _): 						{ lut = checkRef(location, "location", lut); }
		case token(_, _, ID location, _):							{ lut = checkRef(location, "location", lut); }
		 
		// case card(_, list[Exp] exps):								{ lut = addAttrRefs(exps, lut); }	// TO DO: Attr types?
		// case points(list[Scoring] scores):							{ lut = addScores(scores, lut); }	// TO DO: Attr types?
		// case obj(ID name, ID attr):									{ lut = checkRef(name, lut); lut = checkRef(attr, lut); } // TO DO: Attr types?
		//case obtainKnowledge(ID name):								{ lut = checkRef(name, lut); } // TO DO		
	}
	
	return;
}


	
// Check the types of all referrals to LUT.
LUT checkRef(ID use, str nodeType, LUT lut) {
	try {
		if (nodeType == "typedef") {
			list[str] typedefs = getTypedefs(lut);
			if (lut.types[use.name] notin typedefs) {
				println("Your references are incorrect. I expected an element of a typedef but got <lut.types[use.name]> on line <use@location.begin.line>, column <use@location.begin.column>");
				errorsFound += 1;
			}
		} else if (lut.types[use.name] != nodeType) {
			println("<lut.types[use.name]> :: <nodeType>");	
			println("Your references are incorrect. I expected a <lut.types[use.name]> but got <nodeType> on line <use@location.begin.line>, column <use@location.begin.column>");
			errorsFound += 1;
		}
	} catch NoSuchKey(): errorsFound += 1;

	return lut;
}	

list[str] getTypedefs(LUT lut) {
	list[str] typedefs = [];
	

}

// Special case: Attributes (in Card, Token & Typedef)
//LUT checkAttrs(ID name, list[Exp] exps, LUT lut) {
//	for (exp <- exps) {
//		if (var(id(str a)) := exp) { lut = checkRef(id(str a), exp@location, name.name, lut); }
//		else if (val(real r) := exp) { lut = addDef(toString(r), exp@location, name.name, lut); }
//	}
//	
//	return lut;
//}
	
/******************************************************************************
 * Helper functions.
 ******************************************************************************/

str getLoc (str s) {
	return substring(s, findFirst(s, "|"), findLast(s, ","));	
}

bool compareTypes(str s, str t) {
	return (s == t);
}