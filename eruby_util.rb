# This is a cut-down version of the one used for LM and SN.

$tex_points_to_mm = (25.4)/(65536.*72.27)
$n_marg = 0
$in_marg = false
$geom_file = "geom.pos"
$checked_geom = false
$geom_exists = nil
$geom = [ 11.40 ,  63.40 ,  154.40 , 206.40 , 28.00 , 258.00]
  # See geom() for the definitions of these numbers.
  # These are just meant to be sane defaults to use if the geom.pos file hasn't been created yet.
  # If they turn out to be wrong, or not even sane, that doesn't matter, because we'll be getting
  # the right values on the next iteration. Actually it makes very little difference, because on the
  # first iteration, we don't even know whether a particular figure is on a left page or a right page,
  # so we don't even try to position it very well.
$checked_pos = false
$pos_exists = nil
$marg_file = "marg.pos"
$feedback = []
  # ... an array of hashes
$read_feedback = false
$feedback_exists = nil
  #... can't check for existence until the first marg() call, because we don't know $ch yet
$page_invoked_from = []
$reuse = {}
  # a hash for keeping track of how many times a figure has been reused within the same chapter
$web_command_marker = 'ZZZWEB:'

$count_section_commands = 0
$section_level = -1
$hw_number = 0
$hw = []
$hw_has_solution = []
$hw_names_referred_to = []

def is_print
  return ENV['BOOK_OUTPUT_FORMAT']!='web'
end

def is_web
  return ENV['BOOK_OUTPUT_FORMAT']=='web'
end

def pos_file
  return "ch#{$ch}.pos"
end

def previous_pos_file
  p = $ch.to_i-1
  if p<0 then return nil end
  if p<10 then p = '0'+p.to_s end
  return "ch#{p}.pos"
end

# returns data in units of mm, in the coordinate system used by pdfsavepos (positive y up)
def geom(what)
  if ! $checked_geom then
    $geom_exists = File.exist?($geom_file)
    if $geom_exists then
      File.open($geom_file,'r') do |f|
        line = f.gets
        if !(line=~/pt/) then # make sure it's already been parsed into millimeters
          $geom = line.split
        end
      end
    end
    $checked_geom = true
  end
  index = {'evenfigminx'=>0,'evenfigmaxx'=>1,'oddfigminx'=>2,'oddfigmaxx'=>3,'figminy'=>4,'figmaxy'=>5}[what]
  result = $geom[index].to_f
  if what=='figmaxy' then result=result-2.5 end
  return result
end

def end_marg
  if !$in_marg then die('(end_marg)',"end_marg, not in a marg in the first place, chapter #{$ch}") end
  if is_print then print "\\end{textblock*}\\end{margin}%\n" end
  if is_web then print "#{$web_command_marker}end_marg\n" end
  $in_marg = false
end

def marg(delta_y=0)
  if $in_marg then die('(marg)','marg, but already in a marg') end
  $n_marg = $n_marg+1
  $in_marg = true
  if is_print then marg_print(delta_y) end
  if is_web   then print "#{$web_command_marker}marg\n" end
end

