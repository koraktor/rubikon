Rubikon
=======

Rubikon is a simple to use, yet powerful Ruby framework for building
console-based applications.
Rubikon aims to provide an easy to write and easy to read domain-specific
language (DSL) to speed up development of command-line applications. With
Rubikon it's a breeze to implement applications with only few options as well
as more complex programs like RubyGems, Homebrew or even Git.

## Installation

You can install Rubikon using RubyGems. This is the easiest way of installing
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

    class MyApplication < Rubikon::Application::Base
    end

If you save this code in a file called `myapp.rb` you can run it using
`ruby myapp.rb`. Or you could even add a *shebang* (`#!/usr/bin/env ruby`) to
the top of the file and make it executable. You would then be able to run it
even more easily by typing `./myapp.rb`.

Now go on and define what your application should do when the user runs it.
This is done using `default`:

    class MyApplication < Rubikon::Application::Base

      default do
        puts 'Hello World!'
      end

    end

If you run this application it will just print `Hello World!`.

You can also add command-line options to your application using `command`:

    class MyApplication < Rubikon::Application::Base

      command :hello do
        puts 'Hello World!'
      end

    end

This way your application would do nothing when called without options, but it
would print `Hello World!` when called using `ruby myapp.rb hello`. A command
is code that is executed when the application is called with the command's name
as the first argument - just like RubyGem's `install` or Git's `commit`.

Another part of Rubikon's DSL are flags and options. Both are parameter types
that change the behaviour of the application. While a flag is a parameter
without arguments, an option may take one or more additional arguments. Typical
examples for flags are `--debug` or `--verbose` (or short `-d` and `-v`).
RubyGem's `--version` is an example for an option that requires additional
arguments.
Flags and options are easily added to your application's commands using
Rubikon's DSL:

    flag :more
    option :name, [:who]
    command :hello do
      puts "Hello #{who}"
    end

Please see the `samples` directory for more in detail sample applications.

**Warning**:

Rubikon is still in an early development stage. If you want to use it be aware
that you will might run into problems and or restrictions. See the Contribute
section if you want to help to make Rubikon better.

## Features

* A simple to use DSL
* Automatic checks for option arguments
* Built-in methods to capture user input
* Built-in methods to display progress bars and throbbers

## Future plans

* User defined type safety of option arguments
* Automatic generation of help screens
* Improved error handling
* Built-in support for configuration files
* Built-in support for colored output

## Requirements

* Linux, MacOS X or Windows
* Ruby 1.8.6 or newer (see the [compatibility page][4] in Rubikon's wiki)

## Contribute

Rubikon is a open-source project. Therefore you are free to help improving it.
There are several ways of contributing to Rubikon's development:

* Build apps using it and spread the word.
* Report problems and request features using the [issue tracker][2].
* Write patches yourself to fix bugs and implement new functionality.
* Create a Rubikon fork on [GitHub][1] and start hacking. Extra points for
  using GitHubs pull requests and feature branches.

## About the name

Rubikon is the German name of the river Rubicone in Italy. It had a historical
relevance in ancient Rome when Julius Caesar crossed that river with his army
and thereby declared war to the Roman senate. The phrase "to cross the Rubicon"
originates from this event.

You may also see Rubikon as a portmanteau word consisting of *"Ruby"* and
*"console"*.

## License

This code is free software; you can redistribute it and/or modify it under the
terms of the new BSD License. A copy of this license can be found in the
LICENSE file.

## Credits

* Sebastian Staudt -- koraktor(at)gmail.com

## See Also

* [Rubikon's homepage][3]
* [API documentation](http://www.rdoc.info/projects/koraktor/rubikon)
* [GitHub project page][1]
* [GitHub issue tracker][2]

Follow Rubikon on Twitter [@rubikonrb](http://twitter.com/rubikonrb).

 [1]: http://github.com/koraktor/rubikon
 [2]: http://github.com/koraktor/rubikon/issues
 [3]: http://koraktor.github.com/rubikon
 [4]: http://github.com/koraktor/rubikon/wiki/Compatibility
