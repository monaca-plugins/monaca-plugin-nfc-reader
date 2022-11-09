# @monaca/monaca-plugin-nfc-reader

Monaca NFCリーダープラグイン

## 説明

このプラグインではNFCタグの情報を読み取ることができます。

- タグIDの読み取り
  NFCタグに割り振られた固有のIDを読み取ることができます。
- ブロックデータ読み取り(FeliCa[^1]のみ)
  FeliCaのブロックデータを読み取ることができます。

## 対象プラットフォーム

### ビルド環境

- Cordova 11.0.0 以降
- cordova iOSプラットフォーム 6.2.0 以降
- Swift 4 以降 (5 以降推奨)

androidは未対応

### 動作環境

- iOS 13 以降
- iPhone 7 以降

## 対応するNFCタグの種類

- NFC Type A (Mifare[^2])
- NFC Type F (FeliCa)

## API の解説

### readId

```
monaca.NfcReader.readId(successCallback, failCallback, args)
```

NFCタグのIDを読み込みます。
Type A: UID / Type F: IDm
NFC Type Bには対応していません。

#### successCallback

successCallback(result)

result: 以下のデータが返されます。

```
{
  "type": "typeA",  // NFCタグの種類 (typeA / typeF)
  "id": "xxxxxxxxxx",  // NFCタグのID
  "cancelled": false // 読み取りがキャンセルされたかどうか
}
```

