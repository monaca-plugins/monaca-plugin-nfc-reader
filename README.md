# monaca-plugin-nfc-reader

NFC Reader Monaca Plugin.

## Description

This plugin provides reading NFC tag features.

- readId: read NFC Tag ID (NFC typeA(MiFare) / typeF(Felica))
- readBlockData: read Felica Block Data (NFC typeF(Felica))

## Supported Platforms

### Build Environments

- Cordova 11.0.0 or later
- cordova-ios@6.2.0 or later
- Swift 4 or later (5 or later recommended)

### Operating Environments

- iOS 13 or later

## Supported NFC Tag/Card

- typeA (MiFare)
- typeF (Felica)

caution: xxxxxxx

## API Reference

### readId

```
monaca.NfcReader.readId(successCallback, failCallback[, options])
```

#### successCallback

#### failCallback

#### options

#### Example

```javascript
  monaca.NfcReader.readId((result) => {
    if (result.cancelled) {
      // cancelled
    } else {
      // success
    }
  }, (error) => {
    // error
  }, {
      "message" : "NFCタグをスマートフォンに近づけてください"
  });
```

### readBlockData

```
monaca.NfcReader.readBlockData(successCallback, failCallback[, options])
```

#### failCallback

#### options

#### Example

```javascript
  monaca.NfcReader.readBlockData((result) => {
    if (result.cancelled) {
      // cancelled
    } else {
      // convert block data to traffic IC history
      const history = result.data.map(block => {
        return monaca.NfcReader.convertToHistory(block);
      });
    }
  }, (error) => {
    // error
  }, {
    "service_code" : [ 0x09, 0x0f ],
    "start" : 0,  // start index
    "count" : 12, // count
    "message" : "NFCタグをスマートフォンに近づけてください"
  });
```

## iOS Quirks

## License

see [LICENSE](./LICENSE)
