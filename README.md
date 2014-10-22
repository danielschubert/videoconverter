videoconverter
==============

I wrote this because I needed something that produces Videos for use withe the html5 Video Player [Projekktor](http://www.projekktor.com/)

- produces 3 output videos (mpg, mp4, ogv) from (hopefully) any input video file that ffmpeg can decode
- written in ruby
- requires ffmpeg and ffmpeg2theora


Usage:
<pre><code>
#!/usr/bin/env ruby
require 'VideoConversion.class.rb'
v = VideoConversion.new("<videofile>", 800, 100,"projekktor",1500,192)
v.converter
</code></pre>
