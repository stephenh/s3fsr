
Intro
=====

`s3fsr` is yet another file system interface to S3.

Most usefully, `s3fsr` groks three popular styles of S3 directory notation:

* `s3sync` library's `etag` marker directories
* `S3 Organizer` plugin's `_$folder$` suffixed marker directories
* "common prefix" directories (no markers, just inferred from having children objects with `/` delimiters)

When explicitly creating directories (e.g. with `mkdir`), the `s3sync` `etag` marker directory convention is used.

Usage
=====

`s3fsr [<bucket-name>] <mount-point>`

For example, to mount the bucket `mybucket` to the directory `~/s3`:

1. `mkdir ~/s3`
2. `s3fsr mybucket ~/s3`
3. `ls ~/s3` -- see all the directories/files inside of `mybucket`

To mount all of your buckets to the directory `~/s3`:

1. `mkdir ~/s3`
2. `s3fsr ~/s3`
3. `ls ~/s3` -- see all of the buckets for your Amazon account

When you're done:

1. Use `Ctrl-C` to kill the ruby process, this will also unmount the directory

`s3fsr` uses the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables, so you need to set them with your Amazon key information.

Install
=======

* Install Ruby for your OS
* Install [FUSE](http://fuse.sourceforge.net/) and [`fusefs`](http://rubyforge.org/projects/fusefs/) for your OS
  * FUSE is very OS-specific, so the Ruby `fusefs` library is not a gem
  * E.g. on Ubuntu, installing the `libfusefs-ruby` package will install `FUSE` and the Ruby `fusefs` library
* `gem sources -a http://gemcutter.org` to add the [Gemcutter](http://gemcutter.org) gem host
* `gem install s3fsr`

Tips
====

* To avoid indexing daemons from scanning your S3 mount, you might try `chmod og-rx ~/s3`
  * I'm pretty sure this worked for me...feedback appreciated

Caching
=======

* File content is never cached (though file size is)
* Directory listings are always cached
* Directory listings can be explicitly reset using `touch`, e.g. `touch ~/s3/subdir` 

This gives very good CLI performance, e.g. for quick `ls`/`cd` commands, while ensuring the data itself is always fresh.

Changelog
=========

* 1.0 - Initial release
* 1.1 - Fix file size to not make extra per-file HEAD requests
* 1.2 - Fix directories with >1000 files
* 1.3 - Killing `s3fsr` now also unmounts the directory
* 1.4 - Fix directories that are only from common prefixes, move to [Gemcutter](http://gemcutter.org)

Todo
====

* Add switch to pass `allow_other` so that other users can use your mount (e.g. if you want `root` to do the mounting on boot)
* Nothing is streamed, so if you have files larger than your available RAM, `s3fsr` won't work
* Given the recent speedups, timing out the cache every ~5 minutes or so seems reasonable--probably via a command line parameter

