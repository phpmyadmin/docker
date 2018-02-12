#!/usr/bin/env python
import argparse
import os
import re
import sys

import mechanize


def test_content(match, content):
    if not match in content:
        print(content)
        raise Exception('{0} not found in content!'.format(match))


def test_phpmyadmin(url, username, password, server=None, sqlfile=None):
    if sqlfile is None:
        if os.path.exists('/world.sql'):
            sqlfile = '/world.sql'
        elif os.path.exists('./world.sql'):
            sqlfile = './world.sql'
        else:
            sqlfile = './testing/world.sql'
    br = mechanize.Browser()

    # Ignore robots.txt
    br.set_handle_robots(False)

    # Login page
    br.open(url)

    # Fill login form
    br.select_form('login_form')
    br['pma_username'] = username
    br['pma_password'] = password
    if server is not None:
        br['pma_servername'] = server

    # Login and check if loggged in
    response = br.submit()
    test_content('Server version', response.read())

    # Open server import
    response = br.follow_link(text_regex=re.compile('Import'))
    test_content('OpenDocument Spreadsheet', response.read())

    # Upload SQL file
    br.select_form('import')
    br.form.add_file(open(sqlfile), 'text/plain', sqlfile)
    response = br.submit()
    test_content('5326 queries executed', response.read())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--url', required=True)
    parser.add_argument('--username', required=True)
    parser.add_argument('--password', required=True)
    parser.add_argument('--server')
    parser.add_argument('--sqlfile', default=None)
    args = parser.parse_args()

    test_phpmyadmin(
        args.url,
        args.username,
        args.password,
        args.server,
        args.sqlfile
    )


if __name__ == '__main__':
    main()