# sets $page_invoked_from[] as a side-effect
def marg_print(delta_y)
    print "\\begin{margin}{#{$n_marg}}{#{delta_y}}{#{$ch}}%\n";
    # (x,y) are in coordinate system used by pdfsavepos, with positive y up
    miny = geom('figminy')
    maxy = geom('figmaxy')
    x=geom('oddfigminx')
    y=maxy
    fig_file = "figfeedback#{$ch}"
    if $feedback_exists==nil then $feedback_exists=File.exist?(fig_file) end
    if $feedback_exists and !$read_feedback then
      $read_feedback = true
      File.open(fig_file,'r') do |f|
        f.each_line { |line|
          # line looks like this: 1,page=15,refx=6041561,refy=46929091,deltay=12
          if line =~ /(\d+),page=(\d+),refx=(\-?\d+),refy=(\-?\d+),deltay=(\-?\d+)/ then
            n,page,refx,refy,deltay=$1.to_i,$2.to_i,$3.to_i,$4.to_i,$5.to_i
            $feedback[n] = {'n'=>n,'page'=>page,'refx'=>refx,'refy'=>refy,'deltay'=>deltay}
            $page_invoked_from[n] = page
          else
            die(name,"syntax error in file #{fig_file}, line=#{line}")
          end
        }
      end
      File.delete(fig_file) # otherwise it grows by being appended to every time we run tex
    end
    if $feedback_exists then
      feed = $feedback[$n_marg]
      page = feed['page']
      refy = feed['refy']
      deltay = feed['deltay']
      #$stderr.print "page=#{page},refy=#{refy},deltay=#{deltay}\n"
      y = refy*$tex_points_to_mm+deltay
      y_raw = y
      debug = false
      $stderr.print "miny=#{miny}\n" if debug
      ht = height_of_marg
      maxht = maxy-miny
      if page%2==0 then
        x=geom('evenfigminx') # left page
      else
        x=geom('oddfigminx') # right page
      end
      # The following are all in units of millimeters.
      tol_out =   50     # if a figure is outside its allowed region by less than this, we fix it silently; if it's more than that, we give a warning
      tol_in  =    5     # if a figure is this close to the top or bottom, we silently snap it exactly to the top or bottom
      max_fudge =  3     # amount by which a tall stack of figures can stick up over the top, if it's just plain too big to fit
      min_ht =    15     # even if we don't know ht, all figures are assumed to be at least this high
      if y>maxy+tol_out then warn_marg(1,$n_marg,page,"figure too high by #{y-maxy} mm, which is greater than #{tol_out} mm, ht=#{ht}") end
      if y>maxy-tol_in then y=maxy end
      if !(ht==nil) then
        $stderr.print "ht=#{ht}\n" if debug
        if y-ht<miny-tol_out then warn_marg(1,$n_marg,page,"figure too low by #{miny-(y-ht)} mm, which is greater than #{tol_out} mm, ht=#{ht}") end
        if ht>maxht then
          # The stack of figures is simply too tall to fit. The user will get warned about this later, and may be doing it
          # on purpose, as a last resort. Typically in this situation, what looks least bad is to align it at the top, or a tiny bit above.
          fudge = ht-maxht
          if fudge>max_fudge then fudge=max_fudge end
          y=maxy+fudge
        else
          if y-ht<miny+tol_in then y=miny+ht end
        end
      end
      # A final sanity check, which has to work whether or not we know ht.
      if y>maxy+max_fudge then y=maxy+tol_insane end
      if y<miny+min_ht then y=miny+min_ht end
    end # if fig_file exists
    # In the following, I'm converting from pdfsavepos's coordinate system to textpos's; assumes calc package is available.
    print "\\begin{textblock*}{\\marginfigwidth}(#{x}mm,\\paperheight-#{y}mm)%\n"
end

def warn_marg(severity,nmarg,page,message)
  # First, figure out what figures are associated with the current margin block.
  mine = {}
  if File.exist?($marg_file) then
    File.open($marg_file,'r') do |f|
      f.each_line { |line|
        if line=~/fig:(.*),nmarg=(\d+),ch=(\d+)/ then
          fig,gr,ch = $1,$2.to_i,$3
          mine[fig]=1 if (gr==nmarg.to_i && ch==$ch)
        else
          $stderr.print "error in #{$marg_file}, no match?? #{line}\n"
        end
      }
    end
  end
  $stderr.print "warning, severity #{severity} nmarg=#{nmarg}, ch. #{$ch}, p. #{page}, #{mine.keys.join(',')}: #{message}\n"
end

def pos_file_exists
  if ! $checked_pos then
    $pos_exists = File.exist?(pos_file())
    $checked_pos = true
  end
  return $pos_exists
end

