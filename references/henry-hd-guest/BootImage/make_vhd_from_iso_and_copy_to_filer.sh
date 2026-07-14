rm -f fastboot.vdi
VBoxManage convertfromraw --uuid 4da0cf19-7a5d-474d-9748-2c31c11fbbd6 Boot_efi.iso fastboot.vdi
rm -f fastboot.vhd
VBoxManage clonehd fastboot.vdi fastboot.vhd --format VHD
cp fastboot.vhd ~/mac_home/filer_Bluestacks/abhimanyu/
