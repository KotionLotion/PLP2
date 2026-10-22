/* The authoritative grammar of the graph plotting language The grammar is kept as *data* 
instead of being hard coded into the analyzer.  This lets `analyzer.d` run a genuine leftmost derivation:
it expands the leftmost nonterminal of the sentential form, one production at a time, and records every
intermediate sentential form */
module grammar;

import std.algorithm : filter;
import std.array : array, join;

// One symbol of a sentential form
struct Symbol
{
    // The name of the symbol, e.g. "&lt;plot&gt;" or "bar"
    string name;
    // True for terminals (literals), false for nonterminals
    bool isTerminal;

    // Creates a terminal symbol
    static Symbol terminal(string name)
    {
        return Symbol(name, true);
    }

    // Creates a nonterminal symbol
    static Symbol nonterminal(string name)
    {
        return Symbol(name, false);
    }
}

// A single grammar production: a nonterminal and the symbols it rewrites to
struct Production
{
    // The nonterminal being expanded
    string lhs;
    // The symbols the nonterminal is rewritten to
    Symbol[] rhs;

    // The human readable form of the production, e.g. "&lt;plot&gt; -> bar &lt;x&gt; &lt;y&gt; , &lt;y&gt;"
    string toString() const
    {
        string[] parts;
        parts ~= lhs ~ " ->";
        foreach (sym; rhs)
            parts ~= sym.name;
        return parts.join(" ");
    }
}

// The complete grammar of the language
struct Grammar
{
    // Every production of the grammar
    Production[] productions;

    // All productions of a nonterminal, in the order they are tried
    const(Production)[] forLhs(string lhs) const
    {
        return productions.filter!(p => p.lhs == lhs).array;
    }

    // True when the name denotes a nonterminal of this grammar
    bool isNonterminal(string name) const
    {
        foreach (p; productions)
            if (p.lhs == name)
                return true;
        return false;
    }
}

// Builds the grammar of the graph plotting language
Grammar buildGrammar()
{
    Grammar grammar;

    grammar.productions = [
        Production("<graph>", [
            Symbol.terminal("start"), Symbol.nonterminal("<plot_stmts>"), Symbol.terminal("end")
        ]),

        Production("<plot_stmts>", [
            Symbol.nonterminal("<plot>"), Symbol.terminal(";"), Symbol.nonterminal("<plot_stmts>")
        ]),
        Production("<plot_stmts>", [
            Symbol.nonterminal("<plot>")
        ]),

        Production("<plot>", [
            Symbol.terminal("bar"), Symbol.nonterminal("<x>"), Symbol.nonterminal("<y>"),
            Symbol.terminal(","), Symbol.nonterminal("<y>")
        ]),
        Production("<plot>", [
            Symbol.terminal("line"), Symbol.nonterminal("<x>"), Symbol.nonterminal("<y>"),
            Symbol.terminal(","), Symbol.nonterminal("<x>"), Symbol.nonterminal("<y>")
        ]),
        Production("<plot>", [
            Symbol.terminal("grid"), Symbol.nonterminal("<x>"), Symbol.nonterminal("<y>")
        ]),
        Production("<plot>", [
            Symbol.terminal("fill"), Symbol.nonterminal("<x>"), Symbol.nonterminal("<y>")
        ]),

        Production("<x>", [Symbol.terminal("a")]),
        Production("<x>", [Symbol.terminal("b")]),
        Production("<x>", [Symbol.terminal("c")]),
        Production("<x>", [Symbol.terminal("d")]),
        Production("<x>", [Symbol.terminal("e")]),
        Production("<x>", [Symbol.terminal("f")]),
        Production("<x>", [Symbol.terminal("g")]),
        Production("<x>", [Symbol.terminal("h")]),
        Production("<x>", [Symbol.terminal("i")]),
        Production("<x>", [Symbol.terminal("j")]),

        Production("<y>", [Symbol.terminal("0")]),
        Production("<y>", [Symbol.terminal("1")]),
        Production("<y>", [Symbol.terminal("2")]),
        Production("<y>", [Symbol.terminal("3")]),
        Production("<y>", [Symbol.terminal("4")]),
        Production("<y>", [Symbol.terminal("5")]),
        Production("<y>", [Symbol.terminal("6")]),
        Production("<y>", [Symbol.terminal("7")]),
        Production("<y>", [Symbol.terminal("8")]),
        Production("<y>", [Symbol.terminal("9")]),
    ];

    return grammar;
}
