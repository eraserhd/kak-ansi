#include <locale.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>
#include <wctype.h>

wchar_t escape_sequence[1024];
int     escape_sequence_length = 0;

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

        escape_sequence_length = 0;
        return true;
    }
    return false;
}

int main(int argc, char* argv[])
{
    wchar_t ch;

    setlocale(LC_ALL, "en_US.utf8");

    while ((ch = fgetwc(stdin)) != WEOF)
    {
        if (handle_escape_char(ch))
            continue;

        putwchar(ch);
    }

    exit(0);
}
