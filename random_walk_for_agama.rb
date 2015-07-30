#!/user/bin/ruby



RW_CASH_DIFF_THRESHOLD = 0.000000000000000000000001

class RandomWalkForSM
  MAX_CASH_THRESHOLD = 1.0


  #################################################################################################
  #
  # start_nodes -- Hash <Key, Initial Cash>
  #################################################################################################
  public
  def random_walk (graph, start_nodes)
    current_cash = {}
    current_history = {}
    previous_history = {}
    initialize_cash(graph, current_cash, current_history, previous_history, start_nodes)

    begin # do while 1
      historysum = 0
      random_sequence_of_terms = current_cash.keys.shuffle

      random_sequence_of_terms.each_with_index do |t1, i| # loop 2
        previous_history[t1] = current_history[t1]
        current_history[t1] = current_history[t1] + current_cash[t1]

        graph[t1].each do |edge| #loop 3
          begin
            current_cash[edge[:t2]] = current_cash[edge[:t2]] + edge[:gen] * current_cash[edge[:t1]]
          rescue Exception => e
            puts e.inspect
            puts edge.inspect
            puts "!!!!!!!>>>><<<<<<!!!!!#{current_cash[edge[:t2]].inspect}\t#{edge[:gen].inspect}\t#{current_cash[edge[:t1]].inspect}"
            exit 1
          end
        end
        historysum = historysum + current_history[t1]
        current_cash[t1] = 0.0
      end # random_sequence

      current_history.keys.each do |key|
        current_history[key] = (current_history[key] * MAX_CASH_THRESHOLD / historysum)
      end
    end while (!is_stationary_distribution_achieved(current_history, previous_history))

    current_history = current_history.sort_by { |k, v| v }.reverse
    #puts current_history.inspect
    return current_history #returning it
  end

  private
  #################################################################################################
  # Method
  #
  #################################################################################################
  def initialize_cash(graph, current_cash_distribution, current_cash_history, previous_cash_history, start_nodes_cash)
    # set everything to 0.0
    graph.keys.each do |key|
      current_cash_history[key] = 0.0
      previous_cash_history[key] = 0.0
      current_cash_distribution[key] = 0.0
    end

    #if no specific term has to be assigned cash, then assign equal cash to all terms in the graph.
    #esle, assign cash to only those specific terms mentioned in hash - "start_nodes_cash"
    if start_nodes_cash == nil
      current_cash_distribution.keys.each do |key|
        current_cash_distribution[key] = (MAX_CASH_THRESHOLD/(current_cash_distribution.keys.length.to_f)) #to_i
      end
    else
      start_nodes_cash.keys.each do |key|
        if current_cash_distribution.has_key? key # if the term is in graph, then
          cash = start_nodes_cash[key] * MAX_CASH_THRESHOLD
          if cash == nil
            cash = MAX_CASH_THRESHOLD/start_nodes_cash.length
            puts  "No cash provided for #{key} Default cash is ' #{cash}"
          end
          current_cash_distribution[key] = cash.to_f
        else # if the term is not in graph, then
          puts "Term '#{key}' is not found. Exiting....."
          exit -1
        end
      end
    end
  end

  #################################################################################################
  #
  #
  #################################################################################################
  def is_stationary_distribution_achieved (current_cash_history, previous_cash_history)
    current_cash_history.each do |term, cash|
      previous_cash = previous_cash_history[term]
      puts "#{term} has cash nil!" if previous_cash.nil?

      if (previous_cash - cash).abs > (MAX_CASH_THRESHOLD * RW_CASH_DIFF_THRESHOLD)
        return false
      end
    end

    true
  end

end
