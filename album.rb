#!/usr/bin/env ruby
require "bin_packing"
require 'colorize'
require 'mini_exiftool'
require "mini_magick"
require 'optparse'
require 'pathname'
require 'progress_bar'
require 'unicode_utils/upcase'

ONE_INCH = 0.393701                # cm

$opts = {}
$opts[:dpi] = 300
$opts[:paper_width] = 210          # mm
$opts[:paper_height] = 297         # mm
$opts[:paper_margin_width] = 4     # mm
$opts[:photo_margin_width] = 0.5   # mm
$opts[:photo_border_width] = 4     # mm
$opts[:photo_width] = 63           # mm
$opts[:cut_aid_width] = 4          # mm

## Parse command line options.
OptionParser.new do |opt|
  opt.on('--paper-width W',
         Integer,
         "Width (shorter dimension) in mm of the paper you are going to print on.") do |w|
    $opts[:paper_width] = w
  end

  opt.on('--paper-height H',
         Integer,
         "Height (longer dimension) in mm of the paper you are going to print on.") do |h|
    $opts[:paper_height] = h
  end

  opt.on('--paper-margin-width W',
         Integer,
         "Width of the margin applied to the whole sheet of paper.") do |w|
    $opts[:paper_margin_width] = w
  end 

  opt.on('--photo-border-width W',
         Integer,
         "Width of the white border surrouding each photo, in mm.") do |w|
    $opts[:photo_border_width] = w
  end 

  opt.on('--photo-width W',
         Integer,
         "Width of the shorter side of the photo, in mm.") do |w|
    $opts[:photo_width] = w
  end 
end.parse!

# Convert all units to pixels, so that we don't mix millimeters with pixels later on.
def mm_to_px(mm) 
    return (mm.to_f / 10 * ONE_INCH * $opts[:dpi]).round(0)
end

class Integer
    def millimeters
        return (self * 10 / ONE_INCH / $opts[:dpi]).round(2)
    end
end

$opts[:paper_width] = mm_to_px($opts[:paper_width])
$opts[:paper_height] = mm_to_px($opts[:paper_height])
$opts[:paper_margin_width] = mm_to_px($opts[:paper_margin_width])
$opts[:photo_margin_width] = mm_to_px($opts[:photo_margin_width])
$opts[:photo_border_width] = mm_to_px($opts[:photo_border_width])
$opts[:photo_width] = mm_to_px($opts[:photo_width])
$opts[:cut_aid_width] = mm_to_px($opts[:cut_aid_width])

## Rest of ARGV is a list of photos to be placed on the sheet of paper.
photo_files = ARGV
photos = {}
boxes = []

# We need to store not only dimensions, but also filename and rotation status.
class PhotoBox < BinPacking::Box
  attr_reader :photo_file
  attr_reader :original_width

  def initialize(width, height, photo_file)
    super(width, height)
    @original_width = width
    @photo_file = photo_file
  end

  # Library doesn't set a flag to let us know box has been rotated, it just swaps width with height.
  # Hence if we remeber original width, we'll know if the image has been rotated - it won't match
  # the new width.
  def rotated?
    return @width != @original_width
  end
end

## Verify that each photo file exists and create objects for each of them (both image magic ones,
## and binpack's).
puts "Reading photo files ...".light_blue
for f in photo_files;
    photos[f] = photo = MiniMagick::Image.open(f)
    real_w, real_h = photo.dimensions
    if real_w < real_h
        target_w = $opts[:photo_width]
        target_h = (real_h.to_f / real_w * $opts[:photo_width]).round(0)
    else
        target_h = $opts[:photo_width]
        target_w = (real_w.to_f / real_h * $opts[:photo_width]).round(0)
    end
    border = $opts[:photo_border_width] + $opts[:photo_margin_width] + 1 # 1px is for the border used for cutting
    box = PhotoBox.new(target_w + border * 2, target_h + border * 2, f)
    boxes.push(box)
    puts "  #{f}"
    puts "    Max size: #{[real_w, real_h]} px -> print #{[real_w.millimeters, real_h.millimeters]} mm"
    puts "    Desired size: #{[target_w, target_h]} px -> print #{[target_w.millimeters, target_h.millimeters]} mm"
    puts "    Border: #{$opts[:photo_border_width]} px (#{$opts[:photo_border_width].millimeters} mm)"
    puts "    Size incl. border, cut aids and margin: #{[box.width, box.height]} px (#{[box.width.millimeters, box.height.millimeters]}) mm"
