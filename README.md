# masterthesis

This project shows several options. First, open up Eclipse and carry out the following:
> import lang::crds::basis::grammar;   
> import lang::crds::basis::ast;  

1a) To parse a newly defined game and check for grammatical errors:
> import lang::crds::basis::ide;  
> crds_register();  
> Right-click .crds file and choose "Open With.. Impulse Editor".  
  If the game is correctly written, the objects will now be highlighted accordingly.

1b) For detailed feedback on wrongly parsed grammar:  
> import lang::crds::analysis::grammaranalysis;  
> checkGrammar(loc gamefile);

2) To perform a static analysis of the parsed rules:
> import lang::crds::analysis::generalmetrics;  
> analysePrototype(loc gamefile);

3a) To play your own game of Hanabi:
> import lang::crds::hanabi::runhanabi;  
> runGame();

3b) To run an example game of Hanabi - example in output/exampleSimulation1:
> import lang::crds::hanabi::runsimulation;  
> runSimulation(int filenumber);

4) To verify designer hypotheses of Hanabi - example in output/exampleHypotheses
> import lang::crds::hanabi::checkhypotheses;  
> runhypotheses(int filenumber);
