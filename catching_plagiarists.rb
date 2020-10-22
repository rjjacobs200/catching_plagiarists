# Accepts a set of documents, and determines how similar any two documents are.

# In a simplified sense, this program functions by breaking each document
# (plaintext file) into a set of chunks of n number of words, and checking how
# many of those chunks each two documents have in common. The greater the value
# of number n, the more directly similar any two documents have to be in order
# to pass. For example, an n value of 4 (the default) will consider two
# documents simalar if they have a couple common chunks, whereas an n value of
# fifteen may only consider two documents simalar if entire verbaitem sentences
# are shared.

N_VALUE         = 4
DIRECTORY       = Dir.pwd
THRESHOLD       = 10
MAX_NUM_RESULTS = 50

FILENAME_JUSTIFY = 50
NUM_SAME_JUSTIFY = 7

require 'set'
require 'optparse'
require 'matrix'

class WordList
    # Creates a list of words in a file to allow quick chunk generation.

    # filename: The file of which to make a word list. Must be a file object,
    #   or a path to a valid file as a String
    def self.list_words filename
        raise ArgumentError, 'not a file'   unless File.exist?    filename
        raise ArgumentError, 'not readable' unless File.readable? filename
        raise ArgumentError, 'is directory' if     Dir.exist?     filename
        words = []
        File.open filename do |file|
            verbose "Listing words for: #{filename}"
            file.each_line do |line|
                words.concat (line.scrub.downcase.gsub /[[:punct:]]/, '').split
            end
        end
        words
    end
    
end

class ChunkSet
    # Creates chunks from the arrays of words

    # filename: The file of which to make a word list. Must be a file object,
    #   or a path to a valid file as a String
    def self.create_chunks filename, n
        raise ArgumentError, 'not a file'   unless File.exist?    filename
        raise ArgumentError, 'not readable' unless File.readable? filename
        raise ArgumentError, 'is directory' if     Dir.exist?     filename
        verbose "Creating chunks for #{filename}" 
        word_list = WordList.list_words filename
        chunk_set = Set.new
        for i in (0..word_list.length - n)
            chunk_set.add word_list[i...n + i - 1].join ' '
        end
        chunk_set
    end
 
end

class Document
    # Contains basic metadata about a document, and its chunk set.

    # Generates reader functions for the listed variables
    attr_reader :filename, :chunks

    # # filename: The file of which to make a word list. Must be a file object,
    #   or a path to a valid file as a String
    def initialize filename, n
        @chunks   = ChunkSet.create_chunks filename, n
        @filename = filename
    end
    
end

class DocumentFetcher
    # Searches through the given directory for files to analyze, then returns an
    # array of all files as Document objects.

    # filename: The file of which to make a word list. Must be a file object,
    #   or a path to a valid file as a String.
    # recursive: Whether to search the directory tree recursively. 
    # document_collection: Used for recursive searching to allow all files to
    #   be added to the same collection. Calling the function without this
    #   parameter,
    def self.fetch directory, recursive, n, document_collection = Array.new
        raise ArgumentError, 'not a directory' unless Dir.exist? directory
        verbose "Fetching documents from #{directory}"
        Dir.chdir directory
        (Dir.new directory).each do |filename|
            if Dir.exist? filename
                fetch filename, recursive, n, document_collection if recursive
            elsif File.exist? filename
                document_collection.push Document.new filename, n
            else
                raise StandardError, "neither file nor directory: #{filename}"
            end
        end
        document_collection
    end
    
end

class DocumentPair
    # Contains two documents, and their similarity

    # Generates reader functions for the listed variables
    attr_reader :filenames, :similarity, :num_same

    # first, second: The two documents to be contained and compared
    # TODO: Perhaps make this class / function variadic?
    def initialize a, b
        @filenames  = [a.filename, b.filename].sort
        @num_same   = (a.chunks  & b.chunks).size
        @similarity = @num_same.to_f / [a.chunks.size, b.chunks.size].min
    end

    # Ruby's "spaceship operator". Facilitates comparison between two objects,
    #   such as for array sorting.
    def <=> other
        @num_same <=> other.num_same
    end

	# TODO: Make this more flexable instead of just using magic numbers
    def to_s
        ((@filenames.to_s.ljust FILENAME_JUSTIFY) +
         ( @num_same.to_s.ljust NUM_SAME_JUSTIFY) + 
         @similarity.to_s)
    end

