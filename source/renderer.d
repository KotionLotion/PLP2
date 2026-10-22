/* The raylib based renderer of the graph The window shows the 10 x 10 grid of the scene, the labels of the coordinates, the legend of the commands and the program that was drawn Every text that is given to raylib has to end with a zero, because raylib is written in C and reads the texts as C strings.  The labels of the coordinates are kept in a buffer that holds a zero after every character and the other texts are converted with toStringz The size of the window follows the scaling of the display and the layout of the graph follows the size of the window, so that the graph looks the same on every display */
module renderer;

import core.stdc.string : strlen;

import raylib;

import std.conv : to;
import std.math : round;
import std.string : toStringz;

import layout : Layout, designWidth, designHeight;
import scene;
import win32;

// Draws the graph in a window
class Renderer
{
    // The color of a filled area
    private enum FillColor = Color(0, 228, 48, 110);
    private enum FilledLineColor = Color(0, 228, 48, 255);
    private enum FilledBarColor = Color(0, 228, 48, 255);

    // The color of the area of a grid
    private enum GridColor = Color(102, 191, 255, 60);
    // The thickness of a line
    private enum LineThickness = 6.0f;

    // The layout of the graph in the window
    private Layout layout;
    // The labels of the columns and of the rows, every one ends with a zero
    private char[4 * GridSize] axisLabels;

    // Opens the window
    void init(string title)
    {
        /* The program has to know about the scaling of the display before the window is opened */
        win32.enableDpiAwareness();

        // The window can be resized by the user and the graph follows
        SetConfigFlags(ConfigFlags.FLAG_WINDOW_RESIZABLE);

        // Only show warnings and errors from raylib, not the INFO lines
        SetTraceLogLevel(TraceLogLevel.LOG_WARNING);

        InitWindow(designWidth, designHeight, title.toStringz);
        SetTargetFPS(60);

        fillAxisLabels();
        sizeWindow();
        placeWindow();
        relayout();
    }
    // Closes the window
    void close()
    {
        CloseWindow();
    }

    // Draws the whole window
    void draw(const Scene scene, string program, string status)
    {
        BeginDrawing();
        scope (exit) EndDrawing();

        ClearBackground(Colors.RAYWHITE);

        drawTitle(program, status);
        drawLattice();
        drawAxes();
        drawGrids(scene);
        // drawCells(scene);
        drawBars(scene);
        drawFill(scene);
        drawStrokes(scene);
        drawLegend(scene);
    }

    /* Writes a screenshot of the window into the given file The picture is read from the buffer that was shown before the last frame, so the same graph has to be drawn twice before the file is written */
    void screenshot(const Scene scene, string program, string status, string fileName)
    {
        draw(scene, program, status);
        TakeScreenshot(fileName.toStringz);
    }

    // Computes the layout for the size of the window
    void relayout()
    {
        layout = Layout.compute(GetRenderWidth(), GetRenderHeight());
    }

    // True when the user has resized the window
    bool wasResized()
    {
        return IsWindowResized();
    }

    // A line that tells how the window was set up
    string describe()
    {
        void* handle = GetWindowHandle();

        int clientWidth, clientHeight;
        win32.clientArea(handle, clientWidth, clientHeight);

        double scale = win32.windowScale(handle);

        return "The graph window is on " ~ monitorName()
            ~ " with a scaling of " ~ (cast(int) round(scale * 100)).to!string ~ "%"
            ~ ", the area of the drawing is " ~ clientWidth.to!string ~ "x" ~ clientHeight.to!string
            ~ " pixels and one cell of the graph is " ~ layout.cell.to!string ~ " pixels wide.";
    }

    // The name of the monitor the window is on
    private string monitorName()
    {
        const(char)* name = GetMonitorName(GetCurrentMonitor());
        if (name is null)
            return "the monitor";

        size_t length = strlen(name);
        char[] copy = new char[length];
        foreach (i; 0 .. length)
            copy[i] = name[i];

        return cast(string) copy;
    }