# looks at global variable $n_marg to see which margin-group we're working on
# returns height in mm, or nil if the all.pos file doesn't exist yet, or figure not listed in it
def height_of_marg
  #debug = ($ch.to_i==4 and $n_marg==6)
  debug = false
  if !(File.exist?($marg_file)) then return nil end
  if !pos_file_exists() then return nil end
  # First, figure out what figures are associated with the current margin block.
  mine = Hash.new # keys are, e.g., "fig:atomic-clock-boarding-plane"
  File.open($marg_file,'r') do |f|
    # The file grows by appending with each iteration. If the user isn't modifying the tex file (drastically) between
    # runs, then it should all just be exact repetition. If not, then we just use the freshest available data. At any given
    # time, the latest chunk of the file will be incomplete, and the freshest data for some margin blocks could be either
    # in the final chunk or in the penultimate one. There's some risk that something goofy could happen if the user
    # does rearrange blocks between iterations. The file also mixes data from different chapters.
    # ************ Bug: if the same figure is used in two different chapters, I think this will mess up **************************
    # ************ It's inefficient to call this many times. ********************
    f.each_line { |line|
      if line=~/(.*),nmarg=(\d+),ch=(\d+)/ then
        fig,gr,ch = $1,$2.to_i,$3
        mine[fig] = 1 if (gr==$n_marg.to_i and ch==$ch)
        $stderr.print "#{fig} is mine!\n" if debug and mine[fig]
      end
    }
  end
  $stderr.print "keys=" + (mine.keys.join(',')) + "\n" if debug
  # Read the chNN.pos file, which typically looks like this:
  #   fig,label=fig:mass-on-spring,page=15,x=28790655,y=45437345,at=begin
  #   fig,label=fig:mass-on-spring,page=15,x=38486990,y=27308866,at=endgraphic
  #   fig,label=fig:mass-on-spring,page=15,x=38195719,y=22590274,at=endcaption
  huge = 999/$tex_points_to_mm # 999 mm, expressed in units of tex points

  lo_y = huge
  hi_y = -huge
  found = false
  found,lo_y,hi_y = get_low_and_hi!(found,lo_y,hi_y,pos_file(),mine)

  # Very rarely (ch. 4 of genrel), I have a figure on the first page of a chapter, which gets written to the chNN.pos for the previous chapter.
  # I think this happens because the write18 that renames all.pos isn't executed until after the first page of the new chapter is output.
  # I don't know why this never happens in SN or LM; possibly because they have chapter opener photos that are big enough to cause buffers to get flushed?
  # Checking previous_pos_file() seems to take care of this on the very rare occasions when it happens.
  if !found and File.exist?(previous_pos_file()) then
    found,lo_y,hi_y = get_low_and_hi!(found,lo_y,hi_y,previous_pos_file(),mine)
  end
  if !found then
    #warn_marg(1,$n_marg,0,"figure not found in height_of_marg, $n_marg=#{$n_marg} $ch=#{$ch}; see comment in eruby_util for more about this")
    # This happens and is normal for wide figures, which are not in the margin. They appear in chNN.pos, but not in marg.pos.
  end

  if !found then return nil end
  height = (hi_y - lo_y)*$tex_points_to_mm
  #if height<1 then die('(height_of_marg)',"height #{height} is too small, lo=#{lo_y}, hi=#{hi_y}") end
  if height<1 then return nil end #???????????????????????????????????????
  $stderr.print "height=#{height}\n" if debug
  return height
end

def get_low_and_hi!(found,lo_y,hi_y,filename,mine)
  File.open(filename,'r') do |f|
    f.each_line { |line|
      if line=~/^fig,label=(.*),page=(.*),x=(.*),y=(.*),at=(.*)/ then
        fig,page,y=$1,$2.to_i,$4.to_i
        if mine.has_key?(fig) then
          if y<lo_y then lo_y = y end
          if y>hi_y then hi_y = y end
          found = true
        end
      end
    }
  end
  [found,lo_y,hi_y]
end

def figure_exists_in_my_own_dir?(name)
  ch = $ch
  return (File.exist?("ch#{ch}/figs/#{name}.pdf") or File.exist?("ch#{ch}/figs/#{name}.jpg") or File.exist?("ch#{ch}/figs/#{name}.png"))
end

