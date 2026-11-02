# NAME

alter-css.pl -- ALTER-CSS compact CSS preprocessor

# SYNOPSIS

    alter-css.pl input.in.css > output.css
    alter-css.pl -i . -i /usr/local/decor/web/css theme.in.css > theme.css
    alter-css.pl -q -S input.in.css > output.css
    alter-css.pl -h

# DESCRIPTION

ALTER-CSS provides compact implementation of variables, blocks, file includes
and color bumps, to separate static part of a CSS from the configuration part.

ALTER-CSS takes CSS text with defined variables, blocks and file includes and
produces flat CSS file with all variables and blocks values replaced.

ALTER-CSS is written in Perl and has no external dependencies outside Perl's
core modules.

Input is read from the file given as argument, output is printed to the
standard output. Only one input file is accepted, more files can be added
with includes (see INCLUDES below).

# OPTIONS

    -d        -- increase DEBUG level (can be used multiple times)
    -i path   -- add include path to search for included files
                 (can be used multiple times, if not used, '.' will be added)
    -S        -- do not suppress empty lines in the output
    -q        -- quiet mode, will not report missing vars or blocks
    --        -- end of options
    -h        -- print help text and exit (also: --help, help)

The include path is the next argument after `-i`, it cannot be attached
to the option: `-i path` is correct, `-ipath` is not.

# VARS

Variables are defined with $ followed by var name at column 1 (indentation
is not allowed) and the value, separated by whitespace:

    $var  value

Vars can be used (interpolated) anywhere in the text:

    background-color: $var

Single var can hold multiple values, separated by whitespace, which can be
used separately with ".N" suffix, where N starts from 1. ".0" or no suffix
gives all values:

    $body-colors  #444  #EEE

    body
      {
      color:            $body-colors.1;
      background-color: $body-colors.2;
      /* all values: $body-colors */
      }

will produce:

    body
      {
      color:            #444;
      background-color: #EEE;
      /* all values: #444 #EEE */
      }

Using value number past the last value gives empty string, this is intended
and allows optional trailing values:

    $c  #111  #222
    a { x: url( "$c.3" ); }

will produce:

    a { x: url( "" ); }

Var values can reference other values of the same var with $N, which is
expanded only in the var definition line and always references the current
values list. Color bumps (see COLOR BUMPS below) can be applied to them:

    $button-colors  #FFF  $3+4  #336699

$button-colors.2 will take the third value and bump it by 4, which gives
\#77AADD.

Defining var with name only and no value is an error:

    $empty

will produce:

    error: var [empty] has no value, or is not defined, at [...] in line [$empty]

# VARS EVALUATION ORDER

Vars are evaluated when defined. Var defined from another var keeps the
value the other var had at that moment, and redefining the other var later
does not change it:

    $base   #123
    $link   $base
    $base   #456

    a { color: $link; }
    b { color: $base; }

