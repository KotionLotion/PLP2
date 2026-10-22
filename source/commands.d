// Turns the <plot> nodes of the parse tree into the commands of the scene
module commands;

import parsetree;

// The four commands of the language
enum PlotKind
{
    bar,
    line,
    grid,
    fill
}

// One plot command, ready to be drawn
struct PlotCommand
{
    // Which command it is
    PlotKind kind;
    // The column of the first point
    int x1;
    // The row of the first point
    int y1;
    // The column of the second point, only used by a line
    int x2;
    // The row of the second point, only used by a line
    int y2;
}

// The name of a command, as it is written in the program
string nameOf(PlotKind kind)
{
    final switch (kind)
    {
        case PlotKind.bar: return "bar";
        case PlotKind.line: return "line";
        case PlotKind.grid: return "grid";
        case PlotKind.fill: return "fill";
    }
}

// Converts a letter of the input into a column, a..j becomes 0..9
int columnOf(char letter)
{
    if (letter < 'a' || letter > 'j')
        return -1;

    return cast(int)(letter - 'a');
}

// Converts a digit of the input into a row
int rowOf(char digit)
{
    if (digit < '0' || digit > '9')
        return -1;

    return cast(int)(digit - '0');
}

/* Reads one <plot> node of the parse tree Returns false when the node does not hold a 
well formed command, which cannot happen for a program that was accepted by the analyzer */
bool parsePlot(const ParseNode plot, out PlotCommand command)
{
    auto tokens = leaves(plot);
    if (tokens.length == 0)
        return false;

    switch (tokens[0])
    {
        case "bar":
            if (tokens.length != 5)
                return false;

            command = PlotCommand(PlotKind.bar);
            command.x1 = columnOf(tokens[1][0]);
            command.y1 = rowOf(tokens[2][0]);
            command.y2 = rowOf(tokens[4][0]);
            break;

        case "line":
            if (tokens.length != 6)
                return false;

            command = PlotCommand(PlotKind.line);
            command.x1 = columnOf(tokens[1][0]);
            command.y1 = rowOf(tokens[2][0]);
            command.x2 = columnOf(tokens[4][0]);
            command.y2 = rowOf(tokens[5][0]);
            break;

        case "grid":
            if (tokens.length != 3)
                return false;

            command = PlotCommand(PlotKind.grid);
            command.x1 = columnOf(tokens[1][0]);
            command.y1 = rowOf(tokens[2][0]);
            break;

        case "fill":
            if (tokens.length != 3)
                return false;

            command = PlotCommand(PlotKind.fill);
            command.x1 = columnOf(tokens[1][0]);
            command.y1 = rowOf(tokens[2][0]);
            break;

        default:
            return false;
    }

    return true;
}
