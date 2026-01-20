#!/usr/bin/env ruby

require "yaml"
require "fileutils"

DEFAULT_MENU_PATH = File.expand_path("../menu/menu.yml", __dir__)
DEFAULT_OUTPUT_PATH = File.expand_path("../dist/index.html", __dir__)

def abort_with(message)
  warn(message)
  exit(1)
end

def validate_menu!(data)
  abort_with("YAML root must be a mapping with a 'menu' key.") unless data.is_a?(Hash) && data["menu"].is_a?(Hash)

  menu = data["menu"]
  title = menu["title"]
  sections = menu["sections"]

  abort_with("'menu.title' must be a non-empty string.") unless title.is_a?(String) && !title.strip.empty?
  abort_with("'menu.sections' must be an array.") unless sections.is_a?(Array) && !sections.empty?

  sections.each_with_index do |section, index|
    abort_with("Section #{index + 1} must be a mapping.") unless section.is_a?(Hash)
    abort_with("Section #{index + 1} is missing a 'name'.") unless section["name"].is_a?(String) && !section["name"].strip.empty?
    items = section["items"]
    abort_with("Section '#{section['name']}' must have an 'items' array.") unless items.is_a?(Array) && !items.empty?

    items.each_with_index do |item, item_index|
      abort_with("Item #{item_index + 1} in section '#{section['name']}' must be a mapping.") unless item.is_a?(Hash)
      abort_with("Item #{item_index + 1} in section '#{section['name']}' is missing a 'name'.") unless item["name"].is_a?(String) && !item["name"].strip.empty?
      price = item["price"]
      price_valid = price.is_a?(String) && !price.strip.empty?
      price_valid ||= price.is_a?(Hash) && !price.empty? && price.values.all? { |value| value.is_a?(String) && !value.strip.empty? }
      abort_with("Item '#{item['name']}' in section '#{section['name']}' has invalid price.") unless price_valid
    end
  end

  menu
end

def format_price(price)
  return price if price.is_a?(String)

  price.map { |size, value| "#{size}: #{value}" }.join(" / ")
end

def build_html(menu)
  title = menu["title"]
  sections_html = menu["sections"].map do |section|
    items_html = section["items"].map do |item|
      description_html = if item["description"] && !item["description"].strip.empty?
        "<div class=\"item-description\">#{item['description']}</div>"
      else
        ""
      end

      <<~HTML
        <div class="menu-item">
          <div class="item-header">
            <div class="item-name">#{item['name']}</div>
            <div class="item-price">#{format_price(item['price'])}</div>
          </div>
          #{description_html}
        </div>
      HTML
    end.join

    <<~HTML
      <section class="menu-section">
        <div class="section-title">#{section['name'].upcase}</div>
        <div class="section-items">
          #{items_html}
        </div>
      </section>
    HTML
  end.join

  <<~HTML
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>#{title}</title>
        <style>
          :root {
            --ink: #1f1f1f;
            --panel: #e9ecf2;
            --panel-border: #c6c9d1;
            --accent: #c2453a;
            --header-bg: #111111;
            --header-text: #f5f5f5;
          }

          * {
            box-sizing: border-box;
          }

          body {
            margin: 0;
            font-family: "Helvetica Neue", "Arial", sans-serif;
            color: var(--ink);
            background: #d9dde5;
          }

          .page {
            max-width: 980px;
            margin: 0 auto;
            padding: 24px 16px 40px;
          }

          .header {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            background: var(--header-bg);
            color: var(--header-text);
            padding: 16px;
            font-size: 34px;
            letter-spacing: 3px;
            font-weight: 700;
          }

          .header-icon {
            width: 44px;
            height: 44px;
            filter: invert(1);
          }

          .menu-grid {
            margin-top: 18px;
            display: grid;
            gap: 18px;
          }

          .menu-section {
            background: var(--panel);
            border: 2px solid var(--panel-border);
            padding: 14px 14px 8px;
          }

          .section-title {
            color: var(--accent);
            font-weight: 700;
            letter-spacing: 1px;
            font-size: 14px;
            margin-bottom: 8px;
          }

          .menu-item {
            padding: 6px 0;
            border-top: 1px solid #b9bcc6;
          }

          .menu-item:first-child {
            border-top: 0;
          }

          .item-header {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            font-weight: 700;
            font-size: 15px;
          }

          .item-description {
            margin-top: 2px;
            font-size: 13px;
            color: #444;
          }

          @media (min-width: 768px) {
            .menu-grid {
              grid-template-columns: 1fr 1fr;
            }
          }
        </style>
      </head>
      <body>
        <div class="header">
          <img class="header-icon" src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/Cib-coffeescript_%28CoreUI_Icons_v1.0.0%29.svg/250px-Cib-coffeescript_%28CoreUI_Icons_v1.0.0%29.svg.png" alt="Coffee mug icon" />
          #{title.upcase}
        </div>
        <div class="page">
          <main class="menu-grid">
            #{sections_html}
          </main>
        </div>
      </body>
    </html>
  HTML
end

menu_path = ARGV[0] || DEFAULT_MENU_PATH
output_path = ARGV[1] || DEFAULT_OUTPUT_PATH

abort_with("Menu file not found at #{menu_path}.") unless File.exist?(menu_path)

data = YAML.safe_load(File.read(menu_path))
menu = validate_menu!(data)

FileUtils.mkdir_p(File.dirname(output_path))
File.write(output_path, build_html(menu))

puts "Generated #{output_path}"
