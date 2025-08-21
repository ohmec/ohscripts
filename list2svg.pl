#!/usr/bin/perl

use strict;
use POSIX qw(strftime);

my %info;
my @parentless;
my $todayy = strftime "%Y", localtime;
my %placed;
my $EACHH = 29;
my $EACHY = $EACHH + 5;

while(<>)
  {
  chomp;
  s/^\s*#.*$//;
  next if /^\s*$/;
  if(m|^..([A-Z]{4}) \s+     # $1: id
        (.+\S) \s+           # $2: name
        ([A-Z-]{4}) \s+      # $3: parent
        ([\w-]+) \s+         # $4: type
        ([\w?*]+) \s+        # $5: from
        ([\w?*]+) \s+        # $6: to
        ([a-z-]+) \s+        # $7: isoname
        (\d*) \s*            # $8: isonum (optional)
        (https\S+) \s*       # $9: url
        (.*) \s* $|x)        # $10: example|image (optional)
    {
    my($id,$name,$parent,$type,$from,$to,$isoname,$isonum,$url,$example_or_image) = ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10);
    if(defined $info{$id})
      { die "FATAL: Duplicate ID for $id\n" }
    $info{$id}{"name"} = $name;
    if($parent =~ /-/)
      { push(@parentless, $id) }
    elsif(not defined $info{$parent})
      { die "FATAL: can't find info on parent of $id: $parent\n" }
    else
      {
      $info{$id}{"parent"} = $parent;
      push(@{$info{$parent}{"children"}}, $id);
      }
    $info{$id}{"type"} = $type;
    $info{$id}{"from"} = $from;
    $info{$id}{"to"} = $to;
    $info{$id}{"isoname"} = $isoname if $isoname =~ /^[a-z]*$/;
    $info{$id}{"isonum"} = $isonum if defined $isonum;
    $info{$id}{"url"} = $url;
    $info{$id}{"image"} = $1 if defined $example_or_image and $example_or_image =~ /img:(.*)/;
    $info{$id}{"example"} = $example_or_image if defined $example_or_image and $example_or_image !~ /img:/;
    }
  else
    { print STDERR "what is this on line $.: $_\n" }
  }

# algorithm for placement
#
# first go through all of the parent-less items, and place them top to bottom
# based upon inception date.
#
# next go through each of their children, and place them below based upon their
# start date

my $lasty = 5;
my $firstdate;
foreach my $id (sort { &year($info{$a}{"from"},$a) <=> &year($info{$b}{"from"},$b) } @parentless)
  {
  $firstdate = &year($info{$id}{"from"},$id) if not defined $firstdate;
  $lasty = &add_to_chart_recurse($id,$lasty+1)
  }

my $finaly = $lasty;
my $XOFFSET = $firstdate;
my $HEIGHT = $finaly*$EACHY+80;
my $WIDTH = $todayy-$XOFFSET+800;

&print_svg_header($WIDTH,$HEIGHT);
foreach my $y (6..$lasty)
  {
  &print_parent_connection($placed{$y});
  &print_svg_object($placed{$y});
  }
print "</svg>\n";

sub add_to_chart_recurse
  {
  my($id,$cury) = @_;
  $info{$id}{"y"} = $cury;
  $placed{$cury} = $id;
  my $fyear = &year($info{$id}{"from"},$id);
  my $tyear = &year($info{$id}{"to"},$id);
  my $lasty = $cury;
  foreach my $cid (sort { &year($info{$a}{"from"},$a) <=> &year($info{$b}{"from"},$b) } @{$info{$id}{"children"}})
    { $lasty = &add_to_chart_recurse($cid,$lasty+1) }
  $lasty
  }

sub year
  {
  my($datetext,$id) = @_;
  if($datetext =~ /^(\d+)[?*]?$/)
    { return $1 }
  if($datetext =~ /^(\d+)AD[?*]?$/)
    { return $1 }
  if($datetext =~ /^(\d+)BC[?*]?$/)
    { return -$1 }
  if($datetext =~ /present/)
    { return $todayy }
  if($datetext eq '?')
    {
    my $pid = $info{$id}{"parent"};
    return &year($info{$pid}{"from"},$pid) + 100
    }
  return 1000 # completely arbitrary for now
  }

