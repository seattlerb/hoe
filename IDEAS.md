# Ideas for stuff to do

## Easier conditional configuration

Instead of having to do:

	Hoe.plugin :mercurial
	
	Hoe.spec 'treequel' do
		# ...
		hg_sign_tags = true if respond_to?( :hg_sign_tags= )
	end

add something a bit more readable like:

	Hoe.plugin :mercurial
	
	Hoe.spec 'treequel' do
		# ...
		hg_sign_tags = true if activated?( :mercurial )

		# and/or

		if activated?( :mercurial )
			hg_sign_tags = true
			hg_release_tag_prefix = 'r'
		end
	end
	
	
