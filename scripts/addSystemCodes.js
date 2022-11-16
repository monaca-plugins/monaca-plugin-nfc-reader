/**
 * Copyright (c) 2022 Asial Corporation. All rights reserved.
 */
 module.exports = function(context) {
  if (context.opts.platforms.indexOf("ios") == -1) {
    console.log("SKIPPED: addSystemCodes: no ios");
    return;
  }

  const ConfigParser = context.requireCordovaModule('cordova-common').ConfigParser;
  const fs = require('fs-extra');
  const path = require('path');
  const plist = require('plist');
  const root = context.opts.projectRoot;
  const pathAPI = path.resolve(root, 'platforms', 'ios', 'cordova', 'Api.js');
  const API = require(pathAPI);
  const api = new API('ios');
  const originalName = path.basename(api.locations.xcodeCordovaProj);

  // check System Code configuration
  // const ConfigParser = context.requireCordovaModule('cordova-common').ConfigParser;
  // const cfgOrg = new ConfigParser("config.xml");
  // const appName = cfgOrg.name();
  const cfgFilePath = path.resolve(root, "platforms", "ios", originalName, "config.xml");
  const cfg = new ConfigParser(cfgFilePath);
  // check edit-config
  const editConfigs = cfg.getEditConfigs("ios");
  if (editConfigs && editConfigs.length > 0) {
    // check System Codes
    for(editCfg of editConfigs) {
      if(editCfg.target === "com.apple.developer.nfc.readersession.felica.systemcodes") {
        console.log("SKIPPED: addSystemCodes: System Codes already defined.");
        return;
      }
    }
  }
  // check config-file
  const configFiles = cfg.getConfigFiles("ios");
  if (configFiles && configFiles.length > 0) {
    // check System Codes
    for(configFile of configFiles) {
      if(configFile.parent === "com.apple.developer.nfc.readersession.felica.systemcodes") {
        console.log("SKIPPED: addSystemCodes: System Codes already defined.");
        return;
      }
    }
  }

  // System Codes are not defined
  // Add system codes to plist
  const systemCodes = cfg.getPreference("NFC_SYSTEM_CODES", "ios").split(',');

  const plistFile = path.join(api.locations.xcodeCordovaProj, `${originalName}-Info.plist`);
  const infoPlist = plist.parse(fs.readFileSync(plistFile, 'utf8'));
  infoPlist["com.apple.developer.nfc.readersession.felica.systemcodes"] = systemCodes;

  /* eslint-disable no-tabs */
  // Write out the plist file with the same formatting as Xcode does
  let info_contents = plist.build(infoPlist, { indent: '\t', offset: -1 });
  /* eslint-enable no-tabs */

  info_contents = info_contents.replace(/<string>[\s\r\n]*<\/string>/g, '<string></string>');
  fs.writeFileSync(plistFile, info_contents, 'utf-8');
  console.log("addSystemCodes: added System Codes.");
};