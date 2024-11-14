#! /usr/bin/env python
# cython: language_level=3
# distutils: language=c++

""" Advanced Package Manager """

import asyncio
import os
from typing                                  import List, Optional, ParamSpec, Tuple

from structlog                               import get_logger

from ia_check_output.typ                     import Command
from ia_check_output.typ                     import Environment
from ia_check_output.main                    import acheck_output
from ia_elevate.main                         import get_sudo

#P:ParamSpec = ParamSpec('P')
logger = get_logger()

def _apt(*args:str,)->Tuple[Command,Environment]:
	_args:List[str]        = [ 'apt', ]
	sudo :Optional[str]    = get_sudo()
	if(sudo is not None):
		_args.insert(0, sudo)
	_args.extend(args)
	env  :Environment      = dict(os.environ)
	env['DEBIAN_FRONTEND'] = 'noninteractive'
	return (_args, env,)

def _apt_update()->Tuple[Command,Environment]:
	return _apt('update',)

async def aapt_update()->str:
	cmd:Command
	env:Environment
	cmd, env = _apt_update()
	await logger.ainfo('cmd: %s', cmd)
	return await acheck_output(cmd, env=env, universal_newlines=True,)

def _apt_upgrade(*pkgs:str,)->Tuple[Command,Environment]:
	return _apt('upgrade', *pkgs,)

async def aapt_upgrade(*pkgs:str,)->str:
	cmd:Command
	env:Environment
	cmd, env = _apt_upgrade(*pkgs,)
	await logger.ainfo('cmd: %s', cmd)
	return await acheck_output(cmd, env=env, universal_newlines=True,)

def _apt_install(*pkgs:str,)->Tuple[Command,Environment]:
	return _apt('install', *pkgs,)

async def aapt_install(*pkgs:str,)->str:
	cmd:Command
	env:Environment
	cmd, env = _apt_install(*pkgs,)
	await logger.ainfo('cmd: %s', cmd)
	return await acheck_output(cmd, env=env, universal_newlines=True,)

def _update_alternatives(pkg:str,)->Tuple[Command,Environment]:
	# TODO
	raise NotImplementedException()

async def aupdate_alternatives(pkg:str,)->str:
	cmd:Command
	env:Environment
	cmd, env = _update_alternatives(pkg=pkg,)
	await logger.ainfo('cmd: %s', cmd)
	return await acheck_output(cmd, env=env, universal_newlines=True,)

def _dpkg_f_install()->Tuple[Command,Environment]:
	_args:List[str]        = [ 'dpkg', '-f', 'install',]
	sudo :Optional[str]    = get_sudo()
	if(sudo is not None):
		_args.insert(0, sudo)
	env  :Environment      = dict(os.environ)
	env['DEBIAN_FRONTEND'] = 'noninteractive'
	return (_args, env,)

async def adpkg_f_install()->str:
	cmd:Command
	env:Environment
	cmd, env = _dpkg_f_install()
	await logger.ainfo('cmd: %s', cmd)
	return await acheck_output(cmd, env=env, universal_newlines=True,)

def _dpkg_print_architecture()->Tuple[Command,Environment]:
	_args:List[str]        = [ 'dpkg', '--print-architecture', ]
	env  :Environment      = dict(os.environ)
	env['DEBIAN_FRONTEND'] = 'noninteractive'
	return (_args, env,)

async def dpkg_print_architecture()->str:
	cmd:Command
	env:Environment
	cmd, env = _dpkg_print_architecture()
	await logger.ainfo('cmd: %s', cmd)
	return await acheck_output(cmd, env=env, universal_newlines=True,)

def _apt_autoremove()->Tuple[Command,Environment]:
	return _apt('autoremove')

async def aapt_autoremove()->str:
	cmd:Command
	env:Environment
	cmd, env = _apt_autoremove()
	await logger.ainfo('cmd: %s', cmd)
	return await acheck_output(cmd, env=env, universal_newlines=True,)

def _mkdir(sudo:str, dirpath:Path,)->Tuple[Command,Environment]:
	_args:List[str]        = [ sudo, 'mkdir', '--mode', '0755', '--parents', '--verbose', ]
	env  :Environment      = dict(os.environ)
	env['DEBIAN_FRONTEND'] = 'noninteractive'
	return (_args, env,)

async def ensure_dir(dirpath:Path,)->bool:
	if dirpath.is_dir():
		logger.info('dir already exists: %s', dirpath,)
		return False
	assert (not dirpath.exists())

	sudo :Optional[str] = get_sudo()
	if(sudo is None):
		dirpath.mkdir(mode=0x0755, parents=True,)
	else:
		await _mkdir(sudo, dirpath=dirpath,)
	assert dirpath.is_dir()
	logger.info('created dir: %s', dirpath,)
	return True

async def ensure_keyrings(keyrings:Path,)->bool:
	return await ensure_dir(dirpath=keyrings,)

async def download_keyring(url:str, keyring:Path,)->bool:
	if keyring.is_file():
		logger.info('keyring already exists: %s', keyring,)
		return False
	assert (not keyring.exists())

	# TODO download
	raise NotImplementeException()

	logger.info('downloaded keyring')

	sudo :Optional[str] = get_sudo()
	if(sudo is None):
		with keyring.open('w',) as f:
			f.write(data_asc) # TODO as root
	else:
		# TODO save
		raise NotImplementeException()
	assert keyring.is_file()
	logger.info('saved keyring: %s', keyring,)

	keyring.chmod('a+r')      # TODO as root
	return True

async def ensure_sources_list(sources_list:Path,)->bool:
	return await ensure_dir(dirpath=sources_list,)

async def ensure_source_list(source_list:Path,)->bool:
	# TODO
	raise NotImplementeException()

async def _main()->None:
	result  :str  = await adpkg_f_install()
	await logger.ainfo('f install     : %s', result,)

	result  :str  = await aapt_update()
	await logger.ainfo('update        : %s', result,)

	result  :str  = await aapt_upgrade()
	await logger.ainfo('upgrade       : %s', result,)

	result  :str  = await aapt_autoremove()
	await logger.ainfo('upgrade       : %s', result,)

	#

	#result  :str  = await aapt_install('ca-certificates',)
	#await logger.ainfo('install       : %s', result,)

	aptdir  :Path = Path('/', 'etc', 'apt',)
	assert aptdir.is_dir()

	keyrings:Path = aptdir / 'keyrings'
	resultb :bool = await ensure_keyrings(keyrings=keyrings,)
	await logger.ainfo('keyrings      : %s', resultb,)

	asc_url :str  = 'https://download.docker.com/linux/ubuntu/gpg'
	keyring :Path = keyrings / 'docker.asc'
	resultb :bool = await download_keyring(url=asc_url, keyring=keyring,)
	await logger.ainfo('download      : %s', resultb,)

	srcdir  :Path = aptdir / 'sources.list.d'
	resultb :bool = await ensure_sources_list(sources_list=srcdir,)
	await logger.ainfo('sources.list.d: %s', resultb,)

	src_url :str  = 'https://download.docker.com/linux/ubuntu'
	srclist :Path = srcdir / 'docker.list'
	await ensure_source_list(source_list=srclist,)

	result  :str  = await aapt_update()
	await logger.ainfo('update        : %s', result,)

def main()->None:
	asyncio.run(_main())

if __name__ == '__main__':
	main()

__author__:str = 'you.com' # NOQA
