# This file is under GPL
# Do whatever you like
# written by Daniel Schubert 2014 
# <mail@schubertdaniel.de>  

class VideoConversion
  # - converts any (hopefully) video into different other vids, f.e. three vids suitable for projekktor
  # - needs ffmpeg and ffmpeg2theora

  # vidfile   string    video file name
  # video_br   int     (video bitrate in k )
  # audio_br   int      (audio bitrate in k)
  # aufio_q    int      (ogv audio quality between 1 and 10)
  # video_q   int       (ogv video quality between 1 and 10)
  # target    string    determines the output  -> 'mpeg' - simple mpg  , 'projekktor' - for projekktor
  
  def initialize(vidfile, width=640, height=360, target="mpg",video_br=600, audio_br=128, audio_q=5,video_q=7, freq = 48000)
    @videofile = vidfile#.dump
    #target size
    @width = width
    @height= height
    @target= target
    #for webm and mp4 files
    @video_br = video_br
    @audio_br = audio_br
    #for ogv video 
    @audio_q = audio_q
    @video_q = video_q
    
    @freq = freq
    @temp_file = "temp-vid.mpg"
    @aspect= nil
  end
#  
  def get_aspect
    # uses the output from ffprobe to calculate the aspect ratio from input video
    w , h = nil
    f = IO.popen("ffprobe -show_streams \"#{@videofile}\"")
     vidinfo = f.readlines
    f.close
    #  
    unless vidinfo.empty?
      vidinfo.each do |elem|
        if elem =~ /display_aspect_ratio=\d+:\d+/
          b = elem.scan(/\d*:\d*/)[0].split(":")
          @aspect = b[0].to_f/b[1].to_f
        else
          if elem =~ /width=\d+/
		    w = elem.to_s.gsub!("width=", "").chomp.scan(/\d+/)
		  elsif elem =~ /height=\d+/
		    h = elem.to_s.gsub!("height=", "").chomp.scan(/\d+/)
		  end
		end
      end

      if @aspect == nil
        @aspect = w.join.to_f / h.join.to_f
      end
  
    end
    
    return @aspect  
  end
#
  def get_basename
    bn = File.basename(@videofile, ".*")
    return bn
  end
  
  def converter
    Dir.mkdir('converted') unless File.exists?('converted') 
    File.delete(@temp_file) if File::exists?(@temp_file) 
    #
    target_aspect = (@width.to_f / @height.to_f)
    #
    begin
      videobasename = get_basename
      puts videobasename
      #
      if get_aspect > target_aspect # balken oben und unten
	            neue_hoehe = (@width/get_aspect).to_i
	            balken = (@height - neue_hoehe) / 2
	            
	            # if padding applied older versions of ffmpeg need the "-padleft XX -padright XX " syntax
	            padding = "-vf \"pad=#{@width}:#{@height}:0:#{balken}\""
	            
	            @height = neue_hoehe            
      elsif get_aspect < target_aspect   # balken an die seite 
	            neue_breite = (@height * get_aspect).to_i
	            balken = (@width - neue_breite) / 2
	            
	            #  if padding applied older versions of ffmpeg need the "-padleft XX -padright XX " syntax
	            padding = "-vf \"pad=#{@width}:#{@height}:#{balken}:0\""
	            
	            @width = neue_breite
	            
	  else #aspect unchanged -> no padding  
		    padding = ""	
	  end
      #
  	 case @target
  	   when "mpg"  # simple mpeg
  	     #simple mpg
  	     `ffmpeg -i \"#{@videofile}\" -s #{@width}x#{@height} #{padding} -aspect #{target_aspect} -threads 2 -b #{@video_br}k -ab #{@audio_br}k -ar #{@freq} -metadata creation_time=\"#{Time.new}\" converted/\"#{videobasename}.mpg\"`
       when "projekktor"  #Projekktor
         #temp video necessary for correct padding when converting to more formats
	       `ffmpeg -i \"#{@videofile}\" -s #{@width}x#{@height} #{padding} -aspect #{target_aspect} -b 5000k -ar 44100 -ab 320k #{@temp_file}`  
        
          #conversions for projekktor
          `ffmpeg  -i #{@temp_file} -threads 2 -aspect #{target_aspect} -vcodec libx264 -b #{@video_br}k -vpre ipod640 -ab #{@audio_br}k -metadata creation_time=\"#{Time.new}\" converted/\"#{videobasename}.mp4\"`
          `ffmpeg  -i #{@temp_file} -threads 2 -aspect #{target_aspect} -b #{@video_br}k -ab #{@audio_br}k -metadata creation_time=\"#{Time.new}\" converted/\"#{videobasename}.webm\"`
          `ffmpeg2theora #{@temp_file} -v #{@video_q} -a #{@audio_q} -o converted/\"#{videobasename}.ogv\"`
          File.delete(@temp_file)        
       when "youtube"
         puts "YouTube not implemented yet!"
         exit
       else
         puts "Nothing valid chosen-- bye bye"
         exit 
     end   
      
    rescue => e
      puts "Something went terribly wrong: ", e
    end
  end
  #
end
