/******************************************************************************
 * cardscript grammar
 *
 * File       grammar.rsc
 * Package lang::crds
 * Brief       defines the syntax of the Cardscript grammar
 * Contributor Andrea van den Hooff - UvA
 * Date         August 2019
 ******************************************************************************/

// backside or knowledge not implemented. removed for now.

module lang::crds::grammar
  
start syntax CRDS
 = game: "game" ID Decl*;

/******************************************************************************
 * Main game objects of the syntax.
 ******************************************************************************/

syntax Decl
 = @Category="Decl"
   typedef: "typedef" ID "=" "[" {Attr ","}+ "]" 			// E.g. names, values, colours.
 | deck: "deck" ID "=" "[" {Card ","}* "]" Loc Prop+ "[" {Condition ","}* "]"
 | team: "team" ID "=" "[" {ID ","}+ "]" 					// No teams defined == FFA.
 | gameflow: "gameflow" "=" "[" Turnorder {Stage ","}+ "]"
 | players: "players" "=" "[" {ID ","}+ "]"
 | tokens: "tokens" "=" "[" {Token ","}+ "]" 				// Set of all possible tokens.
 | rules: "rules" "=" "[" {Rule ","}+ "]";  
 
syntax Card
 = card: Attr "=" "[" {Attr ","}+ "]";

syntax Token
 = token: ID "=" "[" VALUE "]" Loc Prop+ "[" {Condition ","}* "]";
 
syntax Rule 												// General rules.
 = playerCount: "players" "=" VALUE "to" VALUE
 | points: "scoring" "=" "[" {Scoring ","}+ "]"; 				// Points per card.
 
syntax Stage												// Script of the game. 
 = stage: "stage" ID "=" {Condition ","}+ Playerlist "[" {Turn ","}* "]"
 | basic: "stage" ID "=" Playerlist "[" {Turn ","}* "]";
 
syntax Turnorder
 = turnorder: "turnorder" "=" "[" {ID ","}* "]";
 
syntax Turn
 = req: "req" Action
 | opt: "opt" Action
 | choice: VALUE "of" "[" {Action ","}+ "]";
 
syntax Action																// Specific rules
 = @Category="Action" shuffleDeck: "shuffle" ID 							// DeckID
 | distributeCards: "distribute" VALUE ID "[" {ID ","}+ "]" 				// CardAmount, DeckID , List of Players
 | takeCard: "takeCard" ID ID
 | moveCard: "moveCard" VALUE ID ID
 | moveToken: "moveToken" VALUE ID ID
 | useToken: "useToken" ID
 | returnToken: "returnToken" ID
 | obtainKnowledge: "getInfo" ID
 | communicate: "giveHint" ID Attr
 | changeTurnorder: "changeTurns" Turnorder
 | calculateScore: "calculateScore" ID+
 | endGame: "endGame"; 	
 					
/******************************************************************************
 * Main properties of objects.
 ******************************************************************************/
syntax Prop
 = visibility: Vis
 | usability: Usa;

syntax Vis
 = allcards: "all"
 | none: "none"
 | top: "top"
 | everyone: "everyone"
 | team: "team"
 | hanabi: "hanabi"
 | hand: "hand";
 
syntax Usa
 = draw: "draw"
 | discard: "discard"
 | play: "play"
 | use: "use"
 | ret: "return";
 
syntax Playerlist
 = allplayers: "all"
 | dealer: "dealer"
 | turns: "turns";
 
syntax Scoring
 = s: ID "=" VALUE
 | allcards: "each" "=" VALUE;
 
syntax Loc
 = ID;
 
syntax Attr
 = ID | val: VALUE | LIST;

syntax Condition // TO DO!!
 = deckCondition: "if" Exp "then" Action
 | stageCondition: "while" Exp
 | totalTurns: "for" Exp "turns";
 
syntax Exp
 = var: ID
 | val: VALUE
 | obj: ID"."ID
 > left (
   gt: Exp l "\>" Exp r
 | ge: Exp l "\>=" Exp r
 | lt: Exp l "\<" Exp r
 | le: Exp l "\<=" Exp r
 | neq: Exp l "!=" Exp r
 | eq: Exp l "==" Exp r
 | and: Exp l "&&" Exp r
 | or: Exp l "||" Exp r);
 
/******************************************************************************
 * Basis.
 ******************************************************************************/
syntax ID
 = id: NAME;

syntax LIST 											// TO DO
 = l: VALUE ".." VALUE;

syntax BOOL
 = @category="String" tru: "true" | fal: "false"; 		// TO DO
 
lexical NAME
 = @category="String" ([a-zA-Z_$] [a-zA-Z0-9_$]* !>> [a-zA-Z0-9_$]) \ Reserved;

lexical VALUE
 = @category="Number" ([0-9]+([.][0-9]+?)?);

/******************************************************************************
 * Layout. Should be ignored by the parser.
 ******************************************************************************/

layout LAYOUTLIST
  = LAYOUT* !>> [\t-\n \r \ ] !>> "//" !>> "/*";

lexical LAYOUT
= Comment
| [\t-\n \r \ ];
 
lexical Comment
 = @category="Comment" "/*" (![*] | [*] !>> [/])* "*/"
 | @category="Comment" "//" ![\n]* [\n];
 
/******************************************************************************
 * Keywords.
 ******************************************************************************/
 
keyword Reserved
 = @category="keyword" Visibility | "deck" | "tokens" | "token" | "team" | "player" | "players" | "game" | "typedef"
 | "distribute" | "move" | "shuffle" | "adjust" | "score" | "true" | "false" | "if" | "then" | "each"
 |"public" | "private" | "dealer" | "communicate"; // For testing.

 
public start[CRDS] crds_parse(str src, loc file)
 = parse(#start[CRDS], src, file);
  
public start[CRDS] mm_parse(loc file) 
 = parse(#start[CRDS], file); 