sub print_svg_header
  {
  my($width,$height) = @_;
  print qq|<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="background-color:white" width="$width" height="$height">
  <defs>
    <style>
      rect {
        stroke: #000;
        stroke-width: 2px;
      }
      rect:hover {
        fill: #ccf;
        stroke-width: 3px;
      }
      .rectlogo { fill: #ffffe0; }
      .rectabjd { fill: #d0ffd0; }
      .rectabug { fill: #e0ffe0; }
      .rectalph { fill: #e0e0ff; }
      .rectsyll { fill: #e0ffff; }
      .rectsmsy { fill: #c0ffff; }
      .rectlogc { fill: #ffffc0; }
      .rectpict { fill: #ffe0ff; }
      .rectunkn { fill: #c0c0c0; }
      .linec {
        fill: none;
        stroke: #000;
        stroke-width: 3px;
      }
      .langtextb {
        font-size: 14px;
        font-weight: bold;
        fill: #181818;
        font-family: Baskerville;
        pointer-events: none;
      }
      image {
        pointer-events: none;
      }
      tspan {
        font-weight: normal;
      }
      .circc {
        fill: #ff8080;
        stroke: #000;
        stroke-width: 2px;
      }
    </style>
  </defs>
  <text class="langtext" transform="translate(5, 30) scale(2.0)">Human Language Script Evolution</text>
  <text class="langtext" transform="translate(5, 60) scale(1.2)">The chart below is a generated representation of sorts of the family tree of human language scripts, beginning with Proto Cuneiform</text>
  <text class="langtext" transform="translate(5, 80) scale(1.2)">in approximately 3400BC, and continuing through *all scripts in history. The information is gleaned from Wikipedia pages of the scripts.</text>
  <text class="langtext" transform="translate(5,100) scale(1.2)">(* It is still a work in progress.) Each script shown gives its genealogy: ancestors and children. Its placement on the horizontal axis</text>
  <text class="langtext" transform="translate(5,120) scale(1.2)">indicates its approximate beginning of use, and the width indicates its duration. The colors of the bars indicates the type of script.</text>
  <text class="langtext" transform="translate(5,140) scale(1.2)">You can click on the bar of any script to go to the representative wikipedia page.</text>
  <a href="https://en.wikipedia.org/wiki/pictogram#historical" target="_blank"><rect class="rectpict" x="5"    y="165" width="150" height="29" rx="5"/></a>
  <a href="https://en.wikipedia.org/wiki/logography"           target="_blank"><rect class="rectlogo" x="180"  y="165" width="150" height="29" rx="5"/></a>
  <a href="https://en.wikipedia.org/wiki/logoconsonantal"      target="_blank"><rect class="rectlogc" x="355"  y="165" width="150" height="29" rx="5"/></a>
  <a href="https://en.wikipedia.org/wiki/syllabary"            target="_blank"><rect class="rectsyll" x="530"  y="165" width="150" height="29" rx="5"/></a>
  <a href="https://en.wikipedia.org/wiki/semi-syllabary"       target="_blank"><rect class="rectsmsy" x="705"  y="165" width="150" height="29" rx="5"/></a>
  <a href="https://en.wikipedia.org/wiki/abjad"                target="_blank"><rect class="rectabjd" x="880"  y="165" width="150" height="29" rx="5"/></a>
  <a href="https://en.wikipedia.org/wiki/abugida"              target="_blank"><rect class="rectabug" x="1055" y="165" width="150" height="29" rx="5"/></a>
  <a href="https://en.wikipedia.org/wiki/alphabet"             target="_blank"><rect class="rectalph" x="1230" y="165" width="150" height="29" rx="5"/></a>
  <text class="langtextb" transform="translate(15,185)   scale(1.2)">Pictograph</text>
  <text class="langtextb" transform="translate(190,185)  scale(1.2)">Logography</text>
  <text class="langtextb" transform="translate(365,185)  scale(1.2)">Logoconsonantal</text>
  <text class="langtextb" transform="translate(540,185)  scale(1.2)">Syllabary</text>
  <text class="langtextb" transform="translate(715,185)  scale(1.2)">Semi-syllabary</text>
  <text class="langtextb" transform="translate(890,185)  scale(1.2)">Abjad</text>
  <text class="langtextb" transform="translate(1065,185) scale(1.2)">Abugida</text>
  <text class="langtextb" transform="translate(1240,185) scale(1.2)">Alphabet</text>\n|;
  for(my $year=$firstdate;$year<=$todayy;$year+=100)
    {
    my $str = ($year >= 0) ? $year."AD" : (-$year)."BC";
    my $x = $year - $XOFFSET + 25;
    my $y = 230;
    print qq|  <text class="langtext" transform="translate($x,$y) scale(1.0)">$str</text>\n|;
    }
  }

sub recttype
  {
  my($type) = @_;
  return "rectlogo" if $type eq "Logography";
  return "rectlogo" if $type eq "Logographic";
  return "rectpict" if $type eq "Pictograph";
  return "rectabjd" if $type eq "Abjad";
  return "rectabug" if $type eq "Abugida";
  return "rectalph" if $type eq "Alphabet";
  return "rectsyll" if $type eq "Syllabery";
  return "rectsyll" if $type eq "Syllabary";
  return "rectsmsy" if $type eq "Semisyllabery";
  return "rectsmsy" if $type eq "Semi-syllabic";
  return "rectlogc" if $type eq "Logoconsonantal";
  return "rectunkn";
  }

sub print_parent_connection
  {
  my($id) = @_;
  my $pid = $info{$id}{"parent"};
  if(defined $pid)
    { &print_parent_child_line($id,$pid) }
  else
    { &print_parent_stub($id) }
  }

sub featurew
  {
  my($id) = @_;
  &year($info{$id}{"to"},$id) - &year($info{$id}{"from"},$id)
  }

sub featureh
  {
  $EACHH
  }

sub featurex
  {
  my($id) = @_;
  &year($info{$id}{"from"},$id) - $XOFFSET + 25
  }

sub featurey
  {
  my($id) = @_;
  ($info{$id}{"y"}+1)*$EACHY+2
  }

sub print_parent_stub
  {
  my($id) = @_;
  my $x = &featurex($id);
  my $y = &featurey($id) + &featureh($id)/2;
  my $xm10 = $x-10;
  my $xm12 = $x-12;
  print qq|  <line class="linec" x1="$x" y1="$y" x2="$xm10" y2="$y" />\n|;
  print qq|  <circle class="circc" cx="$xm12" cy="$y" r="4" />\n|;
  }

sub print_parent_child_line
  {
  my($id,$pid) = @_;
  my $x1 = &featurex($pid) + 7;
  my $y1 = &featurey($pid) + &featureh($pid);
  my $x2 = &featurex($id);
  my $y2 = &featurey($id) + &featureh($pid)/2;
  if($x2<$x1)
    { print STDERR "WARN: parent $pid of child $id is >= start date (".$info{$id}{"from"}." compared to ".$info{$pid}{"from"}.")\n" }
  my $y2m4 = $y2-8;
  my $x1p4 = $x1+8;
  print qq|  <path class="linec" d="M $x1,$y1 V $y2m4 C $x1,$y2 $x1,$y2 $x1p4,$y2 H $x2" />\n|;
  }

sub print_svg_object
  {
  my($id) = @_;
  my $name = $info{$id}{"name"};
  my $example = $info{$id}{"example"};
  my $image = $info{$id}{"image"};
  my $x = &featurex($id);
  my $y = &featurey($id);
  my $w = &featurew($id);
  my $h = &featureh($id);
  my $recttype = &recttype($info{$id}{"type"});
  my $rx = 5;
  my $x10 = $x+10;
  my $y5 = $y+16;
  my $url = $info{$id}{"url"};
  print qq|  <!-- $id -->\n|;
  print qq|  <a href="$url" target="_blank"><rect class="$recttype" x="$x" y="$y" width="$w" height="$h" rx="$rx"/></a>\n|;
  print qq|  <text class="langtextb" transform="translate($x10,$y5) scale(1.0)"|;
  if(defined $example)
    {
    while($example =~ /\&#x(\w+)(\s*)-\s*(\w+);/)
      {
      my $to;
      my $val1 = $1;
      my $hval1 = hex $1;
      my $space = $2;
      my $val2 = $3;
      my $hval2 = hex $3;
      my $diff = ($hval2>$hval1) ? 1 : -1;
      my $replace;
      for(my $val=$hval1;$val!=($hval2+$diff);$val+=$diff)
        { $replace .= sprintf "&#x%x;%s", $val, $space }
      $replace =~ s/\s*$//;
      $example =~ s/\&#x$val1\s*-\s*$val2;/$replace/;
      }
    print ">$id $name\n    <tspan>$example</tspan>\n  </text>\n"
    }
  elsif(defined $image)
    {
    my $tlen = length("$id $name");
    my $tw = $tlen*8+10;
    my $ix = $x+$tlen*8+25;
    my $iy = $y+2;
    my $ih = $h-12;
    print qq| textLength="${tw}px">$id $name</text>\n  <image x="$ix" y="$iy" height="$ih" href="$image" />\n|
    }
  else
    { print ">$id $name</text>\n" }
  }
