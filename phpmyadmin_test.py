#!/usr/bin/env python
import argparse
import re
import sys

import mechanize


def test_phpmyadmin(url, username, password, server=None, sqlfile='world.sql'):
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
    assert 'Server version' in response.read()

    # Open server import
    response = br.follow_link(text_regex=re.compile('Import'))
    assert 'OpenDocument Spreadsheet' in response.read()

    # Upload SQL file
    br.select_form(nr=4)
    br.form.add_file(open(sqlfile), 'text/plain', sqlfile)
    response = br.submit()
    assert '5326 queries executed' in response.read()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--url', required=True)
    parser.add_argument('--username', required=True)
    parser.add_argument('--password', required=True)
    parser.add_argument('--server')
    parser.add_argument('--sqlfile', default='world.sql')
    args = parser.parse_args()

    test_phpmyadmin(args.url, args.username, args.password, args.server, args.sqlfile)

if __name__ == '__main__':
    main()
