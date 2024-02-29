/**
 * Copyright (c) 2022 Asial Corporation. All rights reserved.
 */

const fs = require('fs-extra');
const path = require('path');
const plist = require('plist');

const PLIST_KEY_NFC_SYSTEM_CODES = "com.apple.developer.nfc.readersession.felica.systemcodes";

/**
 * Check system codes definition exists in edit-config tags
 * @param {*} config config.xml
 * @returns true: exist, false: not exist
 */
const doesExistEditConfig = function (config) {
  // check edit-config
  const editConfigs = config.getEditConfigs("ios");
  if (editConfigs && editConfigs.length > 0) {
    // check System Codes
    for(editCfg of editConfigs) {
      if(editCfg.target === PLIST_KEY_NFC_SYSTEM_CODES) {
        return true;
      }
    }
  }
  return false;
}

/**
 * Check system codes definition exists in config-file tags
 * @param {*} config config.xml
 * @returns true: exist, false: not exist
 */
 const doesExistConfigFile = function(config) {
  // check config-file
  const configFiles = config.getConfigFiles("ios");
  if (configFiles && configFiles.length > 0) {
    // check System Codes
    for(configFile of configFiles) {
      if(configFile.parent === PLIST_KEY_NFC_SYSTEM_CODES) {
        return true;
      }
    }
  }
  return false;
}

/**
 * Add system codes definition to plist file
 * @param {*} plistPath   plist file path
 * @param {*} systemCodes array of system codes
 */
const addSystemCodesToPlist = function(plistPath, systemCodes) {
  // read plist
  const infoPlist = plist.parse(fs.readFileSync(plistPath, 'utf8'));

  // add system codes definition
  infoPlist[PLIST_KEY_NFC_SYSTEM_CODES] = systemCodes;

  /* eslint-disable no-tabs */
  // Write out the plist file with the same formatting as Xcode does
  let info_contents = plist.build(infoPlist, { indent: '\t', offset: -1 });
  /* eslint-enable no-tabs */

  info_contents = info_contents.replace(/<string>[\s\r\n]*<\/string>/g, '<string></string>');
  fs.writeFileSync(plistPath, info_contents, 'utf-8');
}

module.exports = function(context) {
  if (context.opts.platforms.indexOf("ios") == -1) {
    console.log("SKIPPED: addSystemCodes: no ios");
    return;
  }

  const ConfigParser = context.requireCordovaModule('cordova-common').ConfigParser;
  const root = context.opts.projectRoot;
  const platformRootDir = path.resolve(root, 'platforms', 'ios');
  const pathAPI = path.resolve(root, 'platforms', 'ios', 'cordova', 'Api.js');
  const API = require(pathAPI);
  const api = new API('ios', platformRootDir);
  const originalName = path.basename(api.locations.xcodeCordovaProj);

  // check System Code configuration
  const cfgFilePath = path.resolve(root, "platforms", "ios", originalName, "config.xml");
  const cfg = new ConfigParser(cfgFilePath);

  // check edit-config
  if (doesExistEditConfig(cfg)) {
    console.log("SKIPPED: addSystemCodes: System Codes already defined.");
    return;
  }
  // check config-file
  if (doesExistConfigFile(cfg)) {
    console.log("SKIPPED: addSystemCodes: System Codes already defined.");
    return;
  }

  // System Codes are not defined
  // Add system codes to plist
  const systemCodes = cfg.getPreference("NFC_SYSTEM_CODES", "ios").split(',');
  const plistPath = path.join(api.locations.xcodeCordovaProj, `${originalName}-Info.plist`);
  addSystemCodesToPlist(plistPath, systemCodes);
  console.log("addSystemCodes: added System Codes.");
};
