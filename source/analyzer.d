/* The analyzer is a leftmost derivation engine for the grammar A single pass produces everything the program needs
 whether the input is a sentence of the grammar (validity) - every sentential form of the leftmost derivation (the derivation)
 the parse tree of the input - the partial derivation that led to an error for invalid input The engine keeps the current sentential
 form as an explicit list of symbols At every step it expands the leftmost nonterminal with one of its productions Terminals are matched
 as they are produced, so the derivation also recognises the input PLS DONT CHANGE THIS */
module analyzer;

import std.array : array;
import std.algorithm : filter;
import std.string : join, replace, split;

import grammar;
import parsetree;

// One expansion of the leftmost derivation
struct DerivationStep
{
    // The sentential form after the expansion
    string sententialForm;
    // The nonterminal that was expanded
    string expanded;
    // The production that was applied
    string production;
}

// The outcome of analyzing one program
struct Analysis
{
    // True when the input is a sentence of the grammar
    bool valid;
    // The tokenized input
    string[] tokens;
    // Every step of the leftmost derivation, in order
    DerivationStep[] steps;
    // The parse tree of the input; only set when the program is valid
    ParseNode root;
    // A description of the syntax error; only set when the program is invalid
    string errorMessage;
    // The partial derivation that led to the error
    DerivationStep[] errorSteps;
    // The index of the input token the error was detected at
    size_t errorToken = size_t.max;
}

/* Splits raw input into the terminal sequence used by the analyzer Commas and semicolons become tokens of their own 
A coordinate such as "a1" is split into the two terminals <x> and <y> */
string[] tokenize(string input)
{
    string spaced = input.replace(",", " , ").replace(";", " ; ");

    string[] tokens;
    foreach (word; spaced.split())
    {
        if (word.length == 2 && word[0] >= 'a' && word[0] <= 'j' && word[1] >= '0' && word[1] <= '9')
        {
            tokens ~= word[0 .. 1];
            tokens ~= word[1 .. 2];
        }
        else
        {
            tokens ~= word;
        }
    }

    return tokens;
}

// Analyzes a program against the grammar of the language
Analysis analyze(string input, Grammar grammar = buildGrammar())
{
    Analysis result;
    result.tokens = tokenize(input);

    auto engine = Engine(grammar, result.tokens);

    auto rootNode = engine.addNode("<graph>", false);
    engine.frontier = [FrontierSymbol("<graph>", false, rootNode)];

    bool matched = false;
    size_t span;

    foreach (candidate; grammar.forLhs("<graph>"))
    {
        if (engine.matchProduction(0, candidate, span))
        {
            matched = true;
            break;
        }
    }

    result.steps = engine.steps;

    if (matched && engine.inputPos == result.tokens.length)
    {
        result.valid = true;
        result.root = engine.buildTree(rootNode);
    }
    else
    {
        if (matched)
            engine.noteError("unexpected text after the end of the program", engine.inputPos);

        result.errorMessage = engine.haveError
            ? engine.errorMessage
            : "the program is not a sentence of the grammar";
        result.errorSteps = engine.errorSteps;
        result.errorToken = engine.errorToken;
    }

    return result;
}

private struct FrontierSymbol
{
    string name;
    bool isTerminal;
    size_t node;
}

// A node in the tree arena, with children stored as indices into the arena
private struct ArenaNode
{
    string symbol;
    bool isTerminal;
    size_t[] children;
}

private struct Engine
{
    Grammar grammar;
    string[] input;

    FrontierSymbol[] frontier;
    size_t inputPos;
    DerivationStep[] steps;
    ArenaNode[] nodes;

    bool haveError;
    string errorMessage;
    size_t errorToken = size_t.max;
    DerivationStep[] errorSteps;
    string errorForm;

    this(Grammar grammar, string[] input)
    {
        this.grammar = grammar;
        this.input = input;
    }

    size_t addNode(string symbol, bool isTerminal)
    {
        nodes ~= ArenaNode(symbol, isTerminal, null);
        return nodes.length - 1;
    }

    string sententialForm() const
    {
        string[] parts;
        foreach (sym; frontier)
            parts ~= sym.name;
        return parts.join(" ");
    }

    void noteError(string message, size_t token)
    {
        if (haveError && token < errorToken)
            return;

        haveError = true;
        errorMessage = message;
        errorToken = token;
        errorSteps = steps.dup;
        errorForm = sententialForm();
    }

