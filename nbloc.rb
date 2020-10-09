# Counts non-blank lines of code for the given file, where a non-blank line of
# code is defined as a line in a text file that is neither blank, nor contains
# only the keyword "end", nor is a comment.

# File for which to count lines is provided as the command line argument.

raise ArgumentError, 'must provide filepath' if ARGV.length == 0
filepath = ARGV[0]

def count_lines filepath
	raise ArgumentError, 'invalid file' unless File.exist? filepath
    count = 0
    File.open filepath do |file|
        file.each_line do |line|
            line.strip!
            unless (
            	line.start_with? '#' or line.empty? or
            	['end', '{', '}', '(', ')', '[', ']'].include? line
            ) then count += 1 end
        end
    end
    count
end

puts count_lines filepath
