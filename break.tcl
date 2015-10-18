#!/usr/bin/env tclsh

proc haxis width {
   puts -nonewline "    "
   for {set i 0} {$i <= [expr {$width/10-1}]} {incr i} {
      puts -nonewline [format "% -10s" "[expr {$i % 10000}]0"]
   }
   puts {}
   puts -nonewline "     "
   for {set i 1} {$i <= [expr {$width-5}]} {incr i} {
      puts -nonewline [expr {$i % 10}]
   }
   puts {}
}

proc bin2dec {bin} {
    if {$bin == 0} {
        return 0
    } elseif {[string match -* $bin]} {
        set sign -
        set bin [string range $bin[set bin {}] 1 end]
    } else {
        set sign {}
    }
    return $sign[expr 0b$bin]
}

proc count_members list {
   foreach x $list {
      lappend ulist($x) {}
   }
   foreach name [array names ulist] {
      set count($name) [llength $ulist($name)]
   }
   return [array get count]
}

proc read_file {file_path i} {
   global ciphertexts
   global maxlen
   global c

   set fp [open $file_path r]
   set file_data [read $fp]
   close $fp

   set data [split $file_data " "]

   set j 0
   set c($i) [list]
   foreach byte $data {
      set symbol [bin2dec $byte]
      set ciphertexts($i,[incr j]) $symbol
      lappend c($i) $symbol
   }
   if {$maxlen < $j} {set maxlen $j} 
}

proc break_spaces {} {
   global key
   global maxlen
   global argc
   global ciphertexts
   for {set j 1} {$j <= $maxlen} {incr j} {
      set firsthalf [list]
      set secondhalf [list]
      for {set i 1} {$i <= $argc} {incr i} {
         if {[info exists ciphertexts($i,$j)]} {
            set byte $ciphertexts($i,$j)
            if {$byte > 64} {
               lappend firsthalf $byte
            } else {
               lappend secondhalf $byte
            }
         }
      }
      if {[llength $firsthalf] < [llength $secondhalf]} {
         set space [lindex [lsort -stride 2 -index 1 -decreasing [count_members $firsthalf]] 0]
      } else {
         set space [lindex [lsort -stride 2 -index 1 -decreasing [count_members $secondhalf]] 0]
      }
      if {$space == {}} {
         lappend key {}
      } else {
         lappend key [expr {$space ^ 32}]
      }
   }
}

# initialize global variables
set maxlen 0
set term_width [lindex [exec stty size] 1]
set key [list]
array set c {}
array set ciphertexts {}

# read files
set i 0
foreach ciphertext_file $argv {
   read_file $ciphertext_file [incr i]
}

# output starts here
set width [expr {min($term_width,$maxlen)}]

haxis $width 
   
break_spaces

proc show_plaintexts {lines_from lines_to columns_from columns_to} {
   global argc
   global key
   global c
   
   for {set i $lines_from} {$i <= $lines_to} {incr i} {
      puts -nonewline "[format %03d $i]: "
      foreach keybyte [lrange $key $columns_from $columns_to] byte [lrange $c($i) $columns_from $columns_to] {
         if {$keybyte == {} || $byte == {} } {
            puts -nonewline -
         } else {
            set symbol [format %c [expr {$keybyte ^ $byte}]]
            if [string is print $symbol] {
               puts -nonewline $symbol
            } else {
               puts -nonewline +
            }
         }
      }
      puts {}
   }
}

show_plaintexts 1 $argc 1 [expr {$width-5}]
puts {}
show_plaintexts 1 $argc [expr {$width+1}] [expr {$width+$width-5}]
   
exit
set cmd ""
while 1 {
   if { "$cmd" != "" } {
      # Why "format catch"?  It "is a legacy workaround
      #     for an old bytcode compiler bug."  We should
      #     find out when it's fixed, and "package require
            #     Tcl ..." appropriately.
      catch {[format catch] $::tcl_prompt2}
   } else {
      if {[catch {[format catch] $::tcl_prompt1}]} {
         puts -nonewline "% "
      }
   }
   flush stdout
   append cmd \n[gets stdin]
   if [ info complete $cmd ] {
      catch $cmd res
      puts $res
      set cmd ""
   }
}