    /* Makes the window the size of the design of the program The size of the display is taken into account, so that the graph is the same size on every display.  The size of the window is the size of the area in which the program draws, so the drawing and the window have the same size */
    private void sizeWindow()
    {
        void* handle = GetWindowHandle();
        double scale = win32.windowScale(handle);

        int width = cast(int) round(designWidth * scale);
        int height = cast(int) round(designHeight * scale);

        SetWindowSize(width, height);
    }

    /* Puts the window in the corner of the monitor that is the farthest away from the console The console is usually in the lower left corner, so the window of the graph does not cover the place where the program is typed */
    private void placeWindow()
    {
        int monitor = GetCurrentMonitor();
        int monitorWidth = GetMonitorWidth(monitor);
        int monitorHeight = GetMonitorHeight(monitor);
        int monitorX = cast(int) GetMonitorPosition(monitor).x;
        int monitorY = cast(int) GetMonitorPosition(monitor).y;

        int width, height;
        win32.windowArea(GetWindowHandle(), width, height);

        int gap = 40;
        int x = monitorX + monitorWidth - width - gap;
        int y = monitorY + gap;

        int consoleLeft, consoleTop, consoleRight, consoleBottom;
        if (win32.consoleArea(consoleLeft, consoleTop, consoleRight, consoleBottom))
        {
            int centerX = (consoleLeft + consoleRight) / 2;
            int centerY = (consoleTop + consoleBottom) / 2;

            // The four corners of the monitor
            int[4] cornersX = [monitorX + gap, x, monitorX + gap, x];
            int[4] cornersY = [y, y, monitorY + monitorHeight - height - gap,
                monitorY + monitorHeight - height - gap];

            int best = -1;
            foreach (i; 0 .. 4)
            {
                int distanceX = cornersX[i] - centerX;
                int distanceY = cornersY[i] - centerY;
                int distance = distanceX * distanceX + distanceY * distanceY;

                if (distance > best)
                {
                    best = distance;
                    x = cornersX[i];
                    y = cornersY[i];
                }
            }
        }

        // The window has to stay on the monitor
        if (x + width > monitorX + monitorWidth)
            x = monitorX + monitorWidth - width;
        if (y + height > monitorY + monitorHeight)
            y = monitorY + monitorHeight - height;
        if (x < monitorX)
            x = monitorX;
        if (y < monitorY)
            y = monitorY;

        SetWindowPosition(x, y);
    }

    /* Fills the buffer with the labels of the coordinates Every label ends with a zero, because raylib reads the labels as C strings */
    private void fillAxisLabels()
    {
        foreach (i; 0 .. GridSize)
        {
            // The columns are labelled with the letters a..j
            axisLabels[i * 2] = cast(char)('a' + i);
            axisLabels[i * 2 + 1] = 0;

            // The rows are labelled with the digits 0..9
            axisLabels[2 * GridSize + i * 2] = cast(char)('0' + i);
            axisLabels[2 * GridSize + i * 2 + 1] = 0;
        }
    }

    /* The C string of a label of the coordinates The buffer of the labels holds a zero after every character, so the string ends where the label ends */
    private const(char)* label(int index) const
    {
        return axisLabels[index .. index + 2].ptr;
    }

    // The screen position of the area between neighboring coordinates
    private Point fillAreaPosition(int x, int y) const
    {
        int px = layout.marginLeft + x * layout.cell;
        int bottom = layout.marginTop + GridSize * layout.cell;
        int py = bottom - (y + 1) * layout.cell;
        return Point(px, py);
    }

    // The screen position of a coordinate at the grid intersection
    private Point pointPosition(int x, int y) const
    {
        return Point(layout.pointX(x), layout.pointY(y));
    }

