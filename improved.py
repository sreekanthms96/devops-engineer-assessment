def f(s):
    r = defaultdict(int)
    for i in s:
        r[i] += 1
    return dict(r)