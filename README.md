Description
===========

CRNotes is a note taking application similar to [gjots2][1] but with a
different focus and completely web-based.

**CRNotes** consists of two parts:

1. The server is written in **Ruby** and offers a **REST**ful webservice.
2. The client is written in **JavaScript** and runs in the browser.

Features
========

* Multiuser login by using OpenID
* Managing multiple notes
* Editing notes like text file

Usage
=====

To use the service you can either go to
[http://notes.livoris.de/](http://notes.livoris.de/) or
install it on your own server.

Requirements
============

* Ruby 1.8.7 or newer
* RubyGems 1.3.5 or newer
* Sinatra 0.9.6
* Ruby JSON implementation 1.2.0
* Redis 2.2.2
* Ruby-OpenID 2.1.8
* thin 1.2.11
* RSpec 2.3.0 *for running the tests*
* Rake 0.8.7 *for running the tests*
* RCov 0.9.7.1 *for test coverage*
* Reek 1.2.1 *for code style*

Installation
============

The service is implemented with [Sinatra][2] and runs with [thin][3].
The data backend is a [redis][10] database.

Redis
-----

Install a redis database so that it is accessible from the CRNotes application.
Then configure the CRNotes application by copying the example.config.yml to
config.yml and making appropiate adjustments to the config. It is not
recommended to use the same database number for other applications since
it might cause conflicts.

Thin
----

Write a thin.yml file for configuring *thin*:

    ---
        environment: production
        chdir: /path/to/crnotes/
        address: 127.0.0.1
        port: 4567
        pid: /.../thin.pid
        rackup: /path/to/crnotes/config.ru
        log: /.../thin.log
        max_conns: 64
        timeout: 30
        max_persistent_conns: 32
        daemonize: true

Start it either by

    $ thin -C thin.yml -R config.ru start

or by putting the thin.yml file in the /etc/thin directory if thin is
configured as a service.

Acknowledgement
===============

Apart from all the other components, this project is notably inspired by the
simplicity and power of [Sinatra][2], [jQuery][6] and [SproutCore 2.0][7]. The
icons were provided under the [Creative Commons Attribution License][8]
by the [Axialis Team][9].

[1]: http://www.rememberthemilk.com/
[2]: http://www.sinatrarb.com/
[3]: http://code.macournoyer.com/thin/
[6]: http://jquery.com/
[7]: http://sproutcore20.com/
[8]: http://creativecommons.org/licenses/by/2.5/
[9]: http://axialis.com/
[10]: http://redis.io/
