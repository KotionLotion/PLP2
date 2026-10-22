/* The few things that the program needs from the window system The module hides the details of the platform from the rest of the program: on the systems that are not Windows every function of the module does nothing, so that the program also runs on Linux and on macOS The functions of the Windows API are called with the C calling convention A handle is kept as void* and the result of a function as int, because the types of Windows do not match the types of D */
module win32;

version (Windows)
{
    pragma(lib, "user32");
    // The rectangle of a window
    struct Rect
    {
        int left, top, right, bottom;
    }

    extern (C) nothrow
    {
        void* SetProcessDpiAwarenessContext(void* value);
        int SetProcessDPIAware();
        uint GetDpiForWindow(void* hwnd);
        int GetClientRect(void* hwnd, Rect* rect);
        int GetWindowRect(void* hwnd, Rect* rect);
        void* GetConsoleWindow();
        void* GetForegroundWindow();
        int GetWindowTextA(void* hwnd, char* text, int count);
        uint GetWindowThreadProcessId(void* hwnd, uint* processId);
        uint GetCurrentThreadId();
        int AttachThreadInput(uint from, uint to, int attach);
        int BringWindowToTop(void* hwnd);
        int SetForegroundWindow(void* hwnd);
        int ShowWindow(void* hwnd, int command);
    }
}

// The value of DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
private enum perMonitorAwareV2 = cast(void*) cast(ptrdiff_t) -4;

// The value of SW_RESTORE
private enum swRestore = 9;

/* Tells the system that the program knows how to work with a scaled display Without this, the system scales the window of the program itself and the graph is drawn in a window that is not the size of the drawing */
void enableDpiAwareness()
{
    version (Windows)
    {
        if (SetProcessDpiAwarenessContext(perMonitorAwareV2) is null)
            SetProcessDPIAware();
    }
}

/* The scale of the display the window is on The scale is 1.0 when the display is not scaled and 1.25 when the display is scaled by 125 percent */
double windowScale(void* hwnd)
{
    version (Windows)
    {
        uint dpi = GetDpiForWindow(hwnd);
        if (dpi == 0)
            return 1.0;

        return dpi / 96.0;
    }
    else
        return 1.0;
}

// The size of the area of the window in which the program draws
void clientArea(void* hwnd, out int width, out int height)
{
    version (Windows)
    {
        Rect rect;

        if (GetClientRect(hwnd, &rect))
        {
            width = rect.right - rect.left;
            height = rect.bottom - rect.top;
            return;
        }
    }

    width = 0;
    height = 0;
}

// The size of the whole window, with its frame
void windowArea(void* hwnd, out int width, out int height)
{
    version (Windows)
    {
        Rect rect;

        if (GetWindowRect(hwnd, &rect))
        {
            width = rect.right - rect.left;
            height = rect.bottom - rect.top;
            return;
        }
    }

    width = 0;
    height = 0;
}

/* The rectangle of the console window The result is false when the program has no console of its own */
bool consoleArea(out int left, out int top, out int right, out int bottom)
{
    version (Windows)
    {
        void* console = GetConsoleWindow();
        Rect rect;

        if (console !is null && GetWindowRect(console, &rect))
        {
            left = rect.left;
            top = rect.top;
            right = rect.right;
            bottom = rect.bottom;
            return true;
        }
    }

    left = 0;
    top = 0;
    right = 0;
    bottom = 0;
    return false;
}

/* Gives the keyboard back to the console The window of the graph takes the keyboard when it is opened, so the console has to be brought to the front again.  The window that has the keyboard belongs to another thread, so the two threads are joined before the console is brought to the front The result says whether the console really has the keyboard */
bool focusConsole()
{
    version (Windows)
    {
        void* console = GetConsoleWindow();
        if (console is null)
            return false;

        void* foreground = GetForegroundWindow();
        uint foregroundThread = GetWindowThreadProcessId(foreground, null);
        uint ownThread = GetCurrentThreadId();

        AttachThreadInput(ownThread, foregroundThread, 1);
        scope (exit) AttachThreadInput(ownThread, foregroundThread, 0);

        ShowWindow(console, swRestore);
        BringWindowToTop(console);
        return SetForegroundWindow(console) != 0;
    }
    else
        return false;
}

// The title of the window that has the keyboard
string foregroundTitle()
{
    version (Windows)
    {
        void* hwnd = GetForegroundWindow();
        if (hwnd is null)
            return "";

        char[256] text;
        int count = GetWindowTextA(hwnd, text.ptr, cast(int) text.length);

        if (count <= 0)
            return "";

        return text[0 .. count].idup;
    }
    else
        return "";
}