def fig(name,caption=nil,options={})
  default_options = {
    'anonymous'=>'default',# true means figure has no figure number, but still gets labeled (which is, e.g., necessary for photo credits)
                           # default is false, except if caption is a null string, in which case it defaults to true
    'width'=>'narrow',     # 'narrow'=52 mm, 'wide'=113 mm, 'fullpage'=171 mm
                           #   refers to graphic, not graphic plus caption (which is greater for sidecaption option)
                           #   may get automagically changed for 2-column layout
    'width2'=>'auto',      # width for 2-col layout;
                           #   width='narrow',  width2='auto'  --  narrow figure stays same width, is not as wide as text colum
                           #   width='fullpage',width2='auto'  --  nothing special
                           #   width='wide',    width2='auto'  --  makes it a sidecaption regardless of whether sidecaption was actually set
                           #   width2='column' -- generates a warning if an explicitly created 82.5-mm wide figure doesn't exist
                           #   width2='column_auto' -- like column, but expands automatically, and warns if an explicit alternative *does* exist
    'sidecaption'=>false,
    'sidepos'=>'t',        # positioning of the side caption relative to the figure; can also be b, c
    'float'=>'default',    # defaults to false for narrow, true for wide or fullpage (because I couldn't get odd-even to work reliably for those if not floating)
    'floatpos'=>'h',       # standard latex positioning parameter for floating figures
    'narrowfigwidecaption'=>false, # currently only supported with float and !anonymous
    'suffix'=>'',          # for use when a figure is used in more than one place, and we need to make the label unique
    'text'=>nil,           # if it exists, puts the text in the figure rather than a graphic (name is still required for labeling)
    #      see macros \starttextfig and \finishtextfig
    # not yet implemeted: 
    #    translated=false
    #      or just have the script autodetect whether a translated version exists!
    #    toc=false
    #      figure is to be used in table of contents
    #      see macros \figureintoc, \figureintocnoresize
    #    midtoc=false
    #      figure in toc is to be used in the middle of a chapter (only allowed with toc=true)
    #      see macro figureintocscootx
    #    scootdown=0
    #      distance by which to scoot it down (only allowed with toc=true)
    #      see macro figureintocscooty
    #    gray=false
    #      automagically add a gray background
    #    gray2=false
    #      automagically add a gray background if it's 2-column
    #    resize=true
    #      see macros \fignoresize, \inlinefignocaptionnoresize
    # Note that anonymousinlinefig is a raw call to includegraphics (with figprefix); this is used for stuff like checkmarks, and is very
    # low-level; don't translate into eruby at all.
  }
  caption.gsub!(/\A\s+/,'') # blank lines on the front make latex freak out
  if caption=='' then caption=nil end
  default_options.each { 
    |option,default|
    if options[option]==nil then
      options[option]=default
    end
  }
  width=options['width']
  if options['float']=='default' then
    options['float']=(width=='wide' or width=='fullpage')
  end
  if options['anonymous']=='default' then
    options['anonymous']=(!caption)
  end
  dir = "\\figprefix\\chapdir/figs"
  #------------------------------------------------------------
  if is_print then fig_print(name,caption,options,dir) end
  #------------------------------------------------------------
  if is_web then process_fig_web(name,caption,options) end
end

def process_fig_web(name,caption,options)
  if caption==nil then caption='' end
  # remove comments now, will be too late to do it later; can't use lookbehind because eruby compiled with ruby 1.8
  caption.gsub!(/\\%/,'PROTECTPERCENT') 
  caption.gsub!(/%[^\n]*\n?/,' ')
  caption.gsub!(/PROTECTPERCENT/,"\\%") 
  caption.gsub!(/\n/,' ')
  text = options['text']
  anon = '0'
  anon = '1' if options['anonymous']
  if text==nil then
    print "#{$web_command_marker}fig,#{name},#{options['width']},#{anon},#{caption}END_CAPTION\n"
  else
    text.gsub!(/\n/,' ')
    print "#{text}\n\n#{caption}\n\n" # bug ------------- not really correct
  end
end

