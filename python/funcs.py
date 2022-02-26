import re, subprocess


def comp_str_to_op(compexpr: str):
    comp_and_rhs = compexpr.replace(r'\s*', '')
    if len(comp_and_rhs) < 2:
        raise ValueError(f'Invalid expression length: {len(compexpr)}')

    try:
        if comp_and_rhs[0] == '=':
            return '__eq__', comp_and_rhs[1:]
        if comp_and_rhs[0] == '!':
            if comp_and_rhs[1] == '=':
                return '__ne__', comp_and_rhs[2:]
            raise ValueError(f'Operator \'!\' must be followed by \'=\'')
        if comp_and_rhs[0] == '<':
            if comp_and_rhs[1] == '=':
                return '__le__', comp_and_rhs[2:]
            return '__lt__', comp_and_rhs[1:]
        if comp_and_rhs[0] == '>':
            if comp_and_rhs[1] == '=':
                return '__ge__', comp_and_rhs[2:]
            return '__gt__', comp_and_rhs[1:]
    except IndexError:
        raise ValueError(f'Expression does not contain a number: {compexpr}')


def exc_comparison_str(lhs: int, compexpr: str) -> bool:
    comp_func, comp_to = comp_str_to_op(compexpr)
    return getattr(lhs, comp_func)(int(comp_to))


def meets_numeric_criteria(compexpr: str, actual: int) -> bool:
    return exc_comparison_str(actual, compexpr)


def meets_string_criteria(expected: str, actual: str, exact: bool = True) -> bool:
    if exact:
        return expected == actual
    return re.match(expected, actual) is not None


def stat_formatted(filepath: str, fmt: str) -> str:
    result = subprocess.run(f'stat -f {fmt} {filepath}', shell=True, capture_output=True)
    if result.returncode == 0:
        return result.stdout
    return ''


def exclude_str_or_int(criteria: str or int, actual: int, filter_by: bool) -> bool:
    if not filter_by:
        return False
    if isinstance(criteria, str):
        return not meets_numeric_criteria(criteria, actual)
    if isinstance(criteria, int):
        return criteria != actual
    raise TypeError
