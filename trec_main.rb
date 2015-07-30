require '../atrec/trec_cooccurrence_graph'
require '../atrec/random_walk_for_agama'
require '../atrec/agama_graph_operations'
require '../atrec/solr_handler'
require '../atrec/parse_topics'
require 'engtagger'

$HOME_DIR = File.expand_path "~"
class TrecMain

  def self.main topic_id, data, threshold, aggregate_file

    return false if topic_id == nil || data == nil || data["summary"] == nil || data["type"] == nil
    paragraph = "#{data["type"]} #{data["summary"]}"
    paragraph ="#{data["diagnosis"]} #{paragraph}"  unless data["diagnosis"] == nil

    type = data["type"]
    #paragraph.gsub!("-", " ")
    paragraph.gsub!(/\[[0-9a-zA-Z]*\]/, " ")
    paragraph.gsub!(/\s+/, ' ')
    puts "Topic #{topic_id}; Summary: #{paragraph}"
    puts

    tgr = EngTagger.new
    tagged_text = tgr.add_tags paragraph
    #puts tagged_text
    nouns_hash = tgr.get_nouns tagged_text
    return if nouns_hash == nil || nouns_hash.length == 0
    nouns = nouns_hash.keys
    puts "Extracted Nouns #{nouns.inspect}"


    stop_words = TrecCooccurrenceGraph.load_stop_words("../resource/english.stop", nil)
    key_words = nouns - stop_words
    #key_words = TrecCooccurrenceGraph.get_key_words paragraph, stop_words
    key_words.uniq!
    key_words = key_words.map(&:downcase)
    puts key_words.inspect

    random_walk = RandomWalkForSM.new
    cash_distributions_for_terms = {}
    all_terms_with_cash = {}

    agama_db = AgamaGraphOperations.new("#{$HOME_DIR}/trec-coocurrence-graph")

    key_words.each do |term|
      degree, number_of_neighbors = agama_db.get_term_degree_and_neighbor_count term
      importance = 1.0/ number_of_neighbors.to_f
      next unless agama_db.is_node_present term
      #sc = GraphOperations.get_sc_of_closure_multi_thread [term], 0.5, nil, nil
      sc, degree, number_of_neighbors = agama_db.get_semantic_context_of_closure(term, false, threshold)
      next if sc == nil || sc.length == 0
      return_cash = random_walk.random_walk(sc, nil)
      if return_cash != nil
        return_cash_hash = Hash[*return_cash.flatten]
        cash_distributions_for_terms[term] = return_cash_hash

        return_cash_hash.each do |term, current_cash|
          total_cash = all_terms_with_cash[term]
          total_cash = 0.0 if total_cash == nil
          all_terms_with_cash[term] = total_cash + (current_cash * 1000000.0 * importance)
        end
      end
    end


    all_terms_with_cash.each do |term, value|
      degree, number_of_neighbors = agama_db.get_term_degree_and_neighbor_count term
      importance = 1.0/ number_of_neighbors.to_f
      #all_terms_with_cash[term] = all_terms_with_cash[term]
      all_terms_with_cash[term] = all_terms_with_cash[term] * (1000000.0 * importance)
    end

    agama_db.close

    all_terms_with_cash = Hash[all_terms_with_cash.sort_by { |_key, value| value }.reverse!]
    puts "Final Importance Scores for Terms:\n #{all_terms_with_cash.inspect.sub("{", "").sub("}", "").gsub(", ", "\n")}\n"
    key_words.concat key_words
    key_words << "human"
    key_words << type
    key_words.concat all_terms_with_cash.keys[0..all_terms_with_cash.keys.length * 0.2]
    puts key_words.inspect
    solr_results = SolrHandler.new.query key_words.join(" "), type

    write_to_file(solr_results, threshold, topic_id, type, aggregate_file)
  end

  ######################################################################################################################
  #
  #
  #
  ######################################################################################################################
  def self.write_to_file(solr_results, threshold, topic_id, type, aggregate_file)
    rank = 1
    Dir.mkdir($main_dir) unless File.directory? ($main_dir)
    Dir.mkdir("#{$main_dir}/#{threshold.inspect}") unless File.directory? ("#{$main_dir}/#{threshold.inspect}")
    Dir.mkdir("#{$main_dir}/for-trec-#{threshold.inspect}") unless File.directory? ("#{$main_dir}/for-trec-#{threshold.inspect}")

    File.open("#{$main_dir}/for-trec-#{threshold.inspect}/#{topic_id}-#{type}-#{threshold.inspect}.out", 'w') do |org_file|
      File.open("#{$main_dir}/#{threshold.inspect}/#{topic_id}-#{type}-#{threshold.inspect}.out", 'w') do |file|
        org_file.puts("TOPIC_NO\tQ0\tPMCID\tRANK\tSCORE\tRUN_NAME")
        file.puts("TOPIC_NO\tQ0\tPMCID\tRANK\tSCORE\tRUN_NAME\tFILE_NAME")
        solr_results.each do |result|
          pmcid = File.basename(result['id'], ".txt")
          file.puts("#{topic_id}\tQ0\t#{pmcid}\t#{rank}\t#{result['score']}\tSH.01\t#{result['id']}")
          org_file.puts("#{topic_id}\tQ0\t#{pmcid}\t#{rank}\t#{result['score']}\tSH.01")
          aggregate_file.puts("#{topic_id}\tQ0\t#{pmcid}\t#{rank}\t#{result['score']}\tSH.01")
          rank = rank +1
        end
      end
    end
  end
end


time = Time.new
time_string =  time.strftime("%Y-%m-%d-%H-%M")
$main_dir = "../../Topic-A-output-#{time_string}/"
Dir.mkdir($main_dir) unless File.directory? ($main_dir)
data = ParseTopics.readFile
thresholds = [0.05]
thresholds.each do |threshold|
  File.open("#{$main_dir}/for-trec-all-in-one-#{threshold.inspect}.out", 'w') do |aggregate_file|
    data.each do |topic_id, data|
      if TrecMain.main(topic_id, data, threshold, aggregate_file) == nil
        puts "Some error in data for #{topic_id}, and #{data}!"
      end
    end
  end
end

