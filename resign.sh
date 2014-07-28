#!/bin/bash

#Conf file
CONF=./assets/fcf_dev.conf

#Datetime
NOW=$(date +"%Y%m%d_%s")

#Load config
if [ -f ${CONF} ]; then
    . ${CONF}
fi

#Temp
TEMP="temp"
if [ -e ${TEMP} ]; then
  echo "ERROR : temp already exists!"
  exit 1
fi

#Check app ID
if [ -z ${APP_ID} ]; then
  echo "ERROR : missing APP_ID!"
  exit 1
fi

#Create build dir
if [ ! -d ${BUILD_PATH} ]; then
    mkdir ${BUILD_PATH}
fi

#Unzip the IPA
echo "Unzip the IPA"
unzip -q ${ASSETS_PATH}${IPA_NAME}.ipa -d ${TEMP}

#Remove old CodeSignature
echo "Remove old CodeSignature"
rm -r "${TEMP}/Payload/${APP_NAME}.app/_CodeSignature" "${TEMP}/Payload/${APP_NAME}.app/CodeResources" 2> /dev/null | true

#Replace embedded mobile provisioning profile
echo "Replace embedded mobile provisioning profile"
cp "${ASSETS_PATH}${PROFILE_NAME}.mobileprovision" "${TEMP}/Payload/${APP_NAME}.app/embedded.mobileprovision"

#Change BundleVersion
if [ ! -z ${APP_BUNDLE_VERSION} ]; then
    /usr/libexec/PlistBuddy -c "Set CFBundleVersion ${APP_BUNDLE_VERSION}" ${TEMP}/Payload/${APP_NAME}.app/Info.plist
fi

#Change CFBundleShortVersionString
if [ ! -z ${APP_BUNDLE_SHORT_VERSION_STRING} ]; then
    /usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString ${APP_BUNDLE_SHORT_VERSION_STRING}" ${TEMP}/Payload/${APP_NAME}.app/Info.plist
fi

#Change BundleIdentifier
/usr/libexec/PlistBuddy -c "Set CFBundleIdentifier ${APP_ID}" ${TEMP}/Payload/${APP_NAME}.app/Info.plist

#Create entitlements from template
ENTITLEMENTS=$(<./templates/entitlements.template)
ENTITLEMENTS=${ENTITLEMENTS//#APP_ID#/$APP_ID}
ENTITLEMENTS=${ENTITLEMENTS//#APP_PREFIX#/$APP_PREFIX}
echo ${ENTITLEMENTS} > ${TEMP}/entitlements.temp

#Re-sign
echo "Re-sign"
/usr/bin/codesign -f -s "${CERTIFICATE_TYPE}: ${CERTIFICATE_NAME}" --identifier "${APP_ID}" --entitlements "${TEMP}/entitlements.temp" --resource-rules "${TEMP}/Payload/${APP_NAME}.app/ResourceRules.plist" "${TEMP}/Payload/${APP_NAME}.app"

#echo "Show entitlements"
#/usr/bin/codesign -d --entitlements :- "${TEMP}/Payload/${APP_NAME}.app"

#Re-package
echo "Re-package"
cd ${TEMP}
zip -qr "${IPA_NAME}_resigned_${NOW}.ipa" Payload
mv ${IPA_NAME}_resigned_${NOW}.ipa ../${BUILD_PATH}/${IPA_NAME}_resigned_${NOW}.ipa

#Remove temp
cd ../
rm -rf ${TEMP}

exit 0