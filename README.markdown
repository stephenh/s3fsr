
Intro
=====

`s3fsr` is yet another file system interface to S3.

However, `s3fsr` groks the pseudo-directory notation of both the popular `s3sync` library and `S3 Organizer` Firefox plugin. So no `_$folder$` suffixes, no double entries of folders/files, everything should just work.

When creating directories (with `mkdir`), the `s3sync` directory convention is used.

Usage
=====

`ruby s3fsr.rb <bucket-name> <mount-point>`

For example, to mount the bucket `mybucket` to the directory `~/s3`:

1. First make the directory you want to mount against, e.g. `mkdir ~/s3`
2. Run `ruby s3fsr.rb mybucket ~/s3`
3. Watch the output if you want (or use `&` to send it to the background)
4. Use `Ctrl-C` to kill
5. Run `fusermount -u ~/s3` to unmount the directory

Caching
=======

* File content is never cached
* Directory listings are always cached
* Directory listings can be explicitly reset using `touch`, e.g. `touch ~/s3/subdir` 

This gives very good CLI performance, e.g. for quick `ls`/`cd` commands, while ensuring the data itself is always fresh.

Dependencies
============

* [`fusefs`](http://rubyforge.org/projects/fusefs/) (e.g. the `libfusefs-ruby` package in Ubuntu)
* [`aws-s3`](http://amazon.rubyforge.org/)
  * `s3fsr` ships with a patched version `aws-s3` from [Matt Jamieson's repo](http://github.com/mattjamieson/aws-s3) that parses out out the `CommonPrefixes` responses for even better grokking of directories

Install
=======

* Install [FUSE](http://fuse.sourceforge.net/) for your OS
* Install Ruby and [`fusefs`](http://rubyforge.org/projects/fusefs/)
* Clone the `s3fsr` source--I should make a release...

Todo
====

* Unmounting doesn't kill the process, annoying if you want to run it in the background
* Add switch to pass `allow_other` so that other users can use your mount (e.g. if you want `root` to do the mounting on boot)
* Nothing is streamed, so if you have files larger than your available RAM, `s3fsr` won't work
* It would be nice to ship the `aws-s3` fork as its own gem instead of just checking in the source
* Given the recent speedups, timing out the cache every ~5 minutes or so seems reasonable--probably via a command line parameter
* Package `s3fsr` as a gem/something so it can be easily installed/put on the user's path/etc.


