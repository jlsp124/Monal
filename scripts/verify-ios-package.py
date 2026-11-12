#!/usr/bin/env python3
"""Validate an Xcode-built app without editing its metadata or binaries."""
import argparse
import json
from pathlib import Path
import plistlib
import subprocess


def verify(app, sdk):
    app = Path(app)
    with (app / 'Info.plist').open('rb') as stream:
        info = plistlib.load(stream)
    assert info['CFBundleName'] == 'Monal Alpha', 'Alpha bundle name is not normalized in source'
    assert info['CFBundleDisplayName'] == 'Monal Alpha', 'Alpha display name is not normalized in source'
    assert info['CFBundleIdentifier'] == 'monal.alpha', 'Unexpected application identity'
    expected_platform = 'iPhoneOS' if sdk == 'iphoneos' else 'iPhoneSimulator'
    assert expected_platform in info['CFBundleSupportedPlatforms'], 'Wrong SDK in package'
    bundles = [app] + sorted(app.rglob('*.appex')) + sorted(app.rglob('*.framework'))
    report = []
    for bundle in bundles:
        with (bundle / 'Info.plist').open('rb') as stream:
            metadata = plistlib.load(stream)
        executable = metadata['CFBundleExecutable']
        assert Path(executable).name == executable, f'Invalid executable path in {bundle}'
        binary = bundle / executable
        assert binary.is_file(), f'Missing executable: {binary}'
        assert binary.stat().st_size > 0, f'Empty executable: {binary}'
        if bundle.suffix == '.appex':
            assert metadata['CFBundleIdentifier'].startswith(info['CFBundleIdentifier'] + '.'), 'Extension identity mismatch'
        architectures = subprocess.check_output(['xcrun', 'lipo', '-archs', str(binary)], text=True).strip()
        if sdk == 'iphoneos':
            assert 'arm64' in architectures.split(), f'No device architecture in {binary}'
        report.append({'bundle': str(bundle.relative_to(app.parent)), 'executable': executable, 'architectures': architectures})
    assert (app / 'Frameworks' / 'monalxmpp.framework' / 'monalxmpp').is_file(), 'Missing Monal framework'
    assert not (app / 'Monal.alpha.debug.dylib').exists(), 'Unexpected debug trampoline dylib'
    print(json.dumps({'sdk': sdk, 'name': info['CFBundleName'], 'bundles': report}, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('app')
    parser.add_argument('--sdk', choices=['iphoneos', 'iphonesimulator'], required=True)
    args = parser.parse_args()
    verify(args.app, args.sdk)
