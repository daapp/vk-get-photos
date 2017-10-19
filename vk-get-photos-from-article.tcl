#! /bin/sh
# \
exec tclsh "$0" ${1+"$@"}

# (c) 2017 Alexander Danilov <alexander.a.danilov@gmail.com>
# This script downloads all images from specified vk.com page
# into current directory. Each page name will prefixed with
# last part of specified url + "__" ++ number_of_image


package require http
package require tls
package require tdom
package require uri
package require fileutil

http::register https 443 tls::socket


if {$argc != 1} {
    puts stderr "Usage: $argv0 url"
    exit 1
} else {
    set prefix [lindex [split [dict get [uri::split [lindex $argv 0]] path] /] end]
    set q1 [http::geturl [lindex $argv 0]]
    set code [lindex [http::code $q1] 1]
    if {$code == 302} {
        set q2 [http::geturl [dict get [http::meta $q1] Location]]
        if {[lindex [http::code $q2] 1] == 200} {
        } else {
            puts stderr "[http::code $q2]"
            exit 1
        }
        set html [http::data $q2]
    } elseif {$code == 200} {
        set html [http::data $q1]
    } else {
        puts stderr [http::code $q1]
        exit 1
    }

    set doc [dom parse -html $html]
    set idx 1
    set nodes [$doc selectNodes {//div[@class="thumb_map_img thumb_map_img_as_div"]}]
    set width [expr {int(log10([llength $nodes]))+1}]
    set fmt "${prefix}__%-[string repeat 0 [expr {$width-1}]]${width}d_%s"
    foreach node $nodes {
        if {[$node hasAttribute data-src_big]} {
            lassign [split [$node getAttribute data-src_big] | ] src _width _height
            puts -nonewline $src
            set filename [format $fmt $idx [lindex [split [dict get [uri::split $src] path] /] end]]
            set id [http::geturl $src -command [list apply {{filename token} {
                fileutil::writeFile -encoding binary $filename [http::data $token]
                puts "     $filename"
            }} $filename]]
            http::wait $id
            incr idx
        }
    }
}

# Local Variables:
# mode: tcl
# End:
