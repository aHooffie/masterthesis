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
   typedef: "typedef" ID "=" "[" {Exp ","}+ "]" 			// E.g. names, values, colours.
 | deck: "deck" ID "=" "[" {Card ","}* "]" ID Prop+ "[" {Condition ","}* "]"
 | team: "team" ID "=" "[" {ID ","}+ "]" 					// No teams defined == FFA.
 | gameflow: "gameflow" "=" "[" Turnorder {Stage ","}+ "]"
 | players: "players" "=" "[" {Hands ","}+ "]"
 | tokens: "tokens" "=" "[" {Token ","}+ "]" 				// Set of all possible tokens.
 | rules: "rules" "=" "[" {Rule ","}+ "]";  
 
syntax Card
 = card: Exp "=" "[" {Exp ","}+ "]";

syntax Token
 = token: ID "=" "[" "start" VALUE "," "max" VALUE "]" ID Prop+; // "[" {Condition ","}* "]";
 
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
 = @Category="Action" shuffleDeck: "shuffle" ID
 | distributeCards: "distribute" VALUE "from" ID "to" "[" {ID ","}+ "]"
 | takeCard: "takeCard" "from" ID "to" "[" {ID ","}+ "]" 					// from drawpile
 | moveCard: "moveCard" Exp "from" "[" {ID ","}+ "]" "to" "[" {ID ","}+ "]" // from a to b
 | moveToken: "moveToken" VALUE "from" ID "to" ID
 | useToken: "useToken" ID
 | returnToken: "returnToken" ID
 | obtainKnowledge: "getInfo" ID
 | communicate: "giveHint" "[" {ID ","}* "]" Exp // list of locs, value
 | changeTurnorder: "changeTurns" Turnorder
 | calculateScore: "calculateScore" ID+
 | endGame: "endGame"
 > left sequence: Action "and then" Action; 	
 					
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
 | turns: "turns"
 | teams: "teams";
 
syntax Scoring
 = s: ID "=" VALUE
 | allcards: "each" "=" VALUE;

syntax Hands 
 = hands: ID "has" ID; 

syntax Condition // TO DO!!
 = deckCondition: "if" Exp "then" Action
 | stageCondition: "while" Exp "do"
 | totalTurns: "for" Exp "turns" "do"
 | higher: "value" "=" "higher than current"
 | lower: "value" "=" "lower than current"
 | xhigher: "value" "=" VALUE "higher than current"
 | color: "color" "=" ID;
 
syntax Exp
 = var: ID
 | val: VALUE
 | l: LIST
 | obj: ID"."ID
 | empty: "empty"
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
 = l: "[" VALUE ".." VALUE "]";


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
 |"public" | "private" | "dealer" | "communicate" | "and" | "has" | "empty"; // For testing.

 
public start[CRDS] crds_parse(str src, loc file)
 = parse(#start[CRDS], src, file);
  
public start[CRDS] mm_parse(loc file) 
 = parse(#start[CRDS], file); 
