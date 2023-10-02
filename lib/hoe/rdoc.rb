##
# RDoc plugin for hoe. Switches default text files to rdoc.

module Hoe::Rdoc
  def initialize_rdoc # :nodoc:
    self.readme_file = self.readme_file.sub(/\.txt$/, ".rdoc")
    self.history_file = self.history_file.sub(/\.txt$/, ".rdoc")
  end

  def define_rdoc_tasks # :nodoc:
    # do nothing
  end
end
