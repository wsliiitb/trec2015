require 'nokogiri'
class ParseTopics

  ######################################################################################################################
  #
  #
  #
  ######################################################################################################################
  def self.readFile
    data=Hash.new
    page = Nokogiri::XML(File.open("../resource/topics2015A.xml"))
    page.xpath("//topics").each do |node|
      node.css("topic").each do |response_node|
        topic_number= response_node["number"]
        topic_type= response_node["type"]
        description=response_node.at_css("description").text
        summary=response_node.at_css("summary").text
        diagnosis = response_node.at_css("diagnosis")
        diagnosis = diagnosis.text if diagnosis!=nil
        data[topic_number]={"type" => topic_type, "description" => description, "summary" => summary, 'diagnosis' => diagnosis}
      end
    end
    data
  end # end of readfile
end

#p ParseTopics.readFile
