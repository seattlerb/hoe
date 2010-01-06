= Hoe

* http://rubyforge.org/projects/seattlerb/
* http://seattlerb.rubyforge.org/hoe/
* http://seattlerb.rubyforge.org/hoe/Hoe.pdf
* http://github.com/jbarnette/hoe-plugin-examples

== DESCRIPTION:

Hoe is a rake/rubygems helper for project Rakefiles. It helps you
manage and maintain, and release your project and includes a dynamic
plug-in system allowing for easy extensibility. Hoe ships with
plug-ins for all your usual project tasks including rdoc generation,
testing, packaging, and deployment.

See class rdoc for help. Hint: `ri Hoe` or any of the plugins listed
below.

For extra goodness, see: http://seattlerb.rubyforge.org/hoe/Hoe.pdf

== FEATURES/PROBLEMS:

* Includes a dynamic plug-in system allowing for easy extensibility.
* Auto-intuits changes, description, summary, and version.
* Uses a manifest for safe and secure deployment.
* Provides 'sow' for quick project directory creation.
* Sow uses a simple ERB templating system allowing you to capture your
  project patterns.

== SYNOPSIS:

  % sow [group] project

(you can edit a project template in ~/.hoe_template after running sow
for the first time)

or:

  require 'hoe'
  
  Hoe.spec projectname do
    # ... project specific data ...
  end

  # ... project specific tasks ...

== Deployment, the DRY way

Hoe focuses on keeping everything in its place in a useful form and
intelligently extracting what it needs. As a result, there are no
extra YAML files, config directories, ruby files, or any other
artifacts in your release that you wouldn't already have.

=== Structure Overview

  project_dir/
    History.txt
    Manifest.txt
    README.txt
    Rakefile
    bin/...
    lib/...
    test/...

=== README.txt

Most projects have a readme file of some kind that describes the
project. Hoe projects are no different, but we take them one step
further. The readme file points the reader towards all the information
they need to know to get started including a description, relevant
urls, code synopsis, license, etc. Hoe knows how to read a basic rdoc
formatted file to pull out the description (and summary by extension),
urls, and extra paragraphs of info you may want to provide in
news/blog posts.

=== History.txt

Every project should have a document describing changes over time. Hoe
can read this file (also in rdoc) and include the latest changes in
your announcements.

=== Manifest.txt

<em><strong>manifest [noun]</strong> a document giving comprehensive
details of a ship and its cargo and other contents, passengers, and
crew for the use of customs officers.</em>

Every project should know what it is shipping. This is done via an
explicit list of everything that goes out in a release. Hoe uses this
during packaging so that nothing embarrassing is picked up.
          
Imagine, you're a customs inspector at the Los Angeles Port, the
world's largest import/export port. A large ship filled to the brim
pulls up to the pier ready for inspection. You walk up to the captain
and his crew and ask "what is the contents of this fine ship today"
and the captain answers "oh... whatever is inside". The mind boggles.
There is no way in the world that a professionally run ship would ever
run this way and there is no way that you should either.

Professional software releases know _exactly_ what is in them, amateur
releases _do not_. "Write better globs" is the response I often hear.
I consider myself and the people I work with to be rather smart people
and if we get them wrong, chances are you will too. How many times
have you peered under the covers and seen .DS_Store, emacs backup~
files, vim vm files and other files completely unrelated to the
package? I have far more times than I'd like.

=== VERSION

Releases have versions and I've found it best for the version to be
part of the code. You can use this during runtime in a multitude of
ways. Hoe finds your version and uses it automatically during
packaging.

=== Releasing in 1 easy step
      
  % rake release VERSION=x.y.z
      
That really is all there is to it. Behind the scenes it:

* Branches the release in our perforce server. (via hoe-seattlerb plugin)
* Performs sanity checks to ensure the release has integrity. (hoe-seattlerb)
* Packages into gem and tarballs.
* Uploads the packages to rubyforge.
* Posts news of the release to rubyforge and my blog.
* Sends an announcement email. (hoe-seattlerb)
      
That `VERSION=x.y.z` is there as a last-chance sanity check that you
know what you're releasing. You'd be surprised how blurry eyed/brained
you get at 3AM. This check helps a lot more than it should.

== Plugins:

Hoe has a flexible plugin system that allows you to activate and
deactivate what tasks are available on a given project. Hoe has been
broken up into plugins partially to make maintenance easier but also
to make it easier to turn off or replace code you don't want.

