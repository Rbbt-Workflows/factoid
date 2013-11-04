require 'rbbt/entity'
require 'rbbt/entity/gene'

#$pmid_organism = {}
#$pmid_organism_mentions = {}
#
#get '/process/:pmid' do
#  pmid = params[:pmid]
#  if ($pmid_organism[pmid].nil? or params.include? 'update_species')
#    workflow_render('select_species', Factoid, params)
#  else
#    organisms = $pmid_organism[pmid]
#    pending_organisms = organisms.reject{|organism| $pmid_organism_mentions.include? organism}
#    organism = pending_organisms.first
#    if organism.nil?
#    else
#      workflow_render('select_organism_mentions', Factoid, params.merge(:organism => organism))
#    end
#  end
#end

#post '/select_species/:pmid' do
#  pmid = params[:pmid]
#  organisms = []
#  all_organism = Organism.installable_organisms
#  params.each do |key, value|
#    if all_organism.include? key and value == 'on'
#      organisms << key
#    end
#  end
#  $pmid_organism[pmid] = organisms
#  redirect File.join('/process', pmid)
#end


class Sinatra::Base
  before do
    @file_cache = {}
    @result_cache = {}
    headers "AJAX-URL" => request.env["REQUEST_URI"]

    params[:_format] = params[:resformat] if params[:resformat]
    # CrossOrigin
    headers 'Access-Control-Allow-Origin' => request.env['HTTP_ORIGIN'],
      'Access-Control-Allow-Methods' => %w(GET POST OPTIONS), 
      'Access-Control-Allow-Credentials' => "true",
      'Access-Control-Max-Age' => "1728000"
  end

  get '/process/:pmid' do
    pmid = params[:pmid]

    kb = KnowledgeBase.new user
    kb.define :pmid_organisms, :array
    kb.define :pmid_organism_mentions, :annotations

    organisms = kb.pmid_organisms pmid

    if organisms.nil? or params.include? 'update_species'
      template_render('select_species', params)
    else
      pending_organisms = organisms.select{|organism| kb.pmid_organism_mentions([pmid, organism]).nil?}
      organism = pending_organisms.first
      if organism.nil?
        template_render('done', params)
      else
        article = PMID.setup(pmid)
        mentions = article.dictionary(organism, true)
        #workflow_render('select_organism_mentions', Factoid, params.merge(:organism => organism, :mentions => mentions, :article => article))
        template_render('select_organism_mentions', params.merge(:organism => organism, :mentions => mentions, :article => article))
      end
    end
  end

  post '/select_species/:pmid' do
    pmid = params[:pmid]

    kb = KnowledgeBase.new user
    kb.define :pmid_organisms, :array

    organisms = []
    all_organism = Organism.installable_organisms
    params.each do |key, value|
      if all_organism.include? key and value == 'on'
        organisms << key
      end
    end

    kb.set_pmid_organisms pmid, organisms

    redirect File.join('/process', pmid)
  end

  post '/select_organism_mentions/:pmid' do
    pmid = params[:pmid]
    organism = params[:organism]

    article = PMID.setup(pmid)
    all_mentions = article.dictionary(organism, true)

    kb = KnowledgeBase.new user

    mentions = []

    params.each do |key, value|
      if value == 'on'
        mentions << key
      end
    end

    kb.set_pmid_organism_mentions [pmid, organism], all_mentions.select{|m| mentions.include? m.id}

    redirect File.join('/process', pmid)
  end
end

$title = "Factoid Web Server"
