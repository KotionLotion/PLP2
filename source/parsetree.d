// The parse tree produced by the analyzer and the helpers used to walk it
module parsetree;

import std.array : array, join;
import std.algorithm : filter;

// A node of a parse tree
struct ParseNode
{
    // The symbol of the node, e.g. "&lt;graph&gt;" or "bar"
    string symbol;
    // True when the node is a terminal (a literal of the input)
    bool isTerminal;
    // The children of the node
    ParseNode[] children;

    // Renders the tree as an indented ASCII drawing
    string toString() const
    {
        string[] lines;
        renderLines(this, "", true, lines);
        return lines.join("\n");
    }
}

/* Renders one node and its subtree; a free function on purpose so that the recursion always walks into the child that was passed in */
private void renderLines(const ParseNode node, string prefix, bool isLast, ref string[] lines)
{
    lines ~= prefix ~ (isLast ? "`-- " : "|-- ") ~ node.symbol;

    string childPrefix = prefix ~ (isLast ? "    " : "|   ");
    foreach (i, child; node.children)
        renderLines(child, childPrefix, i == node.children.length - 1, lines);
}

// Returns the terminal symbols of a subtree, from left to right
string[] leaves(const ParseNode node)
{
    if (node.isTerminal)
        return [node.symbol];

    string[] result;
    foreach (child; node.children)
        result ~= leaves(child);
    return result;
}

// Returns the `&lt;plot&gt;` subtrees of a parse tree, in source order
const(ParseNode)[] plotsOf(const ParseNode node)
{
    const(ParseNode)[] result;
    collectPlots(node, result);
    return result;
}

private void collectPlots(const ParseNode node, ref const(ParseNode)[] result)
{
    if (node.symbol == "<plot>")
    {
        result ~= node;
        return;
    }

    foreach (child; node.children)
        collectPlots(child, result);
}
