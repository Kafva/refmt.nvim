def functions_match(
    match: DependencyFunction,
    other
) \
 -> bool:
    '''
    Ensure that the arguments and return value of the provided function
    match that of the current function object. Does not check the filepath
    '''
    match_str = fmt_location(match.ident.location)
    other_str = fmt_location(other.ident.location)
    err = match.ident.eq_report(other.ident, return_value=True,
            check_function=True
    )

