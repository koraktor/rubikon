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

  class MyApplication < Rubikon::Application
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

Ok, this is nothing special, but you can also add command-line options to your
appication using `action` inside your class:

{% highlight ruby %}
  action 'hello' do
    puts 'Hello World!'
  end
{% endhighlight %}

This way your application would do nothing when called without options, but it
would print `Hello World!` when called using e.g. `ruby myapp.rb --hello`.
Please note that Rubikon will add dashes to options by default. If you don't
like this behaviour and want options like RubyGem's `install` or `update` just use
the following inside your application class:

{% highlight ruby %}
  set :dashed_options, false
{% endhighlight %}

Please see the [`samples`][1] directory for more in detail sample applications.

 [1]: http://github.com/koraktor/rubikon/tree/master/samples/
