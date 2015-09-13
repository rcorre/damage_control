# This rakefile builds resources into the content files used in game.
# resources/ contains media formats used while editing game content
# content/ contains the target formats loaded by the game

SOURCEDIR = 'resource'
TARGETDIR = 'content'

task :default => %w{images maps fonts sounds music}
task :default => "#{TARGETDIR}"

directory TARGETDIR
directory "#{TARGETDIR}/image"
directory "#{TARGETDIR}/map"
directory "#{TARGETDIR}/sound"
directory "#{TARGETDIR}/font"
directory "#{TARGETDIR}/music"

# maps are just copied now
# Tiled can directly work with json, no need for tmx->json conversion
task :maps => "#{TARGETDIR}/map"
FileList.new("#{SOURCEDIR}/map/*.json").each do |src|
  fname = File.basename(src)
  target = File.join(TARGETDIR, 'map', fname)

  file target => src do
    sh "cp #{src} #{target}"
  end

  task :maps => target
end

task :images => "#{TARGETDIR}/image"
FileList.new("#{SOURCEDIR}/image/*.ase").each do |src|
  fname = File.basename(src, '.ase')
  target = File.join(TARGETDIR, 'image', fname + '.png')

  file target => src do
    sh "aseprite --batch #{src} --sheet #{target} --data /dev/null"
  end

  task :images => target
end

task :fonts => "#{TARGETDIR}/font"
FileList.new("#{SOURCEDIR}/font/*.ttf").each do |src|
  fname = File.basename(src, '.ttf')
  target = File.join(TARGETDIR, 'font', fname + '.ttf')

  file target => src do
    sh "cp #{src} #{target}"
  end

  task :fonts => target
end

task :sounds => "#{TARGETDIR}/sound"
FileList.new("#{SOURCEDIR}/sound/*").each do |src|
  fname = File.basename(src)
  target = File.join(TARGETDIR, 'sound', fname)

  file target => src do
    sh "cp #{src} #{target}"
  end

  task :sounds => target
end

task :music => "#{TARGETDIR}/music"
FileList.new("#{SOURCEDIR}/music/*").each do |src|
  fname = File.basename(src, '.mmpz')
  target = File.join(TARGETDIR, 'music', fname + '.ogg')

  file target => src do
    sh "lmms --render #{src} -f ogg -o #{target}"
  end

  task :music => target
end
