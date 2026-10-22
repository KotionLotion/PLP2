// Unit tests for the graphical model of the plot
module scene_test;

import scene;

// Counts the cells that hold the given kind of plot
private size_t countKind(const Scene scene, CellKind kind)
{
    size_t count = 0;

    foreach (x; 0 .. GridSize)
        foreach (y; 0 .. GridSize)
            if (scene.hasKind(x, y, kind))
                ++count;

    return count;
}

// Counts the filled cells
private size_t countFilled(const Scene scene)
{
    size_t count = 0;

    foreach (x; 0 .. GridSize)
        foreach (y; 0 .. GridSize)
            if (scene.isFilled(x, y))
                ++count;

    return count;
}

unittest
{
    // A new graph is empty
    auto scene = new Scene();
    assert(scene.paintedCells() == 0);
    assert(countKind(scene, CellKind.bar) == 0);
    assert(countKind(scene, CellKind.line) == 0);
    assert(countKind(scene, CellKind.grid) == 0);
    assert(countFilled(scene) == 0);
}

unittest
{
    // A bar covers the rows y1..y2 of its column
    auto scene = new Scene();
    scene.addBar(0, 1, 5);

    foreach (y; 0 .. GridSize)
    {
        bool covered = y >= 1 && y <= 5;
        assert(scene.hasKind(0, y, CellKind.bar) == covered);
    }

    assert(countKind(scene, CellKind.bar) == 5);
}

unittest
{
    // The rows of a bar may be given in any order
    auto scene = new Scene();
    scene.addBar(3, 7, 2);

    foreach (y; 0 .. GridSize)
    {
        bool covered = y >= 2 && y <= 7;
        assert(scene.hasKind(3, y, CellKind.bar) == covered);
    }
}

unittest
{
    // A line that runs over a bar keeps both of them
    auto scene = new Scene();
    scene.addBar(0, 0, 5);
    scene.addLine(0, 2, 4, 2);

    assert(scene.hasKind(0, 2, CellKind.bar));
    assert(scene.hasKind(0, 2, CellKind.line));
    assert(scene.hasKind(4, 2, CellKind.line));
    assert(!scene.hasKind(4, 2, CellKind.bar));
}

unittest
{
    // A line connects the two points and stays inside the graph
    auto scene = new Scene();
    scene.addLine(0, 0, 3, 2);

    assert(scene.hasKind(0, 0, CellKind.line));
    assert(scene.hasKind(3, 2, CellKind.line));
    assert(scene.hasKind(1, 1, CellKind.line));
    assert(scene.strokes.length == 1);
    assert(scene.strokes[0].length == 4);
    assert(scene.strokes[0][0] == Point(0, 0));
    assert(scene.strokes[0][$-1] == Point(3, 2));
}

unittest
{
    // A horizontal line covers one row
    auto scene = new Scene();
    scene.addLine(1, 4, 5, 4);

    foreach (x; 1 .. 6)
        assert(scene.hasKind(x, 4, CellKind.line));

    assert(countKind(scene, CellKind.line) == 5);
}

unittest
{
    // A grid covers the area between the origin and the given cell
    auto scene = new Scene();
    scene.addGrid(2, 5);

    foreach (x; 0 .. GridSize)
    {
        foreach (y; 0 .. GridSize)
        {
            bool inside = x <= 2 && y <= 5;
            assert(scene.hasKind(x, y, CellKind.grid) == inside);
        }
    }

    assert(scene.regions.length == 1);
    assert(scene.regions[0].x1 == 2);
    assert(scene.regions[0].y1 == 5);
}

unittest
{
    // A grid never overwrites a bar
    auto scene = new Scene();
    scene.addBar(1, 0, 3);
    scene.addGrid(2, 2);

    assert(scene.hasKind(1, 2, CellKind.bar));
    assert(scene.hasKind(2, 2, CellKind.grid));
    assert(!scene.hasKind(2, 2, CellKind.bar));
}

unittest
{
    // A fill without anything else covers the whole graph
    auto scene = new Scene();
    scene.addFill(0, 0);

    assert(countFilled(scene) == GridSize * GridSize);
}

unittest
{
    // A bar bounds the fill
    auto scene = new Scene();
    scene.addBar(0, 0, 9);
    scene.addFill(1, 0);

    // The bar covers the whole height, so the fill stays on its side
    foreach (x; 1 .. GridSize)
        foreach (y; 0 .. GridSize)
            assert(scene.isFilled(x, y));

    assert(!scene.isFilled(0, 0));
    assert(countFilled(scene) == GridSize * (GridSize - 1));
}

unittest
{
    // A line that cuts the graph bounds the fill
    auto scene = new Scene();
    scene.addLine(0, 5, 9, 5);
    scene.addFill(0, 0);

    // The fill stays below the line
    foreach (x; 0 .. GridSize)
        foreach (y; 0 .. 5)
            assert(scene.isFilled(x, y));

    foreach (x; 0 .. GridSize)
        foreach (y; 6 .. GridSize)
            assert(!scene.isFilled(x, y));
}

unittest
{
    // A fill on a bar or on a line does nothing
    auto scene = new Scene();
    scene.addBar(2, 2, 4);
    scene.addFill(2, 3);

    assert(countFilled(scene) == 0);
}

unittest
{
    // The lattice of a grid keeps a fill inside the cell it starts in
    auto scene = new Scene();
    scene.addGrid(4, 4);
    scene.addFill(2, 2);

    assert(scene.isFilled(2, 2));
    assert(countFilled(scene) == 1);
}

unittest
{
    // The lattice of a grid stops a fill that comes from the outside
    auto scene = new Scene();
    scene.addGrid(2, 2);
    scene.addFill(5, 5);

    foreach (x; 0 .. 3)
        foreach (y; 0 .. 3)
            assert(!scene.isFilled(x, y));

    assert(scene.isFilled(5, 5));
}

unittest
{
    // The graph of a session keeps every program
    auto scene = new Scene();
    scene.addBar(0, 0, 2);
    scene.addLine(0, 5, 4, 5);

    assert(countKind(scene, CellKind.bar) == 3);
    assert(scene.strokes.length == 1);
    assert(scene.paintedCells() > 0);
}

unittest
{
    // The graph can be emptied again
    auto scene = new Scene();
    scene.addBar(0, 0, 2);
    scene.addLine(0, 5, 4, 5);
    scene.addGrid(3, 3);
    scene.addFill(8, 8);
    scene.clear();

    assert(scene.paintedCells() == 0);
    assert(countKind(scene, CellKind.bar) == 0);
    assert(countKind(scene, CellKind.line) == 0);
    assert(countKind(scene, CellKind.grid) == 0);
    assert(countFilled(scene) == 0);
    assert(scene.strokes.length == 0);
    assert(scene.regions.length == 0);
}
