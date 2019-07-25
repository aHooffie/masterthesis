module lang::crds::testsample

import lang::crds::grammar;
import lang::crds::ast;

import vis::Figure;
import vis::Render;
import util::IDE;
import util::Math;

import IO;
import ParseTree;

void main(loc file) {	
	try {
		Tree parsedFile = parse(#CRDS, file);			
		CRDSII implodedFile = implode(#CRDSII, parsedFile);
	} catch ParseError(loc l): {
		 println("Error during parsing: line <l.begin.line>, column <l.begin.column>.");
	} catch IllegalArgumentException: {
		println("Error during imploding.");
	}
}

