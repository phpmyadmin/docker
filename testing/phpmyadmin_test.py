#!/usr/bin/env python3
import argparse
import os
import subprocess
import re
import sys

import mechanize
import tempfile
import pytest

def create_browser():
    br = mechanize.Browser()

    # Ignore robots.txt
    br.set_handle_robots(False)
    return br

def do_login(br, url, username, password, server):
    # Login page
    br.open(url)

    # Fill login form
    br.select_form('login_form')
    br['pma_username'] = username
    br['pma_password'] = password
    if server is not None:
        br['pma_servername'] = server

    # Login and check if logged in
    response = br.submit()
    return response

def get_world_sql_path():
    if os.path.exists('/world.sql'):
        return '/world.sql'
    elif os.path.exists('./world.sql'):
        return './world.sql'
    else:
        path = os.path.dirname(os.path.realpath(__file__))
        return path + '/world.sql'

def test_import(url, username, password, server, sqlfile):
    if sqlfile is None:
        sqlfile = get_world_sql_path()

    br = create_browser()

    response = do_login(br, url, username, password, server)

    assert(b'Server version' in response.read())

    # Open server import
    response = br.follow_link(text_regex=re.compile('Import'))
    assert(b'OpenDocument Spreadsheet' in response.read())

    # Upload SQL file
    br.select_form('import')
    br.form.add_file(open(sqlfile), 'text/plain', sqlfile)
    response = br.submit()
    assert(b'5326 queries executed' in response.read())


def docker_secret(env_name):
    dir_path = os.path.dirname(os.path.realpath(__file__))
    secret_file = tempfile.mkstemp()

    password = "The_super_secret_password"
    password_file = open(secret_file[1], 'wb')
    password_file.write(str.encode(password))
    password_file.close()

    test_env = {env_name + '_FILE': secret_file[1]}

    # Run entrypoint and afterwards echo the environment variables
    result = subprocess.Popen("bash " +dir_path+ "/../docker-entrypoint.sh 'env'", shell=True, stdout=subprocess.PIPE, env=test_env)
    output = result.stdout.read().decode()

    assert (env_name + "=" + password) in output

def test_phpmyadmin_secrets():
    docker_secret('MYSQL_PASSWORD')
    docker_secret('MYSQL_ROOT_PASSWORD')
    docker_secret('PMA_USER')
    docker_secret('PMA_PASSWORD')
    docker_secret('PMA_HOSTS')
    docker_secret('PMA_HOST')
    docker_secret('PMA_CONTROLHOST')
    docker_secret('PMA_CONTROLUSER')
    docker_secret('PMA_CONTROLPASS')


def test_php_ini(url, username, password, server):
    br = create_browser()
    response = do_login(br, url, username, password, server)

    assert(b'Show PHP information' in response.read())

    # Open Show PHP information
    response = br.follow_link(text_regex=re.compile('Show PHP information'))
    response = response.read()
    assert(b'PHP Version' in response)

    assert(b'upload_max_filesize' in response)
    assert(b'post_max_size' in response)
    assert(b'expose_php' in response)
    assert(b'session.save_path' in response)

    assert(b'<tr><td class="e">max_execution_time</td><td class="v">125</td><td class="v">125</td></tr>' in response)

    assert(b'<tr><td class="e">upload_max_filesize</td><td class="v">123M</td><td class="v">123M</td></tr>' in response)
    assert(b'<tr><td class="e">post_max_size</td><td class="v">123M</td><td class="v">123M</td></tr>' in response)

    assert(b'<tr><td class="e">expose_php</td><td class="v">Off</td><td class="v">Off</td></tr>' in response)
    assert(b'<tr><td class="e">session.save_path</td><td class="v">/sessions</td><td class="v">/sessions</td></tr>' in response)

def test_import_from_folder(url, username, password, server, sqlfile):
    upload_dir = os.environ.get('PMA_UPLOADDIR');
    if not upload_dir:
        pytest.skip("Missing PMA_UPLOADDIR ENV", allow_module_level=True)

    # Copy file into the volume
    with open(get_world_sql_path(), 'rb') as src, open(upload_dir + '/world-data.sql', 'wb') as dst:
        dst.write(src.read())

    br = create_browser()

    response = do_login(br, url, username, password, server)

    assert(b'Server version' in response.read())

    # Open server import
    response = br.follow_link(text_regex=re.compile('Import'))
    response = response.read()

    assert(b'Browse your computer:' in response)
    assert(upload_dir.encode() in response)
    assert(b'world-data.sql' in response)

def test_export_to_folder(url, username, password, server, sqlfile):
    save_dir = os.environ.get('PMA_SAVEDIR');
    if not save_dir:
        pytest.skip("Missing PMA_SAVEDIR ENV", allow_module_level=True)

    # Delete file from previous runs
    if os.path.exists(save_dir + "/db_server.sql"):
        os.remove(save_dir + "/db_server.sql")

    assert os.path.exists(save_dir + "/db_server.sql") == False

    # Avoid: "The web server does not have permission to save the file"
    os.chmod(save_dir , 0o777)

    br = create_browser()

    response = do_login(br, url, username, password, server)

    assert(b'Server version' in response.read())

    # Open server export
    response = br.follow_link(text_regex=re.compile('Export'))
    response = response.read()
    assert(b'Save on server in the directory' in response)
    assert(save_dir.encode() in response)

    br.select_form('dump')
    br.find_control("quick_export_onserver").items[0].selected=True

    response = br.submit()
    response = response.read()

    assert(b'Dump has been saved to file' in response)
    assert(b'Dump has been saved to file /etc/phpmyadmin/exports/db_server.sql' in response)
    assert os.path.exists(save_dir + "/db_server.sql") == True
