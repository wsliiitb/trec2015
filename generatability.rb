require 'rubygems'
require 'agama'
require 'agama/adapters/tokyocabinet'
require 'fileutils'

class GetGeneratabilityGraph
  def getGeneratabilityGraph(terms)
    tempdirectory="AGraph"
    generatabilityGraphPath = tempdirectory+"/generatabilityGraph"
    FileUtils.mkdir_p generatabilityGraphPath unless File.exists?(generatabilityGraphPath)
    FileUtils.rm_rf(generatabilityGraphPath+'/*')
    generatabilityGraph = Agama::Graph.new(:path => generatabilityGraphPath, :db => Agama::Adapters::TC.new)
    generatabilityGraph.open
    graph = Agama::Graph.new(:path => "/home/sumant/trec-cds/graphFiles", :db => Agama::Adapters::TC.new)
    graph.open
    terms.each do |term|

      node=graph.get_node(:name => term, :type => 'circle')
      if !node
        next
      end
      generatabilityGraph.set_node(node)
      default_node=generatabilityGraph.set_node(:name => 'default', :type => 'triangle', :importance => 0)

      graph.neighbours(node).along('line').each do |edge|
        new_node = generatabilityGraph.set_node(edge[:to])
      end
    end

    terms.each do |term|
      #p term
      node=graph.get_node(:name => term, :type => 'circle')
      if !node
        next
      end
      generatabilityGraph.get_node(node)
      default_node=generatabilityGraph.get_node(:name => 'default', :type => 'triangle', :importance => 0)
      generatabilityGraph.set_edge(:from => node, :to => default_node, :type => 'dotted', :directed => false)
      #puts "\n"
      sum_edge_weights_node=0
      #p "neighbours of node: "
      graph.neighbours(node).along('line').each do |edge|
        #p edge
        sum_edge_weights_node+=edge[:weight]
      end
      #p sum_edge_weights_node
      graph.neighbours(node).along('line').each do |edge|
        #puts edge[:from]
        #puts edge[:to]
        #puts edge
        #p "edge[:to]:"
        #p edge[:to]
        new_node = generatabilityGraph.get_node(edge[:to])
        if edge[:to][:name]!=default_node[:name]
          generatabilityGraph.set_edge(:from => edge[:to], :to => default_node, :type => 'dotted', :directed => false)
        end
        #p node
        #p new_node
        #p edge[:weight]
        #p sum_edge_weights_node
        #p edge[:weight]/sum_edge_weights_node.to_f
        temp = generatabilityGraph.set_edge(:from => node, :to => new_node, :type => 'line', :directed => true, :weight => edge[:weight]/sum_edge_weights_node.to_f)
        #p temp
        sum_edge_weights_new_node=0;
        graph.neighbours(new_node).along('line').each do |new_node_edge|
          sum_edge_weights_new_node+=new_node_edge[:weight]
        end
        graph.neighbours(new_node).along('line').each do |new_node_edge|
          if generatabilityGraph.get_node(new_node_edge[:to])
            #p "new_node_edge: "
            #p new_node_edge
            generatabilityGraph.set_edge(:from => new_node_edge[:from], :to => new_node_edge[:to], :type => 'line', :directed => true, :weight => new_node_edge[:weight]/sum_edge_weights_new_node.to_f)
          end
        end

      end
    end
    graph.close
    generatabilityGraph.close
    generatabilityGraph
  end


###########################################################################################################################################

# This function returns the Topical Anchors for given terms.
  def getTopicalAnchor(generatabilityGraph, terms)
    currentTotalCash=0
    prevTotalCash=0
    generatabilityGraph.open
    cash=1
    min_loop_count=generatabilityGraph.node_count
    #assignCashToNodes(generatabilityGraph,terms,cash)
    assignCashToAllNodes(generatabilityGraph, cash)
    #printNodes(generatabilityGraph)
    nodeNames=Array.new
    default_node=generatabilityGraph.get_node(:name => 'default', :type => 'triangle')
    generatabilityGraph.neighbours(default_node).each do |edge|
      if edge[:to][:name]!= 'default'
        nodeNames.push(edge[:to][:name])
      end
    end
    iteration=0
    while true
      prevTotalCash=currentTotalCash
      currentTotalCash=0
      randomNode_name = nodeNames[rand(nodeNames.length)]
      #print randomNode_name
      #print "\n"
      random_node=generatabilityGraph.get_node(:name => randomNode_name, :type => 'circle')
      generatabilityGraph.neighbours(random_node).along('line').each do |edge|
        #p edge
        #print randomNode_name
        #print edge[:to][:name]
        #print "\n"
        if edge[:to][:name]!=randomNode_name

          generatabilityGraph.set_node(:name => edge[:to][:name], :type => edge[:to][:type],
                                       :importance => edge[:to][:importance]+edge[:weight]*edge[:from][:importance])

        end

      end
      generatabilityGraph.neighbours(default_node).each do |each_edge|
        #print "\n"
        #print each_edge[:to][:importance]
        currentTotalCash=currentTotalCash+each_edge[:to][:importance]
      end
=begin
			#print "\n"
			#print "\n"
			#print prevTotalCash
			#print "\t"
			#print currentTotalCash
=end
      iteration=iteration+1
      if currentTotalCash.round(2)==prevTotalCash.round(2) || iteration>min_loop_count
        break
      end
      #printNodes(generatabilityGraph)
    end
    #print "\n"
    #print prevTotalCash
    #print "\t"
    #print currentTotalCash
    #print "\n"
    #print nodeNames
    #printNodes(generatabilityGraph)
    #print "number of iterations is: "
    #print iteration
    nodeNames_cash=Array.new
    generatabilityGraph.neighbours(default_node).each do |edge|
      if edge[:to][:name]!= 'default'
        nodeNames_cash.push(edge[:to][:name])
        nodeNames_cash.push(edge[:to][:importance])
      end
    end
    nodeNames_cash = nodeNames_cash.each_slice(2).to_a
    nodeNames_cash = nodeNames_cash.sort_by { |nodeNames_cash| -nodeNames_cash[1] }
    topicalAnchor = nodeNames_cash[0][0]
    assignCashToNodes(generatabilityGraph, Array.new, cash)
    generatabilityGraph.close
    return nodeNames_cash

  end
end
###########################################################################################################################################
#a=["fever","disease","vaccine","zinc"]
o=GetGeneratabilityGraph.new
o.getGeneratabilityGraph(["fever"])

