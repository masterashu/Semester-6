# m = [ 11, 16, 21, 25 ]
# a = [  6, 13,  9, 19 ]
m = list(map(int, input('Enter m1, m2, ...: ').split()))
a = list(map(int, input('Enter a1, a2, ...: ').split()))
M = 1
for mi in m:
    M = M * mi
print('M = m1 * m2 * ... * mn = ', M)
for (ai, mi) in zip(a,m):
    print('xi = ', ai, '*', '(inv (',  M, '/', mi, ') %',mi,') *',  M//mi, '= ', ai * pow(M//mi,-1,mi) * M//mi)
x = sum([ ai * pow(M//mi,-1,mi) * M//mi for (ai,mi) in zip(a,m) ]) % M
print('X = (x1 + x2 + ... + xn) % ', M, '=', x)
