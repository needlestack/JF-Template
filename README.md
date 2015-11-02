# NAME

JF::Template - High Performance Text Templating in Perl

# SYNOPSIS

    use JF::Template;
    my $t = JF::Template->new;
    $t->set_value( foo => 1 );
    print $t->parse_file( "template.html" );

# DESCRIPTION

JF::Template allows you to cleanly separate your text output -- in particular
HTML -- from your code. It is primarily used to generate HTML pages in a server
environment, but it works equally well for any time you want to plug data into
some type of text-based template.

The module is written entirely in perl and has no dependancies. A lot of work
went into optimization, so it is very fast. It has been used on prominent
websites that receieved hundreds of hits per second without becoming a
bottleneck.

## USAGE

Here's an example of a minimal HTML5 template:

    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <title><% echo $page_title %></title>
      </head>
      <body>
        <h1><% echo $page_title %></h1>
        <% if $show_sample_text %>
            <p>This is a sample page.</p>
        <% else %>
            <p>This space intentionally left blank.</p>
        <% endif %>
      </body>
    </html>

Let's say we save that file as template.html. Here is an example of perl code
that would render the template:

    use JF::Template;

    my $t = JF::Template->new;

    $t->set_value({
        page_title => "Hello World",
        show_sample_text => 1,
    });

    print $t->parse_file( "template.html" );

And here is what would be printed:

    <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>Hello World</title>
      </head>
      <body>
        <h1>Hello World</h1>
            <p>This is a sample page.</p>
      </body>
    </html>

There's more functionality, but that's the starting point. Read on for the
details.

## THE DETAILS

There are two sides to working with JF::Template - the templating langauge, and
the perl code. We will cover each separately.

### Templating Tags

Tags are defined with an opening "<%" and a closing "%>". Within the tag is the
command and the arguments. Tags are not sensitive to spaces, but a given tag
must appear on one line - newlines are not allowed between the "<%" and "%>",
and will generate a warning as well as not rendering as you expected.

- <% echo $var %>

    This tag echos a variable that you've set. You can set variables either with
    the $t->set\_var("value") call (described below) or with a
    <% set "var", "value" %> tag in the template itself.

- <% if $var %> ... <% endif %>

    This tag set will show its contents if $var evaluates to true (using perl's
    definition of truth). You can also use logical constructs, for example:

            <% if !$foo %> ... <% endif %>
            <% if $foo && ($bar || $baz) %> ... <% endif %>

- <% elsif $var %> and <% else %>

    These tags can be used, as expected, within an <% if %> tag, for example:

            <% if $foo %>
                ...
            <% elsif $bar %>
                ...
            <% else %>
                ...
            <% endif %>

    You can nest <% if %> constructs arbitrarily within any section, just like
    regular perl code.

- <% loop "loopname" %> ... <% endloop %>

    This tag set will repeat its contents as dictated by the perl code, using the
    $t->get\_loop("loopname") function described below. You can nest loops to
    arbitrary depth.

- <% set "varname", "value" %>

    This tag will set a variable for use in <% echo %> and <% if %> tags. You set
    it without the leading $, but when you use it, you will use the leading $.
    Normally values are set from the perl side, but sometimes it's nice to be able
    to set it in the template. The value in the template will override values set
    in the perl code.

- <% include "filename.html" %>
- <% include $filename %>
- <% include $filename ".html" %>

    This tag will include the contents of an external file directly into the
    current template. The path is determined from the path of the current template.
    The argument can be a variable, a literal strings, or any number of variables
    and literal strings, which will be concatenated.

- <% comment %> ... <% endcomment %>

    This tag set will remove all its contents from the rendered page. Text and tags
    inside will be completely ignored. You can nest comments without breaking them,
    unlike with HTML.

### Perl Methods

- my $t = JF::Template->new();

    Creates a new template object. Everything you do on the perl side will take
    place through this object. This module does not export any functions.

- $t->set\_value( foo => 1 );
- $t->set\_value({ foo => 1, bar => 2 });

    These functions will set a value for use in tags like <% echo $foo %> and
    <% if $bar %> ... <% endif %> in the template.

