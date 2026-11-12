#!/usr/bin/python3
"""Rebuild this host's op credential configuration from existing 1Password items."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

STORE = Path('/etc/hamster-travel/credentials')
REPO = Path(__file__).resolve().parent.parent


def output(command, data=None, env=None):
    result = subprocess.run(command, input=data, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env, check=False)
    if result.returncode:
        raise RuntimeError('Credential installation failed. Check native authorization and 1Password access.')
    return result.stdout


def collect():
    references = {}
    for role in ('deploy', 'db', 'infra'):
        vault = 'Hamster Travel Production Deploy' if role == 'deploy' else 'Hamster Travel Production Backups'
        item = json.loads(output(['/usr/bin/op', 'item', 'get', 'hamster-travel-' + role,
                                  '--vault', vault, '--format=json']))
        fields = ('APP_ENV', 'DATABASE_ENV') if role == 'deploy' else (
            ('BACKUP_ENV', 'RESTIC_PASSWORD_FILE') if role == 'infra' else ('BACKUP_ENV',))
        present = {field.get('label'): field for field in item['fields']}
        references[role] = {}
        for field in fields:
            if not present[field].get('value'):
                raise RuntimeError('Required production item field is empty.')
            references[role][field] = f'op://{item["vault"]["id"]}/{item["id"]}/{present[field]["id"]}'
    tokens = {role: output(['/usr/bin/op', 'read', '--no-newline',
        f'op://Private/hamster-travel-{role}-service-account/TOKEN']).decode()
        for role in ('deploy', 'backup')}
    return {'references': references, 'tokens': tokens}


def install(payload):
    if os.geteuid() != 0:
        raise RuntimeError('The installation phase requires root.')
    os.umask(0o077)
    STORE.mkdir(parents=True, exist_ok=True)
    references = payload['references']
    if set(references) != {'deploy', 'db', 'infra'}:
        raise RuntimeError('Expected deploy, db, and infra reference scopes.')
    for fields in references.values():
        if not all(isinstance(reference, str) and reference.startswith('op://') for reference in fields.values()):
            raise RuntimeError('Expected 1Password references.')
    with tempfile.TemporaryDirectory(prefix='.op-install-', dir=STORE) as temporary:
        staging = Path(temporary)
        for role in ('deploy', 'backup'):
            credential = staging / (role + '-op.cred')
            output(['/usr/bin/systemd-creds', '--with-key=host', '--name=op-token',
                    'encrypt', '-', str(credential)], payload['tokens'][role].encode())
            os.chmod(credential, 0o600)
        references_file = staging / 'op.json'
        references_file.write_text(json.dumps(references, indent=2) + '\n')
        os.chmod(references_file, 0o644)
        output(['/usr/bin/install', '-D', '-o', 'root', '-g', 'root', '-m', '0755',
                str(REPO / 'ops/production-credentials.py'), '/usr/local/libexec/hamster-production-credentials'])
        for file in staging.iterdir():
            os.replace(file, STORE / file.name)
    print('Installed root-protected op tokens, references, and credential helper.')


def main():
    if sys.argv[1:] == ['--install']:
        install(json.load(sys.stdin))
    elif sys.argv[1:] == ['--check'] and os.geteuid() != 0:
        payload = collect()
        installed = json.loads((STORE / 'op.json').read_text())
        # References may use either field labels or field IDs. Resolve both
        # rather than requiring identical text for equivalent references.
        with tempfile.TemporaryDirectory(prefix='hamster-op-check-', dir=os.environ.get('XDG_RUNTIME_DIR', '/run/user/1000')) as temporary:
            for scope, references in payload['references'].items():
                token = payload['tokens']['deploy' if scope == 'deploy' else 'backup']
                environment = {'PATH': '/usr/bin', 'HOME': temporary, 'OP_CONFIG_DIR': temporary,
                               'OP_CACHE': 'false', 'OP_SERVICE_ACCOUNT_TOKEN': token,
                               'OP_BIOMETRIC_UNLOCK_ENABLED': 'false'}
                for field, reference in references.items():
                    actual = output(['/usr/bin/op', 'read', '--no-newline', installed[scope][field]], env=environment)
                    expected = output(['/usr/bin/op', 'read', '--no-newline', reference], env=environment)
                    if actual != expected:
                        raise RuntimeError('Installed references differ from the expected production values.')
        print('Existing 1Password items, saved tokens, and installed references are present and consistent. No host changes made.')
    elif not sys.argv[1:] and os.geteuid() != 0:
        # JSON is sent through stdin. Neither tokens nor credential values appear
        # in command arguments, shell history, ordinary files, or tool output.
        payload = collect()
        subprocess.run(['/usr/bin/pkexec', '/usr/bin/python3', str(Path(__file__).resolve()), '--install'],
                       input=json.dumps(payload).encode(), check=True)
    else:
        raise RuntimeError('Run as your normal user after authorizing the 1Password CLI.')


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, ValueError, KeyError, subprocess.SubprocessError):
        print('Credential installation failed. Check native authorization, existing 1Password items, and root access.', file=sys.stderr)
        sys.exit(1)
