#!/bin/usr/env ruby
require 'nokogiri'
require 'fileutils'
require 'json'
require 'time'
require 'pp'

module View
  class Entry < Struct.new(:entry_url, :title, :abstract_html, :icon_url, :published_at)
    def initialize(entry_url, title, abstract_html, icon_url, published_at)
      if entry_url.nil?
        STDERR.puts 'entry_urlがありません:'
        raise ArgumentError
      end
      if title.nil?
        STDERR.puts 'titleがありません:'
        raise ArgumentError
      end
      if published_at.nil?
        STDERR.puts 'published_atがありません:'
        raise ArgumentError
      end
      super(entry_url, title, abstract_html, icon_url, Time.parse(published_at))
    end

    def abstract
      unless self.abstract_html.nil?
        Nokogiri::HTML(self.abstract_html).text
      end
    end

    alias :old_published_at :published_at
    def published_at
      old_published_at.strftime('%Y-%m-%d %H:%M')
    end

    alias :old_to_h :to_h
    def to_h
      old_to_h.merge(abstract: self.abstract, published_at: self.published_at)
    end
  end

  class SourceFeed
    attr_reader :feed_id, :title, :feed_url, :icon_url, :blog_url

    def initialize(feed_id, title, feed_url, icon_url, blog_url)
      @feed_id = feed_id
      @title = title
      @feed_url = feed_url
      @icon_url = icon_url
      @blog_url = blog_url
    end
  end
end

ENTRY_COUNT = 50.freeze

entries_json_string = STDIN.read
entries = JSON.parse(entries_json_string)['entries'].map do |e|
  begin
    View::Entry.new(
      e['entry_url'],
      e['title'],
      e['abstract'],
      e['icon_url'],
      e['published_at']
    )
  rescue ArgumentError
    STDERR.puts "#{e.pretty_inspect}"
    exit(status=1)
  end
end.sort_by(&:published_at).reverse.first(ENTRY_COUNT)

puts JSON.dump(entries.map(&:to_h))
