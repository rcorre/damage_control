# This rakefile builds resources into the content files used in game.
# resources/ contains media formats used while editing game content
# content/ contains the target formats loaded by the game

SOURCEDIR = 'resource'
TARGETDIR = 'content'

task :default => %w{images maps fonts sounds}
task :default => "#{TARGETDIR}"

directory TARGETDIR
directory "#{TARGETDIR}/image"
directory "#{TARGETDIR}/map"
directory "#{TARGETDIR}/sound"
directory "#{TARGETDIR}/font"

task :maps => "#{TARGETDIR}/map"
FileList.new("#{SOURCEDIR}/map/*.tmx").each do |src|
  fname = File.basename(src, '.tmx')
  target = File.join(TARGETDIR, 'map', fname + '.json')

  file target => src do
    sh "tiled #{src} --export-map #{target}"
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
