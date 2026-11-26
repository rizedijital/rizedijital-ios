#!/usr/bin/env python3
"""Fail before publishing if the actual exported IPA does not match the signed release."""
import plistlib
import sys
import zipfile

if len(sys.argv) != 5:
    raise SystemExit("Usage: verify-exported-ipa.py IPA VERSION BUILD BUNDLE_ID")
ipa_path, version, build, bundle = sys.argv[1:]
with zipfile.ZipFile(ipa_path) as ipa:
    paths = ipa.namelist()
    mains = [p for p in paths if p.startswith('Payload/') and p.count('/') == 2 and p.endswith('.app/Info.plist')]
    if len(mains) != 1:
        raise SystemExit(f"ERROR: Expected one main app Info.plist, found: {mains}")
    app_path = mains[0].removesuffix('Info.plist')
    info = plistlib.loads(ipa.read(mains[0]))
    actual = (str(info.get('CFBundleShortVersionString')), str(info.get('CFBundleVersion')), str(info.get('CFBundleIdentifier')))
    expected = (version, build, bundle)
    print(f"IPA main app: version={actual[0]}, build={actual[1]}, bundle={actual[2]}")
    if actual != expected:
        raise SystemExit(f"ERROR: IPA metadata mismatch. Actual={actual}, expected={expected}")
    extensions = [p for p in paths if p.startswith(app_path+'PlugIns/') and p.endswith('.appex/Info.plist')]
    if len(extensions) != 1:
        raise SystemExit(f"ERROR: Expected one OneSignal extension plist, found: {extensions}")
    extension_info = plistlib.loads(ipa.read(extensions[0]))
    ext_version = str(extension_info.get('CFBundleShortVersionString'))
    ext_build = str(extension_info.get('CFBundleVersion'))
    ext_bundle = str(extension_info.get('CFBundleIdentifier'))
    print(f"IPA OneSignal extension: version={ext_version}, build={ext_build}, bundle={ext_bundle}")
    if (ext_version, ext_build, ext_bundle) != (version, build, bundle+'.OneSignalNotificationServiceExtension'):
        raise SystemExit('ERROR: IPA OneSignal extension mismatch')
    print('PASS: IPA app and OneSignal extension metadata verified before publishing')
