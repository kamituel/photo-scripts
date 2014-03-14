#!/usr/bin/env ruby2.0
require 'pathname'

BOX = File.join(File.dirname(__FILE__), "box.rb")
RAW_FOLDER_NAME = "_raw"
def syscall (cmd)
	res = `#{cmd}`
	unless $?.exitstatus == 0
		p "#{res}"
	end
	return res
end

def exists_on_box (account_name, tree, path)
	dir = path.dirname.to_s
	base = path.basename.to_s

	unless tree[dir]
		tree[dir] = []
		p "[ls   ] #{dir}" 
		syscall("#{BOX} #{account_name} ls \"#{dir}\"").each_line do |line|
			filename = line.chomp.sub(/^.*?\s/, '')
			tree[dir] << filename
		end
	end

	return tree[dir].include?(base)
end

def is_directory (dir) 
	Dir.pwd == File.expand_path(File.dirname(dir)) and File.directory?(dir)
end

account_name = ARGV.shift
dir_names = ARGV

unless account_name and dir_names and dir_names.length >= 1 and dir_names.all? { |dir| is_directory(dir) }
	p "Usage: upload-album-box ACCOUNT_NAME DIR1 [DIR2 [...]]"
	p "!! DIR has to be a directory in the CURRENT WORKING DIRECTORY"
	exit -1
end

dir_names = dir_names.map { |dir| dir.sub(/^\.\/?/, '').sub(/\/$/, '') } 
queue = [] 
box_tree = {}

dir_names.each { |dir_name|
	queue = [dir_name]
	#p "Queue is #{queue}"
	queue.each { |item| 
		box_path = Pathname.new("/#{item}")

		#p "Item #{item}"
		if File.directory?(item)
			next unless dir_name == item or item == "#{dir_name}/#{RAW_FOLDER_NAME}"

			# Uncomment to enable RAW files upload
			# next if item == "#{dir_name}/#{RAW_FOLDER_NAME}"

			unless exists_on_box(account_name, box_tree, box_path)
				p "[mkdir] #{item}"
				syscall("#{BOX} #{account_name} mkdir \"#{box_path.dirname}\" \"#{box_path.basename}\"")

				# To avoid doing "ls" later. I know it's empty.
				box_tree["/#{item}"] = []
			end

			Dir.foreach(item) do |child|
				next if child == "." or child == ".."
				next if child =~ /^\..*/

				queue << File.join(item, child)
			end

			next
		end

		if File.file?(item)
			unless exists_on_box(account_name, box_tree, box_path)
				p "[push ] #{item}"
				syscall("#{BOX} #{account_name} push \"#{item}\" \"#{box_path.dirname}\"")
			end

			next
		end

		p "[????]  #{item}"
	}
}
