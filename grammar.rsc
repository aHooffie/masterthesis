/******************************************************************************
 * cardscript grammar
 *
 * File 	      	grammar.rsc
 * Package			lang::crds
 * Brief       		defines the syntax of the Cardscript grammar
 * Contributor	 	Andrea van den Hooff - UvA
 * Date        		August 2019
 ******************************************************************************/

module lang::crds::grammar

start syntax CRDS
 = game: "game" ID Decl*;

/******************************************************************************
 * Main objects of the syntax.
 ******************************************************************************/

syntax Decl
 =  @Category="Decl"
   typedef: "typedef" ID "=" "[" {ID ","}+ "]"							// Set of strings for Attrs such as names, values, colours.
 | deck: "deck" ID "=" "[" {Card ","}* "]" LOCATION Property+ "[" {Condition ","}* "]"
 | team: "team" ID "=" "[" {ID ","}+ "]" 								// No teams defined == FFA.
 | tokens: "tokens" ID "=" "[" {Token ","}+ "]" 						// Set of all possible tokens.
 | players: "players" "=" "[" {Player ","}+ "]"
 | gameflow: "gameflow" "=" "[" Turnorder  {Stage ","}+ "]"
 | rules: "rules" "=" "[" {Rule ","}+ "]"; 
 
syntax Card
 = card: ID "=" "[" {Attr ","}+ "]";  

syntax Token
 = token: ID "=" "[" INT "]" LOCATION Property "[" {Condition ","}* "]";
 
syntax Player 
 = player: ID "=" "[" KNOWLEDGE* "]";			
 
syntax Rule 															// General rules. 
 = playerCount: "players:" INT "to" INT
 | scoring: "scoring: [" {Attr ","}+ "]";								// Points per card.
  
syntax Stage
 = stage: "stage" ID ":" "while" Condition Playerlist "[" {Turn ","}* "]";
 
syntax Turnorder 
 = turnorder: "turnorder = [" {ID ","}* "]";
 
syntax Turn
 = req: "req" Action 
 | opt: "opt" Action;
 
syntax Action
 = @Category="Action" shuffleDeck: "shuffle" ID 											// DeckID 	
 | distributeCards: "distribute" INT ID "[" {ID ","}+ "]"				// CardAmount, DeckID , List of Players
 | moveCard: "moveCard" ID ID ID	 	  								// Object, deck, deck
 | moveToken: "moveToken" ID ID ID 										// Object, deck, deck? 
 | obtainKnowledge: "getInfo" ID KNOWLEDGE 								// TO DO !!
 | communicate: "TO DO" ID Attr											// Object, quality. LOCATION / deck ID necessary?
 | changeTurnorder: "changeTurns" Turnorder								// TO DO: How to skip a player's turn once? 
 | calculateScore: "calculateScore";									// How to count score? What if there are no teams?

/******************************************************************************
 * Main properties of objects.
 ******************************************************************************/
syntax Attr
 = id: ID
 | back: Bool															// How does this practically influence the game when set? 
 | scoring: ID "=" INT; 

syntax Property
 = vis: Visibility
 | usa: Usability;

syntax Visibility
 = allcards: "all" 
 | none: "none" 
 | top: "top" 
 | everyone: "everyone" 
 | team: "team" 
 | hand: "hand";
 
syntax Usability
 = draw: "draw" 
 | discard: "discard" 
 | play: "play" 
 | use: "use" 
 | ret: "return";
 
syntax LOCATION 
 = location: ID;

syntax Condition														// TO DO!! 
 = emptyPile: "if" Exp "then" Action
 | stageCondition: Exp;
 
syntax Playerlist
 = @category="TO DO"
  allplayers: "all" 
 | dealer: "dealer" 
 | turns: "turns";

syntax Exp
 = var: ID
 | obj: ID"."Attr
 > left (
   gt: Exp l "\>" Exp r
 | ge: Exp l "\>=" Exp r 
 | lt: Exp l "\<" Exp r
 | le: Exp l "\<=" Exp r
 | neq: Exp l "==" Exp r
 | eq: Exp l "==" Exp r); 
 
syntax Bool
 = @category="String" tru: "true" | fal: "false"; 

/******************************************************************************
 * Lexicals. 
 ******************************************************************************/
syntax ID
 = STR | INT;

lexical STR
 = @category="String" ([a-zA-Z_$] [a-zA-Z0-9_$]* !>> [a-zA-Z0-9_$]) \ Reserved;

lexical INT 
 = @category="Number" ([0-9]+([.][0-9]+?)?);
 
lexical KNOWLEDGE														// TO DO!! 									
 = @category="TO DO" "knowledge"; 
 
lexical CONDITION
 = @category="TO DO" "condition";

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
 = @category="keyword" Visibility | "deck" | "hand" | "tokens" | "token" | "team" | "player" | "players" | "game" | "typedef" |"knowledge"
 | "distribute" | "move" | "shuffle" | "adjust" | "score"
 |"public" | "private" | "dealer" | "location" | "communicate"; // For testing.
 
 
 /******************************************************************************
 * Parsing functions.
 ******************************************************************************/
 
public CRDS crds_parse(str src, loc file) = 
  parse(#CRDS, src, file);
  
public CRDS crds_parse(loc file) = 
  parse(#CRDS, file); 
 
