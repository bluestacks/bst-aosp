#!/bin/bash
# Research r262 BLAST / shell transitions for P2-TEMP-BLAST
set -e
A=~/aosp16
echo === r262 patch local/remote ===
ls -la ~/bst-aosp/patches/android-16/patches/*r262* 2>/dev/null || true
ls -la $A/frameworks/base/**/*shell*transition* 2>/dev/null | head
rg -n "ENABLE_SHELL_TRANSITIONS|SHELL_TRANSITIONS|r262|TEMP.*shell" $A/frameworks/base --glob "*.java" 2>/dev/null | head -40
echo === SF / BLAST goldfish ===
rg -n "BLAST|BufferQueue|commit.*callback|presentFence" $A/frameworks/native/services/surfaceflinger --glob "*.cpp" 2>/dev/null | head -20
rg -n "BLAST|commit" ~/ggl/goldfish-opengl-pie -g "*.cpp" 2>/dev/null | head -20 || rg -n "BLAST|commit" $A/../ggl/goldfish-opengl-pie -g "*.cpp" 2>/dev/null | head -20
echo DONE_BLAST_RESEARCH
