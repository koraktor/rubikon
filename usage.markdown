---
layout: default
title:  Usage
---
Usage
=====

Creating a Rubikon application is as simple as creating a Ruby class:

{% highlight ruby %}
  require 'rubygems'
  require 'rubikon'

  class MyApplication < Rubikon::Application::Base
  end
{% endhighlight %}

If you save this code in a file called myapp.rb you can run it using
`ruby myapp.rb`. Or you could even add a shebang (`#!/usr/bin/env ruby`) to the
top of the file and make it executable. You would then be able to run it even
more easily by typing `./myapp.rb`.

Now go on and define what your application should do when the user runs it.
This is done using `default` inside your application class:

{% highlight ruby %}
  default do
    puts 'Hello World!'
  end
{% endhighlight %}

If you run this application it will just print `Hello World!`.

Ok, this is nothing special, but you can also add command-line arguments to
your application using `command` inside your class:

{% highlight ruby %}
  command :hello do
    puts 'Hello World!'
  end
{% endhighlight %}

This way your application would do nothing when called without arguments, but
it would print `Hello World!` when called using `ruby myapp.rb hello`. A
command is code that is executed when the application is called with the
command's name as the first argument &ndash; just like RubyGem's `install` or
Git's `commit`.

Another part of Rubikon's DSL are flags and options. Both are parameter types
that change the behaviour of the application. While a flag is a parameter
without arguments, an option may take one or more additional arguments. Typical
examples for flags are `--debug` or `--verbose` (or short `-d` and `-v`).
RubyGem's `--version` is an example for an option that requires additional
arguments. Flags and options are easily added to your application's commands
using Rubikon's DSL:

{% highlight ruby %}
  flag :more
  option :name, 2
  command :hello do
    # Code for command 'hello'
  end
{% endhighlight %}

See the [Rubikon wiki](http://github.com/koraktor/rubikon/wiki) for further
reference.