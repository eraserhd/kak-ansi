#include <locale.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <wctype.h>

#define DEFAULT -1

typedef struct {
    int line;
    int column;
} Coord;

typedef enum {
    BOLD      = 1<<1,
    DIM       = 1<<2,
    ITALIC    = 1<<3,
    UNDERLINE = 1<<4,
    BLINK     = 1<<5,
    REVERSE   = 1<<7,
} Attributes;

typedef struct {
    int foreground;
    int background;
    Attributes attributes;
} Face;

#define RGB_TAG       (1<<25)
#define RGB(r,g,b)    (RGB_TAG|((r)<<16)|((g)<<8)|(b))
#define IS_RGB(color) ((color)&RGB_TAG)

static const char* COLORS[] =
{
    "black",
    "red",
    "green",
    "yellow",
    "blue",
    "magenta",
    "cyan",
    "white",
    "bright-black",
    "bright-red",
    "bright-green",
    "bright-yellow",
    "bright-blue",
    "bright-magenta",
    "bright-cyan",
    "bright-white",
};

static const Face DEFAULT_FACE =
{
    .foreground = DEFAULT,
    .background = DEFAULT,
    .attributes = 0
};

Face current_face =
{
    .foreground = DEFAULT,
    .background = DEFAULT,
    .attributes = 0
};

Coord   current_coord       = { .line = 1, .column = 1 };
Coord   previous_char_coord = { .line = 1, .column = 0 };
Coord   face_start_coord    = { .line = 1, .column = 1 };
bool    in_G1_character_set = false;
wchar_t escape_sequence[1024];
int     escape_sequence_length = 0;

void reset(void)
{
    current_face.foreground = DEFAULT;
    current_face.background = DEFAULT;
    current_face.attributes = 0;
}

bool faces_equal(const Face* a, const Face* b)
{
    return a->foreground == b->foreground && a->background == b->background &&
        a->attributes == b->attributes;
}

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
                return 0;
            ++count;
        }
    }
    return count;
}

char* format_attrs(char* s, int attrs)
{
    char *p = s;
    if (attrs != 0)
    {
        *p++ = '+';
        if (attrs & UNDERLINE) *p++ = 'u';
        if (attrs & REVERSE)   *p++ = 'r';
        if (attrs & BOLD)      *p++ = 'b';
        if (attrs & BLINK)     *p++ = 'B';
        if (attrs & DIM)       *p++ = 'd';
        if (attrs & ITALIC)    *p++ = 'i';
    }
    *p++ = '\0';
    return s;
}

char* format_color(char* s, int color)
{
    if (color == DEFAULT)
        strcpy(s, "default");
    else if (IS_RGB(color))
        sprintf(s, "rgb:%06X", color & ~RGB_TAG);
    else
        strcpy(s, COLORS[color]);
    return s;
}

void format_face(char* s, size_t size, const Face* face)
{
    char fg[64], bg[64], attrs[64];
    if (face->background == DEFAULT)
    {
        snprintf(s, size, "%s%s", 
                 format_color(fg, face->foreground),
                 format_attrs(attrs, face->attributes));
    }
    else
    {
        snprintf(s, size, "%s,%s%s",
                 format_color(fg, face->foreground),
                 format_color(bg, face->background),
                 format_attrs(attrs, face->attributes));
    }
}

void emit_face(Face* face)
{
    char facename[128];
    if (faces_equal(face, &DEFAULT_FACE))
        return;
    if (face_start_coord.line == current_coord.line &&
        face_start_coord.column == current_coord.column)
        return;
    format_face(facename, 127, face);
    fwprintf(stderr, L" %d.%d,%d.%d|%s",
             face_start_coord.line, face_start_coord.column,
             previous_char_coord.line, previous_char_coord.column,
             facename);
}

int parse_extended_color(int* codes, int code_count, int *i)
{
    if (*i >= code_count)
        return DEFAULT;
    switch (codes[(*i)++])
    {
    case 2: /* True color */
        {
            int r, g, b;
            if (*i+3 > code_count) break;
            r = codes[(*i)++];
            g = codes[(*i)++];
            b = codes[(*i)++];
            return RGB(r,g,b);
        }
    case 5: /* 256 color */
        {
            int p;
            if (*i+1 > code_count) break;
            p = codes[(*i)++];
            if (p >= 0 && p <= 15)         /* ANSI colors */
            {
                return p;
            }
            else if (p >= 16 && p <= 231)  /* 6x6x6 color cube */
            {
                static const int LEVELS[] = { 0, 95, 135, 175, 215, 255 };
                int r, g, b;
                r = LEVELS[(p-16)/36%6];
                g = LEVELS[(p-16)/6%6];
                b = LEVELS[(p-16)%6];
                return RGB(r,g,b);
            }
            else if (p >= 232 && p <= 255) /* greyscale */
            {
                int l = 8 + (p - 232)*10;
                return RGB(l,l,l);
            }
        }
    }
    return DEFAULT;
}

