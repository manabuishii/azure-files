# どのように動いているか

cron で、3分ごと定期的にチェックしている。

`wait` コマンドを使用するので、`/bin/bash` を使うようにしている。

# 実際に動いているスクリプト

masterの

```
/usr/local/periodicscript/machine_up_down.sh
```

元のファイルは、


https://github.com/manabuishii/azure-files/blob/master/leader_followers/machine_up_down.sh

このファイルは、以下のファイルが配置する

https://github.com/manabuishii/azure-files/blob/master/leader_followers/azuredeploy.sh

この azuredeploy.sh は、CustomScriptの中から呼ばれる

# スクリプトの動き

```
CONTROLDIRECTORY=/usr/local/periodicscript
MACHINECONTROLDIRECTORY=/usr/local/periodicscript/machine
LOCKFILE=$CONTROLDIRECTORY/azuremanipulate.lock
```

## 落として良いマシンか確認する

3分より古いファイルは、削除する

## スクリプトがすでに動いている確認する

LOCKFILE があるかを確認して、存在していたら、すでにこのスクリプトが動いていると判断し、そこで実行を停止する

確認の方法は

* ファイルとして存在する
* リンクとして存在する

## キューに入っているジョブの数を数える

`qstat -u '*'` で、 `qw` のステータスのものがいくつあるか、確認する

## すでに、停止中のマシンの数を確認する

`stopped` と `deallocated` となっている数を数えた

## 待っているジョブの数が 0 より、大きい

起動していないマシンがあれば、必要な数だけ起動する

### 止まっているマシンの数が 0 より、大きい

以下の方法で、起動する台数をきめて、その数だけ起動する。

`stopped` と `deallocated` されているリストを取得し、

必要な仮想マシンを起動する。このとき、`&` で、起動する。

仮想マシンの起動がおわると、コマンドが終了するので、

``wait`` で、待つ。

#### 止まっているマシンの数より、待っているジョブの数が多い

すべてのマシンを起動させるようにする

#### 止まっているマシンの数のほうが、待っているジョブの数より多い

待っているジョブの数だけ、起動しようとする


### 止まっているマシンがない

あらたに起動できるマシンがないので、なにもしない。


## 待っているジョブがない

起動しているマシンを落とす

### ジョブの数を数える

`qstat -u '*'` の数を数える

#### qstat でジョブの数が0のとき

すべてのマシンについて落とそうとする

マシンを停止対象としてマークしてあれば、 `deallocate` する
マークされていないときは、マークする。今回は何も行わず、次回に停止予定とする。

`deallocate` については、`&` で実行して、`wait` で、待つ

#### ジョブがあるとき

起動しているマシンを探す。
探すときは、以下の文言を探す

##### リスト１を作る。Azureのコマンドで、起動中のノードを探す

Provision 中のものを避けるために、成功したもののみ探す
`Provisioning succeeded`
起動しているものだけを探す
`running`
実行ノードだけを探す
`exec-*`

##### リスト２を作る。ジョブが実行されているノードを探す

実行中のジョブのリストから
`qstat -u '*'` の結果から、`qw`でないもので、実行ノードを探す

TODO: 複数のジョブが走っていることも考慮する

##### 使っていないノードを探す

リスト１にあって、リスト２にないマシンのリストを作る。

マシンを停止対象としてマークしてあれば、 `deallocate` する
マークされていないときは、マークする。今回は何も行わず、次回に停止予定とする。

`deallocate` については、`&` で実行して、`wait` で、待つ
