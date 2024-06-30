def f(s):
	r = {}
	for i in s:
    	if i in r:
        	r[i] += 1
    	else:
        	r[i] = 0
	return r