- my $loop = $t->get\_loop("loopname");

    This function instructs the template to do one iteration of a loop. You pass it
    the name of the loop, matching the name in the template, and it returns a loop
    iteration - which is really just a template object scoped to the loop.

    This is the most complex part of the templating system, so an example is in
    order. Here's a template fragment with a loop:

        Here are some friends:
        <ul>
        <% loop "friends" %>
            <li> <% echo $name %>
        <% endloop %>
        </ul>

    Here is the perl you would use to fill it out:

        foreach my $name (qw( Aki Eric Lisa Kris )) {
            my $loop = $t->get_loop("friends");
            $loop->set_value( name => $name );
        }

    And here is the resulting output:

        Here are some friends:
        <ul>
            <li> Aki
            <li> Eric
            <li> Lisa
            <li> Kris
        </ul>

    The important thing to note is that when setting values for a loop, you set it
    by calling set\_value() on the object returned by get\_loop(), not the original
    template object.

    You can nest loops too, just be sure that you call get\_loop() on the outer loop
    object rather than the template to get at your inner loop. You can then call
    set\_value() on the inner loop object.

- print $t->parse\_file("template.html");

    When you've finished setting values and getting loops, you call this method to
    render your data into the template and return the result. It's just a string,
    which you can print directly, or store for later.

    This function looks for the file in the "current directory". From the command
    line this is usually obvious, but from a webserver it might be something like
    the root of the filesystem. See SECURITY below.

- $t->set\_dir("my/directory");

    Use this to indicate the directory that contains your templates. Strictly
    speaking, this isn't necessary, since you can pass in the full path name to
    parse\_file(), but this makes a nice separation of paths (more of a configure
    thing) and filenames (more of a script thing). It's easy to set the directory
    in a wrapper module (along with other site-wide values) and grab your
    JF::Template object through that so individual scripts don't have to worry
    about it.

    You may include the trailing slash, but it's not necessary.

### Error Reporting

All templating errors will be reported as warnings, which will appear on stderr
or webserver error logs. Errors will include filenames and line numbers. 

The only fatal error a user of this module can trigger is providing a template
file that doesn't exist or can't be opened. For all other errors, the module
will do its best to proceed after reporting the error.

### Performance

JF::Template has been designed to be as efficient as possible considering its
pure-perl implementation.

When first optimizing back in 2003, I did some benchmarks on a laptop. A G4 @
1.33Mhz was able to do 150 "normal sized" templates per second:

    7 secs ( 6.50 usr +  0.10 sys =  6.60 CPU) @ 151.52/s (n=1000)

It is efficient with memory and has no detectable leaks:

                    #MREGS  RPRVT  RSHRD  RSIZE  VSIZE

     500 reps           22  1.13M   404K  1.39M  26.8M
    1000 reps           22  1.13M   404K  1.39M  26.8M
    2000 reps           22  1.13M   404K  1.39M  26.8M

The code uses a smart caching mechanism that retains all the template parsing
work between calls, so all calls after the first call are even faster. This is
ideal for use under mod\_perl as the same templates are likely to be parsed many
times over the life of a child process. The system is smart enough to pick up
new files when they change.

# EXPORT

None.

# DEPENDENCIES

None.

# COMPATIBILITY

This module was inspired by Text::Tmpl in CPAN. At the time I wanted to
add some features and fix some bugs, but I didn't know enough C to do so.
So I wrote this module as a somewhat compatible replacement. The main
non-compatible differences are as follows:

- Tag delimiters are <% and %> instead of &lt;!--# and -->
- get\_loop() replaces loop\_iteration(); there is no fetch\_loop\_iteration()
- The extesibility features are not present: there is no set\_delimiters(),
register\_simple(), register\_pair(), alias\_simple(), alias\_pair(), remove\_simple(),
or remove\_pair().
- The following methods are also not supported: set\_debug(), set\_strip(),
and parse\_string()

This may seem like a significant amount of lost functionality, but in practice
I've found that these are not necessary with the feature set of this module,
namely more advanced logic and flow control, and more verbose error reporting.

Also, excess whitespace stripping is on by default and is smart enough to
give predictable results.

In most cases, one should be able to migrate a codebase without with
a few perl regexes and none too much pain.

# SECURITY

It's worth mentioning that JF::Template will have access to display whatever
files the webserver has permission to read. This means that on some systems
a malicious coder or template writer could call parse\_file() or <% include %>
on something sensitive like /etc/passwd and it would be visible via HTTP.

As always, be careful who is writing your code (and templates).

# AUTHOR

Jonathan Field - &lt;jfield@gmail.com>

Based on designs and concepts learned from Neil Mix and David Lowe.
Dave Bailey wrote the (currently not documented) export\_\*() functions.

# COPYRIGHT AND LICENSE

The MIT LIcense

Copyright (C) 2000, 2003, 2006, 2015 by Jonathan Field

The MIT License (MIT)

Copyright (c) &lt;year> &lt;copyright holders>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
