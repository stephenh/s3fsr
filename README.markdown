
Intro
=====

`s3fsr` is yet another file system interface to S3.

However, `s3fsr` groks the pseudo-directory notation of both the popular `s3sync` library and `S3 Organizer` Firefox plugin. So no `_$folder$` suffixes, no double entries of folders/files, everything should just work.

When creating directories (with `mkdir`), the `s3sync` directory convention is used.

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

1. Use `Ctrl-C` to kill the ruby process
2. Run `fusermount -u ~/s3` to unmount the directory

Note that `s3fsr` uses the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables, so you need to set them with your Amazon key information.

Install
=======

* Install [FUSE](http://fuse.sourceforge.net/) for your OS
* Install Ruby and [`fusefs`](http://rubyforge.org/projects/fusefs/)
  * `fusefs` probably isn't a gem, e.g. on Ubuntu it is the `libfusefs-ruby` package
* `gem install stephenh-s3fsr` (using the GitHub gem server, e.g. `gem sources -a http://gems.github.com`)

Tips
====

* To avoid indexing daemons from scanning your S3 mount, you might try `chmod og-rx ~/s3` (I think that worked for me...feedback appreciated)

Caching
=======

* File content is never cached
* Directory listings are always cached
* Directory listings can be explicitly reset using `touch`, e.g. `touch ~/s3/subdir` 

This gives very good CLI performance, e.g. for quick `ls`/`cd` commands, while ensuring the data itself is always fresh.

Todo
====

* Unmounting doesn't kill the process, annoying if you want to run it in the background
* Add switch to pass `allow_other` so that other users can use your mount (e.g. if you want `root` to do the mounting on boot)
* Nothing is streamed, so if you have files larger than your available RAM, `s3fsr` won't work
* Given the recent speedups, timing out the cache every ~5 minutes or so seems reasonable--probably via a command line parameter
* File size isn't working for some reason