    /* Matches the nonterminal at pos with the given production On success it updates the sentential form,
     input position and recorded steps span receives the number of symbols occupied by the expansion in the
      final sentential form On failure it rolls back the state so another production can be tried */
    bool matchProduction(size_t pos, const Production prod, out size_t span)
    {
        span = prod.rhs.length;

        auto savedFrontier = frontier.dup;
        auto savedInputPos = inputPos;
        auto savedSteps = steps.length;
        auto savedNodes = nodes.length;
        auto savedChildren = nodes[frontier[pos].node].children;

        auto expanded = frontier[pos].name;

        size_t[] childNodes;
        foreach (sym; prod.rhs)
            childNodes ~= addNode(sym.name, sym.isTerminal);
        nodes[frontier[pos].node].children = childNodes;

        FrontierSymbol[] replacement;
        foreach (i, sym; prod.rhs)
            replacement ~= FrontierSymbol(sym.name, sym.isTerminal, childNodes[i]);
        frontier = frontier[0 .. pos] ~ replacement ~ frontier[pos + 1 .. $];

        steps ~= DerivationStep(sententialForm(), expanded, prod.toString());

        bool ok = true;
        size_t remaining = prod.rhs.length;
        size_t k = pos;
        size_t occupied = prod.rhs.length;

        while (remaining > 0)
        {
            auto sym = frontier[k];

            if (sym.isTerminal)
            {
                if (inputPos >= input.length)
                {
                    noteError("expected '" ~ sym.name ~ "' but the input ended", inputPos);
                    ok = false;
                    break;
                }

                if (input[inputPos] != sym.name)
                {
                    noteError("expected '" ~ sym.name ~ "' but found '" ~ input[inputPos] ~ "'", inputPos);
                    ok = false;
                    break;
                }

                inputPos++;
                remaining--;
                k++;
            }
            else
            {
                auto candidates = candidatesFor(sym);

                if (candidates.length == 0)
                {
                    noteError(expectedMessage(sym), inputPos);
                    ok = false;
                    break;
                }

                bool matched = false;
                size_t used;

                foreach (candidate; candidates)
                {
                    if (matchProduction(k, candidate, used))
                    {
                        matched = true;
                        break;
                    }
                }

                if (!matched)
                {
                    ok = false;
                    break;
                }

                remaining--;
                occupied += used - 1;
                k += used;
            }
        }

        if (!ok)
        {
            frontier = savedFrontier;
            inputPos = savedInputPos;
            steps.length = savedSteps;
            nodes.length = savedNodes;
            nodes[frontier[pos].node].children = savedChildren;
            return false;
        }

        span = occupied;
        return true;
    }

    /* Returns the productions to try for a nonterminal, most likely first The grammar is unambiguous, 
    so one token of lookahead is enough to choose a production in each case Alternatives are kept so the 
    matcher can backtrack if lookahead is wrong */
    const(Production)[] candidatesFor(const FrontierSymbol sym)
    {
        auto productions = grammar.forLhs(sym.name);

        switch (sym.name)
        {
            case "<x>":
            case "<y>":
            case "<plot>":
            {
                if (inputPos >= input.length)
                    return null;

                foreach (p; productions)
                    if (p.rhs.length > 0 && p.rhs[0].isTerminal && p.rhs[0].name == input[inputPos])
                        return [p];

                return null;
            }

            case "<plot_stmts>":
            {
                if (hasMorePlots())
                    return [productions[0], productions[1]];

                return [productions[1], productions[0]];
            }

            default:
                return productions;
        }
    }

    // True when another plot follows the current one
    bool hasMorePlots() const
    {
        if (inputPos >= input.length)
            return false;

        size_t length;

        switch (input[inputPos])
        {
            case "bar": length = 5; break;
            case "line": length = 6; break;
            case "grid": length = 3; break;
            case "fill": length = 3; break;
            default: return false;
        }

        auto after = inputPos + length;
        return after < input.length && input[after] == ";";
    }

    string expectedMessage(const FrontierSymbol sym) const
    {
        string found = inputPos < input.length ? "'" ~ input[inputPos] ~ "'" : "the end of the input";

        switch (sym.name)
        {
            case "<x>": return "expected a column letter (a-j) but found " ~ found;
            case "<y>": return "expected a height digit (0-9) but found " ~ found;
            case "<plot>": return "expected a command (bar, line, grid or fill) but found " ~ found;
            case "<plot_stmts>": return "expected a plot command but found " ~ found;
            default: return "could not expand " ~ sym.name ~ " at " ~ found;
        }
    }

    ParseNode buildTree(size_t index) const
    {
        ParseNode node;
        node.symbol = nodes[index].symbol;
        node.isTerminal = nodes[index].isTerminal;

        foreach (child; nodes[index].children)
            node.children ~= buildTree(child);

        return node;
    }
}