end

puts "Packing photographs to fit onto a page ...".light_blue
print_area_width = $opts[:paper_width] - 2 * $opts[:paper_margin_width] + 2 * $opts[:photo_margin_width]
print_area_height = $opts[:paper_height] - 2 * $opts[:paper_margin_width] + 2 * $opts[:photo_margin_width]
puts "  Paper size (including margins): #{$opts[:paper_width]}, #{$opts[:paper_height]} px"
puts "  Printable area size (without paper margins): #{print_area_width},#{print_area_height} px, #{print_area_width.millimeters},#{print_area_height.millimeters} mm."

# This is ugly and potentially really slow, however, BinPacking library isn't the smartes and it
# sometimes misses the most obvios solution - which can be fixed by reordering boxes.
permutations = boxes.permutation
puts "Found #{permutations.size} permutations. Going through them one by one until I can fit all the boxes on a page ...".light_blue
perm_i = 0
perm_progress_bar = ProgressBar.new(permutations.size)
bin = nil
permutations.each do |perm|
    perm_i += 1
    perm_progress_bar.increment!
    bin = BinPacking::Bin.new(print_area_width, print_area_height)
    remaining_boxes = []
    perm.each do |box|
        box.packed = false # Need to clear this as it's marked by bin.insert().
        remaining_boxes << box unless bin.insert(box)
    end
    if remaining_boxes.size == 0
        puts "Found a match after #{perm_i} iterations.".light_blue
        break
    else
        bin = nil
    end
end

if bin == nil
    puts "Could not find a way to fit all those photos on a page :/".red
    exit 3
end

puts "  Photos packed: #{bin.boxes.size}"
puts "  Packing efficiency: #{bin.efficiency}%"


def photo_with_border(box)
    w, h = [box.width, box.height]
    border = $opts[:photo_border_width]
    margin = $opts[:photo_margin_width]
    w_no_border = w - 2 * border - 2 * margin - 2
    h_no_border = h - 2 * border - 2 * margin - 2
    cut_aid_width = $opts[:cut_aid_width]
    return [# Take file with a photo.
            box.photo_file,
            # Rotate image (if needed).
            "-rotate", box.rotated? ? "90" : "0",
            # Resize it to the desired size in pixels (original photograph might be huge).
            "-resize", "#{w_no_border}x#{h_no_border}",
            # Add a white border around the photo.
            "-bordercolor", "white",
            "-border", "#{border}x#{border}",
            # Add a 1 pixel border around the whole thing. It's not meant to be visible,
            # but it will be handy when cutting the photograph out of a larger sheet of paper.
            "-bordercolor", "none",
            "-border", "1x1",
            # Margin around that image.
            "-bordercolor", "white",
            "-border", "#{margin}x#{margin}",
            # Cut aid: top left corner, top right, bottom right, bottom left.
            "-stroke", "#dddddd",
            "-draw", "line 0,#{margin} #{margin + 1 + cut_aid_width},#{margin}",
            "-draw", "line #{margin},0 #{margin},#{margin + cut_aid_width}",
            "-draw", "line #{w},#{margin} #{w - margin - 1 - cut_aid_width},#{margin}",
            "-draw", "line #{w - margin - 1},0 #{w - margin - 1},#{margin + cut_aid_width}",
            "-draw", "line #{w},#{h - margin - 1} #{w - margin - 1 - cut_aid_width},#{h - margin - 1}",
            "-draw", "line #{w - margin - 1},#{h} #{w - margin - 1}, #{h - margin - 1 - cut_aid_width}",
            "-draw", "line 0,#{h - margin - 1} #{margin + 1 + cut_aid_width}, #{h - margin - 1}",
            "-draw", "line #{margin},#{h} #{margin}, #{h - margin - 1 - cut_aid_width}",
            # Place photo in the correct spot of the large sheet of paper.
            "-repage", "+#{box.x}+#{box.y}"]
