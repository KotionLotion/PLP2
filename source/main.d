/* CMPS3111 Programming Project 2 A graph plotting language whose programs are recognized
by a real leftmost derivation over the grammar of the language.  The program checks a program,
shows the leftmost derivation, shows the parse tree and draws the resulting graph in a window 
The commands are read by a second thread so that the window keeps redrawing while the user is typing */
module main;

import core.stdc.stdlib : _Exit;
import core.thread : Thread;
import core.time : msecs;
import std.file : exists, mkdirRecurse;
import std.conv : to;
import std.stdio;
import std.string;

import analyzer;
import commands;
import grammar;
import help;
import parsetree;
import raylib;
import renderer;
import scene;
import win32;

// Everything that the reader thread and the drawing thread share
class Session
{
    // The graph that is drawn
    Scene scene = new Scene();
    // False when the program has to end
    bool running = true;
    // The program that was drawn last
    string program = "";
    // The message that is shown in the window
    string status = "Waiting for a program.";
    // True when a screenshot of the window has to be written
    bool screenshotPending = false;
    // The number of screenshots that were written
    int screenshotCount = 0;
    // True when the derivation and the parse tree are not shown
    bool quiet = false;
}

// Prints the banner with a short hint
void printBanner()
{
    help.printBanner();
    writeln;
    help.printStartup();
    writeln;
}

// Prints the leftmost derivation of an analysis
void deriveSentence(const Analysis analysis)
{
    writeln;
    writeln("LEFTMOST DERIVATION:");

    foreach (i, step; analysis.steps)
        writeln("  ", i + 1, ". ", step.sententialForm);
}

// Prints the parse tree of an analysis
void printParseTree(const Analysis analysis)
{
    writeln;
    writeln("PARSE TREE:");
    writeln(analysis.root.toString());
}

// Draws one command on the graph
void applyCommand(Scene scene, PlotCommand command)
{
    final switch (command.kind)
    {
        case PlotKind.bar:
            scene.addBar(command.x1, command.y1, command.y2);
            break;
        case PlotKind.line:
            scene.addLine(command.x1, command.y1, command.x2, command.y2);
            break;
        case PlotKind.grid:
            scene.addGrid(command.x1, command.y1);
            break;
        case PlotKind.fill:
            scene.addFill(command.x1, command.y1);
            break;
    }
}

// Checks a program, reports the outcome and draws it when it is valid
void checkProgram(Session session, string input)
{
    auto analysis = analyze(input);

    if (!analysis.valid)
    {
        writeln;
        writeln("INVALID PROGRAM: ", analysis.errorMessage, ".");

        if (analysis.errorSteps.length > 0)
        {
            writeln;
            writeln("PARTIAL DERIVATION AT THE POINT OF THE ERROR:");
            foreach (i, step; analysis.errorSteps)
                writeln("  ", i + 1, ". ", step.sententialForm);
        }

        writeln;
        writeln("The graph was not changed.  Type \"help\" to see the commands.");

        synchronized (session)
        {
            session.program = input;
            session.status = "INVALID PROGRAM: " ~ analysis.errorMessage ~ ".";
        }

        return;
    }

    writeln;
    writeln("VALID PROGRAM: the input is a sentence of the grammar.");

    if (!session.quiet)
    {
        deriveSentence(analysis);
        printParseTree(analysis);
    }

    size_t applied = 0;
    size_t painted = 0;

    synchronized (session)
    {
        foreach (plot; plotsOf(analysis.root))
        {
            PlotCommand command;
            if (!parsePlot(plot, command))
                continue;

            applyCommand(session.scene, command);
            ++applied;
        }

        painted = session.scene.paintedCells();

        session.program = input;
        session.status = "The program drew " ~ applied.to!string ~ " command(s) on the graph.";
        session.screenshotPending = true;
    }

    writeln;
    writeln("DREW ", applied, " COMMAND(S) ON THE GRAPH.");
    writeln("The graph holds ", painted, " painted cell(s).");
}

