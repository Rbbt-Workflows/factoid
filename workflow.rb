require 'rbbt-util'
require 'rbbt/workflow'
require 'rbbt/ner/segment/transformed'
require 'rbbt/ner/segment/docid'

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), 'lib')))

Workflow.require_workflow "Genomics"
require 'rbbt/entity/pmid'
require 'factoid'

module Factoid
  extend Workflow

  CORPUS = Persist.open_tokyocabinet(File.join(File.dirname(__FILE__), 'corpora', 'Factoid.corpus'), false, :string, TokyoCabinet::BDB)
  ANNOTATION_REPO = Persist.open_tokyocabinet(File.join(File.dirname(__FILE__), 'annotations', 'Factoid.repo'), false, :list, TokyoCabinet::BDB)

  NORMALIZE = true
  ORGANISM = "Hsa/jun2011"

  input :text, :text, "Document text"
  returns "Document ID"
  task :add_doc => :string do |text|
    raise "No text provided: #{text}" if text.nil?
    text = Document.setup(text.dup)
    text.text
    text.docid
  end

  input :pmid, :string, "Pubmed ID"
  input :type, :string, "Type: abstract or full_text", :abstract
  returns "Document ID"
  task :add_pmid => :string do |pmid, type|
    pmid = PMID.setup(pmid.dup)
    pmid.text(type)
    pmid.docid(type)
  end

  input :list, :array, "Pubmed ID"
  input :type, :string, "Type: abstract or full_text", :abstract
  returns "Document ID"
  task :add_pmid_list => :yaml do |list, type|
    list = PMID.setup(list.dup)
    list.text(type)
    Misc.zip2hash(list, list.docid(type))
  end

  input :docid, :string, "Document ID"
  task :abner => :annotations do |docid|
    doc = Document.setup(docid)
    doc.abner(NORMALIZE, ORGANISM).each{|a| SegmentWithDocid.setup(a, docid)} 
  end

  input :docid, :string, "Document ID"
  task :banner => :annotations do |docid|
    doc = Document.setup(docid)
    doc.banner(NORMALIZE, ORGANISM).each{|a| SegmentWithDocid.setup(a, docid)}
  end

  input :docid, :string, "Document ID"
  input :organism, :string, "Organism codes", "Hsa"
  input :ignore_case, :boolean, "Ignore case on matching", true
  task :gene_names => :annotations do |docid,organism,ignore_case|
    doc = Document.setup(docid)
    doc.dictionary(organism, ignore_case).each{|a| SegmentWithDocid.setup(a, docid)}
  end

  input :docid, :string, "Document ID"
  task :species => :annotations do |docid|
    doc = Document.setup(docid)
    doc.species.each{|a| SegmentWithDocid.setup(a, docid)}
  end

  input :docid, :string, "Document ID"
  input :format, :select, "Format to normalize to", "Compound Name", TextMining.task_info(:compound_mention_recognition)[:input_options][:format]
  task :jochem => :annotations do |docid, format|
    doc = Document.setup(docid)
    doc.jochem(format).each{|a| SegmentWithDocid.setup(a, docid)}
  end

  input :docid, :string, "Document ID"
  task :sentences => :annotations do |docid|
    doc = Document.setup(docid)
    doc.sentences.each{|a| SegmentWithDocid.setup(a, docid)}
  end

  input :docid, :string, "Document ID"
  input :entity_types, :array, "Entities to process", [:dictionary]
  task :sentence_html => :array do |docid, entity_types|
    doc = Document.setup(docid)
    entities = entity_types.inject([]){|acc,type| acc += doc.send(type)}

    entities.each{|a| SegmentWithDocid.setup(a, docid)}                 

    entity_index = Segment.index(entities, Rbbt.var.segment_indices[docid][entity_types.collect{|e| e.to_s}.sort * ","].find)

    sentences = doc.sentences
    sentences.collect{|sentence|
      entities = entity_index[sentence.range]
      entities = Segment.clean_sort(entities)
      Transformed.transform(sentence, entities) do |entity|
        entity.respond_to?(:link) ? entity.link : entity.html
      end
    }
  end

  export_exec :add_doc, :add_pmid, :add_pmid_list, :species, :gene_names, :abner, :banner, :jochem, :sentences, :sentence_html
end

module Document
  self.corpus = Factoid::CORPUS

  persist :abner, :annotations, :annotation_repo => Factoid::ANNOTATION_REPO
  persist :banner, :annotations, :annotation_repo => Factoid::ANNOTATION_REPO
  persist :dictionary, :annotations, :annotation_repo => Factoid::ANNOTATION_REPO
  persist :jochem, :annotations, :annotation_repo => Factoid::ANNOTATION_REPO
  persist :species, :annotations, :annotation_repo => Factoid::ANNOTATION_REPO
  persist :sentences, :annotations
end

if __FILE__ == $0
  #docid = Factoid.job(:add_pmid, '', :pmid => "21828143", :type => :full_text).exec
  docid = "PMID:21343549:full_text"
  ddd Factoid.job(:sentence_html, '', :docid => docid, :entity_types => [:dictionary, :abner, :banner, :jochem]).exec

end