* To activate a plugin, add the following to your Rakefile above your
  Hoe spec:

    Hoe.plugin :plugin_name

* To deactivate a plugin, remove its name from the plugins array:

    Hoe.plugins.delete :plugin_name

Again, this must be done before the Hoe spec, or it won't be useful.

=== Plug-ins Provided:

* Hoe::Clean
* Hoe::Debug
* Hoe::Deps
* Hoe::Flay
* Hoe::Flog
* Hoe::Gemcutter
* Hoe::Inline
* Hoe::Newb
* Hoe::Package
* Hoe::Publish
* Hoe::RCov
* Hoe::RubyForge
* Hoe::Signing
* Hoe::Test

=== Known 3rd-Party Plugins:

* Hoe::Seattlerb - minitest support, email announcements & perforce branching/validation on release.
* Hoe::Git       - git tagging on release, changelogs, and manifest creation.
* Hoe::Doofus    - release checklist.
* Hoe::Debugging - for extensions, run your tests with GDB and Valgrind

=== Writing Plugins:

A plugin can be as simple as:
      
    module Hoe::Thingy
      attr_accessor :thingy

      def initialize_thingy # optional
        self.thingy = 42
      end

      def define_thingy_tasks
        task :thingy do
          puts thingy
        end
      end
    end
      
Not terribly useful, but you get the idea. This example exercises both
plugin methods (initialize_#{plugin} and define_#{plugin}_tasks and
adds an accessor method to the Hoe instance.

=== How Plugins Work

Hoe plugins are made to be as simple as possible, but no simpler. They are
modules defined in the `Hoe` namespace and have only one required method
(`define_#{plugin}_tasks`) and one optional method (`initialize_#{plugin}`).
Plugins can also define their own methods and they'll be available as instance
methods to your hoe-spec. Plugins have 4 simple phases:

==== Loading

When Hoe is loaded the last thing it does is to ask rubygems for all of its
plugins. Plugins are found by finding all files matching "hoe/*.rb" via
installed gems or `$LOAD_PATH`. All found files are then loaded.

==== Activation

All of the plugins that ship with hoe are activated by default. This is
because they're providing the same functionality that the previous Hoe was and
without them, it'd be rather useless. Other plugins should be "opt-in" and are
activated by:
          
    Hoe::plugin :thingy
          
Put this _above_ your hoe-spec. All it does is add `:thingy` to `Hoe.plugins`.
You could also deactivate a plugin by removing it from `Hoe.plugins` although
that shouldn't be necessary for the most part.
          
Please note that it is **not** a good idea to have a plugin you're writing
activate itself. Let developers opt-in, not opt-out. Just because someone
needs the `:thingy` plugin on one project doesn't mean they need them on _all_
their projects.

==== Initialization

When your hoe-spec is instantiated, it extends itself all known plugin
modules. This adds the method bodies to the hoe-spec and allows for the plugin
to work as part of the spec itself. Once that is over, activated plugins have
their **optional** define `initialize_#{plugin}` methods called. This lets
them set needed instance variables to default values. Finally, the hoe-spec
block is evaluated so that project specific values can override the defaults.

==== Task Definition

Finally, once the user's hoe-spec has been evaluated, all activated plugins
have their `define_#{plugin}_tasks` method called. This method must be defined
and it is here that you'll define all your tasks.

== HOW TO CONTRIBUTE OR GET SUPPORT:

=== Mailing List

A mailing list for hoe is hosted at: http://rubyforge.org/projects/seattlerb

=== Bugs & Feature Requests:

We use the bug trackers hosted at: http://rubyforge.org/projects/seattlerb

=== Patches:

* If you have a bug fix or enhancement to hoe that you'd like to
  contribute, please provide a unified diff and file it in a ticket in
  the bug tracker listed above.
* You can check out hoe:
  * With git via github: http://github.com/seattlerb/hoe
  * With svn via rubyforge: http://rubyforge.org/projects/seattlerb
  * Or via perforce if you'd like to directly contribute:
    http://www.zenspider.com/ZSS/Process/Perforce.html

== REQUIREMENTS:

* rake
* rubyforge
* rubygems

== INSTALL:

* sudo gem install hoe

== LICENSE:

(The MIT License)

Copyright (c) Ryan Davis, Seattle.rb

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
