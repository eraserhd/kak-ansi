#include <locale.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>
#include <wctype.h>

#define DEFAULT 9

static const wchar_t* COLORS[] = {
    L"black",
    L"red",
    L"green",
    L"yellow",
    L"blue",
    L"magenta",
    L"cyan",
    L"white",
    L"-",
    L"default",
};

int     line = 1;
int     column = 1;
int     last_line = 1;
int     last_column = 0;
int     foreground = DEFAULT;
int     start_line = 1;
int     start_column = 1;
wchar_t escape_sequence[1024];
int     escape_sequence_length = 0;

int parse_codes(const wchar_t* p, int* codes, int max_codes)
{
    int count = 0;
    for (; *p && count < max_codes; p++)
    {
        if (!iswdigit(p[0]) && iswdigit(p[1]))
        {
            codes[count] = -1;
            swscanf(p + 1, L"%d", &codes[count]);
            if (codes[count] == -1)
                continue;
            ++count;
        }
    }
    return count;
}

void process_ansi_escape(wchar_t* seq)
{
    int codes[512];
    int prev_foreground = foreground;
    int code_count = parse_codes(seq, codes, sizeof(codes)/sizeof(codes[0]));

    for (int i = 0; i < code_count; i++)
    {
        int code = codes[i];
        if (code >= 30 && code <= 39)
        {
            foreground = code % 10;
        }
    }

    if (prev_foreground != foreground && prev_foreground != DEFAULT)
    {
        fwprintf(stderr, L" %d.%d,%d.%d|%ls", start_line, start_column, last_line, last_column, COLORS[prev_foreground]);
        start_line = line;
        start_column = column;
    }
}

void process_escape_sequence(wchar_t* seq)
{
    if (wcslen(seq) < 2)
        return;
    if (seq[1] == L'[' && seq[wcslen(seq)-1] == 'm')
        process_ansi_escape(seq);
}

void add_escape_char(wchar_t ch)
{
    if (escape_sequence_length >= 1020)
        return;
    escape_sequence[escape_sequence_length++] = ch;
    escape_sequence[escape_sequence_length] = L'\0';
}

bool handle_escape_char(wchar_t ch)
{
    if (ch == 0x1b && escape_sequence_length == 0)
    {
        add_escape_char(ch);
        return true;
    }
    if (ch == L'[' && escape_sequence_length == 1)
    {
        add_escape_char(ch);
        return true;
    }
    if ((ch == L';' || iswdigit(ch)) && escape_sequence_length > 1)
    {
        add_escape_char(ch);
        return true;
    }
    if (escape_sequence_length > 1)
    {
        add_escape_char(ch);
        process_escape_sequence(escape_sequence);
        escape_sequence_length = 0;
        return true;
    }
    return false;
}

void display_char(wchar_t ch)
{
    putwchar(ch);
    last_line = line;
    last_column = column;
    if (ch == L'\n')
    {
        ++line;
        column = 1;
    }
    else
        ++column;
}

int main(int argc, char* argv[])
{
    wchar_t ch;

    setlocale(LC_ALL, "en_US.utf8");

    fwprintf(stderr, L"set-option -add buffer ansi_color_ranges");

    while ((ch = fgetwc(stdin)) != WEOF)
    {
        if (handle_escape_char(ch))
            continue;
        display_char(ch);
    }

    fwprintf(stderr, L"\n");
    exit(0);
}
