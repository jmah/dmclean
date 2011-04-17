# dmclean

dmclean is a text filter, designed to be used with Objective-C files stored in git (but should work equally well with other languages). Set it as a [gitattributes] filter, and then you can use dmclean comment directives in affected source files. If no directives are given, the filter does nothing.

[gitattributes]: http://www.kernel.org/pub/software/scm/git/docs/gitattributes.html


## Usage

    // <dmclean.strip-whitespace: true>
will cause trailing whitespace to be stripped from all subsequent lines.

    // <dmclean.filter: BLOCK>
*BLOCK* is a line of Ruby code called with the local variable `lines` bound. The output of this will be printed instead of what appears in the source. Lines are processed until an empty line or a new directive is encountered.

For example:

    // <dmclean.filter: lines.sort.uniq>
    #import "file1.h"
    #import "file2.h"
    #import "file3.h"
    
    /* rest of file */

This will ensures the imports are uniqued and sorted as they are checked in. The empty line after the set of `#import` directives is significant; it marks the end of the group of lines to pass through the filter.

If an error is encountered while parsing or running *BLOCK*, the line will be replaced with `// Invalid filter: <dmclean.filter: BLOCK>`, and subsequent runs will ignore it (as the "Invalid filter: " text causes it to not match the above.


## Installation

I recommend storing the script in the repository where it's used. You can use a tag to store the file without having it as part of your working copy, by running this from your target repository:

    TAGNAME=utils/dmclean.rb
    git tag -f $TAGNAME $(git hash-object -w /path/to/dmclean.rb)

Then add it as a filter in your config: (renormalizing on merges helps to reduce conflicts)

    git config filter.dmclean.clean "git show $TAGNAME | ruby - %f"
    git config merge.renormalize true

And then activate it. For Objective-C files:

    echo '*.h diff=objc filter=dmclean' >>.gitattributes
    echo '*.m diff=objc filter=dmclean' >>.gitattributes
    git add .gitattributes


## License

dmclean is under an MIT license. The full text is in the `LICENSE.txt` file.
