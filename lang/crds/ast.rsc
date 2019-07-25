/******************************************************************************
 * cardscript's abstract syntax 			
 *
 * File 	      	ast.rsc
 * Package			lang::crds
 * Brief       		defines the abstract syntax of the Cardscript grammar for AST building. 
 * Contributor	 	Andrea van den Hooff - UvA
 * Date        		August 2019
 ******************************************************************************/

module lang::crds::ast

import ParseTree;

public lang::crds::ast::CRDSII crds_implode(Tree tree)
  = implode(#lang::crds::ast::CRDSII, tree);

/******************************************************************************
 * Source location annotations as required by Rascal. 
 ******************************************************************************/

anno loc CRDSII@location;
anno loc Decl@location;

anno loc Action@location;
anno loc Attr@location;
anno loc BOOL@location;
anno loc Card@location;
anno loc Condition@location;
anno loc Exp@location;
anno loc ID@location;
anno loc Loc@location;
anno loc Playerlist@location;
anno loc Rule@location;
anno loc Scoring@location;
anno loc Stage@location;
anno loc Token@location;
anno loc Turn@location;
anno loc Turnorder@location;
anno loc Usa@location;
anno loc Vis@location;


/******************************************************************************
 * The cardgame DSL defined in data types for AST building.
 *
 * Main objects of the syntax.
 ******************************************************************************/

data CRDSII
 = game(ID name, list[Decl] decls);

data Decl
 = typedef	(ID name, list[Attr] values) 
 | deck		(ID name, list[Card] cards, Loc location, list[Prop] props, list[Condition] cdns)
 | team		(ID name, list[ID] names)
 | gameflow (Turnorder order, list[Stage] stages)
 | players	(list[ID] names)
 | tokens	(list[Token] tokens)
 | rules	(list[Rule] rules);

data Card 
 = card(ID name, list[Attr] attrs);

data Token 
 = token(ID name, real r, Loc location, list[Prop] props, list[Condition] cdns); 
 
data Rule 
 = playerCount(int min, int max)
 | points(list[Scoring] scores);
 
data Stage 
 = stage(ID name, list[Condition] cdns, Playerlist plist, list[Turn] turns)
 | basic(ID name, Playerlist plist, list[Turn] turns);
 
data Turnorder
 = turnorder(list[ID] names); 
 
data Turn
 = opt(Action action) | req(Action action) | choice(real r, list[Action] Action);

data Action
 = shuffleDeck(ID name)
 | distributeCards(real r, ID name, list[ID] players)
 | takeCard(ID from, ID to)
 | moveCard(ID object, ID from, ID to)
 | moveToken(ID object, ID from, ID to)
 | useToken(ID object)
 | returnToken(ID object)
 | obtainKnowledge(ID name)
 | communicate(ID name, ID attr)
 | changeTurnorder(Turnorder order)
 | calculateScore(list[ID] objects);
 
/******************************************************************************
 * Main properties of objects.
 ******************************************************************************/
data Prop
 = visibility(Vis vis)
 | usability(Usa usa);

data Attr
 = id(str name) | val(real r) | l(real min, real max); 
 
data Loc
 = id(str name); 
 
data Vis
 = allcards() | none() | top() | everyone() | team() | hand() | hanabi();

data Usa
 = draw() | discard() | play() | use() | ret(); 

data Playerlist
 = allplayers() | dealer() | turns();

data Scoring
 = s(str name, real r)
 | allcards(real r);
 
data Condition
 = deckCondition(Exp e, Action action)
 | stageCondition(Exp e)
 | totalTurns(Exp e);
 
data Exp
= var(ID name)
| val(real r)
| obj(ID name, ID attr)
| gt(Exp e1, Exp e2)
| ge(Exp e1, Exp e2)
| lt(Exp e1, Exp e2)
| le(Exp e1, Exp e2)
| eq(Exp e1, Exp e2)
| neq(Exp e1, Exp e2)
| and(Exp e1, Exp e2)
| or(Exp e1, Exp e2);
 
 /******************************************************************************
  * Basis.
  ******************************************************************************/
 
data BOOL
 = tru() | fal();

data LIST
 = l(real min, real max);

data ID
  = id(str name);