# sets $page_rendered_on as a side-effect (or sets it to nil if all.pos isn't available yet)
def fig_print(name,caption,options,dir)
  width=options['width']
  $fig_handled = false
  sidepos = options['sidepos']
  floatpos = options['floatpos']
  suffix = options['suffix']
  if (!(suffix=='')) and width=='wide' and ! options['float'] then die(name,"suffix not implemented for wide, !float") end
  if (!(suffix=='')) and width=='narrow' and options['anonymous'] then die(name,"suffix not implemented for narrow, anonymous") end
  print "\\noindent"
  #============================================================================
  if $reuse.has_key?(name)
    $reuse[name]+=1
  else
    $reuse[name]=0
  end
  if $in_marg then
    File.open($marg_file,'a') do |f|
      f.print "fig:#{name},nmarg=#{$n_marg},ch=#{$ch}\n"
    end
  end
  # Warn about figures that aren't floating, but that occur on a different page than the one on which they were invoked.
  # Since the bug I'm trying to track down is a bug with marginal figures, only check if it's a marginal figure.
  # This is somewhat inefficient.
  if $in_marg and ! options['float'] then
    invoked = $page_invoked_from[$n_marg]
    $page_rendered_on=nil
    last_l,last_page = nil,nil
    if File.exist?(pos_file()) and !(invoked==nil) then
      File.open(pos_file(),'r') do |f|
        reuse = 0
        f.each_line { |line|
          if line=~/^fig,label=fig:(.*),page=(.*),x=(.*),y=(.*),at=(.*)/ then
            l,page=$1,$2.to_i
            if l==name and !(last_l==l and last_page==page) then # second clause is because we get several lines in a row for each fig
              $page_rendered_on=page if reuse==$reuse[name]
              reuse+=1
            end
            last_l,last_page = l,page
          end
        }
      end
    end
    if !($page_rendered_on==nil) and !(invoked==nil) and !(invoked==$page_rendered_on) then
      $stderr.print "***** warning: invoked on page #{invoked}, but rendered on page #{$page_rendered_on}, off by #{$page_rendered_on-invoked}, #{name}, ch.=#{$ch}\n" +
                    "      This typically happens when the last few lines of the paragraph above the figure fall at the top of a page.\n"
    end
  end
  #============================================================================
  #----------------------- text ----------------------
  if options['text']!=nil then
    spit("\\starttextfig{#{name}}#{options['text']}\n\\finishtextfig{#{name}}{%\n#{caption}}\n")
  end
  #----------------------- narrow ----------------------
  if width=='narrow' and options['text']==nil then
    if options['anonymous'] then
      if caption then
        spit("\\anonymousfig{#{name}}{%\n#{caption}}{#{dir}}\n")
      else
        spit("\\fignocaption{#{name}}{#{dir}}\n")
      end
    else # not anonymous
      if caption then
        spit("\\fig{#{name}}{%\n#{caption}}{#{suffix}}{#{dir}}\n")
      else
        die(name,"no caption, but not anonymous")
      end
    end
  end
  #----------------------- wide ------------------------
  if width=='wide' and options['text']==nil then
    if options['anonymous'] then
      if options['narrowfigwidecaption'] then die(name,'narrowfigwidecaption requires anonymous=false, and float=false') end
      if options['float'] then
        if caption then
          if options['sidecaption'] then
            spit("\\widefigsidecaption{#{sidepos}}{#{name}}{%\n#{caption}}{anonymous}{#{floatpos}}{float}{#{suffix}}{#{dir}}\n")
          else
            spit("\\widefig[#{floatpos}]{#{name}}{%\n#{caption}}{#{suffix}}{anonymous}{#{dir}}\n")
          end
        else
          die(name,"widefignocaption is currently only implemented as a nonfloating figure")
        end
      else # not floating
        if caption then
          die(name,"widefig is currently only implemented as a floating figure, because I couldn't get it to work right unless it was floating (see comments in lmcommon.sty)")
        else
          spit("\\widefignocaptionnofloat[#{dir}]{#{name}}\n")
        end
      end
    else # not anonymous
      if options['float'] then
        if options['narrowfigwidecaption'] then die(name,'narrowfigwidecaption requires anonymous=false, and float=false') end
        if caption then
          if options['sidecaption'] then
            spit("\\widefigsidecaption{#{sidepos}}{#{name}}{%\n#{caption}}{labeled}{#{floatpos}}{float}{#{suffix}}{#{dir}}\n")
          else
            spit("\\widefig[#{floatpos}]{#{name}}{%\n#{caption}}{#{suffix}}{labeled}{#{dir}}\n")
          end
        else
          die(name,"no caption, but not anonymous")
        end
      else # not floating
        if options['narrowfigwidecaption'] then
          spit("\\narrowfigwidecaptionnofloat{#{name}}{%\n#{caption}}{#{dir}}\n")
        else
          die(name,"The only wide figure that's implemented the option of not floating is narrowfigwidecaption. See comments in lmcommon.sty for explanation.")
        end
      end # not floating
    end # not anonymous
  end # if wide
  #----------------------- fullpage ----------------------
  if width=='fullpage' and options['text']==nil then
    if options['anonymous'] then
      if caption then
        die(name,"the combination of options fullpage+anonymous+caption is not currently supported")
      else
        spit("\\fullpagewidthfignocaption[#{dir}]{#{name}}\n")
      end
    else # not anonymous
      if caption then
        spit("\\fullpagewidthfig[#{dir}]{#{name}}{%\n#{caption}}\n")
      else
        die(name,"no caption, but not anonymous")
      end
    end
  end
  #============================================================================
  if !$fig_handled then
    die(name,"not handled")
  end
end

def spit(tex)
  print tex
  $fig_handled = true
end

def die(name,message)
  $stderr.print "eruby_util: figure #{name}, #{message}\n"
  exit(-1)
end

def end_sec()
  $count_section_commands += 1
  $section_level -= 1
end