will produce:

    a { color: #123; }
    b { color: #456; }

This means vars must be defined before they are used, including in other
vars definitions. Using var, which is not defined yet, is an error:

    error: unknown var name [NOPE] at [file.in.css:1] in line [a { color: $nope; }]

With -q option unknown vars are replaced with empty string and no error is
reported.

# VARS AND BLOCKS NAMES

Vars and blocks names can include letters, numbers, dash and underscore.
Var names must start with a letter or underscore, otherwise error is
reported. ALTER-CSS is case insensitive and does not make difference between
dashes and underscores:

    "var-NAME"   is the same as   "VAR_name"

ALTER-CSS converts internally all names to uppercase with underscores, which
is how names are shown in error messages.

# COLOR BUMPS

All hex colors can have scale bumps. Scale bump is a number, which pushes
the color up (lighter) or down (darker):

    #158+3   will become   #48B
    #FC2-4   will become   #B80
    #FFF+2   will stay     #FFF
    #002-5   will become   #000

For 3-digit colors each digit is bumped by N. For 6-digit colors each RGB
channel is bumped by N \* 0x11 and clamped to 00..FF:

    #2173A8+2   will become   #4395CA
    #F8572A-6   will become   #920000

4-digit (#RGBA) and 8-digit (#RRGGBBAA) colors are bumped the same way, but
the alpha part is kept unchanged:

    #2A9FCB59+1   will become   #3BB0DC59
    #F008-1       will become   #E008

Multiple bumps can be applied one after another:

    #158+3-1   will become   #37A

Vars, which contain colors, can also be bumped, but since minus sign is
valid var name character (dash), bumps must be separated with slash "/":

    $action-color  #2173A8  #FFF

    .button       { background-color: $action-color.1;    color: $action-color.2; }
    .button:hover { background-color: $action-color.1/+2; border: solid 1px $action-color.1/-2; }

will produce:

    .button       { background-color: #2173A8;    color: #FFF; }
    .button:hover { background-color: #4395CA; border: solid 1px #005186; }

WARNING: # followed by 3, 4, 6 or 8 hex digits and +N or -N is always
treated as color bump, anywhere in the text. So ID selectors, url(#...)
references or text in regular comments, which look like #bed-2, #face-1 or
url(#add-1), will be changed. Avoid such names made only of hex digits
followed by -N.

# BLOCKS

Blocks are multi-line variables. They cannot be interpolated in the text
but can be used separately on a single line and preprocessor replaces them
with the multi-line value.

Block definition starts at column 1 with $$ and block name, which must be
alone on its line. The block body is the indented lines that follow it and
ends at the first empty or not indented line. To be used, block name must
be indented:

    $$color-box-3d
            color: $1;
            background-color: $2;
            border-top:    solid 1px $3;
            border-bottom: solid 1px $4;

    $icon-colors  #FFF  #448  #66A  #226

    .icon
            {
            cursor: pointer;
            $$color-box-3d  $icon-colors
            }

    .icon-red
            {
            $$color-box-3d  #FFF  #822  #B55  #511
            }

will produce:

    .icon
            {
            cursor: pointer;
            color: #FFF;
            background-color: #448;
            border-top:    solid 1px #66A;
            border-bottom: solid 1px #226;
            }
    .icon-red
            {
            color: #FFF;
            background-color: #822;
            border-top:    solid 1px #B55;
            border-bottom: solid 1px #511;
            }

Blocks can have arguments, which are replaced upon use. Arguments are
numbered, starting from 1, and are used with "$" inside block body:

    $1 -- first arg
    $2 -- second arg...

As vars, blocks also can access the whole argument list with "$0":

    $$all-args
            /* got: $0 */
            color: $1;

    x
            {
            $$all-args  #111  #222  #333
            }

will produce:

    x
            {
            /* got: #111  #222  #333 */
            color: #111;
            }

Vars in the block body are expanded when the block is used, not when it is
defined. Using argument, which is not given, is an error:

    error: referencing out of bounds [2] at [...] in line [  $$blk  #111]

Text after the block name in the definition line is an error, arguments are
given only when block is used:

    error: unexpected text [  #111] after block name at [...] in line [$$blk  #111]

# INCLUDES

Other files can be included with $$$ and file name. The included file is
processed as if its text was in place of the include line:

    $$$include-file-name.css
    $$$../other.css

Included files are searched only in -i paths, in the given order, not in the
directory of the including file. If no -i is given, current directory ('.')
is used. Absolute file names are used as given.

Since the first found file is used, an application can override a file
included by a common (core) template, by putting its own file with the same
name in an include path given before the core one:

    core/main.in.css:     $$$fonts.css
                          body { font: $font; }
    core/fonts.css:       $font  11pt sans
    app/fonts.css:        $font  12pt serif

    cd app; alter-css.pl -i ../core      ../core/main.in.css   # 11pt sans
    cd app; alter-css.pl -i . -i ../core ../core/main.in.css   # 12pt serif

The same file can be included more than once. File, which includes itself,
directly or through other files, is an error:

    error: include loop detected, file [./a.css] is already being included

Includes are expanded when files are loaded, before alter-css comments are
removed. So commented out includes are still included and text on the same
line as the include is dropped. Keep includes alone on their lines and do
not comment them out, remove them instead.

# COMMENTS

ALTER-CSS has own comments, which are removed and not produced in the output.

Single line, inline comments, there can be more than one per line:

    /*$ ... */

Multi-line comments must begin on a line, which starts with /\*$, and end
with a line, which starts with \*/. Begin and end lines are removed too:

    /*$ ...
    ...
    ...
    */

Unterminated multi-line comment is an error.

ALTER-CSS comments are removed before processing, so vars or blocks inside
them are not seen. Regular CSS comments are left intact and are processed
as any other text, so vars inside them are expanded and using undefined var
in a regular comment is an error:

    /*$ this alter-css comment is removed */
    $c  #123
    /* this regular CSS comment is kept, vars in it are expanded too: $c */
    a { color: $c; } /*$ removed */ /*$ removed too */

will produce:

    /* this regular CSS comment is kept, vars in it are expanded too: #123 */
    a { color: #123; }

# RESERVED $ SIGN

$ is reserved for alter-css vars, blocks, refs and includes. Literal $
cannot be used in the input. $ was chosen because it is not used in CSS.

# PREDEFINED VARS

There are several predefined variables:

    $ALTER_CSS_GEN_WARNING
        has value "THIS FILE IS GENERATED! PLEASE, DO NOT MODIFY!"

    $ALTER_CSS_GEN_TIME
        has the generation date and time

The purpose of $ALTER\_CSS\_GEN\_WARNING and $ALTER\_CSS\_GEN\_TIME is to add
hints in the output file that it is generated (i.e. modifications may be
lost), and when it is generated. Usual use is:

    /* $ALTER_CSS_GEN_WARNING -- GENERATED AT $ALTER_CSS_GEN_TIME */

which will produce:

    /* THIS FILE IS GENERATED! PLEASE, DO NOT MODIFY! -- GENERATED AT Mon Nov  2 11:30:46 2026 */

# OUTPUT AND ERRORS

Empty lines are not produced in the output, unless -S option is given.

Output is printed only when the whole input is processed without errors.
On error, nothing is printed to the standard output, error message is
printed to the standard error, and exit code is not zero. Error messages
show the file name and line number, where the error is found:

    error: unknown var name [NOPE] at [./theme.in.css:12] in line [a { color: $nope; }]

Note that shell redirection empties the output file before alter-css is
started, so on error the output file will be empty. To keep the previous
output file on errors, use temporary file:

    alter-css.pl theme.in.css > theme.css.tmp && mv theme.css.tmp theme.css

# EXAMPLE

There is an example file called "example/example.in.css", which has detailed
explanation of using vars and blocks and small but complex enough example
for mixing blocks and vars. It can be processed this way:

    cd example
    alter-css.pl example.in.css > result.css

# WHY $$$s

The reason to choose $, $$, $$$ is that $var is a common script languages
sigil and is well known. $$ means "multiple lines" and $$$ is "even more
lines in a separate file" :) Initially @ and # were considered but they
would clash with CSS syntax, and $ is (still) free.

# AUTHORS

    (c) Vladi Belperchinov-Shabanski "Cade" 2021-2026
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
        http://cade.noxrun.com
        https://github.com/cade-vs/alter-css

# LICENSE

DISTRIBUTED UNDER GNU GPLv2. FOR FULL TEXT SEE ENCLOSED 'COPYING' FILE.

# FEEDBACK

For any questions, problems, notes, contact me at:

    <cade@noxrun.com>

# VERSION

    1.6