// Reads the programs of the user and draws them
void inputLoop(Session session)
{
    writeln("Enter a program, for example:");
    writeln("  start bar a1,5;line a1,b1 end");
    writeln("Type \"help\" for the commands, \"clear\" to empty the graph,");
    writeln("\"shot\" to save a picture of the graph and \"STOP\" to exit.");
    writeln;

    while (true)
    {
        write("> ");
        stdout.flush();

        auto line = readln();
        if (line is null)
        {
            // The input ended, the program ends as well
            synchronized (session)
                session.running = false;
            break;
        }

        line = line.strip;
        if (line.length == 0)
            continue;

        if (line == "STOP" || line == "stop" || line == "quit")
        {
            writeln("Exiting the program, good day!");
            synchronized (session)
                session.running = false;
            break;
        }

        if (line == "help" || line == "?")
        {
            help.printHelp();
            continue;
        }
        if (line == "clear")
        {
            synchronized (session)
            {
                session.scene.clear();
                session.program = "";
                session.status = "The graph was cleared.";
            }

            writeln("The graph was cleared.");
            continue;
        }
        if (line == "shot")
        {
            synchronized (session)
                session.screenshotPending = true;

            writeln("A picture of the graph is written to the folder of the screenshots.");
            continue;
        }

        checkProgram(session, line);
        writeln;
    }
}

// Why the drawing loop ended
enum LoopEnd
{
    // The user typed STOP, the session is over
    sessionEnded,
    // The user closed the window
    windowClosed
}

// Opens the window and keeps drawing the graph until the program ends
LoopEnd graphicsLoop(Session session, Renderer graph)
{
    if (!exists("screenshots"))
        mkdirRecurse("screenshots");

    while (true)
    {
        /* The layout of the graph follows the size of the window, so a window that was resized by the user is laid out again */
        if (graph.wasResized())
            graph.relayout();

        synchronized (session)
        {
            if (!session.running)
                return LoopEnd.sessionEnded;

            graph.draw(session.scene, session.program, session.status);

            if (session.screenshotPending)
            {
                session.screenshotPending = false;
                session.screenshotCount++;

                /* The picture is read from the buffer of the frame before the last one, so the graph is drawn again before it is saved */
                graph.screenshot(session.scene, session.program, session.status,
                    "screenshots/graph-" ~ session.screenshotCount.to!string ~ ".png");
            }
        }
        // Let the reader thread take the lock between frames
        Thread.sleep(2.msecs);

        if (WindowShouldClose())
            return LoopEnd.windowClosed;
    }
}

// Ends the program right away, without running the cleanup of the runtime
void quitNow()
{
    /* The reader thread is still waiting for a line, so the program ends the hard way; the cleanup of the runtime would close the input stream while the other thread is using it */
    _Exit(0);
}


// Runs the program
void main(string[] args)
{
    bool headless = false;
    bool wantsHelp = false;
    bool quiet = false;

    foreach (arg; args[1 .. $])
    {
        if (arg == "--no-gui" || arg == "-nogui")
            headless = true;
        else if (arg == "--help" || arg == "-h")
            wantsHelp = true;
        else if (arg == "--quiet" || arg == "-q")
            quiet = true;
    }

    if (wantsHelp)
    {
        help.printBanner();
        writeln;
        help.printHelp();
        return;
    }

    printBanner();

    auto session = new Session();
    session.quiet = quiet;

    if (headless)
    {
        inputLoop(session);
        return;
    }

    auto graph = new Renderer();
    graph.init("CMPS3111 - Graph Plotting Language");
    scope (exit) graph.close();

    writeln(graph.describe());

    /* The window of the graph takes the keyboard when it is opened, so the console is brought to the front again */
    writeln("The graph window is open.  Click in this console window and type your program.");
    writeln;

    auto reader = new Thread({
        try
            inputLoop(session);
        catch (Exception error)
            stderr.writeln("ERROR: ", error.msg);
    });

    reader.start();

    auto reason = graphicsLoop(session, graph);

    if (reason == LoopEnd.windowClosed)
        quitNow();

    /* The reader stopped on its own, wait for it so that it does not use the input stream while the program ends */
    reader.join();
}

