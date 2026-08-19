# VALOTRACK 配布

VALOTRACK の更新を配るための置き場です。中身は `docs/` だけ。

- `docs/manifest.json` … アプリが見に行くファイル（版と入手先）
- `docs/VALOTRACK-Setup.exe` … インストーラー本体
- `docs/index.html` … 自分用の管理ページ

GitHub Pages を有効にすると、次のURLで公開されます。

```
https://<あなたのGitHub名>.github.io/<リポジトリ名>/manifest.json
https://<あなたのGitHub名>.github.io/<リポジトリ名>/VALOTRACK-Setup.exe
```

どちらもログイン不要で読めるので、利用者のアプリが更新に気づけます。

---

## 最初の1回だけ

1. GitHub で**空のリポジトリ**を作る（公開・Public にする）
   - Pages は公開リポジトリでないと無料で使えません
   - README などは追加しない（空のまま作る）

2. このフォルダで次を実行する

```
powershell -File push-to-github.ps1 -Url https://github.com/あなた/リポジトリ名.git
```

3. GitHub の **Settings → Pages** を開き
   - Source: `Deploy from a branch`
   - Branch: `main` / フォルダ: `/docs`
   - Save

   1〜2分で `https://…github.io/…/manifest.json` が見えるようになります。

4. そのURLを VALOTRACK 側に教える

```
powershell -File ..\valotrack\app\release.ps1 -UpdateUrl https://…github.io/…/manifest.json -Bump minor -Notes "更新機能に対応"
```

5. できた `VALOTRACK-Setup.exe` を利用者に**一度だけ**手渡す

これで完了です。以降は手渡し不要になります。

---

## 2回目以降（新しい版を出す）

```
powershell -File ..\valotrack\app\release.ps1 -Bump patch -Notes "変えたところ"
powershell -File push-to-github.ps1
```

利用者は次に VALOTRACK を起動したとき、画面の上に知らせが出ます。
「更新する」を押すまで、落としてくることも入れ替えることもありません。

---

## 注意

- `docs/` の中は**誰でも読めます**。見られて困るものは置かないでください。
- 版を下げると更新が誰にも届きません。`release.ps1` が止めてくれます。
- exe は毎回まるごと入るので、リポジトリは少しずつ大きくなります。
  気になったら古い履歴を整理してください（普通は気にしなくて大丈夫です）。
