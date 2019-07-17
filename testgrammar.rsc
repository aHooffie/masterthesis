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

void foo() {

	loc tests = |project://DSL/src/lang/crds/tests|;
	loc failures = tests.ls[0];
	loc successes = tests.ls[1];
	
	int nparsed = 0;
			
	println("\n--------------------------------------------------------------------------\n There are <size(failures.ls)> wrongly written files. \n--------------------------------------------------------------------------\n");
	
	for (file <- failures.ls) { 
		println("Parsing: <file>");
		try {
			parsedFile = parse(#CRDS, file);
			nparsed += 1;
			println("Successfully finished parsing.");
			//println("<parsed> \n");
		} catch ParseError(loc l): {
			 println("Error during parsing: line <l.begin.line>, column <l.begin.column>.");
		}
	}


		println("\n--------------------------------------------------------------------------\n Summary: successfully parsed <nparsed> out of <size(failures.ls)> wrongly written files. \n--------------------------------------------------------------------------\n");
	nparsed = 0;

	println("\n--------------------------------------------------------------------------\n There are <size(successes.ls)> correctly written files. \n--------------------------------------------------------------------------\n");
	for (file <- successes.ls) { 
		println("Parsing: <file>");
		try {
			parsedFile = parse(#CRDS, file);
			nparsed += 1;
			
			println("Successfully finished parsing.");
			//println("<parsed> \n");
		} catch ParseError(loc l): {
			 println("Error during parsing: line <l.begin.line>, column <l.begin.column>.");
		}
		
		println("Successfully parsed <file>");
	}
	
		println("\n--------------------------------------------------------------------------\n Summary: successfully parsed <nparsed> out of <size(successes.ls)> correctly written files. \n--------------------------------------------------------------------------\n");
	

}