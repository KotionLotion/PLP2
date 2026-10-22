/* The graphical model of the plot The model is a fixed 10 x 10 grid of cells. Columns are addressed by the letters a..j (0..9 from left to right) and rows by the digits 0..9 (0 at the bottom, 9 at the top) The labels of the columns and of the rows are drawn on the gridlines: the letter of a column is on the gridline at its right edge and the digit of a row is on the gridline at its bottom edge.  The origin is a0 and the point a1 is the lower right corner of the cell a1 This module deliberately does not depend on any graphics library so that it can be unit tested without opening a window */
module scene;

import std.math : abs, sqrt;

/* The kind of plot a cell belongs to A cell can hold more than one kind at the same time: a line that runs over a bar keeps both of them */
enum CellKind : uint
{
    // Nothing was drawn on the cell
    empty = 0,
    // Part of a bar
    bar = 1,
    // Part of a line
    line = 2,
    // Part of the area covered by a grid
    grid = 4
}

// The number of columns (a..j) and rows (0..9) of the grid
enum GridSize = 10;

// in order to resolve the fill issue as seen '../screenshots/fille issue.png' each cell will be cut into tiny squares 
//so fill APPEARS to follow a diagonal line ;)
//this is my '3 am, 31 hours of no sleep' solution
enum Detail = 20;

enum FieldSize = 9*Detail;

// One cell of the grid
struct Cell
{
    // What was drawn on the cell
    CellKind kind = CellKind.empty;
    // True when a fill covered the cell
    bool filled = false;
}
// A point of the grid in cell coordinates
struct Point
{
    int x;
    int y;
}

// The area that is covered by a grid command
struct GridRegion
{
    // The first column of the grid
    int x0;
    // The first row of the grid
    int y0;
    // The last column of the grid
    int x1;
    // The last row of the grid
    int y1;
}

struct BarSegment
{
    // int x;
    // int y1;
    // int y2;
    int x0;
    int x1;
    int top;

    //is true when a fill recolors bar
    bool filled = false;
}

// A horizontal run of painted small squares in one row
struct Run{
    int fy;
    int x0;
    int x1;
}

// The state of the graph; every program of a session is drawn on top of it
class Scene
{
    // The cells of the grid, indexed by [column][row]
    Cell[GridSize][GridSize] cells;

    // One entry per line command, holding the points of the drawn stroke
    Point[][] strokes;

    //true when fill COLORS A LINE... 
    bool[] strokeFilled;
    //  1 entry per line the cells the line passes through
    Point[][] strokeCells;

    // One entry per grid command, holding the area it covers
    GridRegion[] regions;

    BarSegment[] bars;

    // a fill cant cross small squares whre a line passes
    bool[FieldSize][FieldSize] wall;

    //small squares inside a bar
    bool[FieldSize][FieldSize] inBar;

    // squares fill painted
    bool[FieldSize][FieldSize] painted;

    // painted runs, so the renderer does nto scan every small square
    Run[] fillRuns;
    
    //small squares that are already part of a run
    bool[FieldSize][FieldSize] counted;

    // Noticed fill was allocating 1MB everytime. Added buffer for flood thas reused
    Point[] pendingBuffer;

    // Removes everything from the graph
    void clear()
    {
        foreach (x; 0 .. GridSize)
            foreach (y; 0 .. GridSize)
                cells[x][y] = Cell.init;

        strokes.length = 0;
        strokeFilled.length = 0;
        strokeCells.length = 0;
        regions.length = 0;
        bars.length = 0;

        foreach (ref column; counted)
            column[] = false;
        fillRuns.length = 0;

        foreach (ref column; wall)
            column[] = false;
        foreach (ref column; inBar)
            column[] = false;
        foreach (ref column; painted)
            column[] = false;
    }

    // True when the given cell is inside the grid
    bool inBounds(int x, int y) const
    {
        return x >= 0 && x < GridSize && y >= 0 && y < GridSize;
    }

    // The kind of the given cell, CellKind.empty outside of the grid
    CellKind kindAt(int x, int y) const
    {
        return inBounds(x, y) ? cells[x][y].kind : CellKind.empty;
    }

