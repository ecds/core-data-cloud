records = CoreDataConnector::Place.where(project_model_id: 6)
attrs.each do |a|
  records.each do |record|
    center = Ecds::Helpers.point(record.place_geometry.geometry)
    distance = RGeo::Geographic.spherical_factory.point(a[:longitude].to_f, a[:latitude].to_f).distance(center)
    maybe.push({geoname: a[:name], coredata: record.name}) if distance < 2
  end
end; nil

no_match = []
attrs.each do |a|
  records.each do |record|
    next unless record.web_identifiers.find_by(web_authority: geonames)
    no_match.push({geoname_id: a[:gn_id], geoname: a[:name], coredata_id: record.id, coredata: record.name})
  end
end; nil


attrs.each do |a|
  records.each do |record|
    maybe_names.push({geoname: a[:name], coredata: record.name}) if a[:name].parameterize == record.name.parameterize
  end
end; nil

maybe_names.each do |name|
  record = CoreDataConnector::Place.find(name[:coredata_id])
  next unless record.web_identifiers.find_by(web_authority: web_auth).nil?
  CoreDataConnector::WebIdentifier.create(web_authority: web_auth, identifiable: record, identifier: name[:geoname_id])
end; nil

CoreDataConnector::WebIdentifier.where(web_authority: geonames).each do |web_identifier|
  record = CoreDataConnector::Place.find(web_identifier.identifiable_id)
  next unless record.web_identifiers.find_by(web_authority: wikidata).nil?
  geonames_auth = CoreDataConnector::Authority::Geonames.new
  geonames_data = geonames_auth.find(web_identifier.identifier).deep_symbolize_keys
  next if geonames_data[:alternateNames].nil?
  wiki_id = geonames_data[:alternateNames].find {|an| an[:lang] == 'wkdt'}
  next if wiki_id.nil?
  puts wiki_id[:name]
  CoreDataConnector::WebIdentifier.create(web_authority: wikidata, identifiable: record, identifier: wiki_id[:name])
end

CoreDataConnector::WebIdentifier.where(web_authority: wikidata).each do |web_identifier|
  record = CoreDataConnector::Place.find(web_identifier.identifiable_id)
  next unless record.web_identifiers.find_by(web_authority: viaf).nil?

  wd_auth = CoreDataConnector::Authority::Wikidata.new
  wd_data = wd_auth.find(web_identifier.identifier).deep_symbolize_keys
  next if wd_data[:entities][web_identifier.identifier.to_sym][:claims][:P214].nil?

  wd_data[:entities][web_identifier.identifier.to_sym][:claims][:P214].each do |p214|
    viaf_id = p214[:mainsnak][:datavalue][:value]
    puts viaf_id
    CoreDataConnector::WebIdentifier.create(web_authority: viaf, identifiable: record, identifier: viaf_id)
  end
end

wd_auth = CoreDataConnector::Authority::Wikidata.new
existing_wd = CoreDataConnector::WebIdentifier.where(web_authority_id: 1).map(&:identifiable_id)

CoreDataConnector::Place.all.each do |place|
  next if existing_wd.includes(place.id)
  wd = wd_auth.search(place.name).deep_symbolize_keys
  match = wd[:search].find { |r| r[:label] == place.name }
  next if match.nil?
  puts place.name
  CoreDataConnector::WebIdentifier.create(web_authority: wd_auth, identifiable: place, identifier: match[:id])
end; nil

maps.each do |map|
  next unless map.user_defined['66578ed8-65e6-4b5b-b6b7-20526a5d9f12'].nil?
  date = {
    range: false,
    accuracy: 0,
    end_date: Date.parse("1-1-#{map.name.scan(/\d/).join('').to_i + 1}"),
    start_date: Date.parse("1-1-#{map.name.scan(/\d/).join('')}"),
    description: ""
  }
  map.update(user_defined: {'66578ed8-65e6-4b5b-b6b7-20526a5d9f12': date})
end

maps.each do |m|
  next if m.relationships.where(project_model_relationship_id: 15).empty?
  rel = m.relationships.find_by(project_model_relationship_id: 15)
  rel.update(
    project_model_relationship_id: 10,
    primary_record_id: rel.related_record_id,
    related_record_id: rel.primary_record_id
  )
end; nil

