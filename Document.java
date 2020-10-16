
import DocumentProcessor;

class Document {

	public final HashSet<String> chunks;
	public final String filename;

	public Document(String filename, int chunkLen) {
    	this.filename = filename;
    	chunks = getChunks(getWords(filename), chunkLen);
	}

 	public double percentInCommon(Document other) {

    	if (chunks.size() > other.chunks().size())
			return other.compareTo(this);

		HashSet<String> otherChunks = other.chunks();
    	int numPhrasesInCommon = 0;

    	for (String curChunk : chunks)
      		if otherChunks.contains(curChunk)
        		numPhrasesInCommon++;

    	return numPhrasesInCommon / chunks.size();

  	}

}
