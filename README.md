
# NAME

ALTER-CSS is CSS preprocessor

# SYNOPSIS

    alter-css  sample.in.css > sample.out.css

# DESCRIPTION

ALTER-CSS provides compact implementation of variables and blocks
to separate static part of a css from the configuration part.

ALTER-CSS is written in Perl and has no external dependencies outside Perl's
core modules.

ALTER-CSS takes CSS text with defined variables, blocks and file includes and
produce flat CSS file with all variables and blocks values replaced. It also
supports "color bumping" (see below).

# VARS

Variables are defined with $ followed by varname (alphanumeric) at column 1
(currently no indentation is allowed):

    $var  value
  
Vars can be used (interpolated) anywere in the text:

    background-color: $var
  
Single variable can hold multiple values:

    $body_colors  #FFF  #000
  
which can be used this way:

    body 
      { 
      color:            $body_colors.1; 
      background-color: $body_colors.2; 
      }
  
Thre is and $body_color.0 but it is the same as $body_color and represents
the whole value (not splitted values, though splitted values are always
available).

Vars can self-reference:

    $button_colors  #FFF  $3+4  #336699

second item in this var will take value from the third and will bump it 4,
result in $button_colors.2 will be #77AADD.  Vars with name '$digit' are
expanded only at the same line of the var definition and always reference
current items list.

# VARS AND BLOCKS NAMES

Vars and blocks names can include letters, numbers, dash and underscore but 
must start with a letter. ALTER-CSS is case insensitive and does not make 
difference between dashes and underscores:

    "var-NAME"   is the same as   "VAR_name"

Tech note (not visible to users): ALTER-CSS converts internally all names 
to uppercase with underscores.

# COLOR BUMPS

All colors can have scale bumps. Scale bump is a number, which pushes all
values up or down:

    #158+3   will become   #48B
    #FC2-4   will become   #B80
    #FFF+2   will stay     #FFF
    #002-5   will become   #000

Vars, which contain colors can also be bumped, but since minus sign is valid
var name (dash), bumps must be separated with slash "/":

    color: $action-color/+2
    border: solid 1px $action-color/-2
  
Multiple var values can be used as usual:  

    color:            $action-color.1/+2
    border: solid 1px $action-color.3/-2
  
etc.

# BLOCKS

Blocks are multi-line variables. They cannot be interpolated in the text but
can be used separately on a single line and to instruct preprocessor to 
replace them with the multi-line value.

When defined, block names must not be indented (at column 1, same as vars) 
and they must be indented to be used:

    /* must start at column 1 */
    $$color_box_3d
            color: $1;
            background-image: none;
            background-color: #2;
            border-top:    solid 1px $4;
            border-left:   solid 1px $4;
            border-bottom: solid 1px $5;
            border-right:  solid 1px $5;

and then be used as:

    .icon
            {
            cursor:  pointer;
            padding: 0.4em;
            $$color_box_3d   #FFF   #448   #559    #66A   #226
            }
        
Blocks can have arguments, which are replaced upon use. Arguments are numbered,
starting from 1, and are used with "$" inside block value:

    $1 -- first arg
    $2 -- second arg...
  
As vars, blocks also can access the whole argument list at any time with "$0"
(even together with the separated arguments, $0, $1, $5, etc.)

# INCLUDES

CSS files can be included with $$$ and full name of the CSS file. "full name" 
means the required file name with or without path to access a file. This means
file can have no path if it is in the current directory.

    $$$include-file-name.css
    $$$../other.css

# COMMENTS

ALTER-CSS recognizes this comments syntax:
which start with:

single line, inline comments:

    /*$ ... */

multiline:

    /*$ ...
    ...
    ...
    */ 

ALTER-CSS comments will strip text before processing, so ALTER-CSS will not see
any variables or blocks defined or used inside.

PLEASE NOTE: all regular CSS comments are left intact and even will not be 
considered comments by ALTER-CSS. so if any usage of non-defined vars or blocks
will result in processing error!

# PREDEFINED VARS

There are several predefined variables:

    $ALTER_CSS_GEN_WARNING  
        this has value text of 
        "THIS FILE IS GENERATED! PLEASE, DO NOT MODIFY!"
        
    $ALTER_CSS_GEN_TIME
        this has the generation date and time

The puprose of $ALTER_CSS_GEN_WARNING and $ALTER_CSS_GEN_TIME to add aditional
hints in the output file that this file is generated (i.e. modifications may
not have an effect), and when it is generated.

Usual use will be:

    /* $ALTER_CSS_GEN_WARNING -- GENERATED AT $ALTER_CSS_GEN_TIME */

so in the output file will be a comment saying do not modify the file and
time of generation.

# LAZY EVALUATION

All vars' values are used on demand, which means that it is possible to 
reference non-existing-yet var as long as it is inside var or block definition.

See "examples/self.in.css" file:

    $$setup-act-fg-bg-border
            color:            $1;
            background-color: $in;
            border: solid 2px $3;

    $in $bu.2
    $bu #123 #445599 #778899+2

    $asd #f00 $3+3 $in/-2
    $qwe #123 $3+2 $1+2

    color1: $asd.2
    color2: $qwe.2

      $$setup-act-fg-bg-border  $bu

$in references $bu, but it is ok since value was not yet requested, which
happens when color1 value is requested lines below.

Also the setup-act-fg-bg-color block references $in, which is not yet defined,
but it is ok since when used later $in will already have value.

That said, variables defined after usage lines will produce error:

    $in   $bu
    
    color: $in
    
    $bu   #456

will fail with "error: unknown var name [BU] in line [color: $in]"
    
# EXAMPLE

There is an example file called "example.in.css", which has detailed explanation
of using vars and blocks and small but complex enough example for mixing blocks
and vars.

Example file can be processed this way:

    alter-css  example.in.css > result.css

# WHY $$$$s

The reason to choose $, $$, $$$ is that $var is a common script languages sigil
and is well known. $$ means "multiple lines" and $$$ is "even more lines in a 
separate file" :) Initially @ and # are considered but they would clash with 
CSS syntax, and $ is (still) free.

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade" 

          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com

    https://github.com/cade-vs/alter-css

# LICENSE

Distributed under the GPLv2 license, see COPYING file for the full text.

