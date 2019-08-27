/******************************************************************************
 * implementing the grammar in eclipse 
 *
 * File 	      	ide.rsc
 * Package			lang::crds
 * Brief       		defines eclipse usages
 * Contributor	 	Andrea van den Hooff - UvA
 * Date        		August 2019
 ******************************************************************************/

module lang::crds::ide

import lang::crds::grammar;
import lang::crds::ast;

import vis::Figure;
import vis::Render;
import util::IDE;
import util::Math;

import Ambiguity;
import IO;
import Map;
import Message;
import ParseTree;
import Set;

/******************************************************************************
 * Create .crds file extensions and implose using data types specified in ast.rsc.
 ******************************************************************************/

public str CRDS_NAME = "cardscript";                   // DSL Name
public str CRDS_EXT  = "crds" ;                        // File Extension

private node crds_ide_outline (Tree t)
  = crds_implode(t);

/******************************************************************************
 * Register highlighting for .crds file s.
 ******************************************************************************/
public void crds_register()
{
	Contribution crds_style =
    	categories
    	(
      		(
      			"TO DO": { foregroundColor( color("lightsalmon"))},
      			"keyword": { foregroundColor( color("red"))}, 		// Nothing this color.
		        "Comment": { foregroundColor( color("seagreen"))},
		        "Number": { foregroundColor( color("royalblue"))}
	     	 )
	    );
     
	set[Contribution] crds_contributions = { crds_style };
    	
 	registerLanguage(CRDS_NAME, CRDS_EXT, lang::crds::grammar::crds_parse);
  	registerOutliner(CRDS_NAME, crds_ide_outline);
 	registerContributions(CRDS_NAME, crds_contributions);
}