    // Draws a text and cuts it with three dots when it is too long
    private void drawText(string text, int x, int y, int fontSize, Color color, int maxWidth) const
    {
        const(char)* shown = text.toStringz;

        if (MeasureText(shown, fontSize) > maxWidth)
        {
            string shorter = text;

            while (shorter.length > 1 && MeasureText((shorter ~ "...").toStringz, fontSize) > maxWidth)
                shorter = shorter[0 .. $ - 1];

            shown = (shorter ~ "...").toStringz;
        }

        DrawText(shown, x, y, fontSize, color);
    }

    // The title and the program that was drawn
    private void drawTitle(string program, string status) const
    {
        int width = layout.graphWidth() + layout.legendWidth;

        drawText("CMPS3111 Programming Project 2 - Graph Plotting Language",
            layout.marginLeft, layout.titleY, layout.fontTitle, Colors.DARKGRAY, width);
        drawText("Program: " ~ program, layout.marginLeft, layout.programY,
            layout.fontText, Colors.GRAY, width);
        drawText(status, layout.marginLeft, layout.statusY, layout.fontText, Colors.GRAY, width);

        if (program.length == 0)
            drawText("Type the program in the CONSOLE window.", layout.marginLeft,
                layout.graphHeight() + layout.axisGap + layout.fontAxis + layout.axisGap,
                layout.fontNote, Colors.GRAY, width);
    }

    // The light lines of the graph paper
    private void drawLattice() const
    {
        foreach (i; 0 .. GridSize + 1)
        {
            DrawLine(layout.marginLeft + i * layout.cell, layout.marginTop,
                layout.marginLeft + i * layout.cell, layout.graphHeight(), Colors.LIGHTGRAY);
            DrawLine(layout.marginLeft, layout.marginTop + i * layout.cell,
                layout.graphWidth(), layout.marginTop + i * layout.cell, Colors.LIGHTGRAY);
        }
    }

    // The two axes of the grid and the labels of the coordinates
    private void drawAxes() const
    {
        int right = layout.graphWidth();
        int bottom = layout.graphHeight();

        DrawLineEx(Vector2(layout.marginLeft, layout.marginTop),
            Vector2(layout.marginLeft, bottom), 2.0f, Colors.DARKGRAY);
        DrawLineEx(Vector2(layout.marginLeft, bottom), Vector2(right, bottom), 2.0f, Colors.DARKGRAY);

        // The origin is marked with a single 0 where the two axes meet
        {
            const(char)* zero = "0".toStringz;
            int textWidth = MeasureText(zero, layout.fontAxis);
            DrawText(zero, layout.marginLeft - textWidth / 2, bottom + layout.axisGap, layout.fontAxis, Colors.DARKGRAY);
        }

        /* The columns are labelled on the gridlines: a is on the first gridline to the right of the origin, b on the second one and so on */
        foreach (i; 0 .. GridSize)
        {
            const(char)* letter = label(i * 2);
            int textWidth = MeasureText(letter, layout.fontAxis);
            DrawText(letter, layout.pointX(i) - textWidth / 2,
                bottom + layout.axisGap, layout.fontAxis, Colors.DARKGRAY);
        }

        /* The rows are labelled on the gridlines as well: 1 is on the first gridline above the origin.  The 0 is the one at the origin, so it is not drawn again here */
        foreach (i; 1 .. GridSize)
        {
            const(char)* digit = label(2 * GridSize + i * 2);
            int textWidth = MeasureText(digit, layout.fontAxis);
            DrawText(digit, layout.marginLeft - textWidth - layout.axisGap,
                layout.pointY(i) - layout.fontAxis / 2,
                layout.fontAxis, Colors.DARKGRAY);
        }
    }

