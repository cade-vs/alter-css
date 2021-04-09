
# NAME

ALTER-CSS is CSS preprocessor

# SYNOPSIS

  alter-css  sample.in.css > sample.out.css

# DESCRIPTION

ALTER-CSS provides compact implementation of variables and blocks
to separate static part of a css from the configuration part.

# VARS

Variables are defined with $ followed by varname (alphanumeric) at column 1
(currently no indentation is allowed):

  $var  value
  
Vars can be used (interpolated) anywere in the text:

  background-color: $var
  
Single variable can hold multiple values:

  $body_colors  #FFF  #000
  
which can be used this way:

  body { color: $body_colors.1; background-color: $body_colors.2; }
  
Thre is and $body_color.0 but it is the same as $body_color and represents
the whole value (not splitted values, though splitted values are always
available).

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

# EXAMPLE

There is an example file called "exaple.in.css", which has detailed explanation
of using vars and blocks and small but complex enough example for mixing blocks
and vars.

Example file can be processed this way:

  alter-css  example.in.css > result.css

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade" 

    <cade@bis.bg> <cade@noxrun.com> <cade@cpan.org>

    https://github.com/cade-vs/alter-css

# LICENSE

Distributed under the GPL license, see COPYING file for the full text.

