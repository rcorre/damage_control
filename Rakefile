# This rakefile builds resources into the content files used in game.
# resources/ contains media formats used while editing game content
# content/ contains the target formats loaded by the game

task :default => %w{images maps}
task :images => %w{content/image/tileset.png}
task :maps => %w{content/maps/map1.json}

file 'content/maps/map1.json' => 'resources/maps/map1.tmx' do
  sh "tiled resources/maps/map1.tmx --export-map content/maps/map1.json"
end

file 'content/image/tileset.png' => 'resources/image/tileset.ase' do
  sh "aseprite --batch resources/image/tileset.ase --sheet content/image/tileset.png"
end
