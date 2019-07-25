module lang::crds::basicanalysis

import lang::crds::ast;
import util::NameGraph;

import IO;
import List;

loc NULL_LOC = |null://null|(0,0,<0,0>,<0,0>);

data Scope
  = scope(str name, loc l,
          map[str scopeName, Scope s] scopes,
          map[str defName, loc l] defs);
          
// CRDSII          
public CRDSII setScope(CRDSII c: game(ID name, list[Decl] decls))
 = game(name, [setScope(scope(c), decl, [ID.name]) | d <- decls])[@location = c.id@location][@scope = []];
 
// DECLS (7x) 
public Decl setScope(Scope s, Decl d: typedef(ID name, list[Attr] values), list[str] scope)
 = ;

public Decl setScope(Scope s, Decl d: deck(ID name, list[Card] cards, Loc location, list[Prop] props, list[Condition] cdns), list[str] scope)
 = ;

public Decl setScope(Scope s, Decl d: team(ID name, list[ID] names), list[str] scope)
 = ;

public Decl setScope(Scope s, Decl d: gameflow(Turnorder order, list[Stage] stages), list[str] scope)
 = ;

public Decl setScope(Scope s, Decl d: players(list[ID] names), list[str] scope)
 = ;

public Decl setScope(Scope s, Decl d: tokens(list[Token] tokens), list[str] scope)
 = ;
 
public Decl setScope(Scope s, Decl d: rules(list[Rule] rules), list[str] scope)
 = ;
 
 
// CARD 

public Card setScope(Scope s, Card c: card(ID name, list[Attr] values), list[str] scope)
 = ;

// TOKEN
public Token setScope(Scope s, Token t: token(ID name, real r, Loc location, list[Prop] props, list[Condition] cdns), list[str] scope)
= ;

// RULE (2x) 
public Rule setScope(Scope s, Rule r: playerCount(real min, real max), list[str] scope)
= ;
public Rule setScope(Scope s, Rule r: points(list[Scoring] scores), list[str] scope)
 = ;

// STAGE (2x)
public Stage setScope(Scope s, Stage st: stage(ID name, list[Condition] cdns, Playerlist plist, list[Turn] turns), list[str] scope)
= ;
public Stage setScope(Scope s, Stage st: basic(ID name, Playerlist plist, list[Turn] turns), list[str] scope)
= ;


// TURNORDER 
public Turnorder setScope(Scope s, Turnorder t: turnorder(list[ID] names), list[str] scope) 
= ;

// TURN (3x)
public Turn setScope(Scope s, Turn t: opt(Action action), list[str] scope) 
 = ;
public Turn setScope(Scope s, Turn t: req(Action action), list[str] scope) 
 = ;
public Turn setScope(Scope s, Turn t: choice(real r, list[Action] Actions), list[str] scope)
 = ;

// ACTION (11x)

// PROP (2x)
public Prop setScope(Scope s, Prop p: visibility(Vis vis), list[str] scope) 
 = ;
public Prop setScope(Scope s, Prop p: usability(Usa usa), list[str] scope) 
 = ;


// ATTR (3x) 
public Attr setScope(Scope s, Attr a: id(Str name), list[str] scope) 
 = ;
 public Attr setScope(Scope s, Attr a: val(real r), list[str] scope) 
 = ;
 public Attr setScope(Scope s, Attr a: l(real min, real max), list[str] scope) 
 = ;


// LOC (1x)
public Loc setScope(Scope s, Loc l: id(Str name), list[str] scope) 
 = ;

// SCORING (2x)
public Exp setScope(Scope s, Scoring sc: s(str name, real r), list[str] scope) 
= ;

public Exp setScope(Scope s, Scoring sc: allcards(real r), list[str] scope) 
= ;

// CONDITION (3x)
public Condition setScope(Scope s, Condition c: deckCondition(Exp e, Action action), list[str] scope) 
= ;

public Condition setScope(Scope s, Condition c: stageCondition(Exp e), list[str] scope) 
= ;

public Condition setScope(Scope s, Condition c: totalTurns(Exp e), list[str] scope) 
= ;


// EXP (11x) 
public Exp setScope(Scope s, Exp e: var(ID name), list[str] scope) 
= ;

public Exp setScope(Scope s, Exp e: val(real r), list[str] scope) 
= ;

