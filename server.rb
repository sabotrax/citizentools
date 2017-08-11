#!/usr/bin/env ruby

#
# citizentools - API fuer Star Citizen
#
# Copyright 2017 marcus@dankesuper.de
#
# This file is part of citizenzools.

# citizenzools is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# citizenzools is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with citizenzools.  If not, see <http://www.gnu.org/licenses/>.

require "logger"
require "json"
require 'sinatra'
require "sinatra/namespace"
require "sinatra/reloader"

require "nokogiri"
require "open-uri"

set :environment, :development
set :bind, "0.0.0.0"
#set :environment, :production
configure :development do
    register Sinatra::Reloader
end

logger = Logger.new('./log/citizentools.log')

namespace '/ct/api/v1' do

  before do
    content_type 'application/json'
  end

  get '/citizen/:citizen' do |citizen|
    logger.info "#{request.ip} #{request.path} #{request.query_string}"
    citizen.downcase!
    begin
      page = Nokogiri::HTML(open("https://robertsspaceindustries.com/citizens/#{citizen}"))
    rescue => e
      halt(404, 'Citizen not found.')
    end
    data = []
    data = page.css('title').text.split('|')
    # keine Org
    if data.size < 3
      data[1] = ""
      data[2] = ""
    end
    citizen_record = page.css('p.entry.citizen-record strong.value').text
    enlisted = page.css('div.left-col div.inner p.entry strong.value')[2].text
    # datum formatieren
    enlisted =~ /(\w{1,3}) (\d{1,2}), (\d{4})/
    month = {
      "Jan"	=> "01",
      "Feb"	=> "02",
      "Mar"	=> "03",
      "Apr"	=> "04",
      "May"	=> "05",
      "Jun"	=> "06",
      "Jul"	=> "07",
      "Aug"	=> "08",
      "Sep"	=> "09",
      "Oct"	=> "10",
      "Nov"	=> "11",
      "Dec"	=> "12"
    }
    # TODO
    # enlisted_iso auf korrekte form testen
    # helper auslagern
    # test fuer enlisted schreiben
    # auf bundler.require umstellen
    enlisted_iso = $3.to_s + month[$1] + "%02d" % $2
    user = {
      :handle	=> data[0].strip,
      :citizen_record => citizen_record.sub(/^#/, '').strip,
      :enlisted	=> enlisted_iso,
      :org	=> data[1].sub(/^.+ - /, '').strip,
      :sid	=> data[2].sub(/\).*/, ')').strip,
    }
    user.to_json
  end

  get '/org/:sid' do |sid|
    logger.info "#{request.ip} #{request.path} #{request.query_string}"
    sid.downcase!
    begin
      page = Nokogiri::HTML(open("https://robertsspaceindustries.com/orgs/#{sid}"))
    rescue => e
      halt(404, 'SID not found.')
    end
    title = page.css('title').text
    title =~ /^(.+) \[.+/
    title = $1
    members = page.css('span.count').text
    archetype = page.css('li.model').text
    pactivity = page.css('li.primary.tooltip-wrap div.content').text
    sactivity = page.css('li.secondary.tooltip-wrap div.content').text
    commitment = page.css('li.commitment').text
    roleplay = page.css('li.roleplay').text
    emembership = page.css('li.exclusive').text
    logo = page.css('div.logo.noshadow img').attr('src').text
    org = {
      #:name	=> title.sub(/\[.+/, "").strip,
      :name	=> title.strip,
      :members	=> members.sub(/ .+$/, "").strip,
      :archetype => archetype,
      :primary_activity => pactivity,
      :secondary_activity => sactivity,
      :commitment => commitment,
      :roleplay => roleplay != "" ? roleplay : "No",
      :exclusive_membership => emembership != "" ? emembership :"No",
      :logo => logo,
    }
    org.to_json
  end

end
