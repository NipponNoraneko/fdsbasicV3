# [WIP] *Family BASIC V3 on Disk System*
https://github.com/NipponNoraneko/FC-DiskBASIC/tree/v3 から分離しました。<br>
今後はこのリポジトリを更新していきます。<br>

最近の更新<BR>
- ファイルリネーム: FDSRENコマンドを仮実装<br>
- ファイル削除: FDSDELコマンドを仮実装<br>
- [テル氏](https://x.com/teru72ig)のPAC-WORLDを同梱<br>
- 許諾画面のスキップ<br>
- fdsファイルの作成に [fdspacker](https://github.com/ClusterM/fdspacker)を使用<br>
- BASICファイルのLOAD/SAVE<br>

## Disk Systemで Family BASIC V3
![fdsv3_001](img/fdsv3_001.png)
![fdsv3_000](img/fdsv3_000.png)
![fdsv3_002](img/fdsv3_002.png)
### 追加機能
1. ディスクカードアクセス(実験中)<br>
現在は$6000から$6fffをBASICプログラムとして扱っています。今後仕様の変更を行いますのでご注意ください。
    - FDS<br>
    ディスクカードのファイル一覧を表示
    - FDSLIST<br>
ディスクカードのファイル詳細を表示<br>
    - FDSLOAD fileID<br>
    BASICプログラムを読み込みます。引数にはFDS/FDSLISTで表示されるfileIDを指定します。
    - FDSSAVE "filename"<br>
    BASICプログラムを保存します。ファイル名が同じ場合は上書きされます。<br>
    - FDSDEL fileID<br>
    ファイルを削除します。引数にはFDS/FDSLISTで表示されるfileIDを指定します。<br>
    
    ※ディスクカードの残量を見ていませんので、たくさんファイルを追加すると壊れます。

2. 簡易モニタ(未完成)<BR>
メモリ内容の表示・変更を行います。<br>
  ■起動:　ダイレクトモードでMONと入力<br>
   MON<br>
  - D<br>
メモリ・ダンプ
  - M<br>
メモリ変更
  - Q<br>
終了

## ビルド
### 準備
- [fdspacker](https://github.com/ClusterM/fdspacker): .fdsファイルの作成に使用します。
- [ca65,ld65(cc65スイート)](https://cc65.github.io/): アセンブラ、リンカ
- Family BASIC V3 と、その .nesファイル<br>
  ※"FamilyBasicV3.nes"として配置します。<br>
  
### 作成
```
ca65 fbv3d.s
ld65 -o fbv3d.bin -C fbv3d.cfg fbv3d.o
fdspacker pack fbv3d.json fbv3d.fds
```

## テスト/デバッグ環境
- [Mesen2](https://www.mesen.ca/)

## 謝辞
- [Micah Cowan](https://github.com/micahcowan)'s: GitHub [Family BASIC V3 逆アセンブル](https://github.com/micahcowan/fbdasm)
- [TakuikaNinja](https://github.com/TakuikaNinja)'s: GitHub [FDS BIOS ROM 逆アセンブリ](https://github.com/TakuikaNinja/FDS-disksys)
- PAC-WORLD<br>
[テル氏](https://x.com/teru72ig) 同梱の許可をいただきました。
- 許諾画面スキップ<br>
  - Forum discussion:<br> https://forums.nesdev.org/viewtopic.php?t=25171
  - Github bbbradsmith/NES-ca65-example<br> https://github.com/bbbradsmith/NES-ca65-example/tree/fds
- [ClusterM](https://github.com/ClusterM)'s: GitHub [fdspacker](https://github.com/ClusterM/fdspacker)
