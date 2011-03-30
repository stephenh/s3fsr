
Intro
=====

`s3fsr` is yet another file system interface to S3.

This means you can mount your S3 buckets as directories (like `~/s3`) and then use `ls/cp/mv` to copy/move directories and files between your S3 buckets and your other file systems.

Most usefully, `s3fsr` understands four popular styles of S3 directory notation:

* `s3sync` library's `etag` marker objects
* `S3 Organizer` plugin's `_$folder$` suffixed marker objects
* AWS Console's `folder/` marker objects
* Plain "common prefix" directories (no marker objects, just inferred by Amazon's S3 API by having children objects, based on `/` as a delimiter)

This means you should be able to browse most any S3 bucket hierarchically without seeing odd names, duplicates entries, or missing directories.

When explicitly creating directories (e.g. with `mkdir`), the AWS Console `folder/` marker directory convention is used.

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
* Install `libopenssl-ruby`
* `gem install s3fsr`

Tips
====

* To avoid indexing daemons from scanning your S3 mount, you might try `chmod og-rx ~/s3`
  * I'm pretty sure this worked for me...feedback appreciated

Disclaimer
==========

s3fsr is very handy, but it's target audience is a developer poking at S3 during their everyday development tasks. Before using it in production for any sort of automation processes, please consider that:

* Ruby's FuseFS is inherently single-threaded (AFAICT), so if one process is saving/loading a file, any other process that accesses the s3fsr-mounted directory will block.
* Ruby's FuseFS has no streaming support (again AFAICT), so all data is passed around in memory as Strings.
* s3fsr itself uses a very naive way of accessing files (explicitly, saving `sub1/sub2/filea.txt` implicitly involves loading the files of `sub1` and files of `sub2`) that is not optimized for the case of only writing new files and not ever reading back the list of existing files.

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
* 1.5 - Fix touching a file that does not yet exist, add dependent gems
* 1.6 - Fix for directory marker files ending with /, e.g. `dir/`
* 1.7 - Fix deletion of AWS Console-style directory marker files, create new directories with AWS Console-style
* 1.8 - Fix marker handling and horrible performance for large, prefix-based directories.
* 1.9 - Fix file/directory names being numbers causing TypeErrors

Todo
====

* Add switch to pass `allow_other` so that other users can use your mount (e.g. if you want `root` to do the mounting on boot)
* Nothing is streamed, so if you have files larger than your available RAM, `s3fsr` won't work
* Given the recent speedups, timing out the cache every ~5 minutes or so seems reasonable--probably via a command line parameter

