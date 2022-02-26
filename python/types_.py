from dataclasses import dataclass
from enum import Enum
from typing import Union


class ResultType(Enum):

    EITHER = 0
    FILESONLY = 1
    DIRSONLY = 2


class _StringMatchType(Enum):

    NOTHING = 0
    EXACT = 1
    PATTERN = 2

    @classmethod
    def det_type(cls, val, is_pattern: bool = False):
        if val is None:
            return _StringMatchType.NOTHING
        if isinstance(val, str):
            return 2 if is_pattern else 1
        raise TypeError


class _NumMatchType(Enum):

    NOTHING = 0
    EXACT = 1
    COMP_STR = 2

    @classmethod
    def det_type(cls, val):
        if val is None:
            return _NumMatchType.NOTHING
        if isinstance(val, str):
            return _NumMatchType.COMP_STR
        if isinstance(val, int):
            return _NumMatchType.EXACT
        raise TypeError


@dataclass
class StringMatch:

    type_: _StringMatchType
    value: str

    @classmethod
    def from_val(cls, val, is_pattern: bool = False):
        return StringMatch(_StringMatchType.det_type(val, is_pattern), val)

    def filter_by(self):
        return self.type_ != _StringMatchType.NOTHING


@dataclass
class NumMatch:

    type_: _NumMatchType
    value: Union[int, str]

    @classmethod
    def from_val(cls, val):
        return NumMatch(_NumMatchType.det_type(val), val)

    def filter_by(self):
        return self.type_ != _NumMatchType.NOTHING


@dataclass
class LsfArgs:

    type_excl: ResultType
    mode: Union[StringMatch, NumMatch]
    links: NumMatch
    username: StringMatch
    groupname: StringMatch
    size: NumMatch
    days: NumMatch
    filename: StringMatch
