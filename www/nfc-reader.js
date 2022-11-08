/**
 * Copyright (c) 2022 Asial Corporation. All rights reserved.
 */

const monaca = function () {};
const NfcReader = function() {};

NfcReader.prototype.readId = function(success, fail, args) {
  cordova.exec(success, fail, "MonacaNfcReaderPlugin","readId", [args]);
};

NfcReader.prototype.readBlockData = function(success, fail, args) {
  cordova.exec(success, fail, "MonacaNfcReaderPlugin","readBlockData", [args]);
};

NfcReader.prototype.convertToHistory = function(blockData) {
  var history = {};
  history["year"] = (blockData[4] >> 1) + 2000;
  history["month"] = ((blockData[4] & 1) == 1 ? 8 : 0) + (blockData[5] >> 5);
  history["day"] = blockData[5] & 0x1f;
  history["boarding_station_code"] = [ blockData[6], blockData[7] ];
  history["exit_station_code"] = [ blockData[8], blockData[9] ];
  history["balance"] = blockData[10] + (blockData[11] << 8);

  return history;
}

monaca.NfcReader = new NfcReader();
module.exports = monaca.NfcReader;
