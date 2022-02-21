#############################################################################
##
##  This file is part of GAP, a system for computational discrete algebra.
##
##  Copyright of GAP belongs to its developers, whose names are too numerous
##  to list here. Please refer to the COPYRIGHT file for details.
##
##  SPDX-License-Identifier: GPL-2.0-or-later
##

"""
This script is intended to iterate through package metadata in the repo:

      https://github.com/gap-system/PackageDistro

and do the following:

    * extract the `PackageInfoURL` field from the metadata
    * download the `PackageInfo.g` file from the URL
    * use GAP to compute the version number from the downloaded `PackageInfo.g`
      file
    * report whether or not there is a new version (higher version number) for
      the package.

usage:

    import scan_for_updates
    scan_for_updates.scan_for_updates("digraphs")
    digraphs: new version 1.5.0 detected, current distributed version is 1.3.1
"""

import json
import os
import subprocess
import sys

import requests


# print notices in green
def notice(msg):
    print("\033[32m" + msg + "\033[0m")


# print warnings in yellow
def warning(msg):
    print("\033[33m" + msg + "\033[0m")


# print error in red and exit
def error(msg):
    print("\033[31m" + msg + "\033[0m")
    sys.exit(1)


def gap_compare_version_numbers(pkg_name, pkg_info_fname, distro_version):
    with subprocess.Popen(
        r'echo "ScanForUpdates(\"{}\", \"{}\", \"{}\");"'.format(
            pkg_name, pkg_info_fname, distro_version
        ),
        stdout=subprocess.PIPE,
        shell=True,
    ) as cmd:
        with subprocess.Popen(
            "gap scan_for_updates.g",
            stdin=cmd.stdout,
            shell=True,
            stdout=subprocess.DEVNULL,
        ) as gap:
            gap.wait()

            with open(pkg_name + ".version", "r") as version_file:
                url_version = version_file.read().strip()
            return gap.returncode != 0, url_version


def scan_for_updates(pkg_name):
    # TODO assumes we are in the root of the repo:
    # https://github.com/gap-system/PackageDistro
    fname = os.path.join(pkg_name, pkg_name + ".json")
    with open(fname, "r") as f:
        pkg_json = json.load(f)
        distro_version = pkg_json[pkg_name]["Version"]
        url = pkg_json[pkg_name]["PackageInfoURL"]
        html_response = requests.get(url)
        if html_response.status_code != 200:
            error(
                "error trying to download {}, status code {}".format(
                    url, html_response.status_code
                )
            )
        pkg_info_fname = os.path.join(pkg_name, "PackageInfo.g")
        with open(pkg_info_fname, "w") as pif:
            pif.write(html_response.text)

        release_detected, url_version = gap_compare_version_numbers(
            pkg_name, pkg_info_fname, distro_version
        )
        if url_version.endswith("dev"):
            warn(
                "{}: invalid new version {} detected".format(
                    pkg_name, url_version
                )
            )
        elif release_detected:
            notice(
                "{}: new version {} detected, current distributed version is {}".format(
                    pkg_name, url_version, distro_version
                )
            )
