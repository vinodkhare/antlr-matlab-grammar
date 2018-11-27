# MatlabAntlrGrammar
An ANTLR4 grammar for MATLAB

## Antlr Notes
* `*` matches zero or more repetitions
* `+` matches one or more repetitions
* `?` matches zero or one

## Using ANTLR MATLAB Grammar in MATLAB

We need to add ANTLR and generated CLASS files to the MATLAB Java static path. Adding to dynamic path doesn't work. Once everything is added to the path, we can run the ANTLR `TestRig` from the MATLAB command prompt.

```matlab
>> testRig = org.antlr.v4.gui.TestRig({'MATLAB' 'matlab_file' '-tree' 'startup.m'})
>> testRig.process()
(matlab_file (statement (assignment (lvalue (variable paths)) = (expression (cell { (expression_list (expression (lvalue (variable pwd))) , (expression 'D:\Source\BitBucket\vinodkhare\MATLAB-PEP') , (expression 'D:\Source\BitBucket\vinodkhare\MATLAB-Javelin')) }))) ;) (statement (for_statement for 
... more output
```

Since the output above is being generated on `stdout` but Java, we can't capture it into a MATLAB variable. The workaround here is to use the MATLAB [`diary`](https://www.mathworks.com/help/matlab/ref/diary.html) function. This writes the command line output to a text file called `diary` in the current folder.

- Use a minus sign for a bullet
+ Or plus sign
* Or an asterisk

1. Numbered lists are easy
2. Markdown keeps track of
   the numbers for you
7. So this will be item 3.

## Ranges in MATLAB

Ranges in MATLAB can be written in the following forms

* `:` - a simple color indicates the 'all' range.
* `end` - indicates the last element of the array.
* `A` - a single expression `A`
* `A:B` - indicates a range from `A` to `B`, where `A` and `B` are any expression including `end`. Floats are accepted, they are incremented by 1.0. E.g. `2.3:4.5` evaluates to `[2.3000    3.3000    4.3000]`.
* `A:S:B` - indicates a range with a user specified step.