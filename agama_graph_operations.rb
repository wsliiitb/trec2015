require 'rubygems'
require 'agama'
require 'agama/adapters/tokyocabinet'
require 'fileutils'

######################################################################################################################
#
#
#
#
#
#
######################################################################################################################
class AgamaGraphOperations

  ######################################################################################################################
  # The graph database handler
  ######################################################################################################################
  @graph = nil
  @degrees = {}
  @distinct_neighbors = {}

  ######################################################################################################################
  #
  #
  #
  ######################################################################################################################
  def initialize graph_path
    #puts graph_path
    @graph = Agama::Graph.new(:path => graph_path, :db => Agama::Adapters::TC.new)
    puts "Initialized Agama!"
    @graph.open
    @degrees = {}
    @distinct_neighbors = {}
  end

  ######################################################################################################################
  #
  #
  #
  ######################################################################################################################
  def get_neighbors(term, need_generatability, sort, praportion)

    node = is_node_present(term)
    if node == nil
      return nil, nil
    end

    degree, neighbors_with_weight, number_of_neighbors = get_node_details(node)
    @degrees[term] = degree
    @distinct_neighbors[term] = number_of_neighbors

    #hack
    new_praportion = (number_of_neighbors.to_f/degree.to_f) * praportion

    if need_generatability
      neighbors_with_generatability = {}
      neighbors_with_weight.each do |term, weight|
        neighbors_with_generatability[term] = weight.to_f / degree
      end

      result = neighbors_with_generatability
    else
      result = neighbors_with_weight
    end

    if sort && result!=nil
      if new_praportion != nil
        limit = (new_praportion.to_f * result.length.to_f).to_i
        #puts "Out of #{result.length} node, only #{limit} nodes were selected"
        result = Hash[result.sort_by { |_key, value| value }.reverse![0..limit-1]]
      else
        result = result.sort_by { |_key, value| value }.reverse!
        result = Hash[*result.flatten]
      end
    end

    [degree, number_of_neighbors, result]
  end


  ######################################################################################################################
  #
  #
  #
  ######################################################################################################################
  def get_node_details(node)
    degree = 0
    neighbors_with_weight = {}
    @graph.neighbours(node).along('line').each do |edge|
      term = edge[:to][:name]
      wt = edge[:weight]

      unless term =~ /\d/
        neighbors_with_weight[term]= wt
        degree = degree + wt
      end
    end
    number_of_neighbors = neighbors_with_weight.length
    return degree, neighbors_with_weight, number_of_neighbors
  end


  ######################################################################################################################
  #
  #
  #
  ######################################################################################################################
  def get_term_degree_and_neighbor_count(term)
    return [@degrees[term], @distinct_neighbors[term]] if (@degrees.include? term) && (@distinct_neighbors.include? term)

    node = is_node_present(term)
    if node == nil
      return nil, nil
    end
    degree, neighbors_with_weight, number_of_neighbors = get_node_details node
    [degree, number_of_neighbors]
  end


  ######################################################################################################################
  #
  #
  #
  ######################################################################################################################
  def is_node_present(term)

    node=@graph.get_node(:name => term, :type => 'circle')
    if !node
      puts "The term #{term.inspect} is not present."
      return nil
    else
      #puts "The term #{term.inspect} is present!"
    end
    node
  end

  # end of get_neighbors

  ######################################################################################################################
  #
  #
  #
  ######################################################################################################################
  def get_semantic_context_of_closure(term, is_sampling_based, praportion)

    degree, number_of_neighbors, neighbors_with_gen= get_neighbors term, true, true, praportion
    return nil if degree == nil || neighbors_with_gen == nil
    print "Degree of #{term} =  #{degree}. Number of neighbors = #{number_of_neighbors}."
    puts  " Importance = #{(number_of_neighbors.to_f/degree.to_f) * praportion}. We chose #{neighbors_with_gen.length} top co-occurring nodes."
    neighboring_nodes = neighbors_with_gen.keys
    neighboring_nodes << term
    #puts neighboring_nodes.inspect

    semantic_context = {}
    semantic_context[term] = convert_to_rw_format(term, neighboring_nodes, neighbors_with_gen)
    neighbors_with_gen.each do |neighbor, generatability|
      degree_n, number_of_neighbors_n, neighbors_with_gen_n = get_neighbors neighbor, true, true, praportion
      valid_edges = {}
      neighbors_with_gen_n.each do |nbr, gen|
        if neighboring_nodes.include? nbr
          valid_edges[nbr] = gen
        end
      end
      semantic_context[neighbor] = convert_to_rw_format(neighbor, neighboring_nodes, valid_edges)
      @degrees[neighbor] = degree_n
      @distinct_neighbors[neighbor] = number_of_neighbors_n
    end
    [semantic_context, degree, number_of_neighbors]
  end


  ######################################################################################################################
  # Expected output-oldest:
  # {"clammy"=>[{:t1=>"clammy", :t2=>"current", :gen=>0.046511627906976744, :wt=>2}, {:t1=>"clammy", :t2=>"river", :gen=>0.046511627906976744, :wt=>2}],
  # "river"=>[{:t1=>"river", :t2=>"clammy", :gen=>1.5233452662045852e-05, :wt=>2}, {:t1=>"river", :t2=>"current", :gen=>0.0001447178002894356, :wt=>19}],
  # "current"=>[{:t1=>"current", :t2=>"clammy", :gen=>0.00019083969465648855, :wt=>2}, {:t1=>"current", :t2=>"river", :gen=>0.0018129770992366412, :wt=>19}]}
  ######################################################################################################################
  def convert_to_rw_format(t1, neighboring_nodes, neighbors_with_gen)
    all_neighbors_in_format = []
    neighbors_with_gen.each do |t2, generatability|
      if neighboring_nodes.include? t2
        all_neighbors_in_format << {:t1 => t1, :t2 => t2, :gen => generatability, :wt => 0}
      end
    end
    #puts all_neighbors_in_format.inspect
    all_neighbors_in_format
  end


  def close
    @graph.close
  end

  ######################################################################################################################
  #
  #
  #
  ######################################################################################################################
  def self.test
    agamadb = AgamaGraphOperations.new "/home/sumant/trec-cds/graphFiles"
    degree, neighbors= agamadb.get_neighbors "immune", true, false, nil
    puts "Degree #{degree}"
    puts (Hash[neighbors.sort_by { |k, v| -v }[0..9]]).inspect.sub("{", "").sub("}", "").gsub(", ", "\n")
    #puts neighbors.inspect.sub("{", "").sub("}", "").gsub(", ", "\n")
    #puts neighbors.keys.inspect

  end # end of test

end

# end of the class


=begin
agama = AgamaGraphOperations.new("/home/sumant/trec-cds/graphFiles")
sc = agama.get_semantic_context_of_closure "immune", false, 0.01
puts sc
agama.close
=end