    // True when the given cell holds the given kind of plot
    bool hasKind(int x, int y, CellKind kind) const
    {
        return (kindAt(x, y) & kind) != 0;
    }

    // True when the given cell is covered by a fill
    bool isFilled(int x, int y) const
    {
        return inBounds(x, y) && cells[x][y].filled;
    }

    /* Bars, lines and the lattice of a grid are solid: they stop a fill from spreading further */
    bool isSolid(int x, int y) const
    {
        return (kindAt(x, y) & (CellKind.bar | CellKind.line )) != 0;
    }

    bool inField(int x, int y) const{
        return x >= 1 && x < GridSize && y >= 0 && y < GridSize - 1;
    }

    // // Marks every line that passes through the given cell as filled
    // private void recolorLinesAt(int x, int y){
    //     foreach (i, cellsOfLine; strokeCells){
    //         foreach (cell; cellsOfLine){
    //             if (cell.x == x && cell.y == y){
                    
    //                 strokeFilled[i] = true;
    //                 break;
    //             }
    //         }
    //     }
    // }

    // Marks every bar that covers the given cell as filled
    // private void recolorBarsAt(int x, int y){
    //     foreach (ref bar; bars)
    //         if (x > bar.x0 && x <= bar.x1 && y < bar.top)
    //             bar.filled = true;
    // }

    // void addFill(int x, int y){
    //     if (!inField(x, y))
    //         return;

    //     bool onLine = hasKind(x, y, CellKind.line);
    //     bool onBar = hasKind(x, y, CellKind.bar);

    //     if (onLine || onBar){
    //         if (onLine)
    //             recolorLinesAt(x, y);
    //         if (onBar)
    //             recolorBarsAt(x, y);
    //         return;
    //     }

    //     bool[GridSize][GridSize] seen;
    //     Point[] pending;
    //     pending ~= Point(x, y);
    //     seen[x][y] = true;

    //     while (pending.length > 0){
    //         Point current = pending[$ - 1];
    //         pending = pending[0 .. $ - 1];

    //         cells[current.x][current.y].filled = true;

    //         static immutable int[4] dx = [1, -1, 0, 0];
    //         static immutable int[4] dy = [0, 0, 1, -1];

    //         foreach (i; 0 .. 4){
    //             int nx = current.x + dx[i];
    //             int ny = current.y + dy[i];

    //             if (!inField(nx, ny) || seen[nx][ny] || isSolid(nx, ny))
    //                 continue;

    //             seen[nx][ny] = true;
    //             pending ~= Point(nx, ny);
    //         }
    //     }
    // }

    // The number of cells that are covered by something
    size_t paintedCells() const{
        size_t count = 0;
        foreach (column; cells)
            foreach (cell; column)
                if (cell.kind != CellKind.empty || cell.filled)
                    ++count;
        return count;
    }

    // Draws a vertical bar in column x that spans the rows
    void addBar(int x, int top, int width){
        int right = x + width;
        if (right > GridSize - 1)
            right = GridSize - 1;

        bars ~= BarSegment(x, right, top);

        foreach (fx; x * Detail .. right * Detail)
            foreach (fy; 0 .. top * Detail)
                inBar[fx][fy] = true;

        foreach (column; x + 1 .. right + 1)
            foreach (row; 0 .. top){
                if (!inBounds(column, row))
                    continue;

                cells[column][row].kind |= CellKind.bar;
            }
    }

    // Draws a line between the two given points using Bresenham's algorithm
    // void addLine(int x1, int y1, int x2, int y2)
    // {
    //     Point[] points;

    //     int dx = abs(x2 - x1);
    //     int sx = x1 < x2 ? 1 : -1;
    //     int dy = -abs(y2 - y1);
    //     int sy = y1 < y2 ? 1 : -1;
    //     int error = dx + dy;

    //     int x = x1;
    //     int y = y1;

    //     while (true)
    //     {
    //         points ~= Point(x, y);

    //         if (inBounds(x, y))
    //             cells[x][y].kind |= CellKind.line;

    //         if (x == x2 && y == y2)
    //             break;

    //         int doubled = 2 * error;
    //         if (doubled >= dy)
    //         {
    //             error += dy;
    //             x += sx;
    //         }
    //         if (doubled <= dx)
    //         {
    //             error += dx;
    //             y += sy;
    //         }
    //     }

