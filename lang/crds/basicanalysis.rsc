module lang::crds::basicanalysis

import lang::crds::ast;

import lang::crds::grammar;
import util::NameGraph;


import Prelude;
import List;
import ParseTree;
import String;
import Type;

loc NULL_LOC = |null://null|(0,0,<0,0>,<0,0>);

data Scope
  = scope(str scopeName, loc l, map[str defName, loc l] defs, map[str defName, str nodeType] types);

public Scope globalLUT = scope("global", NULL_LOC, (), ());
public list[ tuple[str def, list[loc l] uses]] refs = [];

void leuk(loc f) {
	Tree parsedFile = parse(#CRDS, f);			
	CRDSII implodedFile = implode(#CRDSII, parsedFile);
	
	addIDstoLUT(implodedFile);
	checkIDstoLUT(implodedFile);
	addRefs(implodedFile);
	//println(globalLUT);
}

public void addIDstoLUT(CRDSII c)
{
	visit(c) {
		case card(ID name, _): 							{ globalLUT.defs += (name.name : name@location); globalLUT.types += (name.name: "card"); refs += <name.name, [name@location]>; }
		case team(ID name, _):							{ globalLUT.defs += (name.name : name@location); globalLUT.types += (name.name: "team"); refs += <name.name, [name@location]>; }
		case players(list[Hands] hands):				{ addPlayers(hands); }
		case deck(ID name, _, _, _):					{ globalLUT.defs += (name.name : name@location); globalLUT.types += (name.name: "deck"); refs += <name.name, [name@location]>; }
		case game(ID name, list[Decl] decls):			{ globalLUT.defs += (name.name : name@location); globalLUT.types += (name.name: "game"); refs += <name.name, [name@location]>;}
		case typedef(ID name, list[Attr] values):		{ globalLUT.defs += (name.name : name@location); globalLUT.types += (name.name: "typedef"); foo(values); refs += <name.name, [name@location]>;}
		case stage(ID name, _, _, _): 					{ globalLUT.defs += (name.name : name@location); globalLUT.types += (name.name: "stage"); refs += <name.name, [name@location]>;}	
		case basic(ID name, _, _):						{ globalLUT.defs += (name.name : name@location); globalLUT.types += (name.name: "stage"); refs += <name.name, [name@location]>;}
		case token(ID name, _, _, _): 					{ globalLUT.defs += (name.name : name@location); globalLUT.types += (name.name: "token"); refs += <name.name, [name@location]>;}
	}
		
  	return;
}


public Scope addPlayers(list[Hands] hands) {
	for (hand <- hands) {
	
		if (hand.player in globalLUT.defs) {
			println("Player <hand.player>  is already defined. Please use unique identifiers.");
			return NULL;
		} else
			globalLUT.defs += (hand.player : hand@location);
			globalLUT.types += (hand.player : "player");
		}
	
	return globalLUT;
}

// TO DO: Values of typedef attrs.
public void foo(list[Attr] values) {
	//for (v <- values) {
		//println(v);
	//}
	
	return;
}


public void checkIDstoLUT(CRDSII c)
{
	println("Checking IDs");
	
	visit(c) {
		case id(str name): { if (name notin globalLUT.defs) println("ERROR: Could not find: <name>");}
	}
	
	println("Finished");
		
  	return;
}

public void addRefs(CRDSII c)
{
	visit(c) {
		case team(_, list[ID]names): 								{ addIDs(names); }
		case turnorder(list[ID]names): 								{ addIDs(names); }
		case shuffleDeck(ID name): 									{ addIDs(name); }
		case distributeCards(_, ID name, list[ID] players): 		{ addIDs(name); addIDs(players); }
		case moveCard(_, list[ID] from, list[ID] to):				{ addIDs(from); addIDs(to); }
 		case moveToken(_, ID from, ID to):						 	{ addIDs(from); addIDs(to); }
		case useToken(ID object):									{ addIDs(object); }
		case returnToken(ID object):								{ addIDs(object); }
		case obtainKnowledge(ID name):								{ addIDs(object); }
		case communicate(list[ID] locations, Attr attr):			{ addIDs(locations); } 
		case calculateScore(list[ID] objects):						{ addIDs(objects); }
//		case Loc (hands, attr)
//		case scoring
// 		case Exp
	}
	
	return;
}


public void addIDs (list[ID] names) {
	for (name <- names) {
		println(name);
		println(name@location);
	}
	return;
}

public void addIDs (ID name) {
	println(name);
	println(name@location);
	
	return;
}