end

def photo_description(box, label, datetime)
    return ["-background", "none",
            # Size is equal to the photo size including its borders. However, since the photo
            # might be rotated, size of this overlay needs to take that into account to ensure
            # labels appear always on the bottom and top in relation to photograph's orientation.
            "-size", box.rotated? ? "#{box.height}x#{box.width}" : "#{box.width}x#{box.height}",
            # Write the photo description.
            "-gravity", "south",
            "-fill", "black",
            "-pointsize", "6",
            "-font", "Arial",
            "-annotate", "+0+18", label,
            # Write the photo taken date.
            "-gravity", "north",
            "-pointsize", "6",
            "-annotate", "+0+20", datetime,
            # Without this, for some reason, annotations don't appear.
            "caption:",
            # Now rotate the box to match photo rotation.
            "-rotate", box.rotated? ? "90" : "0",
            # Place this overlay in the exact same spot (on the large sheet of paper) where
            # photo has been placed.
            "-repage", "+#{box.x}+#{box.y}"]
end

puts "Rendering final print file with Image Magick ...".light_blue
MiniMagick::Tool::Convert.new do |convert|
  paper_width = $opts[:paper_width] - 2 * $opts[:paper_margin_width]
  paper_height = $opts[:paper_height] - 2 * $opts[:paper_margin_width]

  convert << "-units" << "pixelsperinch" << "-density" << $opts[:dpi] <<  "-size" << "#{paper_width}x#{paper_height}" << "xc:white" << "-flatten"
  boxes.each do |box|
      meta = MiniExiftool.new(box.photo_file)
      title = meta.headline or ""
      datetime = meta.date_time_original
      puts  "  #{box.photo_file}, title: #{title}, date: #{datetime}"
      if title.empty? or not datetime
        puts "    Missing title and/or datetime.".yellow
      end

      if datetime
          day = datetime.strftime("%d")
          year = datetime.strftime("%Y")
          roman_months = {
              1 => "I", 2 => "II", 3 => "III", 4 => "IV", 5 => "V", 6 => "VI", 7 => "VII",
              8 => "VIII", 9 => "IX", 10 => "X", 11 => "XI", 12 => "XII"
          }
          month = roman_months[datetime.month]
          date = "#{day} #{month} #{year}"
      end

      # Place an image, with a border, correctly positioned and rotated.
      convert.stack do |stack|
          for arg in photo_with_border(box);
              stack << arg
          end
      end

      # Place photo descriptions (couldn't get it to work with a single stack because labels might
      # need to be rotated).
      convert.stack do |stack|
          for arg in photo_description(box, UnicodeUtils.upcase(title), date);
              stack << arg
          end
      end
  end

  convert << "-flatten"

  # Apply a margin for the whole page.
  margin = $opts[:paper_margin_width]
  convert << "-bordercolor" << "white" << "-border" << "#{margin}x#{margin}" 

  # Create an output file.
  convert << "canvas.jpg"
end


# convert -size 2480x3425 xc:white -flatten \
#     \( 17-01-31-22-42__DSC3579_v2_4.jpg -resize 1051x709 -bordercolor white -border 47x47 -bordercolor black -border 1x1 -repage +50+150 \) \
#     \( -background none -size 1147x807 -gravity south -fill black -pointsize 34 -font ~/photo-scripts/NotoSans-Regular.ttf -annotate +0+6  "DUPA" caption:"" -repage +50+150 \) \
#     \( 17-01-30-18-41__DSC3413_v1_3.jpg -resize 709x709  -bordercolor white -border 47x47 -bordercolor black -border 1x1 -gravity south -fill black -pointsize 34 -kerning 0 -font ~/photo-scripts/NotoSans-Regular.ttf -annotate +47+6  "Dupa Wołowa" -repage +1363+50 \) \
#     -flatten canvas.jpg
