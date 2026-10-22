// Unit tests for the leftmost derivation engine
module analyzer_test;

import std.algorithm : canFind;
import std.stdio;
import std.string : split;

import analyzer;
import grammar;
import parsetree;

private string[] formsOf(const Analysis analysis)
{
    string[] forms;
    foreach (step; analysis.steps)
        forms ~= step.sententialForm;
    return forms;
}

unittest
{
    /* The derivation of a single bar starts at <graph> and ends at the terminals of the input */
    auto analysis = analyze("start bar a1,5 end");

    assert(analysis.valid, "a single bar is a valid program");
    assert(analysis.steps.length == 6, "six expansions are needed for a single bar");
    assert(analysis.steps[0].sententialForm == "start <plot_stmts> end");
    assert(analysis.steps[1].sententialForm == "start <plot> end");
    assert(analysis.steps[2].sententialForm == "start bar <x> <y> , <y> end");
    assert(analysis.steps[3].sententialForm == "start bar a <y> , <y> end");
    assert(analysis.steps[4].sententialForm == "start bar a 1 , <y> end");
    assert(analysis.steps[5].sententialForm == "start bar a 1 , 5 end");
    assert(analysis.root.symbol == "<graph>");

    // Every step expands one nonterminal and records which one it was
    assert(analysis.steps[0].expanded == "<graph>");
    assert(analysis.steps[1].expanded == "<plot_stmts>");
    assert(analysis.steps[2].expanded == "<plot>");
    assert(analysis.steps[3].expanded == "<x>");
    assert(analysis.steps[4].expanded == "<y>");
    assert(analysis.steps[5].expanded == "<y>");
}

unittest
{
    // A program with two commands is derived command by command
    auto analysis = analyze("start bar a1,5;line a1,b1 end");

    assert(analysis.valid);
    assert(analysis.steps[0].sententialForm == "start <plot_stmts> end");
    assert(analysis.steps[1].sententialForm == "start <plot> ; <plot_stmts> end");
    assert(analysis.steps[2].sententialForm == "start bar <x> <y> , <y> ; <plot_stmts> end");
    assert(analysis.steps[$-1].sententialForm == "start bar a 1 , 5 ; line a 1 , b 1 end");
}

unittest
{
    // The leftmost nonterminal is always the one that is expanded
    auto analysis = analyze("start grid c5 end");
    assert(analysis.valid);

    foreach (i, step; analysis.steps)
    {
        auto before = i == 0 ? "<graph>" : analysis.steps[i - 1].sententialForm;
        assert(step.expanded.length > 0);
        assert(before.canFind(step.expanded), "the expanded nonterminal has to be the leftmost one");
    }
}

unittest
{
    // Every command of the language is accepted
    assert(analyze("start bar a1,5 end").valid);
    assert(analyze("start line a1,b5 end").valid);
    assert(analyze("start grid c5 end").valid);
    assert(analyze("start fill b3 end").valid);
    assert(analyze("start bar a1,5;line a1,b1;grid c5;fill b3 end").valid);
    assert(analyze("start bar a0,0 end").valid);
    assert(analyze("start bar j9,9 end").valid);
}

unittest
{
    // Invalid programs are rejected and report a partial derivation
    auto unknown = analyze("start circle a1,5 end");
    assert(!unknown.valid);
    assert(unknown.errorMessage.length > 0);
    assert(unknown.errorSteps.length > 0, "an invalid program still shows a partial derivation");

    assert(!analyze("start bar a1,5").valid);
    assert(!analyze("bar a1,5 end").valid);
    assert(!analyze("start bar k1,5 end").valid);
    assert(!analyze("start bar a1,12 end").valid);
    assert(!analyze("start bar a1;line a1,b1 end").valid);
    assert(!analyze("start bar a1,5 end extra").valid);
    assert(!analyze("").valid);
}

unittest
{
    // The tokenizer splits coordinates into <x> and <y>
    assert(tokenize("start bar a1,5 end") == ["start", "bar", "a", "1", ",", "5", "end"]);
    assert(tokenize("start line a1,b5 end") == ["start", "line", "a", "1", ",", "b", "5", "end"]);
    assert(tokenize("start bar a1,5;line a1,b1 end")
        == ["start", "bar", "a", "1", ",", "5", ";", "line", "a", "1", ",", "b", "1", "end"]);
}

unittest
{
    // The parse tree has the shape of the grammar
    auto analysis = analyze("start bar a1,5 end");
    assert(analysis.valid);

    auto tree = analysis.root;
    assert(tree.children.length == 3);
    assert(tree.children[0].symbol == "start");
    assert(tree.children[1].symbol == "<plot_stmts>");
    assert(tree.children[2].symbol == "end");

    auto plot = tree.children[1].children[0];
    assert(plot.symbol == "<plot>");
    assert(plot.children.length == 5);
    assert(plot.children[0].symbol == "bar");
    assert(plot.children[1].symbol == "<x>");
    assert(plot.children[1].children[0].symbol == "a");
    assert(plot.children[4].children[0].symbol == "5");
}

unittest
{
    // The plot commands can be recovered from the parse tree
    auto analysis = analyze("start bar a1,5;line a1,b1 end");
    assert(analysis.valid);

    auto plots = plotsOf(analysis.root);
    assert(plots.length == 2);
    assert(leaves(plots[0]) == ["bar", "a", "1", ",", "5"]);
    assert(leaves(plots[1]) == ["line", "a", "1", ",", "b", "1"]);
}

unittest
{
    /* The parse tree is rendered as an ASCII drawing Regression test: the renderer used to be a member function that called itself without a receiver, so it walked into the same node again and again until the stack overflowed */
    auto analysis = analyze("start bar a1,5 end");
    assert(analysis.valid);

    auto text = analysis.root.toString();
    assert(text.canFind("<graph>"));
    assert(text.canFind("start"));
    assert(text.canFind("`-- "));
    assert(text.canFind("bar"));

    // The tree of a program with two commands is rendered as well
    auto two = analyze("start bar a1,5;line a1,b1 end");
    assert(two.valid);

    auto longer = two.root.toString();
    assert(longer.canFind("line"));
    assert(longer.split('\n').length == 26, "the tree of two commands has 26 nodes");
}

unittest
{
    // The grammar itself is consistent
    auto grammar = buildGrammar();
    assert(grammar.isNonterminal("<graph>"));
    assert(grammar.isNonterminal("<plot_stmts>"));
    assert(grammar.isNonterminal("<plot>"));
    assert(grammar.isNonterminal("<x>"));
    assert(grammar.isNonterminal("<y>"));
    assert(!grammar.isNonterminal("bar"));
    assert(grammar.forLhs("<x>").length == 10);
    assert(grammar.forLhs("<y>").length == 10);
    assert(grammar.forLhs("<plot>").length == 4);
    assert(grammar.forLhs("<plot_stmts>").length == 2);
}
