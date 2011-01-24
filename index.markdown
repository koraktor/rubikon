---
layout: default
title:  Home
---
About
=====

Rubikon is a simple to use, yet powerful Ruby framework for building
console-based applications.

Features
========

* A simple to use DSL (domain-specific language)
* Automatic checks for option arguments
* Built-in methods to capture user input
* Built-in methods to display progress bars and throbbers
* Built-in support for configuration files
* Built-in support for colored output
* Automatic generation of application and command help screens
* User defined validation of option arguments
* Application sandboxing

Installation
============

You can install Rubikon using RubyGem. This is the easiest way of installing
and recommended for most users.

{% highlight bash %}
  $ gem install rubikon
{% endhighlight %}

If you want to use the development code you should clone the Git repository:

{% highlight bash %}
  $ git clone git://github.com/koraktor/rubikon.git
  $ cd rubikon
  $ rake install
{% endhighlight %}

Requirements
============

* Any operating system which has a usable console and is supported by a
  compatible Ruby implementation
* Ruby 1.8.6 or newer (see the [wiki][1] for supported Rubies)

Rubikon doesn't have any dependencies. So there's nothing else to worry
about.

Contact
=======

* Twitter: [@rubikonrb][2]
* IRC: #rubikon on freenode.net
* GitHub: [koraktor][3]
* Mailing list: [Google Group][4]

[1]: http://github.com/koraktor/rubikon/wiki/Compatibility
[2]: http://twitter.com/rubikonrb
[3]: http://github.com/koraktor
[4]: http://groups.google.com/group/rubikonrb
