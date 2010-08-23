Rubikon
=======

Rubikon is a simple to use, yet powerful Ruby framework for building
console-based applications.

## Installation

You can install Rubikon using RubyGem. This is the easiest way of installing
and recommended for most users.

    $ gem install rubikon

If you want to use the development code you should clone the Git repository:

    $ git clone git://github.com/koraktor/rubikon.git
    $ cd rubikon
    $ rake install

## Usage

Creating a Rubikon application is as simple as creating a Ruby class:

    require 'rubygems'
    require 'rubikon'

    class MyApplication < Rubikon::Application
    end

If you save this code in a file called `myapp.rb` you can run it using
`ruby myapp.rb`. Or you could even add a *shebang* (`#!/usr/bin/env ruby`) to
the top of the file and make it executable. You would then be able to run it
even more easily by typing `./myapp.rb`.

Now go on and define what your application should do when the user runs it.
This is done using `default`:

    class MyApplication < Rubikon::Application

      default do
        puts 'Hello World!'
      end

    end

If you run this application it will just print `Hello World!`.

You can also add command-line options to your appication using `command`:

    class MyApplication < Rubikon::Application

      command :hello do
        puts 'Hello World!'
      end

    end

This way your application would do nothing when called without options, but it
would print `Hello World!` when called using `ruby myapp.rb hello`. A command
is code that is executed when the application is called with the command's name
as the first argument - just like RubyGem's `install` or Git's `commit`.

Please see the `samples` directory for more in detail sample applications.


**Warning**:

Rubikon is still in an early development stage. If you want to use it be aware
that you will probably run into problems and or restrictions. See the
Contribute section if you want to help making Rubikon better.

## Features

* A simple to use DSL
* Automatic checks for option arguments
* User defined type safety of option arguments
* Built-in methods to capture user input
* Built-in methods to display progress bars and throbbers

## Future plans

* Automatic generation of help screens
* Improved error handling
* Built-in support for configuration files
* Built-in support for colored output

## Requirements

* Linux, MacOS X or Windows
* Ruby 1.8.6 or newer

## Contribute

There are several ways of contributing to Rubikon's development:

* Build apps using it and spread the word.<br />
* Report problems and request features using the [issue tracker][2].
* Write patches yourself to fix bugs and implement new functionality.
* Create a Rubikon fork on [GitHub][1] and start hacking.

## About the name

Rubikon is the German name of the river Rubicone in Italy. It had a historical
relevance in ancient Rome when Julius Caesar crossed that river with his army
and thereby declared war to the Roman senate. The phrase "to cross the Rubicon"
originates from this event.

You may also see Rubikon as a portmanteau word consisting of *"Ruby"* and
*"console"*.

## License

This code is free software; you can redistribute it and/or modify it under the
terms of the new BSD License. A copy of this license can be found in the LICENSE
file.

## Credits

* Sebastian Staudt -- koraktor(at)gmail.com

## See Also

* [API documentation](http://www.rdoc.info/projects/koraktor/rubikon)
* [GitHub project page][1]
* [GitHub issue tracker][2]

 [1]: http://github.com/koraktor/rubikon
 [2]: http://github.com/koraktor/rubikon/issues
