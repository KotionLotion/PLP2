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
        
        // checkProgram(c1);

        //tokenize input
        string input = c1.replace(",", " , ");
        input = input.replace(";", " ; ");

        auto tokens = input.split();

        if (checkProgram(tokens)){
            if (deriv(tokens)){
                writeln("\nPress ENTER to display the parse tree...");
                readln();

                //currently, extracts bar values and prints. graphics() extracts values and draws rectangle.
                //We will use as the basis for building tree and/or extracting info into a data structure
                // parse(tokens);

                writeln("\nPress ENTER to display the graphical output...");
                readln();

                graphics(tokens);

                writeln("\nPress ENTER to continue...");
                readln();
            }
            else{
                writeln("\nThe derivation failed. Invalid program.");
                writeln("\nPress ENTER to continue...");
                readln();
            }
        }

        // writeln("\nPress ENTER key to continue...");
        // readln();

    }
   
}

bool checkProgram(string[] tokens){
    // if (!input.startsWith("start")){
    //     writeln("Invalid syntax! Must begin with \"start\"");
    // }
    // if (!input.endsWith("end")){
    //     writeln("Invalid syntax! Must end with \"end\"");
    // }

    //adding spaces around commas and semicolons
    // so something like "start bar a1,5;line a1,b1;grid a2 end" becomes 
    // input = input.replace(",", " , ");
    // input = input.replace(";", " ; ");

    //next we split tokens meaning we get an array of strings wherever there is a whitespace.
    //so in  "start bar a1 , 5 ; line a1 , b1 ; grid a2 end", index 0 = start, index 1 = bar, index 2 = a1, etc...
    // auto tokens = input.split();

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
        return false;
    }
    
    while (i < tokens.length){
        //check end
        if(tokens[i] == "end"){
            i++;

            if (i < tokens.length){
                writeln("Invalid syntax! Unexpected text after \"end\"");
                return false;
            }

            writeln("Valid syntax!");
            return true;
        }

        //Validation for commands bar, line, grid and fill
        string command = tokens [i];

        if (command != "bar" && command != "line" && command != "grid" && command != "fill"){
            writeln("Invalid command: ", command);
            writeln("accepted commands: bar, line, grid & fill");
            return false;
        }

        //Next token (coods)
            i++;

        //Check first coordinate
        if (i >= tokens.length){
            writeln("Missing coordinate after '", command, "'");
            return false;
        }

        string coord = tokens[i];

        if (coord.length != 2 || coord[0] < 'a' || coord[0] > 'j' || coord[1] < '0' || coord[1] > '9'){
            writeln("Invalid coord '", coord, "'. Expected a letter a-j followed by a digit 0-9");
            return false;
        }

        i++;

        //Bar
        if (command == "bar"){
            if (i >= tokens.length || tokens[i] != ","){
                writeln("Uh oh! Missing a comma in bar command");
                return false;
            }

            i++;

            if (i >= tokens.length || tokens[i].length != 1 || tokens[i][0] < '0' || tokens [i][0] > '9'){
                writeln("Invalid bar width! Expected digit between 0-9");
                return false;
            }

            i++;
        }

        // Lnie
        else if (command == "line"){
            if (i >= tokens.length || tokens [i] != ","){
                writeln("Uh oh! Missing comma in line command");
                return false;
            }

            i++;

           // Check second coordinate
            if (i >= tokens.length){
                writeln("Missing second coordinate in line command");
                return false;
            }

            string coord2 = tokens[i];

            if (coord2.length != 2 || coord2[0] < 'a' || coord2[0] > 'j' || coord2[1] < '0' || coord2[1] > '9')
            {
                writeln("Invalid second coordinate: ", coord2);
                writeln("Expected a letter a-j followed by a digit 0-9");
                return false;
            }

            i++;
        }

        //check for separator or end
        if (i < tokens.length && tokens[i] != ";" && tokens[i] != "end"){
            writeln("Error! Expected ';' or 'end' after command");
            return false;
        }

        //consume semicolon
        if (i < tokens.length && tokens[i] == ";"){
            i++;

            if (i >= tokens.length || tokens[i] == "end" || tokens[i] == ";"){
                writeln("Error! Missing command after semicolon");
                return false;
            }
        }
    }

    //if exit loop without end
    writeln("Invalid syntax! Missing \"end\" at the end of input!");
    return false;
}

bool parser(string[] tokens){
    //skips the first keyword at token [0] 'start'
    size_t i = 1;

    while (i < tokens.length){
        if (tokens[i] == "end"){
            return true;
        }


        //current token is command keyword
        string command = tokens[i];

        switch (command){
            case "bar":
                //move past bar
                i++;

                //extract coord
                string coord = tokens[i];
                i++;

                //move past comma
                i++;

                //get width
                string width = tokens[i];
                i++;

                //values for derivation
                writeln("Command: ", command);
                writeln("Coords: ", coord);
                writeln("Width: ", width);

                break;
            
            //case "line":
            //case "grid":
            //case "fill":

            default:
                writeln("Unknown command: ", command);
                return false;
        }

        //skip semi if present
        if (i < tokens.length && tokens[i] == ";"){
                i++;
        }
    }

    return false;
}

// Helper
string repLMost(string input, string target, string repl){
    size_t pos = 0;

    //left most offurence
    while(pos + target.length <= input.length){
        if (input[pos .. pos + target.length] == target){
            return input[0 .. pos] ~ repl ~ input[pos + target.length .. $];
        }

        pos++;
    }

    //no target found
    return input;
}

