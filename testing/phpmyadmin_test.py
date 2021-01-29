#!/usr/bin/env python2
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

def test_phpmyadmin(url, username, password, server, sqlfile):
    if sqlfile is None:
        if os.path.exists('/world.sql'):
            sqlfile = '/world.sql'
        elif os.path.exists('./world.sql'):
            sqlfile = './world.sql'
        else:
            path = os.path.dirname(os.path.realpath(__file__))
            sqlfile = path + '/world.sql'

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
    docker_secret('PMA_PASSWORD')
    docker_secret('PMA_HOSTS')
    docker_secret('PMA_HOST')
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

    assert(b'<tr><td class="e">max_execution_time</td><td class="v">125</td><td class="v">125</td></tr>' in response)

    assert(b'<tr><td class="e">upload_max_filesize</td><td class="v">123M</td><td class="v">123M</td></tr>' in response)
    assert(b'<tr><td class="e">post_max_size</td><td class="v">123M</td><td class="v">123M</td></tr>' in response)

    assert(b'<tr><td class="e">expose_php</td><td class="v">Off</td><td class="v">Off</td></tr>' in response)