    // The filled areas between neighboring coordinates
    private void drawCells(const Scene scene) const
    {
        foreach (x; 0 .. GridSize)
        {
            foreach (y; 0 .. GridSize)
            {
                auto position = fillAreaPosition(x, y);
                auto cell = scene.cells[x][y];

                if (cell.filled)
                    // DrawRectangle(position.x + 1, position.y + 1, layout.cell - 2, layout.cell - 2, FillColor);
                    DrawRectangle(position.x, position.y, layout.cell, layout.cell, FillColor);
            }
        }
    }

    // The bars are strokes through their coordinate points
    private void drawBars(const Scene scene) const {
    // {
    //     foreach (x; 0 .. GridSize)
    //     {
    //         foreach (y; 0 .. GridSize)
    //         {
    //             if (!scene.hasKind(x, y, CellKind.bar))
    //                 continue;

    //             bool hasPrevious = y > 0 && scene.hasKind(x, y - 1, CellKind.bar);
    //             bool hasNext = y + 1 < GridSize && scene.hasKind(x, y + 1, CellKind.bar);
    //             auto position = pointPosition(x, y);

    //             if (hasNext)
    //             {
    //                 auto next = pointPosition(x, y + 1);
    //                 Vector2 start = Vector2(position.x, position.y);
    //                 Vector2 end = Vector2(next.x, next.y);
    //                 DrawLineEx(start, end, LineThickness + 2.0f, Colors.DARKBLUE);
    //                 DrawLineEx(start, end, LineThickness, Colors.BLUE);
    //             }
    //             else if (!hasPrevious)
    //             {
    //                 DrawCircleV(Vector2(position.x, position.y),
    //                     (LineThickness + 2.0f) / 2.0f, Colors.DARKBLUE);
    //                 DrawCircleV(Vector2(position.x, position.y),
    //                     LineThickness / 2.0f, Colors.BLUE);
    //             }
    //         }
    //     }
    // }
        foreach (bar; scene.bars){
            auto topLeft = pointPosition(bar.x0, bar.top);
            auto bottomRight = pointPosition(bar.x1, 0);

            int width = bottomRight.x - topLeft.x;
            int height = bottomRight.y - topLeft.y;

            // A bar with a width or a height of 0 has no area
            if (width <= 0 || height <= 0)
               continue;

            // DrawRectangle(topLeft.x, topLeft.y, width, height, Colors.DARKBLUE);

            // if (width > 2 && height > 2)
            //     DrawRectangle(topLeft.x + 1, topLeft.y + 1, width - 2, height - 2, Colors.BLUE);
            Color border = bar.filled ? Colors.DARKGREEN : Colors.DARKBLUE;
            Color body = bar.filled ? FilledBarColor : Colors.BLUE;

            DrawRectangle(topLeft.x, topLeft.y, width, height, border);

            if (width > 2 && height > 2)
                DrawRectangle(topLeft.x + 1, topLeft.y + 1, width - 2, height - 2, body);
        }
    }
    
    // paiont small squares, drawn as runs so that it stays fast (i think idk, im tiored and the indian video is AI translated)
      private void drawFill(const Scene scene) const{
        int left = layout.pointX(0);
        int bottom = layout.pointY(0);
        int width = layout.pointX(GridSize - 1) - layout.pointX(0);
        int rise = layout.pointY(0) - layout.pointY(GridSize - 1);

        foreach (piece; scene.fillRuns){
            int top = bottom - (piece.fy + 1) * rise / FieldSize;
            int low = bottom - piece.fy * rise / FieldSize;
            int x0 = left + piece.x0 * width / FieldSize;
            int x1 = left + piece.x1 * width / FieldSize;

            DrawRectangle(x0, top, x1 - x0, low - top, FillColor);
        }
    }
    

