// Unit tests for the texts that the program shows on the console
module help_test;

import std.algorithm : canFind;
import std.string : join;

import help;

unittest
{
    // The banner holds the name of the project
    auto banner = bannerLines.join("\n");
    assert(banner.canFind("CMPS3111"));
    assert(banner.canFind("GRAPH PLOTTING LANGUAGE"));
}

unittest
{
    // The grammar holds every production of the language
    auto grammar = grammarLines.join("\n");
    assert(grammar.canFind("<graph> -> start <plot_stmts> end"));
    assert(grammar.canFind("bar <x><y>,<y>"));
    assert(grammar.canFind("line <x><y>,<x><y>"));
    assert(grammar.canFind("grid <x><y>"));
    assert(grammar.canFind("fill <x><y>"));
    assert(grammar.canFind("a | b | c | d | e | f | g | h | i | j"));
    assert(grammar.canFind("0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9"));
}

unittest
{
    // Every command of the language is explained
    auto commands = commandLines.join("\n");
    assert(commands.canFind("bar <x><y>,<y>"));
    assert(commands.canFind("line <x><y>,<x><y>"));
    assert(commands.canFind("grid <x><y>"));
    assert(commands.canFind("fill <x><y>"));
    assert(commands.canFind("a vertical bar"));
    assert(commands.canFind("a straight line"));
    assert(commands.canFind("graph paper"));
    assert(commands.canFind("fills the area"));
}

unittest
{
    // The help text explains the words of the console
    auto text = helpLines.join("\n");
    assert(text.canFind("start bar a1,5;line a1,b1 end"));
    assert(text.canFind("leftmost"));
    assert(text.canFind("parse tree"));
    assert(text.canFind("STOP"));
    assert(text.canFind("clear"));
}