- idは16進数文字列です。
- idの桁数はNFCタグの種類によって変わります。
- FeliCaではアプリケーションに指定されたシステムコード(後述)に対応するIDが返ります。
  - プラグインのデフォルトではシステムコード=`0003`のカードに設定されています。
  - システムコードを変更したい場合や、異なる複数のシステムコードのIDの読み取りに対応したい場合は、後述の[システムコードの指定](#システムコードの指定)を参照してください。

#### failCallback

failCallback(error)

error: エラーメッセージ(文字列)

エラーの内容は[エラーメッセージ](#エラーメッセージ)参照

#### args

```
{
  "message" : "NFCタグをスマートフォンに近づけてください"
}
```

| parameter | type | optional | default value | description |
|---|---|---|---|---|
| message | string | YES | "Bring the NFC tag closer to your Smartphone" | 検出中のUIに表示されるメッセージ文字列 |

#### 例

```javascript
  monaca.NfcReader.readId((result) => {
    if (result.cancelled) {
      // cancelled
    } else {
      // success
      const detected_id = result.id;
      const detected_type = result.type;
    }
  }, (error) => {
    // error
    const error_message = error;
  }, {
      "message" : "NFCタグをスマートフォンに近づけてください"
  });
```

### readBlockData

```
monaca.NfcReader.readBlockData(successCallback, failCallback, args)
```

FeliCaのブロックデータを読み込みます。

#### successCallback

successCallback(result)

result: 以下のデータが返されます。

```
{
  "type": "typeF",  // NFCタグの種類 (typeF)
  "id": "xxxxxxxxxx",  // NFCタグのID
  "cancelled": false, // 読み取りがキャンセルされたかどうか
  "data": [n][16]   // blockData[n][16]  1ブロック=16byte x n(n: 0 .. count-1)
}
```

- 指定したサービスコード・システムコード(後述)に対応するIDおよびブロックデータが返ります。

#### failCallback

failCallback(error)

error: エラーメッセージ(文字列)

エラーの内容は[エラーメッセージ](./エラーメッセージ)参照

#### args

```
{
  "service_code" : [ 0x09, 0x0f ],  // サービスコード
  "start" : 0,  // 読み取り開始インデックス
  "count" : 12, // 読み取りブロック数 (count <= 12)
  "message" : "NFCタグをスマートフォンに近づけてください"
}
```

| parameter | type | optional | default value | description |
|---|---|---|---|---|
| service_code | array(byte[2]) | NO | - | サービスコード |
| start | int | NO | - | 読み取り開始インデックス (0 <= start < 20) |
| count | int | NO | - | 読み取りブロック数 (count <= 12) |
| message | string | YES | "Bring the NFC tag closer to your Smartphone" | 検出中のUIに表示されるメッセージ文字列 |

- 指定したサービスコード(後述)に対応するデータが返ります。
  - サービスコードは１つのみ対応しています。複数のサービスコードを指定することはできません。
  - システムコードを指定したい場合は、後述の[システムコードの指定](#システムコードの指定)を参照してください。
  
- FeliCaのブロックデータは最大20個です。
- 一度に読み取れるブロックデータ数は12個までです。
  - count <= 12
  - start + count <= 20

#### 例

```javascript
  monaca.NfcReader.readBlockData((result) => {
    if (result.cancelled) {
      // cancelled
    } else {
      // success
      const detected_id = result.id;
      const detected_type = result.type;
      const blockData = result.data;

      // convert block data to traffic IC history
      const history = blockData.map(block => {
        return monaca.NfcReader.convertToHistory(block);
      });
    }
  }, (error) => {
    // error
    const error_message = error;
  }, {
    "service_code" : [ 0x09, 0x0f ],
    "start" : 0,  // start index
    "count" : 12, // count
    "message" : "NFCタグをスマートフォンに近づけてください"
  });
```

### エラーメッセージ

| message | description |
|---|---|
| "Invalid Arguments" | 引数指定のエラー |
| "NFC Not Available" | NFCが使用できない |
| "NFC Connection Error" | NFC接続時のエラー|
| "Feature Not Supported" | 対応していない機能の呼び出し(typeA + readBlockData etc.) |
| "Unsupported NFC Tag is detected" | 未対応のNFCタグの検出 |
| "Request Service Error" | サービスコードの指定エラー |
| "Read Block Data Error" | ブロックデータ読み込みエラー |
| "Read Block Data Error: Invalid Status Code" | ブロックデータ読み込み ステータスコード異常 |
| "NFC Session timed out" | NFC読み取りタイムアウト |
| "Unhandled NFC error" | その他のNFCエラー |

## iOS 特有の動作

プラグインの使用にはアプリケーションの`config.xml`に以下の設定を追加する必要があります。

- Swiftバージョンの指定(必須)
- システムコードの指定(任意)

### Swiftバージョンの指定

このプラグインはSwiftで書かれています。
アプリケーションの `config.xml` にてSwiftのバージョンを指定する必要があります。
`config.xml`に以下の記述を追加してください。

```
<platform name="ios">
  <preference name="SwiftVersion" value="5"/>
</platform>
```

### システムコードの指定

プラグインにデフォルトで指定されているFeliCaシステムコードは`0003`です。
このコードを変更もしくは追加したい場合はアプリケーションの`config.xml`にコードを定義して設定を上書きしてください。

`0003`を`fe00`に変更する場合
```
<platform name="ios">
  <edit-config target="com.apple.developer.nfc.readersession.felica.systemcodes" file="*-Info.plist" mode="overwrite">
    <array>
      <string>fe00</string>
    </array>
  </edit-config>
</platform>
```

複数のシステムコード`0003`、`fe00`を指定する場合
```
<platform name="ios">
  <edit-config target="com.apple.developer.nfc.readersession.felica.systemcodes" file="*-Info.plist" mode="overwrite">
    <array>
      <string>0003</string>
      <string>fe00</string>
    </array>
  </edit-config>
</platform>
```

### 記述例

```config.xml
    <platform name="ios">
        <preference name="SwiftVersion" value="5"/>
        <edit-config target="com.apple.developer.nfc.readersession.felica.systemcodes" file="*-Info.plist" mode="overwrite">
            <array>
                <string>0003</string>
            </array>
        </edit-config>
    </platform>
```

## 補足

### FeliCaの読み込みについて

#### システムコード

FeliCaにおいて事業者や使用目的ごとに割り当てられたコードをシステムコードと呼びます。
FeliCaカードを採用しているサービスごとに異なるシステムコードが割り当てられています。
前述のようにアプリケーションに複数のシステムコードを設定しておくことで複数の種類のFeliCaカードに対応することができます。

また、FeliCaカードでは１枚のカードの中に複数のシステム領域を持つことができます。
この場合、１枚のカード内には複数のシステムコードが存在します。ID(IDm)はシステム領域ごとに割り当てられています。
対象のIDを取得するにはシステムコードの指定が必要となります。

iOSアプリケーションでは対応するシステムコードを`*.plist`ファイルに指定しておく必要があります。
この設定方法については前述の[システムコードの指定](#システムコードの指定)を参照してください。

#### サービスコード

FeliCaのシステム領域の中にはサービスと呼ばれる領域が存在します。複数のサービス領域が存在し、その中にブロックデータが格納されています。
どのサービス領域のブロックデータを取得するか特定するためにサービスコードが用いられます。

ブロックデータの取得にはシステムコードとサービスコードの両方が必要です。

#### プラグインの対応状況

- `readId()`では複数の種類のカードに対応しています。
- １枚のカードに複数のシステム領域が割り当てられている場合、`readId()`で取得できるIDは１つのみです。
- `readBlockData()`では複数の種類のカード(複数のシステムコード)に対応していますが、現在指定できるサービスコードは１つのみとなります。
  異なるサービスコードを持つカードを読み取った場合はエラーが返ります。

### 応用

ブロックデータの活用方法の１つとして、交通系ICカードの利用履歴の読み取りが挙げられます。
このプラグインでは参考としてブロックデータから利用履歴への変換メソッドを提供しています。

```
/**
 * Convert blockData to traffic history
 * @param {int[16]} blockData
 * @return {object} traffic history object
 */
monaca.NfcReader.convertToHistory(blockData)
```

traffic history object:
```
{
  "year": 2022, // 年
  "month": 11,  // 月
  "day": 1,   // 日
  "boarding_station_code": [xxx, xxx], // 乗車駅(2byte)
  "exit_station_code": [xxx, xxx],  // 降車駅(2byte)
  "balance": 1000   // 残高
}
```

使用例
```
    monaca.NfcReader.readBlockData((result) => {
        if (result.cancelled) {

        } else {
            const history = result.data.map(block => {
                return monaca.NfcReader.convertToHistory(block);
            });
        }
    }, (error) => {

    }, {
      // (略)
    });
```

**注意**

交通系ICのデータ形式は公表されていません。
`convertToHistory`の処理は独自の調査結果により実装されています。
このメソッドに関してはあくまでも参考程度として、以下の方針のもと提供させて頂きます。
- 全ての交通系ICカードに対応しているものではありません。
- 一般的な交通系ICカードの列車の乗降履歴のみに対応しています。
- それ以外の乗り物や買い物の履歴などはデータ形式が異なるケースがあり対応していません。
- このメソッドに関しての一切の動作保証は致しかねます。
- 今後のバージョンでの提供や互換性に関しても未定となります。

## 注意事項

### FeliCaおよび関連の技術方式について

- FeliCaはソニー株式会社の登録商標です。
- このドキュメント内に記載されたFeliCaおよびそれに関する技術用語はソニー株式会社様により公開されている技術資料を基に構成されています。
- システムコード、サービスコード等の数値については対応するカード・サービスの事業者様より提供を受けた上でご利用ください。

## License

see [LICENSE](./LICENSE)

[^1]: FeliCa はソニー株式会社の登録商標です。
[^2]: Mifare はNXPセミコンダクターズN.V.の登録商標です。
