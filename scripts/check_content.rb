#!/usr/bin/env ruby

require "date"
require "yaml"

allowed_categories = %w[blog slides life]
files = Dir["_posts/*.md"] + Dir["_drafts/*.md"]
abort "没有找到 Markdown 内容" if files.empty?

files.each do |path|
  source = File.read(path)
  front_matter = source.match(/\A---\s*\n(.*?)\n---\s*\n/m)&.[](1)
  abort "缺少 YAML 头部：#{path}" unless front_matter

  data = YAML.safe_load(front_matter, [Date, Time], [], true)
  missing = %w[layout title date category].reject { |key| data[key] }
  abort "缺少 #{missing.join(', ')}：#{path}" unless missing.empty?
  abort "分类必须是 blog、slides 或 life：#{path}" unless allowed_categories.include?(data["category"])
end

Dir["_posts/*.md"].each do |path|
  abort "文章文件名必须以 YYYY-MM-DD- 开头：#{path}" unless File.basename(path).match?(/\A\d{4}-\d{2}-\d{2}-.+\.md\z/)
end

{ "blog.html" => "blog", "slides.html" => "slides", "life.html" => "life" }.each do |page, category|
  expected = "include content-list.html category=\"#{category}\""
  abort "#{page} 没有读取 #{category} 文章" unless File.read(page).include?(expected)
end

puts "Markdown 内容检查通过（#{files.size} 个文件）"
