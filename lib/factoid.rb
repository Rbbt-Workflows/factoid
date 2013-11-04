require 'rbbt'
require 'rbbt/workflow'
require 'rbbt/entity/document'
require 'rbbt/bow/misc'

Workflow.require_workflow "TextMining"

module Document

  property :banner do |*args|
    normalize, organism = args
    TextMining.job(:gene_mention_recognition, "Factoid", :text => text, :method => :banner, :normalize => normalize, :organism => organism).exec.reject{|m| $stopwords.include? m.downcase}
  end

  property :abner do |*args|
    normalize, organism = args
    TextMining.job(:gene_mention_recognition, "Factoid", :text => text, :method => :abner, :normalize => normalize, :organism => organism).exec.reject{|m| $stopwords.include? m.downcase}
  end

  property :species do |*args|
    normalize, organism = args
    TextMining.job(:species_mention_recognition, "Factoid", :text => text).exec.reject{|m| $stopwords.include? m.downcase}.each{|m| 
      taxid = m.code.first.split(":").last
      begin
        organism = Organism.entrez_taxid_organism(taxid)
        m.code.replace [organism]
      rescue
        Log.debug $!.message
      end
    }
  end

  property :dictionary do |*args|
    organism, ignore_case = args
    ignore_case = false if ignore_case.nil?
    TextMining.job(:gene_mention_recognition, "Factoid", :text => text, :method => :dictionary, :normalize => false, :organism => organism, :ignore_case => ignore_case).exec.reject{|m| $stopwords.include? m.downcase}
  end

  property :jochem do |*args|
    format = args[0]
    TextMining.job(:compound_mention_recognition, "Factoid", :text => text, :method => :JoChem, :format => format).exec.reject{|m| $stopwords.include? m.downcase}
  end

  property :sentences do 
    TextMining.job(:split_sentences, "Factoid", :text => text).exec
  end
end

