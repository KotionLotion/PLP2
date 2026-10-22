/* The layout of the graph in the window The layout is a pure function of the size of the window,
so that it can be checked by the unit tests without opening a window and so that the graph fits 
in the window whatever the size of the display is The design of the program is a window of 860 x 640 pixels
with cells of 50 pixels.  Every other size is the design scaled by a factor, so the graph looks the same on
every display */
module layout;

import std.math : round;

import scene : GridSize;

// The width of the design of the window
enum designWidth = 860;
// The height of the design of the window
enum designHeight = 640;
// The size of one cell of the design
enum designCell = 50;
// The smallest cell that can still be read
enum minCell = 10;

// The layout of the graph for a window of a given size
struct Layout
{
    // The size of one cell of the grid
    int cell;
    // The space on the left of the grid for the labels of the rows
    int marginLeft;
    // The space above the grid for the title
    int marginTop;
    // The space below the grid for the labels of the columns
    int marginBottom;
    // The space on the right of the grid for the legend
    int legendWidth;
    // The space between the grid and the legend
    int legendPad;
    // The size of the title of the window
    int fontTitle;
    // The size of the program that was drawn and of the status
    int fontText;
    // The size of the labels of the coordinates
    int fontAxis;
    // The size of the headings of the legend
    int fontLegend;
    // The size of the names of the commands
    int fontEntry;
    // The size of the descriptions of the commands
    int fontDescription;
    // The size of the notes under the legend
    int fontNote;
    // The line of the title of the window
    int titleY;
    // The line of the program that was drawn
    int programY;
    // The line of the status
    int statusY;
    // The space between the grid and the labels of the columns
    int axisGap;
    // The size of the colour box of the legend
    int legendBox;
    // The space between the colour box and the text of the legend
    int legendOffset;
    // The space between two entries of the legend
    int legendGap;
    // The space under a heading of the legend
    int legendHeadGap;
    // The space before the second part of the legend
    int legendSectionGap;
    // The space between two lines of the legend
    int legendLineGap;
    // The space before the notes under the legend
    int legendNoteGap;
    // The factor the design was scaled by
    double scale;

    // The width of the grid of the graph
    int graphWidth() const
    {
        return marginLeft + GridSize * cell;
    }

    // The height of the grid of the graph
    int graphHeight() const
    {
        return marginTop + GridSize * cell;
    }

    /* The x of the point of a column The labels of the columns are on the gridlines, so the point of a column is the gridline at its right edge */
    int pointX(int column) const
    {
        return marginLeft + (column + 1) * cell;
    }

    /* The y of the point of a row The labels of the rows are on the gridlines, so the point of a row is the gridline at its bottom edge */
    int pointY(int row) const
    {
        return graphHeight() - row * cell;
    }

    /* Computes the layout for a window of the given size The size is given in the pixels of the drawing, so that the layout is the same on every display */
    static Layout compute(int width, int height)
    {
        Layout result;

        int w = width > 0 ? width : designWidth;
        int h = height > 0 ? height : designHeight;

        /* The cell is the biggest one that still leaves room for the margins and for the legend.  The division is done with whole numbers, so that the result does not depend on the rounding of the decimals */
        int cell = w * designCell / designWidth;
        int cellOfHeight = h * designCell / designHeight;
        if (cellOfHeight < cell)
            cell = cellOfHeight;
        if (cell < minCell)
            cell = minCell;

        result.cell = cell;
        result.scale = cell / cast(double) designCell;

        result.marginLeft = scaled(result.scale, 80);
        result.marginTop = scaled(result.scale, 80);
        result.marginBottom = scaled(result.scale, 60);
        result.legendWidth = scaled(result.scale, 280);
        result.legendPad = scaled(result.scale, 24);

        result.fontTitle = scaled(result.scale, 20);
        result.fontText = scaled(result.scale, 14);
        result.fontAxis = scaled(result.scale, 16);
        result.fontLegend = scaled(result.scale, 18);
        result.fontEntry = scaled(result.scale, 15);
        result.fontDescription = scaled(result.scale, 12);
        result.fontNote = scaled(result.scale, 13);

        result.titleY = scaled(result.scale, 18);
        result.programY = scaled(result.scale, 46);
        result.statusY = scaled(result.scale, 62);
        result.axisGap = scaled(result.scale, 12);

        result.legendBox = scaled(result.scale, 24);
        result.legendOffset = scaled(result.scale, 34);
        result.legendGap = scaled(result.scale, 44);
        result.legendHeadGap = scaled(result.scale, 30);
        result.legendSectionGap = scaled(result.scale, 60);
        result.legendLineGap = scaled(result.scale, 20);
        result.legendNoteGap = scaled(result.scale, 40);

        return result;
    }
}

// A length of the design at the given scale
private int scaled(double scale, int length)
{
    return cast(int) round(length * scale);
}