void process_ansi_escape(wchar_t* seq)
{
    int codes[512];
    int code_count = parse_codes(seq, codes, sizeof(codes)/sizeof(codes[0]));
    Face previous_face = current_face;

    for (int i = 0; i < code_count;)
    {
        int code = codes[i++];
        switch (code)
        {
        case 0:
            reset();
            break;
        case 1: case 2: case 3: case 4: case 5: case 7:
            current_face.attributes |= (1<<code);
            break;
        case 21: case 23: case 24: case 25: case 27:
            current_face.attributes &= ~(1<<(code%10));
            break;
        case 22:
            current_face.attributes &= ~(BOLD | DIM);
            break;
        case 30: case 31: case 32: case 33: case 34: case 35: case 36: case 37:
            current_face.foreground = code % 10;
            break;
        case 38:
            current_face.foreground = parse_extended_color(codes, code_count, &i);
            break;
        case 39:
            current_face.foreground = DEFAULT;
            break;
        case 40: case 41: case 42: case 43: case 44: case 45: case 46: case 47:
            current_face.background = code % 10;
            break;
        case 48:
            current_face.background = parse_extended_color(codes, code_count, &i);
            break;
        case 49:
            current_face.background = DEFAULT;
            break;
        }
    }
    if (code_count == 0)
        reset();

    if (!faces_equal(&previous_face, &current_face))
    {
        emit_face(&previous_face);
        face_start_coord = current_coord;
    }
}

void process_escape_sequence(wchar_t* seq)
{
    if (wcslen(seq) < 2)
        return;
    if (seq[1] == L'[' && seq[wcslen(seq)-1] == 'm')
        process_ansi_escape(seq);
    if (!wcscmp(seq, L"\x1B(0"))
        in_G1_character_set = true;
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
    if (ch == 0x0e && escape_sequence_length == 0)
    {
        in_G1_character_set = true;
        return true;
    }
    if (ch == 0x0f && escape_sequence_length == 0)
    {
        in_G1_character_set = false;
        return true;
    }
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
    if (ch == L'(' && escape_sequence_length == 1)
    {
        add_escape_char(ch);
        return true;
    }
    if (ch == L'0' && escape_sequence_length == 2 && escape_sequence[1] == L'(')
    {
        add_escape_char(ch);
        process_escape_sequence(escape_sequence);
        escape_sequence_length = 0;
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

wchar_t translate_char(wchar_t ch)
{
    if (in_G1_character_set)
    {
        switch (ch)
        {
        case L'j': return L'┘';
        case L'k': return L'┐';
        case L'l': return L'┌';
        case L'm': return L'└';
        case L'n': return L'┼';
        case L'q': return L'─';
        case L't': return L'├';
        case L'u': return L'┤';
        case L'v': return L'┴';
        case L'w': return L'┬';
        case L'x': return L'│';
        }
    }
    return ch;
}

void display_char(wchar_t ch)
{
    putwchar(translate_char(ch));

    previous_char_coord = current_coord;
    if (ch == L'\n')
    {
        ++current_coord.line;
        current_coord.column = 1;
    }
    else
        ++current_coord.column;
}

int main(int argc, char* argv[])
{
    wchar_t ch;

    setlocale(LC_ALL, "en_US.utf8");

    for (int i = 1; i < argc; i++)
    {
        if (!strcmp(argv[i], "-start"))
        {
            ++i;
            if (i >= argc)
            {
                fwprintf(stderr, L"fail \"kak-ansi-filter: -start needs an argument\"\n");
                exit(1);
            }
            if (sscanf(argv[i], "%d.%d", &current_coord.line, &current_coord.column) != 2)
            {
                fwprintf(stderr, L"fail \"kak-ansi-filter: invalid value for -start\"\n");
                exit(1);
            }
        }
        else
        {
            fwprintf(stderr, L"fail \"kak-ansi-filter: invalid argument '%s'\"\n", argv[i]);
            exit(1);
        }
    }

    fwprintf(stderr, L"set-option -add buffer ansi_color_ranges");
    while ((ch = fgetwc(stdin)) != WEOF)
    {
        if (handle_escape_char(ch))
            continue;
        display_char(ch);
    }
    emit_face(&current_face);
    fwprintf(stderr, L"\n");
    exit(0);
}