end

class DocumentSet
    # Accepts a list of documents, and compares all possible combinations

    # filename: The file of which to make a word list. Must be a file object,
    #   or a path to a valid file as a String.
    # recursive: Whether to search the directory tree recursively. Currently
    #   not used, but may be someday. Expects a boolean, anything else will be
    #   forcibly resolved to one
    # threshold: The amount of similarity a document must surpass in order to be
    #   displayed after analasys.
    def self.compare directory, recursive, n, threshold
        verbose "Creating document set for #{directory}"
        pairs = Array.new
        (DocumentFetcher.fetch directory, recursive, n).combination 2 do |a, b|
            pair = DocumentPair.new a, b
            pairs.push pair if pair.num_same >= threshold
        end
        pairs.sort!
    end
    
end

# The following are some housekeeping things. These don't have much to do with
# theory, it's more about making the user input computer readable, and
# putting the theory stuff above into motion

class DocMatrix

	def initialize directory, recursive, n, threshold, max_num_results
		@pairs = (DocumentSet.compare directory, recursive, n, threshold)
 			 .last max_num_results
		max_num_results = [max_num_results, @pairs.length].min
		return nil if max_num_results == 0
		@matrix = Matrix.empty 0, 4
		@pairs.each do |pair|
			a, b = pair.filenames
			@matrix = Matrix.vstack @matrix,
				(Matrix.row_vector [a, b, pair.num_same, pair.similarity])
		end
		@matrix
	end

	def justified_rows
		justs = find_justifications
		rows = []
		(0...@matrix.row_count).each do |row|
			rows.push ("#{@matrix[row, 0].to_s.ljust justs[0]}   " + 
					   "#{@matrix[row, 1].to_s.ljust justs[1]}   " +
					   "#{@matrix[row, 2].to_s.rjust justs[2]}   " +
					   "#{@matrix[row, 3]} "                        )
		end
		rows
	end

	private
	
	def find_justifications
		justifications = Array.new 2 do |col|
			longest = 0   # Length of longest filename
			(0..@matrix.row_count).each do |row|
				longest = [longest, @matrix[row, col].to_s.length].max
			end
			longest
		end
		
		longest = 0   # Length of largest number
		(0..@matrix.row_count).each do |row|
			longest = [longest, @matrix[row, 2].to_s.length].max
		end
		justifications[2] = longest
		justifications
	end

end

# Prints the provided message to the terminal if VERBOSE_MODE is on
def verbose message
    puts message if VERBOSE
end

# Sets the default values of some command line options
n_value         = N_VALUE
directory       = DIRECTORY
threshold       = THRESHOLD
max_num_results = MAX_NUM_RESULTS

# Read command line optins into variables. Uses the Ruby optparse library
OptionParser.new do |opti|
    opti.banner = 'Usage: catching_plagiarists.rb [options] directory_name'
    opti.on('-v',        'Run in verbose mode'        ){VERBOSE   = true}
    opti.on('-r',        'Crawl directory recursively'){recursive = true}
    opti.on('-dSTRING',  'Directiry to search through'){|d| directory       = d}
    opti.on('-nINTEGER', 'Value of n, chunk length'   ){|n| n_value         = n}
    opti.on('-tINTEGER', 'Threshold value'            ){|t| threshold       = t}
    opti.on('-mINTEGER', 'Max number of results shown'){|m| max_num_results = m}
    opti.on('-h',        'Display this help message'  ){puts opti}
end.parse!

# Unless the user requests these to be true, they become false
VERBOSE   = false unless defined? VERBOSE
recursive = false unless recursive 

# Checks to see whether the directory passed in is valid
unless Dir.exist? directory then
    puts "ERROR: invalid directory"
    exit 1
end

# Now run it!
matrix = DocMatrix.new directory, recursive, n_value, threshold, max_num_results

puts matrix.justified_rows