media.each do |medium|
  # puts medium.name
  name = medium.name.remove(/\..*/)
  parts = name.split('_')
  next if parts.count == 1
  d = parts.pop
  next if d.length < 6
  parts.reject! {|p| p =~ /\d\d\d\d/ || p.length == 1}
  date = Date.parse(d.split('-')[-1].scan(/\d/).join)
  puts("#{parts.join(' ').titleize} : #{date.strftime}")
  hash = Hash.new
  hash['1032d8d1-0e6b-4669-a8c7-045c554ba2de'] = date.strftime
  puts medium.user_defined.merge(hash)
  medium.update(name: "#{parts.join(' ').titleize}", user_defined: medium.user_defined.merge(hash))
end

media.each do |medium|
  next if medium.user_defined.keys.include? '1032d8d1-0e6b-4669-a8c7-045c554ba2de'
  name = medium.name.remove(/\..*/)
  parts = name.split('_')
  parts.reject! {|p| p =~ /\d\d\d\d/ || p.length == 1}
  new_name = parts.join.titleize
  next if new_name.empty?
  puts new_name
end

topics = CoreDataConnector::Taxonomy.where(project_model_id: 13).to_a.to_a
rels = CoreDataConnector::Relationship.where(project_model_relationship_id: 39).to_a
parents = topics.reject {|t| rels.map(&:related_record).include? t}

parents.each {|t| topics.delete(t)}


response = HTTParty.post(
  'https://coredata.ecds.io/core_data/media_contents',
  {

  }
)


require 'uri'
require 'net/http'

url = URI("https://coredata.ecds.io/core_data/media_contents")

https = Net::HTTP.new(url.host, url.port)
https.use_ssl = true
failed = []

request = Net::HTTP::Post.new(url)
request['Authorization'] = 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJpZCI6MSwiZXhwIjoxNzQ3NzQzNjIyfQ.AQvOWDMlf2ZV9hJK4JjuOasapFmMEfRSCfcUgqRH29c'
files = Dir.entries('./')
files.each do |file|
  puts file
  next unless file.end_with? '.tiff'

  form_data = [
    ['media_content[project_model_id]', '28'],
    ['media_content[name]', File.basename(file, '.tiff')],
    ['media_content[content]', File.open(file)]
  ]
  request.set_form form_data, 'multipart/form-data'
  begin
    response = https.request(request)
    puts response.read_body
  rescue
    failed.push(file)
  end
end


# gdal_translate -co PHOTOMETRIC=RGB -b 1 -b 1 -b 1 -of GTiff -ot UInt16 ~/Downloads/chatham/Chatham_1953_raster.tif ~/Downloads/dot_maps/ChathamCounty/32617/Chatham1972.tiff
# gdal_translate -co 'GDAL_PAM_ENABLED=NO' -expand rgba ~/Downloads/dot_maps/BryanCounty/32617/Bryan1972.tiff ~/Downloads/dot_maps/BryanCounty/32617/Bryan1972.tif
# gdal_translate -co 'GDAL_PAM_ENABLED=NO' -expand rgba ~/Downloads/chatham/Chatham_1953_raster.tif ~/Downloads/dot_maps/ChathamCounty/32617/Chatham1953.tif
# gdalwarp -s_srs EPSG:32617 -t_srs EPSG:3857 -r average -co 'TILED=YES' -co 'BLOCKXSIZE=256' -co 'BLOCKYSIZE=256' -co 'COMPRESS=DEFLATE' ~/Downloads/dot_maps/ChathamCounty/32617/Chatham1953.tif ~/Downloads/dot_maps/ChathamCounty/3857/Chatham1953.tiff
# gdaladdo --config GDAL_TIFF_OVR_BLOCKSIZE 256 -r average ~/Downloads/dot_maps/ChathamCounty/3857/Chatham1953.tiff 2 4 8 16 32

# for FILE in ./BryanCounty/32617/*.tif;
#   do
#     echo "${$(basename $FILE .tif)}.tiff";
#     gdalwarp -s_srs EPSG:32617 -t_srs EPSG:3857 -r average -co 'TILED=YES' -co 'BLOCKXSIZE=256' -co 'BLOCKYSIZE=256' -co 'COMPRESS=JPEG' "$FILE" "./BryanCounty/3857/${$(basename $FILE .tif)}.tiff";
#     gdaladdo --config GDAL_TIFF_OVR_BLOCKSIZE 256 -r average "./BryanCounty/3857/${$(basename $FILE .tif)}.tiff" 2 4 8 16 32;
#   done
