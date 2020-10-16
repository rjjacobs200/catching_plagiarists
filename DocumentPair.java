
class DocumentPair implements Comparable<DocumentPair> {

	public final Document first, second;
  	public final double percentInCommon;

  	public DocumentPair(Document first, second) {
    	this.first      = first;
    	this.second     = second;
    	percentInCommon = first.percentInCommon(second);
  	}

  	public int compareTo(DocumentPair other) {
    	return Double.compare(percentInCommon, other.percentInCommon);
  	}

}
