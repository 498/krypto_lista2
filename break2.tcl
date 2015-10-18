#!/usr/bin/env tclsh

package require rc4

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

foreach arg $argv {
   append ciphertext [format %c [bin2dec $arg]]
}

puts $ciphertext

for {set i 0} {$i < 4294967296} {incr i} {
   set keydata [format %08x $i]a6035635
   #set key  [ ::rc4::RC4Init $keydata ]
   #set plaintext [::rc4::RC4 $key $ciphertext]
   set plaintext [rc4::rc4 -key $keydata $ciphertext]
   if {[string is print $plaintext]} {
      puts -nonewline "$keydata "
      puts $plaintext
   }
   unset plaintext
   #rc4::RC4Final $keydata
   unset keydata
}
