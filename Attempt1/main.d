import std;

void main(){
    while(true){
        //clear the console
        version(Windows) { spawnShell("cls").wait; } else { spawnShell("clear").wait; }

        writeln("######################################");
        writeln("#                                    #");
        writeln("#           D BNF GRAMMAR            #");
        writeln("#                                    #");
        writeln("###################################### \n");

        writeln("     <graph> -> start <plot_stmts> end");
        writeln("<plot_stmts> -+ <plot>");
        writeln("              | <plot>;<plot_stmt>\n");
        writeln("      <plot> -+ bar<x><y>,<y>");
        writeln("              | line<x><y>,<x><y>");
        writeln("              | grid<x><y>");
        writeln("              | fill<x><y>\n");

        writeln("         <x> -> a | b | c | d | e | f | g | h | i | j");
        writeln("         <y> -> 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9\n\n");

        
        writeln("Please enter a command or type \"STOP\" to exit: ");
        string c1 = readln().strip();

        if(c1 == "STOP"){
            writeln("Exiting the program, good day!");
            break;
        }


    }
   
}