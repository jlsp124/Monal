#!/usr/bin/env python3
"""Select and boot an available iPhone for the currently selected Xcode SDK."""
import json
from pathlib import Path
import re
import subprocess
import sys


def output(*args):
    return subprocess.check_output(args, text=True).strip()


def version(value):
    parts = [int(item) for item in re.findall(r'\d+', value)]
    return tuple((parts + [0, 0, 0])[:3])


def runtimes():
    data = json.loads(output('xcrun', 'simctl', 'list', 'runtimes', '-j'))
    return sorted((item for item in data['runtimes']
                   if item.get('isAvailable')
                   and item['identifier'].startswith('com.apple.CoreSimulator.SimRuntime.iOS-')
                   and version(item['version'])[0] == version(sdk)[0]
                   and version(item['version']) <= version(sdk)),
                  key=lambda item: version(item['version']), reverse=True)


def log_command(*args):
    subprocess.run(args, check=True, stdout=sys.stderr, stderr=sys.stderr)


sdk = output('xcrun', '--sdk', 'iphonesimulator', '--show-sdk-version')
available = runtimes()  # Also starts CoreSimulator before Xcode queries destinations.
if not available:
    log_command('xcodebuild', '-downloadPlatform', 'iOS', '-buildVersion', sdk)
    available = runtimes()
if not available:
    raise SystemExit(f'No available simulator runtime for the selected iOS {sdk} SDK')
runtime = available[0]
devices = json.loads(output('xcrun', 'simctl', 'list', 'devices', 'available', '-j'))['devices']
phones = [item for item in devices.get(runtime['identifier'], [])
          if item.get('isAvailable') and item['name'].startswith('iPhone')]
phones.sort(key=lambda item: (item['name'] != 'iPhone 16', item['name']))
if phones:
    device = phones[0]
else:
    types = json.loads(output('xcrun', 'simctl', 'list', 'devicetypes', '-j'))['devicetypes']
    phone_types = [item for item in types if item['name'].startswith('iPhone')]
    phone_types.sort(key=lambda item: (item['name'] != 'iPhone 16', item['name']))
    if not phone_types:
        raise SystemExit('Xcode has no iPhone device type')
    kind = phone_types[0]
    identifier = output('xcrun', 'simctl', 'create', 'Monal CI iPhone', kind['identifier'], runtime['identifier'])
    device = {'name': 'Monal CI iPhone', 'udid': identifier, 'state': 'Shutdown'}
if device['state'] != 'Booted':
    log_command('xcrun', 'simctl', 'boot', device['udid'])
log_command('xcrun', 'simctl', 'bootstatus', device['udid'], '-b')
report = Path(__file__).resolve().parent.parent / 'build' / 'simulator.json'
report.parent.mkdir(parents=True, exist_ok=True)
report.write_text(json.dumps({'sdk': sdk, 'runtime': runtime, 'device': device}, indent=2), encoding='utf-8')
print(device['udid'])