    //     strokes ~= points;
    //     strokeFilled ~= false;
    // }

    // Marks the small squares along a line, 2 x 2 squares thick so that no fill can leak through
    private void rasterizeWall(int x1, int y1, int x2, int y2){
        int dx = abs(x2 - x1);
        int sx = x1 < x2 ? 1 : -1;
        int dy = -abs(y2 - y1);
        int sy = y1 < y2 ? 1 : -1;
        int error = dx + dy;

        int x = x1;
        int y = y1;

        while (true){
            foreach (ax; x - 1 .. x + 1)
                foreach (ay; y - 1 .. y + 1)
                    if (ax >= 0 && ax < FieldSize && ay >= 0 && ay < FieldSize)
                        wall[ax][ay] = true;

            if (x == x2 && y == y2)
                break;

            int doubled = 2 * error;
            if (doubled >= dy){
                error += dy;
                x += sx;
            }
            if (doubled <= dx){
                error += dx;
                y += sy;
            }
        }
    }
    private static Point crossedCell(Point from, Point to){
        if (from.x != to.x && from.y != to.y)
            return Point(from.x > to.x ? from.x : to.x, from.y < to.y ? from.y : to.y);

        if (from.x != to.x)
            return Point(from.x > to.x ? from.x : to.x, from.y);

        return Point(from.x, from.y < to.y ? from.y : to.y);
    }

    // draws line between two given points using BrAlg.
    void addLine(int x1, int y1, int x2, int y2){
        Point[] points;
        Point[] crossed;

        int dx = abs(x2 - x1);
        int sx = x1 < x2 ? 1 : -1;
        int dy = -abs(y2 - y1);
        int sy = y1 < y2 ? 1 : -1;
        int error = dx + dy;

        int x = x1;
        int y = y1;

        while (true)
        {
            Point here = Point(x, y);

            if (points.length > 0)
            {
                Point cell = crossedCell(points[$ - 1], here);
                crossed ~= cell;

                if (inBounds(cell.x, cell.y))
                    cells[cell.x][cell.y].kind |= CellKind.line;
            }

            points ~= here;

            if (x == x2 && y == y2)
                break;

            int doubled = 2 * error;
            if (doubled >= dy)
            {
                error += dy;
                x += sx;
            }
            if (doubled <= dx)
            {
                error += dx;
                y += sy;
            }
        }

        rasterizeWall(x1 * Detail, y1 * Detail, x2 * Detail, y2 * Detail);
        strokes ~= points;
        strokeCells ~= crossed;
        strokeFilled ~= false;
    }

    /* Draws a grid that covers the area between the origin and the given cell The area reaches from the origin (a0) to the given cell, so "grid c5" covers the columns a..c and the rows 0..5 */
    void addGrid(int x, int y)
    {
        GridRegion region;
        region.x0 = 0;
        region.y0 = 0;
        region.x1 = x;
        region.y1 = y;
        regions ~= region;

        foreach (column; 1 .. x + 1)
            foreach (row; 0 .. y)
            {
                if (!inBounds(column, row))
                    continue;

                cells[column][row].kind |= CellKind.grid;
            }
    }

    // Marks every line that passes through the given point as filled
    // private void recolorLinesAt(int x, int y)
    // {
    //     foreach (i, stroke; strokes){
    //         foreach (point; stroke){
    //             if (point.x == x && point.y == y){
    //                 strokeFilled[i] = true;
    //                 break;
    //             }
    //         }
    //     }
    // }

    // How far the middle of a cell is from a line segment, in cells
    private static double distanceToLine(double px, double py, Point a, Point b){
        double dx = b.x - a.x;
        double dy = b.y - a.y;
        double lengthSquared = dx * dx + dy * dy;

        double t = lengthSquared == 0 ? 0 : ((px - a.x) * dx + (py - a.y) * dy) / lengthSquared;
        if (t < 0) t = 0;
        if (t > 1) t = 1;

        double ex = a.x + t * dx - px;
        double ey = a.y + t * dy - py;
        return sqrt(ex * ex + ey * ey);
    }

