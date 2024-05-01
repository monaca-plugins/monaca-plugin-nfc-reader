# @monaca/monaca-plugin-nfc-reader

NFC Reader Monaca Plugin.

## Description

This plugin provides reading NFC tag features.

- Reading NFC Tag ID
  Can read unique IDs assigned to NFC tags
- Reading Block Data (only FeliCa[^1])
  Can read block data of FeliCa

## Supported Platforms

### Build Environments

- Cordova 11.0.0 or later
- cordova-ios@6.2.0 or later
- Swift 4 or later (5 or later recommended)

### Operating Environments

- iOS 13 or later
- iPhone 7 or later

## Supported NFC Tags

- NFC TypeA (Mifare[^2])
- NFC TypeF (FeliCa)

## API Reference

### readId

```
monaca.NfcReader.readId(successCallback, failCallback, args)
```

Read ID of NFC Tags.
Type A: UID / Type F: IDm
NFC Type B is not supported.

#### successCallback

successCallback(result)

result: following data

```
{
  "type": "typeA",  // The type of NFC Tag (typeA / typeF)
  "id": "xxxxxxxxxx",  // The ID of NFC Tag
  "cancelled": false // reading cancelled(true) or not(false)
}
```

- Id consists of hexadecimal string.
- Length of id depends on NFC types.
- In the case of FeliCa, returned id is associated with the `system code` configured for the application.
  - By default, the `system code` is defined to `0003`
  - To change the system code, refer [Definition of system codes](#definition-of-system-codes).

#### failCallback

failCallback(error)

error: error message(string)

Refer [Error Messages](#error-messages)

#### args

```
{
  "message" : "Bring the NFC tag closer to your smartphone."
}
```

| parameter | type | optional | default value | description |
|---|---|---|---|---|
| message | string | YES | "Bring the NFC tag closer to your Smartphone" | The message shown on detection UI |

#### Example

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
      "message" : "Bring the NFC tag closer to your Smartphone."
  });
```

### readBlockData

```
monaca.NfcReader.readBlockData(successCallback, failCallback, args)
```

Read block data of FeliCa.

#### successCallback

successCallback(result)

result: following data

```
{
  "type": "typeF",  // The type of NFC Tag (typeF)
  "id": "xxxxxxxxxx",  // The ID of NFC Tag
  "cancelled": false // reading cancelled(true) or not(false)
  "data": [n][16]   // blockData[n][16]  1 block = 16byte x n(n: 0 .. count-1)
}
```

- Returns the id and block data associated with system code.

#### failCallback

error: error message(string)

Refer [Error Messages](#error-messages)

#### args

```
{
  "service_code" : [ 0x09, 0x0f ],  // service code
  "start" : 0,  // start index
  "count" : 12, // block count (count <= 12)
  "message" : "Bring the NFC tag closer to your Smartphone."
}
```

| parameter | type | optional | default value | description |
|---|---|---|---|---|
| service_code | array(byte[2]) | NO | - | service code |
| start | int | NO | - | start index (0 <= start < 20) |
| count | int | NO | - | block count (count <= 12) |
| message | string | YES | "Bring the NFC tag closer to your Smartphone" | The message shown on detection UI |

- Returns the block data associated with specified service code.
  - Only 1 service code can be specified. Cannot specify multiple service codes.
  - If changing system code, refer [Definition of system codes](#definition-of-system-codes).

- The max size of block data is 20.
- The data count can be read at once is 12.
  - count <= 12
  - start + count <= 20

#### Example

```javascript
  monaca.NfcReader.readBlockData((result) => {
    if (result.cancelled) {
      // cancelled
    } else {
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
    "message" : "Bring the NFC tag closer to your Smartphone."
  });
```

### Error Messages

| message | description |
|---|---|
| "Invalid Arguments" | Invalid value specified for arguments |
| "NFC Not Available" | NFC is not available |
| "NFC Connection Error" | Error during connecting NFC session |
| "Feature Not Supported" | Calling unsupported feature(typeA + readBlockData etc.) |
| "Unsupported NFC Tag is detected" | Detected unsupported tag |
| "Request Service Error" | Invalid service code is specified |
| "Read Block Data Error" | Error during reading block data |
| "Read Block Data Error: Invalid Status Code" | Error during reading block data - status code is invalid |
| "NFC Session timed out" | Time out reading NFC |
| "Unhandled NFC error" | Unhandled error occurs |

## iOS Quirks

To use this plugin, adding configuration to `config.xml` is required.

- Definition of Swift version(mandatory)
- Definition of system codes(optional)

### Definition of Swift version

This plugin includes Swift codes.
The Swift version should be defined at application's `config.xml`.
Add following part to `config.xml`.

```
<platform name="ios">
  <preference name="SwiftVersion" value="5"/>
</platform>
```

### Definition of system codes

By default, the FeliCa system code `0003` is defined in this plugin.
If change or add system code, please set by one of the following way.

#### Setting for Monaca Cloud IDE

1. From Monaca Cloud IDE menu, go to `Configure -> Cordova Plugin Settings`.
2. Under Available Plugins section, hover over the `@monaca/monaca-nfc-reader-plugin` plugin and click `Configure` button.
3. Enter the following value in `Install Parameters`
  Change the value from `0003` to `fe00`: `SYSTEM_CODES=fe00`

#### Setting for Cordova CLI by variable option

When using the plugin from the Cordova CLI, specify the value by `variable` option when adding the plugin.

```
# Change the value from `0003` to `fe00`
cordova plugin add @monaca/monaca-plugin-nfc-reader --variable SYSTEM_CODES=fe00
```

## Appendix

Refer [About FeliCa(article in Japanese)](README.md#felica%E3%81%AE%E8%AA%AD%E3%81%BF%E8%BE%BC%E3%81%BF%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6) about detail information of FeliCa, `System Code` and `Service Code`.

## iOS Privacy Manifest

As of May 1, 2024, Apple requires a privacy manifest file to be created for apps and third-party SDKs. The purpose of the privacy manifest file is to explain the data being collected and the reasons for the required APIs it uses. Starting with `cordova-ios@7.1.0`, APIs are available for configuring the privacy manifest file from `config.xml`.

As an app developer, it will be your responsibility to identify additional information explaining what your app does with that data.
In this case, you will need to review the "[Describing data use in privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_data_use_in_privacy_manifests)" to understand the list of known `NSPrivacyCollectedDataTypes` and `NSPrivacyCollectedDataTypePurposes`.

Also, ensure all four keys—`NSPrivacyTracking`, `NSPrivacyTrackingDomains`, `NSPrivacyAccessedAPITypes`, and `NSPrivacyCollectedDataTypes`—are defined, even if you are not making an addition to the other items. Apple requires all to be defined.

Additional Resources:
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Privacy Manifest Files](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files?language=objc)

## License

see [LICENSE](./LICENSE)

[^1]: FeliCa is a registered trademark of SONY Corporation.
FeliCa is a contactless IC card technology developed by Sony Corporation.
[^2]: Mifare is a registered trademark of NXP Semiconductors N.V.
