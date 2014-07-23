#!/bin/bash


#Datetime
NOW=$(date +"%Y%m%d.%s")

#Load config
CONF=./sign.conf
if [ -f ${CONF} ]; then
    . ${CONF}
fi

#Temp
TEMP="temp"
if [ -e ${TEMP} ]; then
  echo "ERROR : temp already exists!"
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
rm -r "${TEMP}/Payload/${IPA_NAME}.app/_CodeSignature" "${TEMP}/Payload/${IPA_NAME}.app/CodeResources" 2> /dev/null | true

#Replace embedded mobile provisioning profile
echo "Replace embedded mobile provisioning profile"
cp "${ASSETS_PATH}${PROFILE_NAME}.mobileprovision" "${TEMP}/Payload/${IPA_NAME}.app/embedded.mobileprovision"

#Re-sign
echo "Re-sign"
/usr/bin/codesign -f -s "${CERTIFICATE_TYPE}: ${CERTIFICATE_NAME}" --resource-rules "${TEMP}/Payload/${IPA_NAME}.app/ResourceRules.plist" "${TEMP}/Payload/${IPA_NAME}.app"

#Re-package
echo "Re-package"
zip -qr "${BUILD_PATH}${IPA_NAME}_resigned_${NOW}.ipa" ${TEMP}/Payload

#Remove Payload
rm -rf ${TEMP}

exit 0