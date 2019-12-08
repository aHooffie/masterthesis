/******************************************************************************
 * Tests for the grammar written in lang::crds::ast.
 *
 * File 	      	testast.rsc
 * Package			lang::crds
 * Brief       		tests for the datatypes for the ast.
 * Contributor	 	Andrea van den Hooff - UvA
 * Date        		August 2019
 ******************************************************************************/
module lang::crds::testAST

import lang::crds::grammar;
import lang::crds::ast;

import vis::Figure;
import vis::Render;
import util::IDE;
import util::Math;

import IO;
import ParseTree;

void main() {
	loc tests = |project://DSL/src/lang/crds/ASTtests|;
	loc successes = tests.ls[0];
	
	int nparsed = 0;
	int nimploded = size(successes.ls);
	
	
	for (file <- successes.ls) { 
		println("Parsing: <file>");
		
		try {
			Tree parsedFile = parse(#CRDS, file);
			nparsed += 1;
			
			CRDSII implodedFile = implode(#CRDSII, parsedFile);
		} catch ParseError(loc l): {
			 println("Error during parsing: line <l.begin.line>, column <l.begin.column>.");
		} catch IllegalArgumentException: {
			nimploded -= 1;
			println("Error during imploding.");
		}

	}	
	
	println("\n--------------------------------------------------------------------------\n Summary: successfully imploded <nimploded> out of <nparsed> correctly parsed files. \n--------------------------------------------------------------------------");
}

