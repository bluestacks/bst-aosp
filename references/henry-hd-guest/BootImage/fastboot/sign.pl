#!/usr/bin/perl

$initrd_file_name = "initrd.img";
$initrd_file_sz = -s $initrd_file_name;
$initrd_file_sz = pack("L", $initrd_file_sz);

open(SIG, $ARGV[0]) || die "open $ARGV[0]: $!";

$n = sysread(SIG, $buf, 1000);

#if($n > 510){
if($n > 506){
#  print STDERR "boot block too large: $n bytes (max 510)\n";
  print STDERR "boot block too large: $n bytes (max 506)\n";
  exit 1;
}

#print STDERR "boot block is $n bytes (max 510)\n";
print STDERR "boot block is $n bytes (max 506)\n";

#$buf .= "\0" x (510-$n);
$buf .= "\0" x (506-$n);
$buf .= $initrd_file_sz;
$buf .= "\x55\xAA";

open(SIG, ">$ARGV[0]") || die "open >$ARGV[0]: $!";
print SIG $buf;
close SIG;
