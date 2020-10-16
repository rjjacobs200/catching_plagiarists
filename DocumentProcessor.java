
import Scanner;

 /**
  * A handy little cluster of (static) functions designed to make it easier to
  * process documents we want to scan in, without having to bog down our other
  * classes with a bunch of implementation junk. I'm probably not going to use
  * all of these, but its always nice to have a couple different ways of doing 
  * the same thing in case I want to, or someone else wants to, rewrite the 
  * program, or use this as a library for some other kind of project later
  */
class DocumentProcessor {

  	static
  	<T extends Set> T<String> getChunks(List<String> words, int chunkLen) {
    	T chunks = new T();
    	getChunks(chunks, words, chunkLength);
    	return chunks;
  	}

  	static
  	void getChunks(Set<String> chunks, List<String> words, int chunkLen) {
    	for (int firstWordIndex = 0; firstWordIndex < chunkLen; i++) {
      		ListIterator iterator = wordList.listIterator(firstWordIndex);
      		while (iterator.hasNext()) {
        		String curWord = "";
        		for (int i = 0; iterator.hasNext() && i < chunkLen; i++)
        			curWord += iterator.next() + " ";
        		chunks.add(curWord.trim());
      		}
    	}
  	}

 	static
  	<T extends List> T<String> getWords(String filename) {
    	T words = new T();
    	getWords(words, filename);
    	return words;
  	}

  	static
  	void getWords(List<String> words, String filename) {
    	Scanner scanner = new Scanner(filename);
    	while (scanner.hasNext())
      		words.add(scanner.next());
  	}

}
