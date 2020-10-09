# Accepts a set of documents, and determines how similar any two documents are.

# In a simplified sense, this program functions by breaking each document
# (plaintext file) into a set of chunks of n number of words, and checking how
# many of those chunks each two documents have in common. The greater the value
# of number n, the more directly similar any two documents have to be in order
# to pass. For example, an n value of 4 (the default) will consider two
# documents simalar if they have a couple common chunks, whereas an n value of
# fifteen may only consider two documents simalar if entire verbaitem sentences
# are shared.

N_VALUE   = 4
DIRECTORY = Dir.pwd
THRESHOLD = 10

require 'set'
require 'optparse'

class WordList
    # Creates a list of words in a file to allow quick chunk generation.

    # filename: The file of which to make a word list. Must be a file object,
    #   or a path to a valid file as a String
    def self.list_words filename
        raise ArgumentError, 'not a file'   unless File.exist?    filename
        raise ArgumentError, 'not readable' unless File.readable? filename
        raise ArgumentError, 'is directory' if     Dir.exist?     filename
        verbose "Beginning to list words"
        words = Array.new
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
    # TODO: Make a <=> function to increase comparison refactorability?

    # Generates reader functions for the listed variables
    attr_reader :filename, :chunks

    # # filename: The file of which to make a word list. Must be a file object,
    #   or a path to a valid file as a String
    def initialize filename, n
    	verbose "Sanitizing Doc: #{@filename}" 
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
            	verbose "Adding #{filename} to document list"
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
    	verbose "Creating DocPair: #{@filenames}"
        @filenames  = [a.filename, b.filename]
        @num_same   = (a.chunks  & b.chunks).size
        @similarity = @num_same.to_f / [a.chunks.size, b.chunks.size].min
    end

    # Ruby's "spaceship operator". Facilitates comparison between two objects,
    #   such as for array sorting.
    def <=> other
        @similarity <=> other.similarity
    end

    def to_s
        ((@filenames.to_s.ljust 50) + (@num_same.ljust 6) + @similarity.to_s)
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
            pairs.push pair if pair.similarity > threshold
        end
        puts pairs.sort
    end
    
end

# The following are some housekeeping things. These don't have much to do with
# theory, it's more about making the user input computer readable, and
# putting the theory stuff above into motion

# Prints the provided message to the terminal if VERBOSE_MODE is on
def verbose message
    puts message if VERBOSE
end

# Sets the default values of some command line options
n_value   = N_VALUE
directory = DIRECTORY
threshold = THRESHOLD

# Read command line optins into variables. Uses the Ruby optparse library
OptionParser.new do |opti|
    opti.banner = 'Usage: catching_plagiarists.rb [options] directory_name'
    opti.on '-v',        'Run in verbose mode'          do VERBOSE    = true end
    opti.on '-r',        'Search directory recursively' do recursive  = true end
    opti.on '-dSTRING',  'Directiry to search through'  do |d| directory = d end
    opti.on '-nINTEGER', 'Value of n, chunk length'     do |n| n_value   = n end
    opti.on '-tINTEGER', 'Threshold value'              do |t| threshold = t end
    opti.on '-h',        'Display this help message'    do puts opti         end
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
DocumentSet.compare directory, recursive, n_value, threshold
