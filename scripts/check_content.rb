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

  if data["cover_image"]
    cover_path = data["cover_image"].delete_prefix("/")
    abort "找不到封面 #{data['cover_image']}：#{path}" unless File.file?(cover_path)
  end

  source.scan(/!\[([^\]]*)\]\(<([^>]+)>\)/).each do |alt, url|
    abort "图片缺少说明文字：#{path}" if alt.strip.empty?
    image_path = url.delete_prefix("/")
    abort "找不到图片 #{url}：#{path}" unless File.file?(image_path)
  end
end

Dir["_posts/*.md"].each do |path|
  abort "文章文件名必须以 YYYY-MM-DD- 开头：#{path}" unless File.basename(path).match?(/\A\d{4}-\d{2}-\d{2}-.+\.md\z/)
end

{ "blog.html" => "blog", "slides.html" => "slides", "life.html" => "life" }.each do |page, category|
  expected = "include content-list.html category=\"#{category}\""
  abort "#{page} 没有读取 #{category} 文章" unless File.read(page).include?(expected)
end

(Dir["*.html"] + Dir["_layouts/*.html"]).each do |path|
  source = File.read(path)
  source.scan(/<link rel="stylesheet" href="([^"]*style\.css[^"]*)"/).flatten.each do |href|
    abort "页面不会处理样式版本：#{path}" unless path.start_with?("_layouts/") || source.start_with?("---\n")
    abort "样式地址缺少缓存版本：#{path}" unless href.include?("?v=")
  end
end

abort "文章正文不能整体使用 data-reveal，否则长文章可能永远不可见" if File.read("_layouts/post.html").match?(/class="article-content"[^>]*\bdata-reveal\b/)

puts "Markdown 内容检查通过（#{files.size} 个文件）"
