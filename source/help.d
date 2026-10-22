/* The texts that the program shows on the console The texts are plain data so that 
they can be checked by the unit tests and so that the wording of the program can be 
changed without touching the logic of the session */
module help;

import std.stdio;

// The banner with the name of the project
immutable string[] bannerLines =
[
    "##########################################",
    "#                                        #",
    "#      CMPS3111 PROGRAMMING PROJECT 2     #",
    "#        GRAPH PLOTTING LANGUAGE          #",
    "#                                        #",
    "##########################################",
];

// The short hint that is shown when the program starts
immutable string[] startupLines =
[
    "Type a whole program on one line, for example:",
    "",
    "      start bar a1,5;line a1,b1 end",
    "",
    "The program is typed in this console and the graph is drawn in the",
    "window of the graph.  Type \"help\" to see all the commands.",
];

// The grammar of the language
immutable string[] grammarLines =
[
    "     <graph> -> start <plot_stmts> end",
    "<plot_stmts> -+ <plot>",
    "              | <plot> ; <plot_stmts>",
    "",
    "      <plot> -+ bar <x><y>,<y>",
    "              | line <x><y>,<x><y>",
    "              | grid <x><y>",
    "              | fill <x><y>",
    "",
    "         <x> -> a | b | c | d | e | f | g | h | i | j",
    "         <y> -> 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9",
];

// The list of the commands of the language and what they do
immutable string[] commandLines =
[
    "THE COMMANDS OF THE LANGUAGE:",
    "",
    "  bar <x><y>,<y>       a vertical bar in the column <x> that spans",
    "                       the rows <y> to <y>, for example \"bar a1,5\"",
    "                       draws the bar in the column a from the row 1",
    "                       to the row 5.",
    "",
    "  line <x><y>,<x><y>   a straight line between two points of the",
    "                       graph, the points are the crossings of the",
    "                       gridlines, for example \"line a1,b1\" draws the",
    "                       line from the point a1 to the point b1.",
    "",
    "  grid <x><y>          graph paper that covers the area between the",
    "                       origin a0 and the cell <x><y>, for example",
    "                       \"grid c5\" covers the columns a, b and c and",
    "                       the rows 0 to 5.",
    "",
    "  fill <x><y>          fills the area that is not closed by the bars,",
    "                       the lines and the graph paper, starting at the",
    "                       cell <x><y>.  A fill that starts inside a grid",
    "                       stays in the cell it starts in.",
    "",
    "THE GRAPH:",
    "",
    "  The graph has ten columns a to j and ten rows 0 to 9, with the",
    "  row 0 at the bottom.  The labels are drawn on the gridlines: the",
    "  letter of a column is under the gridline at its right edge and the",
    "  digit of a row is beside the gridline below it, so the origin is a0.",
    "  Every program of the session is drawn on the same graph, so the",
    "  commands of several programs can be seen together.",
];

// The text that is shown when the user asks for help
immutable string[] helpLines =
[
    "HOW TO USE THE PROGRAM:",
    "",
    "  Type a whole program on one line, for example:",
    "",
    "      start bar a1,5;line a1,b1 end",
    "",
    "  The program checks the program against the grammar, shows the leftmost",
    "  derivation and the parse tree and draws the commands on the graph.",
    "",
    "  The program is typed in this console and the graph is drawn in the",
    "  window of the graph.  The window of the graph can be resized and the",
    "  graph follows the size of the window.",
    "",
    "  Type \"help\" to see this text again, \"clear\" to empty the graph,",
    "  \"shot\" to save a picture of the graph and \"STOP\" to leave the program.",
];

// Prints a list of lines
private void printLines(const string[] lines)
{
    foreach (line; lines)
        writeln(line);
}

// Prints the banner with the name of the project
void printBanner()
{
    printLines(bannerLines);
}

// Prints the short hint that is shown when the program starts
void printStartup()
{
    printLines(startupLines);
}

// Prints the grammar of the language
void printGrammar()
{
    printLines(grammarLines);
}

// Prints the list of the commands of the language
void printCommands()
{
    printLines(commandLines);
}

// Prints the text that is shown when the user asks for help
void printHelp()
{
    writeln;
    printLines(helpLines);
    writeln;
    printGrammar();
    writeln;
    printCommands();
    writeln;
}
