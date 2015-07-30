#http://rubular.com/

$local_graph = {}

#####################################################################################################################
# Class to create in memory co-occurence graph. We can modify main method to add it to permanent store
#####################################################################################################################

class TrecCooccurrenceGraph

  #####################################################################################################################
  #
  #####################################################################################################################
  def self.get_cooccurrence_graph filename, stop_words
    cliques_of_each_paragraph = []
    final_results_hash = {} # returned

    File.open(filename).each do |paragraph|
      paragraph_keywords = get_key_words(paragraph, stop_words)
      next if paragraph_keywords == nil
      #if return_list.include? "orbitrap xl etd"
      #  puts "Found in -- #{filename.inspect}"
      #  exit 1
      #end
      clique_of_paragraph = paragraph_keywords.combination(2).to_a
      cliques_of_each_paragraph <<  clique_of_paragraph
    end


    cliques_of_each_paragraph.each do |clique|
      clique.each do |edge|
        key = edge.join("<<YYY>>")
        val = final_results_hash[key]
        if val == nil
          val = 0
        end
        final_results_hash[key] = val + 1
      end
    end

    #puts final_results_hash.inspect
    final_results_hash
    #all_results
  end

  def self.get_key_words(paragraph, stop_words)
    return nil if paragraph == nil || paragraph.strip.length == 0
    paragraph.gsub!("'s ", " ") # remove all 's
    paragraph.gsub!(/[^a-zA-Z0-9\-.\,\!\?\;\:\ ]/, " | ")
    paragraph = paragraph.gsub(/[\.,!\?:|;]/, " . ")
    paragraph.gsub!(/\s+/, " ")
    paragraph.strip!

    cap_phrases = get_cap_phrases(paragraph, stop_words)
    cap_phrases.each do |cap_phrase|
      substitute_phrase = cap_phrase.gsub(/\s/, 'nnnnnnddddnnnnnn')
      paragraph.gsub!(cap_phrase, substitute_phrase)
      #puts line.inspect
    end

    paragraph = paragraph.gsub(".", " ")
    #puts line.inspect
    return nil if paragraph == nil
    paragraph.downcase!
    words = paragraph.split(/\s+/)
    words.each(&:lstrip!)
    words.uniq!
    words.sort! # the edge between 'sort' and 'addition' should be listed like 'addition<<YYY>>sort' and not as 'sort<<YYY>>addition'

    paragraph_keywords = []
    words.each do |word|
      word = word.strip
      next if stop_words.include?(word) || paragraph_keywords.include?(word)
      word = word.gsub("nnnnnnddddnnnnnn", " ")
      word = word.gsub(/\s+/, " ")
      word = word.strip
      paragraph_keywords << word
    end
    paragraph_keywords
  end

  #####################################################################################################################
  #
  #####################################################################################################################
  def self.load_stop_words(stop_word_file_path, stop_words)
    if stop_words == nil
      stop_words = []
    end
    File.open(stop_word_file_path).each do |line|
      stop_words << line.strip
    end
    #puts stop_words
    return stop_words
  end

  #####################################################################################################################
  #
  #####################################################################################################################
  def self.get_cap_phrases(text, stop_word_list)
    text = " #{text}"
    #puts text.inspect
    #puts
    cap_phrases_temp = text.scan(/(([ ][A-Z][A-Za-z]+[\-]?[A-Za-z]*)(\s+[A-Z][A-Za-z]+[\-]?[A-Za-z]*)*(\s+[A-Z][A-Za-z]+[\-]?[A-Za-z]*)+)/).map { |i| i.first }
    #puts cap_phrases_temp.inspect
    cap_phrases = []
    cap_phrases_temp.each do |cap_phrase|
      unless stop_word_list.include? cap_phrase.split[0...1][0].downcase
        cap_phrases << cap_phrase.strip
      end
    end
    #puts cap_phrases.inspect.sub("{","").sub("}", "")
    cap_phrases
  end


  #####################################################################################################################
  # Main -- Call this to start
  #####################################################################################################################
  def self.main dir_path, stopword_file_path
    file_count = 0
    stop_words = []
    load_stop_words stopword_file_path, stop_words
    Dir.foreach(dir_path) do |file|
      next if file == '.' or file == '..'
      cooccurrence_graph_hash_of_file = TrecCooccurrenceGraph.get_cooccurrence_graph("#{dir_path}/#{file}", stop_words)
      $local_graph.merge!(cooccurrence_graph_hash_of_file) { |key, oldval, newval| newval + oldval }
      file_count = file_count + 1
      if file_count % 100 == 0 || $local_graph.length > 100000
        # Update Agama
        # $local_graph = {}
        puts("Number of files: #{file_count}, Number of Edges: #{$local_graph.length}")
      end
    end
    puts $local_graph.inspect.sub("{", "").sub("}", "").gsub(", ", "\n")
  end
end # END of CLASS

#####################################################################################################################
#
#####################################################################################################################

#if ARGV != nil && ARGV.length == 2
#  TrecCooccurrenceGraph.main ARGV[0], ARGV[1]
#else
#  TrecCooccurrenceGraph.main "/home/sumant/temp",
#                             "/home/sumant/sm/src/resource/english.stop"
#end
