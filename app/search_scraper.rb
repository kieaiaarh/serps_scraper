require 'open-uri'
require 'uri'
require 'pry'
require "ruby-progressbar"
require "csv"
require 'dotenv/load'

SITE_URL = ENV['SITE_URL'].freeze
USER_AGENTS = [
  'Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_2 like Mac OS X) AppleWebKit/603.2.4 (KHTML, like Gecko) Version/10.0 Mobile/14F89 Safari/602.1',
  'Mozilla/5.0 (Linux; U; Android 4.0.1; ja-jp; Galaxy Nexus Build/ITL41D) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30']
user_agent = USER_AGENTS.sample

class FileReader
  SRC = 'src/keywords.txt'.freeze

  def read_contents
    lines = []
    File.open(SRC, 'r:utf-8') do |f|
      f.each_line do |line|
        lines << line.chomp
      end
    end
    lines
  end
end

handler = FileReader.new
keywords = handler.read_contents

URL = 'https://www.google.co.jp/search?q='.freeze

pb = ProgressBar.create(:title => "keywords_scraping", :starting_at => 0, :total => keywords.size, :output => $stderr)
lines = []
lines << [user_agent]
p user_agent

ng = []

keywords.each.with_index(1) do |keyword, index|
  url = URI.escape("#{URL}#{keyword}")

  charset = nil
  html = open(url, "User-Agent" => user_agent) do |f|
    charset = f.charset
    f.read
  end

  strings = html.scan(%r{<h3 class="r">(.+?)</h3>})
  length = strings.length

  unless strings.flatten.join().include?(SITE_URL)
    ng << [keyword]
    next;
  end

  for i in 0...length do
    url, title = (strings[i][0].scan(%r{<a.+href="(.+?)".+?>(.+?)</a>}))[0]
    if url&.include?(SITE_URL)
      position = i + 1
      p "#{position}位：#{keyword} -> #{title} #{url}"
      lines << ["#{position}位", keyword, url]
    end
  end

  pb.increment
  sleep 0.1
end
pb.finish

OUT = './dist'.freeze
CSV.open("#{OUT}/keywords.csv",'wb') do |file|
  lines.each do |line|
    file << line
  end
end
CSV.open("#{OUT}/not_first_page_keywords.csv",'wb') do |file|
  ng.each do |line|
    file << line
  end
end
