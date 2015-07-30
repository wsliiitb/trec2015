# trec2015
1) We used Nokogiri a ruby gem to parse the documents and got useful text from the Journal docs and indexed them in Solr.

2) Extracted terms for around 13000 random abstracts and created term co-occurence graph for the same.

3) For each topic we extracted terms from summary and type of the topic.

4) We created an induced sub graph for these terms (including the type) and ran Random walk Algorithm on the induced graph. This gave us more related terms for the given input terms.

5) We used Solr to retrieve related Journal Documents using the expanded keywords.

      