def begin_sec(title,pagebreak=nil,label='',options={})
  $count_section_commands += 1
  $section_level += 1
  # In LM, section level 1=section, 2=subsection, 3=subsubsection; 0 would be chapter, but chapters aren't done with begin_sec()
  if $section_level==0 then
    $stderr.print "warning, at #{$count_section_commands}th begin/end section command, ch #{$ch}, section #{title}, section level=#{$section_level}, zero section level (happens in NP Preface)\n"
    $section_level = 1
  end
  if pagebreak==nil then pagebreak=4-$section_level end
  if pagebreak>4 then pagebreak=4 end
  if pagebreak<0 then pagebreak=0 end
  pagebreak = '['+pagebreak.to_s+']'
  if $section_level>=3 then pagebreak = '' end
  macro = ''
  label_level = ''
  if $section_level==1 then
    label_level = 'sec'
    macro = 'mysection'
  end
  if $section_level==2 then
    if options['toc']==false then
      macro = 'mysubsectionnotoc'
    else
      macro = 'mysubsection'
    end
    label_level = 'subsec'
  end
  if $section_level==3 then
    macro = 'subsubsection'
    label_level = 'subsubsec'
  end
  if label != '' then label="\\label{#{label_level}:#{label}}" end
  print "\\#{macro}#{pagebreak}{#{title}}#{label}\n"
end

def end_chapter
  $section_level -= 1
  if $section_level != -1 then
    $stderr.print "warning,  at end_chapter, ch #{$ch}, section level at end of chapter is #{$section_level}, should be -1; probably begin_sec's and end_sec's are not properly balanced (happens in NP preface)\n"
  end
end

def chapter(number,title,label,caption='',options={})
  default_options = {
    'opener'=>'',
    'anonymous'=>'default',# true means figure has no figure number, but still gets labeled (which is, e.g., necessary for photo credits)
                           # default is false, except if caption is a null string, in which case it defaults to true
    'width'=>'wide',       # 'wide'=113 mm, 'fullpage'=171 mm
                           #   refers to graphic, not graphic plus caption (which is greater for sidecaption option)
    'sidecaption'=>false,
    'special_width'=>nil   # used in CL4, to let part of the figure hang out into the margin
  }
  $section_level += 1
  $ch = number
  default_options.each { 
    |option,default|
    if options[option]==nil then
      options[option]=default
    end
  }
  opener = options['opener']
  if opener!='' then
    if options['anonymous']=='default' then
      options['anonymous']=(caption=='')
    end
  end
  chapter_print(number,title,label,caption,options)
end

def chapter_print(number,title,label,caption,options)
  opener = options['opener']
  has_opener = (opener!='')
  result = nil
  if !has_opener then
    result = "\\mychapter{#{title}}"
  else
    opener=~/([^\/]+)$/     # opener could be, e.g., ../../../9share/optics/figs/crepuscular-rays
    opener_label = $1
    ol = "\\label{fig:#{opener_label}}" # needs label for figure credits, and TeX isn't smart enough to handle cases where it's got ../.., etc. on the front
                            # not strictly correct, because label refers to chapter, but we only care about page number for photo credits
    if options['width']=='wide' then
      if caption!='' then
        if !options['sidecaption'] then
          if options['special_width']==nil then
            result = "\\mychapterwithopener{#{opener}}{#{caption}}{#{title}}#{ol}"
          else
            result = "\\specialchapterwithopener{#{options['special_width']}}{#{opener}}{#{caption}}{#{title}}#{ol}"
          end
        else
          if options['anonymous'] then
            result = "\\mychapterwithopenersidecaptionanon{#{opener}}{#{caption}}{#{title}}#{ol}"
          else
            result = "\\mychapterwithopenersidecaption{#{opener}}{#{caption}}{#{title}}#{ol}"
          end
        end
      else
        result = "\\mychapterwithopenernocaption{#{opener}}{#{title}}#{ol}"
      end
    else
      if options['anonymous'] then
        if caption!='' then
          result = "\\mychapterwithfullpagewidthopener{#{opener}}{#{caption}}{#{title}}#{ol}"
        else
          result = "\\mychapterwithfullpagewidthopenernocaption{#{opener}}{#{title}}#{ol}"
        end
      else
        $stderr.print "********************************* ch #{ch}full page width chapter openers are only supported as anonymous figures ************************************\n"
        exit(-1)
      end
    end
  end
  if result=='' then
    $stderr.print "**************************************** Error, ch #{$ch}, processing chapter header. ****************************************\n"
    exit(-1)
  end
  print "#{result}\\label{#{label}}\n"
end

def begin_hw(name,difficulty=1,options={})
  if difficulty==nil then difficulty=1 end # why doesn't this happen by default?
  print "\\begin{homework}{#{name}}{#{difficulty}}{}"
  $hw_number += 1
  $hw[$hw_number] = name
  $hw_has_solution[$hw_number] = false
end

def end_hw()
  print "\\end{homework}"
end
