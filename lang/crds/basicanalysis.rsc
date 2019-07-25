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
 
// DECLS
public Decl setScope(Scope s, Decl d: typedef(ID name, list[Attr] values), list[str] scope)
 = typedef(name, [setScope(s, v, scope, [ID.name])| v <- values])[@location = d.name@location][@scope = scope];

//public Decl setScope(Scope s, Decl d: deck(ID name, list[Card] cards), Loc location, list[Prop] props, list[Condition] cdns, list[str] scope)
 //= deck(name, [setScope(s, v, scope, [ID.name])| v <- values])[@location = d.name@location][@scope = scope];

public Decl setScope(Scope s, Decl d: typedef(ID name, list[Attr] values), list[str] scope)
 = typedef(name, [setScope(s, v, scope, [ID.name])| v <- values])[@location = d.name@location][@scope = scope];

public Decl setScope(Scope s, Decl d: typedef(ID name, list[Attr] values), list[str] scope)
 = typedef(name, [setScope(s, v, scope, [ID.name])| v <- values])[@location = d.name@location][@scope = scope];

public Decl setScope(Scope s, Decl d: typedef(ID name, list[Attr] values), list[str] scope)
 = typedef(name, [setScope(s, v, scope, [ID.name])| v <- values])[@location = d.name@location][@scope = scope];
 
 public Decl setScope(Scope s, Decl d: typedef(ID name, list[Attr] values), list[str] scope)
 = typedef(name, [setScope(s, v, scope, [ID.name])| v <- values])[@location = d.name@location][@scope = scope];
 
 public Decl setScope(Scope s, Decl d: rules(list[Rule] rules), list[str] scope)
 = typedef(name, [setScope(s, v, scope, [ID.name])| v <- values])[@location = d.name@location][@scope = scope];
 
 
 
 
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
 