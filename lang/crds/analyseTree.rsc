/******************************************************************************
 * bla.	
 *
 * File 	      	analysetree.rsc
 * Package			lang::crds
 * Brief       		bla
 * Contributor	 	Andrea van den Hooff - UvA
 * Date        		August 2019
 ******************************************************************************/
module lang::crds::analysetree

import lang::crds::grammar;
import lang::crds::ast;

import vis::Figure;
import vis::Render;
import util::IDE;
import util::Math;

import Ambiguity;
import IO;
import Message;
import ParseTree;
import Type;

public list[str] knownAttrs;
public list[str] knownCards;
public list[str] knownPlayers;
public list[str] knownTokens;

void foo() {
	loc file = |project://DSL/src/lang/crds/ASTtests/success/blabla.crds|;
	Tree parsedFile = parse(#CRDS, file);	
	print("PARSED");		
	
	CRDSII implodedFile = implode(#CRDSII, parsedFile);
	println("&IMPLODED");
}