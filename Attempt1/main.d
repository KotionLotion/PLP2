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
        
        checkProgram(c1);

        writeln("\nPress ENTER key to continue...");
        readln();

    }
   
}

bool checkProgram(string input){
    // if (!input.startsWith("start")){
    //     writeln("Invalid syntax! Must begin with \"start\"");
    // }
    // if (!input.endsWith("end")){
    //     writeln("Invalid syntax! Must end with \"end\"");
    // }

    //adding spaces around commas and semicolons
    // so something like "start bar a1,5;line a1,b1;grid a2 end" becomes 
    input = input.replace(",", " , ");
    input = input.replace(";", " ; ");

    //next we split tokens meaning we get an array of strings wherever there is a whitespace.
    //so in  "start bar a1 , 5 ; line a1 , b1 ; grid a2 end", index 0 = start, index 1 = bar, index 2 = a1, etc...
    auto tokens = input.split();

    size_t i = 0;

    //Check for start
    if (tokens.length == 0 || tokens[0] != "start"){
        writeln("Invalid syntax! Must begin with \"start\"");
        return false;
    }

    i++;

    //check for atleast ONE command after start
    if (i >= tokens.length || tokens[i] == "end"){
        writeln("Uh oh! missing plot command after \"start\"");
    }
    
    while (i < tokens.length){
        //check end
        if(tokens[i] == "end"){
            i++;

            if (i < tokens.length){
                writeln("Invalid syntax! Unexpected text after \"end\"");
                return false;
            }

            writeln("Valid start and end");
            return true;
        }
        //Validation for commands bar, line, grid and fill

        //TEMPORARY MOVE TO NETX TOKEN
            i++;

        //Check first coordinate
    }

    //if exit loop without end
    writeln("Invalid syntax! Missing \"end\" at the end of input!");
    return false;
}