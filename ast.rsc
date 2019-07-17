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

/******************************************************************************
 * Public APIs.
 ******************************************************************************/

public lang::crds::ast::CRDS crds_implode(Tree tree)
  = implode(#lang::crds::ast::CRDS, tree);

/******************************************************************************
 * Source location annotations as required by Rascal. 
 ******************************************************************************/

anno loc CRDS@location;
anno loc Decl@location;
anno loc Card@location;
anno loc Token@location;
anno loc Player@location;
anno loc Rule@location;
anno loc Stage@location;
anno loc Turnorder@location;
anno loc Turn@location;
anno loc Action@location;

anno loc Attr@location;
anno loc Visibility@location;
anno loc Usability@location;
anno loc Condition@location;
anno loc Playerlist@location;
anno loc Exp@location;
anno loc Bool@location;
anno loc ID@location;

/******************************************************************************
 * The cardgame DSL defined in data types for AST building.
 *
 * Main objects of the syntax.
 ******************************************************************************/

data CRDS
  = game(ID name, list[Decl] decls);

data Decl
 = typedef(ID name, list[ID] values) 
 | deck(ID name, list[Card] cards, ID location, list[Property] props, list[Condition] cdns)
 | team(ID name, list[ID] players)
 | tokens(ID name, list[Token] tokens)
 | players(list[Player] players)
 | gameflow(Turnorder order, list[Stage] stages)
 | rules(list[Rule] rules);

data Card 
 = card(ID name, list[Attr] attrs);

data Token 
 = token(ID name, real val, ID location, Property prop, list[Condition] cdns); 
 
data Player 
 = player(ID name);
 
data Rule 
 = playerCount(int min, int max)
 | scoring(Attr Attr);
 
data Stage 
 = stage(ID name, Condition cdn, Playerlist plist, list[Turn] turn);
 
data Turnorder
 = turnorder(list[ID] names)
 | turnorder();
 
data Turn
 = opt(Action action) | req(Action action);

data Action
 = shuffleDeck(ID name)
 | distributeCards(real val, ID name, list[ID] players)
 | moveCard(ID object, ID from, ID to)
 | moveToken(ID object, ID from, ID to)
 | obtainKnowledge(ID name)
 | communicate(ID name, Attr attr)
 | changeTurnorder(Turnorder order)
 | calculateScore();
 
/******************************************************************************
 * Main properties of objects.
 ******************************************************************************/
data Attr 
 = id(ID name)
 | back(Bool boolean)
 | scoring(ID name, real val);
 
data Visibility
 = allcards() | none() | top() | everyone() | team() | hand();

data Usability
 = draw() | discard() | play() | use() | ret(); 

data Condition
 = emptyPile(Exp exp, Action action) 
 | stageCondition(Exp exp);
 
data Playerlist
 = allplayers() | dealer() | turns();
 
data Exp
= var(str name)
| obj(ID name, Attr attr)
| gt(Exp e1, Exp e2)
| ge(Exp e1, Exp e2)
| lt(Exp e1, Exp e2)
| le(Exp e1, Exp e2)
| eq(Exp e1, Exp e2)
| neq(Exp e1, Exp e2);
 
data Bool
 = tru() | fal();

data ID
  = id(str name)
  | id(real val);