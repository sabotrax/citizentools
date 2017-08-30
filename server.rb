#!/usr/bin/env ruby

#
# citizentools - API fuer Star Citizen
#
# Copyright 2017 marcus@dankesuper.de
#
# This file is part of citizentools.

# citizenzools is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# citizenzools is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with citizentools.  If not, see <http://www.gnu.org/licenses/>.

# TODO

require "bundler"
require "logger"
require "open-uri"

Bundler.require

set :environment, :development
#set :environment, :production
set :bind, "0.0.0.0"
configure :development do
    register Sinatra::Reloader
end

logger = Logger.new("./log/citizentools.log")

namespace "/api/v1" do

  before do
    content_type "application/json"
  end

  helpers do
    def enlisted_to_iso(date)
      date =~ /(\w{1,3}) (\d{1,2}), (\d{4})/
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
      $3.to_s + month[$1] + "%02d" % $2
    end
  end

  get "/citizen/random_famous" do
    famous_citizen = %w(croberts68 discolando WLeverett_CIG boredgameruk proxus-cig Zyloh-CIG TylerN-CIG wcloaf).sample
    redirect "/ct/api/v1/citizen/#{famous_citizen}"
  end

  get "/citizen/:handle" do |handle|
    logger.info "#{request.ip} #{request.path} #{request.query_string}"
    handle.downcase!
    begin
      page = Nokogiri::HTML(open("https://robertsspaceindustries.com/citizens/#{handle}"))
    rescue => e
      halt 404, { status: 404, message: "Handle not found" }.to_json
    end
    title = page.css("title").text
    moniker, org, sid = /^(.+)\|(?: #{handle} - (.+)\|(.+) - .+| #{handle} - Roberts Space Industries)$/i.match(title).captures
    org = "" if org.nil?
    sid = "" if sid.nil?
    citizen_record = page.css("p.entry.citizen-record strong.value").text
    enlisted = page.css("div.left-col div.inner p.entry strong.value")[2].text
    # datum normalisieren
    enlisted_iso = enlisted_to_iso(enlisted)
    fluency = page.css("div.left-col div.inner p.entry strong.value")[4]
    if fluency.nil?
      fluency = []
    else
      fluency = fluency.text.split(",")
      fluency.map! {|i| i.strip }
    end
    user = {
      :moniker => moniker.strip,
      :citizen_record => citizen_record.sub(/^#/, "").strip,
      :enlisted	=> enlisted_iso,
      :fluency => fluency,
      :org => org.strip,
      :sid => sid.strip
    }
    user.to_json
  end

  get "/org/:sid" do |sid|
    logger.info "#{request.ip} #{request.path} #{request.query_string}"
    sid.downcase!
    begin
      page = Nokogiri::HTML(open("https://robertsspaceindustries.com/orgs/#{sid}"))
    rescue => e
      halt 404, { status: 404, message: "SID not found" }.to_json
    end
    title = page.css("title").text
    title =~ /^(.+) \[.+/
    title = $1
    members = page.css("span.count").text
    archetype = page.css("li.model").text
    pactivity = page.css("li.primary.tooltip-wrap div.content").text
    sactivity = page.css("li.secondary.tooltip-wrap div.content").text
    commitment = page.css("li.commitment").text
    roleplay = page.css("li.roleplay").text
    emembership = page.css("li.exclusive").text
    logo = page.css("div.logo.noshadow img")
    # Element fehlt, wenn es nur das Standard-Logo gibt
    if logo.empty?
      logo = ""
    else
      logo = logo.attr("src").text
    end
    org = {
      :name => title.strip,
      :members => members.sub(/ .+$/, "").strip,
      :archetype => archetype,
      :primary_activity => pactivity,
      :secondary_activity => sactivity,
      :commitment => commitment,
      :roleplay => roleplay != "" ? roleplay : "No",
      :exclusive_membership => emembership != "" ? emembership : "No",
      :logo => logo,
    }
    org.to_json
  end

end

# Redirects fuer alte API
namespace "/vakss/api/v1" do

  get "/citizen/:handle" do |handle|
    redirect "/ct/api/v1/citizen/#{handle}", 301
  end

  get "/org/:sid" do |sid|
    redirect "/ct/api/v1/org/#{sid}", 301
  end

end

namespace "/api/v2" do

  before do
    content_type "application/json"
  end

  get "/citizen/:handle" do |handle|
    logger.info "#{request.ip} #{request.path} #{request.query_string}"
    handle.downcase!

    # v1-Daten holen
    status, headers, body = call env.merge("PATH_INFO" => "/api/v1/citizen/#{handle}")
    #if status == "200"
      #logger.info "tach"
      citizen = JSON.parse(body.shift)
    #else
      #logger.info "nope"
      #halt [status, headers, body.map]
    #end

    logger.info citizen
    citizen["orgs"] = []
    if citizen["org"]
      citizen["orgs"].push({
	"org" => citizen["org"],
	"sid" => citizen["sid"].sub(/ .+$/, "")
      })
    end
    %w{ org sid }.each{ |k| citizen.delete(k) }

    # Daten um Nebenorganisationen erweitern
    begin
      logger.info handle
      page = Nokogiri::HTML(open("https://robertsspaceindustries.com/citizens/#{handle}/organizations"))
    rescue => e
      halt 404, { status: 404, message: "Handle not found" }.to_json
    end
    page.css("div.box-content.org.affiliation").each do |affil|
      info = affil.css("div.inner-bg.clearfix div.left-col div.inner.clearfix div.info")
      citizen["orgs"].push({
	"org" => info.css("p.entry.orgtitle a.value").text,
	"sid" => info.css("p.entry strong.value")[0].text
      })
    end
    citizen.to_json
  end

end