public Exp setScope(Scope s, Exp e: obj(ID name, ID attr), list[str] scope) 
= ;

public Exp setScope(Scope s, Exp e: gt(Exp e1, Exp e2), list[str] scope) 
= ;

public Exp setScope(Scope s, Exp e: ge(Exp e1, Exp e2), list[str] scope) 
= ;

public Exp setScope(Scope s, Exp e: lt(Exp e1, Exp e2), list[str] scope) 
= ;

public Exp setScope(Scope s, Exp e: le(Exp e1, Exp e2), list[str] scope) 
= ;

public Exp setScope(Scope s, Exp e: eq(Exp e1, Exp e2), list[str] scope) 
= ;

public Exp setScope(Scope s, Exp e: neq(Exp e1, Exp e2), list[str] scope) 
= ;

public Exp setScope(Scope s, Exp e: and(Exp e1, Exp e2), list[str] scope) 
= ;

public Exp setScope(Scope s, Exp e: or(Exp e1, Exp e2), list[str] scope) 
= ;

// LIST
public List setScope(Scope s, List l: l(real min, real max), list[str] scope) 
 = ;

// ID
public ID setScope(Scope s, ID i: id(str name), list[str] scope) 
 = ;

// BOOL (2x)
// Hoeft niet? 

// VIS (7x)
// HOEFT NIET?? 


// USA (5x)
// HOEFT NIET?? 

// PLAYERLIST (3x)
// HOEFT NIET??



// st = symbol table. scope = to search in. findNames = to find.
public loc findLoc(Scope st, list[str] currentScope, list[str] findNames)
{
	Scope s = st;
	for (str scopeName <- currentScope) {
		s = s.scopes[scopeName];
	}
  
  	print("SEARCHING in SCOPE "+s.findNames+" for: ");
  	
  	for(name <- findNames){
  		print(name+".");
  	}
  	println("");
  
  
  	// What does this dooo?
	Scope find = s;
	list[str] tail = findNames;
	str n;
  	do
	{
		<n,tail>= headTail(tail);
	    println("Search " +n);  
	    
	    // If n is in the current scope.
	    if (n in find.scopes) { 				//nested search	      
	    	if (tail != []) {
	        	find = find.scopes[n];
	     	} else {
	        	println("Found Scope "+n);
	       		return find.scopes[n].l;
	       	}
	    } else if (n in find.defs) { 			//found state
	    	println("Found state "+n);
	    	return find.defs[n];
	    } else {  								// failed to find scope or state, go up a level
			if (currentScope != []) {
	        	println("Failed to find " + n);      
	       		list[str] currentSReversed = reverse(currentScope); 	// Reverse list order.
		        <_, temp> = pop(currentSReversed);
		        list[str] finalReverse = reverse(temp);	 				// Reverse list order.       
	        	return findLoc(st, finalReverse, findNames);
	      	} else {
	        	break;
	      	}
	    }    
	  }	while(tail != []);
	  
	  println("DONE.");  
	  return NULL_LOC;
}


// 
public NameGraph getNameGraph(CRDSII c)
{
	set[loc] defs = {};
	set[loc] uses = {};
	rel[loc, loc] refs = {};
  
	visit(c) {
		case Action a:  	{ defs += {a@location}; }
		case Attr a:  		{ defs += {a@location}; }
		case Card c:		{ defs += {c@location}; }
		case Condition c:  	{ defs += {c@location}; }
		case CRDSII c:		{ defs += {c@location}; }
		case Decl d:		{ defs += {d@location}; }
		case Exp e:  		{ defs += {e@location}; }
		case Loc l:  		{ defs += {l@location}; }
		case Playerlist p:  { defs += {p@location}; }
		case Prop p:  		{ defs += {p@location}; }	
		case Rule r:  		{ defs += {r@location}; }
		case Scoring s:  	{ defs += {s@location}; }
		case Stage s: 		{ defs += {s@location}; }
		case Token t: 		{ defs += {t@location}; }
		case Turn t:  		{ defs += {t@location}; }
		case Turnorder t: 	{ defs += {t@location}; }
		case Usa u:  		{ defs += {u@location}; }
		case Vis v:  		{ defs += {v@location}; }
	}
  
  	return <defs,uses,refs>;
}
 