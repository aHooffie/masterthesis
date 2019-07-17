module lang::crds::test1

import IO;
import ParseTree;
import lang::crds::grammar;
import lang::crds::ast;


void foo() {
	loc file = |project://DSL/src/lang/crds/tests/success/basic_small.crds|;

	try {
		println("Trying to parse <file>");
		
		Tree parsedFile = crds_parse(file);
		println("Successfully finished parsing.");
		println(parsedFile); // print naar file :) 
		
		
		lang::crds::ast::CRDS implodedFile = implode(#lang::crds::ast::CRDS, parsedFile);
		iprintln(implodedFile);
	} catch ParseError(loc l): {
		 println("Error during parsing: line <l.begin.line>, column <l.begin.column>.");
	}
}