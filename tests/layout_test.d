// Unit tests for the layout of the graph
module layout_test;

import layout;
import scene : GridSize;

unittest
{
    // The design of the program keeps the size of its cells
    assert(Layout.compute(860, 640).cell == 50);
}

unittest
{
    // A window that is bigger has bigger cells
    assert(Layout.compute(1075, 800).cell == 62);
}

unittest
{
    // A window that is smaller has smaller cells
    assert(Layout.compute(688, 512).cell == 40);
}

unittest
{
    // A big screen is limited by its height
    assert(Layout.compute(1920, 1080).cell == 84);
}

unittest
{
    // A small window still has cells that can be read
    assert(Layout.compute(400, 300).cell == 23);
    assert(Layout.compute(100, 100).cell == minCell);
}

unittest
{
    // The graph and the legend fit in the window
    int[5] widths = [860, 1075, 688, 1920, 400];
    int[5] heights = [640, 800, 512, 1080, 300];

    foreach (i; 0 .. widths.length)
    {
        auto result = Layout.compute(widths[i], heights[i]);

        assert(result.marginLeft + GridSize * result.cell + result.legendWidth <= widths[i]);
        assert(result.marginTop + GridSize * result.cell + result.marginBottom <= heights[i]);
    }
}

unittest
{
    // The whole layout grows with the window
    auto small = Layout.compute(688, 512);
    auto big = Layout.compute(1075, 800);

    assert(big.cell > small.cell);
    assert(big.marginLeft > small.marginLeft);
    assert(big.marginTop > small.marginTop);
    assert(big.legendWidth > small.legendWidth);
    assert(big.fontTitle > small.fontTitle);
    assert(big.fontAxis > small.fontAxis);
    assert(big.scale > small.scale);
}

unittest
{
    // The point of a column is the gridline at its right edge
    auto result = Layout.compute(860, 640);

    assert(result.pointX(0) == result.marginLeft + result.cell);
    assert(result.pointX(9) == result.graphWidth());
}

unittest
{
    // The point of a row is the gridline at its bottom edge
    auto result = Layout.compute(860, 640);

    assert(result.pointY(0) == result.graphHeight());
    assert(result.pointY(9) == result.graphHeight() - 9 * result.cell);
}

unittest
{
    // A window without a size falls back on the design of the program
    auto result = Layout.compute(0, 0);

    assert(result.cell == 50);
    assert(result.marginLeft == 80);
    assert(result.marginTop == 80);
    assert(result.marginBottom == 60);
    assert(result.legendWidth == 280);
}
