// Unit tests for the commands that are read out of the parse tree
module commands_test;

import analyzer;
import commands;
import parsetree;

// Reads the first <plot> of a program
private bool firstPlot(string program, out PlotCommand command)
{
    auto analysis = analyze(program);
    if (!analysis.valid)
        return false;

    auto plots = plotsOf(analysis.root);
    if (plots.length == 0)
        return false;

    return parsePlot(plots[0], command);
}

unittest
{
    // A bar is read with its column and its rows
    PlotCommand command;
    assert(firstPlot("start bar a1,5 end", command));
    assert(command.kind == PlotKind.bar);
    assert(command.x1 == 0);
    assert(command.y1 == 1);
    assert(command.y2 == 5);
}

unittest
{
    // A line is read with both of its points
    PlotCommand command;
    assert(firstPlot("start line a1,c7 end", command));
    assert(command.kind == PlotKind.line);
    assert(command.x1 == 0);
    assert(command.y1 == 1);
    assert(command.x2 == 2);
    assert(command.y2 == 7);
}

unittest
{
    // A grid is read with the cell it reaches
    PlotCommand command;
    assert(firstPlot("start grid c5 end", command));
    assert(command.kind == PlotKind.grid);
    assert(command.x1 == 2);
    assert(command.y1 == 5);
}

unittest
{
    // A fill is read with the cell it starts in
    PlotCommand command;
    assert(firstPlot("start fill b3 end", command));
    assert(command.kind == PlotKind.fill);
    assert(command.x1 == 1);
    assert(command.y1 == 3);
}

unittest
{
    // The letters of the columns and the digits of the rows
    assert(columnOf('a') == 0);
    assert(columnOf('j') == 9);
    assert(columnOf('k') == -1);
    assert(columnOf('A') == -1);
    assert(rowOf('0') == 0);
    assert(rowOf('9') == 9);
    assert(rowOf('x') == -1);
}

unittest
{
    // Every command of a program is read
    auto analysis = analyze("start bar a1,5;line a1,b1;grid c5;fill b3 end");
    assert(analysis.valid);

    auto plots = plotsOf(analysis.root);
    assert(plots.length == 4);

    PlotCommand[4] commands;
    foreach (i, plot; plots)
        assert(parsePlot(plot, commands[i]));

    assert(commands[0].kind == PlotKind.bar);
    assert(commands[1].kind == PlotKind.line);
    assert(commands[2].kind == PlotKind.grid);
    assert(commands[3].kind == PlotKind.fill);
}

unittest
{
    // The name of the commands
    assert(nameOf(PlotKind.bar) == "bar");
    assert(nameOf(PlotKind.line) == "line");
    assert(nameOf(PlotKind.grid) == "grid");
    assert(nameOf(PlotKind.fill) == "fill");
}
