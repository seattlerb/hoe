= Hoe

* http://rubyforge.org/projects/seattlerb/
* http://seattlerb.rubyforge.org/hoe/
* http://seattlerb.rubyforge.org/hoe/Hoe.pdf
* http://github.com/jbarnette/hoe-plugin-examples

== DESCRIPTION:

Hoe is a rake/rubygems helper for project Rakefiles. It helps generate
rubygems and includes a dynamic plug-in system allowing for easy
extensibility. Hoe ships with plug-ins for all your usual project
tasks including rdoc generation, testing, packaging, and deployment.

See class rdoc for help. Hint: `ri Hoe` or any of the plugins listed
below.

See Also: http://seattlerb.rubyforge.org/hoe/Hoe.pdf

== FEATURES/PROBLEMS:

* Includes a dynamic plug-in system allowing for easy extensibility.
* Auto-intuits changes, description, summary, and version.
* Uses a manifest for safe and secure deployment.
* Provides 'sow' for quick project directory creation.
* Sow uses a simple ERB templating system allowing you to capture your
  project patterns.

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
