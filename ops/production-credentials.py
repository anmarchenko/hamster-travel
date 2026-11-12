#!/usr/bin/python3
"""Fetch scoped production inputs, keeping the op token out of application jobs."""

import json
import os
from pathlib import Path
import pwd
import signal
import stat
import subprocess
import sys
import tempfile

STORE = Path('/etc/hamster-travel/credentials')
FILES = {
    'deploy': {'APP_ENV': 'app.env', 'DATABASE_ENV': 'database.env'},
    'db': {'BACKUP_ENV': 'backup.env'},
    'infra': {'BACKUP_ENV': 'backup.env', 'RESTIC_PASSWORD_FILE': 'restic-password'},
}


def checked_output(command, *, env=None):
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            env=env, timeout=90, check=False)
    if result.returncode:
        raise RuntimeError('Production credential lookup failed. Check 1Password access and connectivity.')
    if not result.stdout:
        raise RuntimeError('Production credential lookup returned an empty value.')
    return result.stdout


def materialize(role, directory):
    config_path = STORE / 'op.json'
    info = config_path.stat()
    if info.st_uid != 0 or info.st_mode & 0o022:
        raise RuntimeError('Production credential references must be owned by root and not writable by others.')
    references = json.loads(config_path.read_text())[role]
    credential_directory = os.environ.get('CREDENTIALS_DIRECTORY')
    if credential_directory:
        token = (Path(credential_directory) / 'op-token').read_bytes()
    else:
        scope = 'deploy' if role == 'deploy' else 'backup'
        token = checked_output(['/usr/bin/systemd-creds', '--name=op-token', 'decrypt',
                                str(STORE / (scope + '-op.cred')), '-'])
    with tempfile.TemporaryDirectory(prefix='op-config.', dir=directory) as config:
        environment = {
            'PATH': '/usr/bin', 'HOME': '/root', 'OP_CONFIG_DIR': config,
            'OP_CACHE': 'false', 'OP_BIOMETRIC_UNLOCK_ENABLED': 'false',
            'OP_SERVICE_ACCOUNT_TOKEN': token.decode().strip(),
        }
        for field, filename in FILES[role].items():
            reference = references[field]
            if not reference.startswith('op://'):
                raise RuntimeError('Expected a 1Password secret reference.')
            value = checked_output(['/usr/bin/op', 'read', '--no-newline', reference], env=environment)
            target = directory / filename
            with target.open('xb') as output:
                os.chmod(target, 0o600)
                output.write(value)


def run_job(role, command):
    account = pwd.getpwnam('marvin')
    with tempfile.TemporaryDirectory(prefix='hamster-op-', dir='/run') as temporary:
        directory = Path(temporary)
        materialize(role, directory)
        environment = {key: value for key, value in os.environ.items()
                       if not key.startswith('OP_') and key not in ('CREDENTIALS_DIRECTORY', 'RUNTIME_DIRECTORY')}
        environment.update({
            'HOME': account.pw_dir, 'USER': account.pw_name, 'LOGNAME': account.pw_name,
            'PATH': '/usr/bin', 'HAMSTER_TRAVEL_PRODUCTION_ENV_FILE': str(directory / 'backup.env'),
        })
        if role == 'infra':
            environment['HAMSTER_TRAVEL_INFRA_RESTIC_PASSWORD_FILE'] = str(directory / 'restic-password')
            environment['RESTIC_PASSWORD_FILE'] = str(directory / 'restic-password')
        for file in directory.iterdir():
            os.chown(file, account.pw_uid, account.pw_gid)
        os.chown(directory, account.pw_uid, account.pw_gid)
        # Only the short-lived op subprocess receives the service-account token.
        # The backup command runs with the existing unprivileged user's access.
        return subprocess.run(command, env=environment, user=account.pw_uid,
                              group=account.pw_gid, extra_groups=[], check=False).returncode


def main():
    os.umask(0o077)
    if os.geteuid() != 0:
        raise RuntimeError('Use sudo or pkexec for production credential access.')
    if subprocess.check_output(['/usr/bin/stat', '-f', '-c', '%T', '/run']).strip() != b'tmpfs':
        raise RuntimeError('Production credentials require /run on tmpfs.')
    if len(sys.argv) < 4 or sys.argv[2] not in FILES:
        raise RuntimeError('Usage: hamster-production-credentials materialize <scope> <directory> | run <db|infra> <command> [args]')
    operation, role = sys.argv[1:3]
    if operation == 'materialize':
        directory = Path(sys.argv[3])
        info = directory.lstat()
        if (len(sys.argv) != 4 or directory.parent != Path('/run')
                or not stat.S_ISDIR(info.st_mode) or info.st_uid != 0 or info.st_mode & 0o077):
            raise RuntimeError('Expected a private root-owned runtime directory directly under /run.')
        materialize(role, directory)
        return 0
    if operation == 'run' and role in ('db', 'infra'):
        return run_job(role, sys.argv[3:])
    raise RuntimeError('Unsupported production credential operation.')


if __name__ == '__main__':
    # Raise on termination so temporary directories are removed by context managers.
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(143))
    try:
        sys.exit(main())
    except (RuntimeError, OSError, ValueError, KeyError, subprocess.SubprocessError):
        print('Production credential access failed. Check root configuration, 1Password access, and connectivity.', file=sys.stderr)
        sys.exit(1)