    // The graph paper of the grid commands
    private void drawGrids(const Scene scene) const
    {
        foreach (region; scene.regions)
        {
            auto topLeft = pointPosition(region.x0, region.y1);
            auto bottomRight = pointPosition(region.x1, region.y0);
            int width = bottomRight.x - topLeft.x;
            int height = bottomRight.y - topLeft.y;

            // The area of the grid
            DrawRectangle(topLeft.x, topLeft.y, width, height, GridColor);

            // The lattice of the grid
            foreach (column; region.x0 .. region.x1 + 1)
            {
                auto position = pointPosition(column, region.y0);
                DrawLine(position.x, topLeft.y, position.x, bottomRight.y, Colors.SKYBLUE);
            }

            foreach (row; region.y0 .. region.y1 + 1)
            {
                auto position = pointPosition(region.x0, row);
                DrawLine(topLeft.x, position.y, bottomRight.x, position.y, Colors.SKYBLUE);
            }

            // The border of the grid
            DrawRectangleLines(topLeft.x, topLeft.y, width, height, Colors.BLUE);
        }
    }

    // The lines are drawn as one stroke per command
    private void drawStrokes(const Scene scene) const
    {
        foreach (index, stroke; scene.strokes)
        {
            Color color = scene.strokeFilled[index] ? FilledLineColor : Colors.RED;

            foreach (i; 1 .. stroke.length)
            {
                auto from = pointPosition(stroke[i - 1].x, stroke[i - 1].y);
                auto to = pointPosition(stroke[i].x, stroke[i].y);

                DrawLineEx(Vector2(from.x, from.y), Vector2(to.x, to.y), LineThickness, color);
            }

            // dot on every point of line so end points are markes
            foreach (point; stroke)
            {
                auto position = pointPosition(point.x, point.y);
                DrawCircleV(Vector2(position.x, position.y), LineThickness / 2.0f, color);
            }
        }
    }

    // The legend of the commands on the right side of the window
    private void drawLegend(const Scene scene) const
    {
        int x = layout.graphWidth() + layout.legendPad;
        int y = layout.marginTop;

        drawText("LEGEND", x, y, layout.fontLegend, Colors.DARKGRAY, layout.legendWidth);
        y += layout.legendHeadGap;

        drawLegendEntry(x, y, Colors.BLUE, "bar <x><y>,<y>", "a vertical bar in a column");
        y += layout.legendGap;
        drawLegendEntry(x, y, Colors.RED, "line <x><y>,<x><y>", "a line between two points");
        y += layout.legendGap;
        drawLegendEntry(x, y, GridColor, "grid <x><y>", "graph paper from the origin");
        y += layout.legendGap;
        drawLegendEntry(x, y, FillColor, "fill <x><y>", "fills the area that is not closed");

        y += layout.legendSectionGap;
        drawText("THE GRAPH", x, y, layout.fontLegend, Colors.DARKGRAY, layout.legendWidth);
        y += layout.legendHeadGap;
        drawText("Painted cells: " ~ scene.paintedCells().to!string, x, y,
            layout.fontText, Colors.GRAY, layout.legendWidth);
        y += layout.legendLineGap;
        drawText("Lines drawn: " ~ scene.strokes.length.to!string, x, y,
            layout.fontText, Colors.GRAY, layout.legendWidth);
        y += layout.legendNoteGap;
        drawText("Every program of the session is", x, y, layout.fontNote, Colors.GRAY, layout.legendWidth);
        y += layout.legendLineGap;
        drawText("drawn on the same graph.", x, y, layout.fontNote, Colors.GRAY, layout.legendWidth);
    }

    // One line of the legend
    private void drawLegendEntry(int x, int y, Color color, string title, string description) const
    {
        DrawRectangle(x, y, layout.legendBox, layout.legendBox, color);
        DrawRectangleLines(x, y, layout.legendBox, layout.legendBox, Colors.DARKGRAY);

        int textWidth = layout.legendWidth - layout.legendOffset;

        drawText(title, x + layout.legendOffset, y, layout.fontEntry, Colors.DARKGRAY, textWidth);
        drawText(description, x + layout.legendOffset, y + layout.legendBox * 3 / 4,
            layout.fontDescription, Colors.GRAY, textWidth);
    }
}
