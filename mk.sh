# 各種フラグ
ASM_FLG="--debug-info"
LD_FLG="--dbgfile fdsv3.dbg -Ln fdsv3.lbl"

# ビルド日時タイトル表示用
date +"%y%m%d%H%M" > datetime.s

#
ca65 fdsv3.s -g $ASM_FLG
if [ "$?" -eq 0 ]; then
	ld65 -o fdsv3.bin -C fdsv3.cfg fdsv3.o $LD_FLG

	fdspacker pack fdsv3.json fdsv3.fds
	echo
else
	echo
	echo	"Error"
	echo
fi
