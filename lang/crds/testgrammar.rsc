/******************************************************************************
 * Tests for the grammar written in lang::crds::grammar.
 *
 * File 	      	testgrammar.rsc
 * Package			lang::crds
 * Brief       		tests for dsl.
 * Contributor	 	Andrea van den Hooff - UvA
 * Date        		August 2019
 ******************************************************************************/

module lang::crds::testgrammar

import IO;
import ParseTree;
import lang::crds::grammar;

void main() {
	loc tests = |project://DSL/src/lang/crds/DSLtests|;
	loc failures = tests.ls[0];
	loc successes = tests.ls[1];
	
	testSuccesses(successes);
	testFailures(failures);
}

void testFailures(loc failures) {	
	int nparsed = size(failures.ls);
		
	println("\n--------------------------------------------------------------------------\n There are <size(failures.ls)> wrongly written files. \n--------------------------------------------------------------------------");
	
	for (file <- failures.ls) { 
		//println("Parsing: <file>");
		try {
			Tree parsedFile = parse(#CRDS, file);
 		} catch ParseError(loc l): {
			 //println("Error during parsing: line <l.begin.line>, column <l.begin.column>.");
			 nparsed -= 1;
			 
		}
	}

	println("\n--------------------------------------------------------------------------\n Summary: parsed <nparsed> out of <size(failures.ls)> wrongly written files. \n--------------------------------------------------------------------------");
}


void testSuccesses(loc successes) {
	int nparsed = 0;

	println("\n--------------------------------------------------------------------------\n There are <size(successes.ls)> correctly written files. \n--------------------------------------------------------------------------");
		
	for (file <- successes.ls) { 
		//println("Parsing: <file>");
		try {
			Tree parsedFile = parse(#CRDS, file);
			nparsed += 1;
			
		} catch ParseError(loc l): {
			 println("Error during parsing: line <l.begin.line>, column <l.begin.column>.");
		}
		
	}
	
		println("\n--------------------------------------------------------------------------\n Summary: successfully parsed <nparsed> out of <size(successes.ls)> correctly written files. \n--------------------------------------------------------------------------");
	
}