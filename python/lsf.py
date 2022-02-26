#!/usr/bin/env python3

from os import stat
from glob import glob
from .funcs import meets_numeric_criteria, meets_string_criteria, exclude_str_or_int
from .types_ import LsfArgs

STAT_FORMAT = '%p %Sp %l %u %Su %g %Sg %z %m %N'


def exclude_by_mode(criteria: str or int, actual: int, should_filter_by: bool) -> bool:
    return exclude_str_or_int(criteria, actual, should_filter_by)


def exclude_by_links(criteria: str, actual: int, should_filter_by: bool) -> bool:
    return should_filter_by and not meets_numeric_criteria(criteria, actual)


def exclude_by_user(criteria: str or int, actual: int, should_filter_by: bool) -> bool:
    return exclude_str_or_int(criteria, actual, should_filter_by)


def exclude_by_group(criteria: str or int, actual: int, should_filter_by: bool) -> bool:
    return exclude_str_or_int(criteria, actual, should_filter_by)


def exclude_by_size(criteria: str, actual: int, should_filter_by: bool) -> bool:
    return should_filter_by and not meets_numeric_criteria(criteria, actual)


def exclude_by_time(criteria: str or int, actual: int, should_filter_by: bool) -> bool:
    return exclude_str_or_int(criteria, actual, should_filter_by)


# TODO
def exclude_by_filename(criteria: str, actual: str, should_filter_by: bool) -> bool:
    return should_filter_by and meets_string_criteria(criteria, actual)


def main(dirpath: str, argtuple: LsfArgs):
    total = 0
    for file_ in glob(dirpath + '/*'):
        filestats = stat(file_)
        # TODO filename -> basename of file_
        filename = ''

        # exclude by filesonly/dirsonly

        if exclude_by_mode(argtuple.mode, filestats.st_mode, argtuple.mode.filter_by()):
            continue
        if exclude_by_links(argtuple.links, filestats.st_nlink, argtuple.links.filter_by()):
            continue
        if exclude_by_user(argtuple.username, filestats.st_uid, argtuple.username.filter_by()):
            continue
        if exclude_by_group(argtuple.groupname, filestats.st_gid, argtuple.groupname.filter_by()):
            continue
        if exclude_by_size(argtuple.size, filestats.st_size, argtuple.size.filter_by()):
            continue
        if exclude_by_time(argtuple.days, filestats.st_mtime, argtuple.days.filter_by()):
            continue
        if exclude_by_filename(argtuple.filename, filename, argtuple.filename.filter_by()):
            continue

        # TODO: check values
        modestr = ''
        linksstr = ''
        userstr = ''
        groupstr = ''
        sizestr = ''
        timestr = ''

        print(f'{modestr:-11} {linksstr:3} {userstr:-10} {groupstr:-10} {sizestr:6} {timestr} {filename}')


if __name__ == '__main__':
    main('')