    private bool recolorLinesAt(int x, int y){
        // The middle of the cell in point coordinates
        double middleX = x - 0.5;
        double middleY = y + 0.5;
        bool found = false;

        foreach (i, stroke; strokes){
            if (distanceToLine(middleX, middleY, stroke[0], stroke[$ - 1]) <= 0.25){
                strokeFilled[i] = true;
                found = true;
            }
        }

        return found;
    }

    // Turns the squares painted by the last fill into runs, scanning only the rows it touched
    private void recordRuns(int lowRow, int highRow){
        foreach (fy; lowRow .. highRow + 1){
            int start = -1;

            foreach (fx; 0 .. FieldSize + 1){
                bool on = fx < FieldSize && painted[fx][fy] && !counted[fx][fy];

                if (on && start < 0)
                    start = fx;

                if (!on && start >= 0){
                    fillRuns ~= Run(fy, start, fx);

                    foreach (k; start .. fx)
                        counted[k][fy] = true;

                    start = -1;
                }
            }
        }
    }

    // Works like the paint bucket: spreads over the small squares of the same kind
    void addFill(int x, int y){
        if (!inField(x, y))
            return;

        if (recolorLinesAt(x, y))
            return;

        int startX = (x - 1) * Detail + Detail / 2;
        int startY = y * Detail + Detail / 2;

        if (wall[startX][startY] || painted[startX][startY])
            return;

        // A fill that starts in a bar stays in the bar, one that starts outside stays outside
        bool startsInBar = inBar[startX][startY];

        // auto pending = new Point[FieldSize * FieldSize];
        // hate this so much, Please end me  -Jesse at 3 am
            if (pendingBuffer.length == 0)
                pendingBuffer.length = FieldSize * FieldSize;

        auto pending = pendingBuffer;
        int lowRow = startY;
        int highRow = startY;

        size_t top = 0;

        pending[top++] = Point(startX, startY);
        painted[startX][startY] = true;

        static immutable int[4] stepX = [1, -1, 0, 0];
        static immutable int[4] stepY = [0, 0, 1, -1];

        while (top > 0){
            Point current = pending[--top];
            if (current.y < lowRow) lowRow = current.y;
            if (current.y > highRow) highRow = current.y;

            // Keeps the "painted cells" counter of the legend right
            cells[current.x / Detail + 1][current.y / Detail].filled = true;

            foreach (i; 0 .. 4){
                int nx = current.x + stepX[i];
                int ny = current.y + stepY[i];

                if (nx < 0 || ny < 0 || nx >= FieldSize || ny >= FieldSize)
                    continue;

                if (painted[nx][ny] || wall[nx][ny] || inBar[nx][ny] != startsInBar)
                    continue;

                painted[nx][ny] = true;
                pending[top++] = Point(nx, ny);
            }
        }
        recordRuns(lowRow, highRow);
    }


    /* Fills the area that is reachable from the given cell The fill spreads over the cells that are not solid, so bars, lines and the lattice of a grid stop it.  The border of the grid stops it as well.  When the fill starts inside the lattice of a grid it stays in that one cell */
    // void addFill(int x, int y){
    //     if (!inBounds(x, y))
    //         return;

    //     // if fill start on line, change color of line
    //     if (hasKind(x, y, CellKind.line)){
    //         recolorLinesAt(x, y);
    //         return;
    //     }

    //     // A fill that starts on a bar does nothing
    //     if (hasKind(x, y, CellKind.bar))
    //         return;

    //     bool[GridSize][GridSize] seen;
    //     Point[] pending;
    //     pending ~= Point(x, y);
    //     seen[x][y] = true;

    //     while (pending.length > 0){
    //         Point current = pending[$ - 1];
    //         pending = pending[0 .. $ - 1];

    //         cells[current.x][current.y].filled = true;

    //         static immutable int[4] dx = [1, -1, 0, 0];
    //         static immutable int[4] dy = [0, 0, 1, -1];

    //         foreach (i; 0 .. 4){
    //             int nx = current.x + dx[i];
    //             int ny = current.y + dy[i];

    //             if (!inBounds(nx, ny) || seen[nx][ny] || isSolid(nx, ny))
    //                 continue;

    //             seen[nx][ny] = true;
    //             pending ~= Point(nx, ny);
    //         }
    //     }
    // }
}