//Derivation
bool deriv(string[] tokens){
    writeln("\nLEFTMOST DERIVATION:");

    string result = "<graph>";
    writeln(result);

    //step 1 Expand <graph>
    result = "start <plot_stmts> end";
    writeln(result);

    // Collect the plot commands from the input where each plot is stored as its own arary of tokens
    string[][] plots;

    //skips start
    size_t i = 1; 

    while (i < tokens.length && tokens[i] != "end"){
        string[] currentPlot;

        while (i < tokens.length && tokens[i] != ";" && tokens[i] != "end"){
            currentPlot ~= tokens[i];
            i++;
        }

        plots ~= [currentPlot];

        if (i < tokens.length && tokens[i] == ";"){
            i++;
        }
    }

    if (plots.length == 0){
        writeln("Derivation failed: no plot commands.");
        return false;
    }

    // step 2 expand <plot_stmts> using a recursive rule
    for (size_t j = 1; j < plots.length; j++){
        result = repLMost( result, "<plot_stmts>", "<plot> ; <plot_stmts>");
        writeln(result);
    }

    //expand the final <plot_stmts> into <plot>
    result = repLMost(result, "<plot_stmts>", "<plot_stmt>");
    writeln(result);

    result = repLMost(result, "<plot_stmt>", "<plot>");
    writeln(result);

    // Step 3 Expand each plot from L - R
    foreach (plot; plots){
        if (plot.length == 0){
            writeln("Derivation failed: empty plot.");
            return false;
        }

        string command = plot[0];

        switch (command){
            case "bar":{
                // Input tokens:
                // plot[0] = "bar"
                // plot[1] = coordinate, e.g. "b4"
                // plot[2] = ","
                // plot[3] = width, e.g. "2"

                if (plot.length != 4){
                    writeln("Derivation failed: invalid bar.");
                    return false;
                }

                string coord = plot[1];
                string width = plot[3];

                // Expand the leftmost <plot>.
                result = repLMost(result, "<plot>", "bar <x><y>,<y>");
                writeln(result);

                // Expand the leftmost <x>.
                result = repLMost( result, "<x>", coord[0 .. 1]);
                writeln(result);

                // Expand the leftmost <y>.
                result = repLMost( result, "<y>", coord[1 .. 2]);
                writeln(result);

                // Expand the remaining <y> into the width.
                result = repLMost( result, "<y>", width);
                writeln(result);

                break;
            }

            case "line": {
                writeln("Line derivation not implemented yet.");
                return false;
            }

            case "grid": {
                writeln("Grid derivation not implemented yet.");
                return false;
            }

            case "fill": {
                writeln("Fill derivation not implemented yet.");
                return false;
            }

            default: {
                writeln("Unknown command in derivation: ", command);
                return false;
            }
        }
    }

    // The derivation should match the input sentence
    writeln("\nSuccessfully derived the input sentence!");
    writeln("Generated sentence: ", result);

    return true;
}

//graphics (visual?)
void graphics(string[] tokens)
{
    writeln("\nGRAPHICAL OUTPUT:");

    //skip start
    size_t i = 1;

    while (i < tokens.length && tokens[i] != "end"){
        string command = tokens[i];

        switch (command){
            case "bar":
            {
                // Extract bar values from the tokens.
                string coord = tokens[i + 1];
                int width = to!int(tokens[i + 3]);

                int x = coord[0] - 'a';
                int y = coord[1] - '0';

                drawBar(x, y, width);

                // Move past: bar, coordinate, comma, width
                i += 4;

                break;
            }

            case "line": {
                writeln("Line graphics not implemented yet.");
                return;
            }

            case "grid": {
                writeln("Grid graphics not implemented yet.");
                return;
            }

            case "fill": {
                writeln("Fill graphics not implemented yet.");
                return;
            }

            default: {
                writeln("Unknown graphics command: ", command);
                return;
            }
        }

        // Skip the semicolon between plots
        if (i < tokens.length && tokens[i] == ";"){
            i++;
        }
    }
}


void drawBar(int x, int y, int width){
    int left = x;
    int right = x + width;

    int bottom = 0;
    int top = y;

    // Check coordinate boundary
    if (right > 9){
        writeln("Error: Bar exceeds the maximum x-coordinate (j).");
        return;
    }

    //each x-coordinate gets 4 character spaces
    int spacing = 4;

    int leftPos = left * spacing;
    int rightPos = right * spacing;
    int maxX = right * spacing;

    writeln("\nBAR GRAPH");
    writeln("Top-left: ", cast(char)('a' + left), top);
    writeln("Bottom-right: ", cast(char)('a' + right), bottom);
    writeln();

    // Draw the rectangle from top to bottom
    for (int row = top; row >= bottom; row--){
        // create a row with enough space for all columns
        char[] graphRow = new char[maxX + 1];

        foreach (ref ch; graphRow){
            ch = ' ';
        }

        // Draw vertical sids
        if (row > bottom && row < top){
            graphRow[leftPos] = '|';
            graphRow[rightPos] = '|';
        }

        // Draw top and bottom side
        if (row == top || row == bottom){
            foreach (col; leftPos .. rightPos + 1)
            {
                graphRow[col] = '-';
            }

            graphRow[leftPos] = '+';
            graphRow[rightPos] = '+';
        }

        //Print y-coordinate label
        write(row, " | ");

        // Print the spaced graph row
        writeln(graphRow);
    }

    //print x labels, spaced evenly
    write("   ");

    for (int col = 0; col <= right; col++){
        write("  ", cast(char)('a' + col), " ");
    }
    writeln();
}